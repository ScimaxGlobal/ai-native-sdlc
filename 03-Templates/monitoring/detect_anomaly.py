#!/usr/bin/env python3
"""
detect_anomaly.py - deterministic control-band detection for Stage 6 (Maintain).

NO language model is used here. Whether a metric is anomalous is decided by
arithmetic that is versioned, unit-tested (test_detect_anomaly.py) and
reproducible. Claude is only invoked afterwards, with the permissions of the
tier that was breached (see bands.yaml and ci/scheduled-anomaly-check.yml).

Method
------
For each point i with at least `window` predecessors:
    mean_i, std_i = mean/std of the `window` points BEFORE i (rolling baseline;
                    the point itself is excluded so a spike cannot hide itself)
    z_i           = (x_i - mean_i) / max(std_i, min_std)

The four Western Electric rules are then applied to the z sequence:
    WE1  one point beyond 3 sigma                               -> tier 3
    WE2  2 of 3 consecutive points beyond 2 sigma, same side    -> tier 2
    WE3  4 of 5 consecutive points beyond 1 sigma, same side    -> tier 1
    WE4  8 consecutive points on the same side of the mean      -> tier 1 (drift)

Tier -> action mapping comes from bands.yaml (1sigma: log, 2sigma: diagnose,
3sigma: propose by default). Consecutive firings of the same rule are merged
into one violation with a start and end. A violation is "active" when it ends
within the last `lookback` points; only active violations drive a response.

Usage
-----
    python detect_anomaly.py metric.csv
    python detect_anomaly.py metric.csv --bands bands.yaml --metric ci_test_failure_rate
    python detect_anomaly.py metric.csv --window 20 --lookback 5 --exit-code

Input CSV: header row with columns `timestamp,value` (extra columns ignored).
Output: JSON on stdout (or --out FILE).
Exit: 0, or with --exit-code the highest ACTIVE tier (0-3) so CI can branch.
"""
from __future__ import annotations

import argparse
import csv
import json
import math
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Sequence

# --------------------------------------------------------------------------
# Defaults (overridden by bands.yaml, then by CLI flags)
# --------------------------------------------------------------------------
DEFAULT_WINDOW = 20
DEFAULT_LOOKBACK = 5
DEFAULT_MIN_STD = 1e-9
DEFAULT_TIERS = {
    1: {"action": "log"},
    2: {"action": "diagnose"},
    3: {"action": "propose"},
}

RULES = {
    "WE1": {"tier": 3, "description": "1 point beyond 3 sigma"},
    "WE2": {"tier": 2, "description": "2 of 3 consecutive points beyond 2 sigma on the same side"},
    "WE3": {"tier": 1, "description": "4 of 5 consecutive points beyond 1 sigma on the same side"},
    "WE4": {"tier": 1, "description": "8 consecutive points on the same side of the mean (drift)"},
}


# --------------------------------------------------------------------------
# Data loading
# --------------------------------------------------------------------------
def load_csv(path: str) -> List[Dict[str, Any]]:
    """Read `timestamp,value` rows. Blank/non-numeric values are skipped."""
    rows: List[Dict[str, Any]] = []
    with open(path, newline="", encoding="utf-8") as fh:
        reader = csv.DictReader(fh)
        if reader.fieldnames is None or "timestamp" not in reader.fieldnames or "value" not in reader.fieldnames:
            raise ValueError("CSV must have a header with 'timestamp' and 'value' columns")
        for r in reader:
            raw = (r.get("value") or "").strip()
            try:
                v = float(raw)
            except ValueError:
                continue
            if math.isnan(v) or math.isinf(v):
                continue
            rows.append({"timestamp": (r.get("timestamp") or "").strip(), "value": v})
    return rows


def load_bands(path: str, metric: str) -> Dict[str, Any]:
    """Return the config block for `metric` from bands.yaml.

    Uses PyYAML when installed; otherwise a minimal parser that understands
    the subset used by bands.yaml (nested mappings, scalars, inline lists,
    comments). Keeping a fallback means the detector has no hard dependency.
    """
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    try:
        import yaml  # type: ignore
        doc = yaml.safe_load(text)
    except ImportError:
        doc = _mini_yaml(text)
    metrics = (doc or {}).get("metrics", {})
    if metric not in metrics:
        raise KeyError(f"metric '{metric}' not found in {path}; have: {sorted(metrics)}")
    return metrics[metric]


def _mini_yaml(text: str) -> Dict[str, Any]:
    """Tiny indentation-based YAML subset parser (mappings + inline lists)."""
    def scalar(s: str) -> Any:
        s = s.strip()
        if not s:
            return {}
        if s[0] in "\"'" and s[-1] == s[0]:
            return s[1:-1].replace('\\"', '"')
        if s.startswith("[") and s.endswith("]"):
            return [scalar(x) for x in _split_inline(s[1:-1])] if s[1:-1].strip() else []
        low = s.lower()
        if low in ("true", "false"):
            return low == "true"
        if low in ("null", "~"):
            return None
        try:
            return int(s)
        except ValueError:
            pass
        try:
            return float(s)
        except ValueError:
            return s

    root: Dict[str, Any] = {}
    stack = [(-1, root)]
    for raw in text.splitlines():
        line = _strip_comment(raw).rstrip()
        if not line.strip():
            continue
        indent = len(line) - len(line.lstrip(" "))
        key, _, rest = line.strip().partition(":")
        while stack and stack[-1][0] >= indent:
            stack.pop()
        parent = stack[-1][1]
        if rest.strip() == "":
            child: Dict[str, Any] = {}
            parent[key.strip()] = child
            stack.append((indent, child))
        else:
            parent[key.strip()] = scalar(rest)
    return root


def _strip_comment(line: str) -> str:
    """Remove a trailing '# comment' that is not inside quotes."""
    out, quote = [], None
    for i, ch in enumerate(line):
        if quote:
            if ch == quote and line[i - 1] != "\\":
                quote = None
        elif ch in "\"'":
            quote = ch
        elif ch == "#" and (i == 0 or line[i - 1] in " \t"):
            break
        out.append(ch)
    return "".join(out)


def _split_inline(s: str) -> List[str]:
    parts, cur, quote = [], [], None
    for ch in s:
        if quote:
            quote = None if ch == quote else quote
        elif ch in "\"'":
            quote = ch
        elif ch == ",":
            parts.append("".join(cur)); cur = []; continue
        cur.append(ch)
    parts.append("".join(cur))
    return [p for p in (x.strip() for x in parts) if p]


# --------------------------------------------------------------------------
# Statistics
# --------------------------------------------------------------------------
@dataclass
class Point:
    index: int
    timestamp: str
    value: float
    mean: Optional[float] = None
    std: Optional[float] = None
    z: Optional[float] = None


def rolling_zscores(values: Sequence[float], window: int, min_std: float) -> List[Optional[tuple]]:
    """For each i, (mean, std, z) from the `window` points before i, else None.

    Population standard deviation over the window. `min_std` floors the
    denominator so a perfectly flat baseline does not produce division by zero.
    """
    if window < 2:
        raise ValueError("window must be >= 2")
    out: List[Optional[tuple]] = []
    for i, x in enumerate(values):
        if i < window:
            out.append(None)
            continue
        base = values[i - window:i]
        m = sum(base) / window
        var = sum((b - m) ** 2 for b in base) / window
        sd = math.sqrt(var)
        z = (x - m) / max(sd, min_std)
        out.append((m, sd, z))
    return out


# --------------------------------------------------------------------------
# Western Electric rules — each returns the list of indices where the rule
# is satisfied by the run ENDING at that index.
# --------------------------------------------------------------------------
def _k_of_n(z: Sequence[Optional[float]], k: int, n: int, limit: float) -> List[int]:
    hits = []
    for end in range(len(z)):
        start = end - n + 1
        if start < 0:
            continue
        win = z[start:end + 1]
        if any(v is None for v in win):
            continue
        # The run's last point must itself be beyond the limit (anchors the alarm).
        last = win[-1]
        for sign in (1, -1):
            if sign * last > limit and sum(1 for v in win if sign * v > limit) >= k:
                hits.append(end)
                break
    return hits


def rule_we1(z: Sequence[Optional[float]]) -> List[int]:
    return [i for i, v in enumerate(z) if v is not None and abs(v) > 3.0]


def rule_we2(z: Sequence[Optional[float]]) -> List[int]:
    return _k_of_n(z, 2, 3, 2.0)


def rule_we3(z: Sequence[Optional[float]]) -> List[int]:
    return _k_of_n(z, 4, 5, 1.0)


def rule_we4(z: Sequence[Optional[float]], run: int = 8) -> List[int]:
    hits = []
    for end in range(run - 1, len(z)):
        win = z[end - run + 1:end + 1]
        if any(v is None for v in win):
            continue
        if all(v > 0 for v in win) or all(v < 0 for v in win):
            hits.append(end)
    return hits


RULE_FUNCS = {"WE1": rule_we1, "WE2": rule_we2, "WE3": rule_we3, "WE4": rule_we4}
RULE_SPAN = {"WE1": 1, "WE2": 3, "WE3": 5, "WE4": 8}


def _merge_runs(indices: List[int]) -> List[tuple]:
    """Group consecutive indices into (first, last) runs."""
    runs: List[tuple] = []
    for i in sorted(indices):
        if runs and i == runs[-1][1] + 1:
            runs[-1] = (runs[-1][0], i)
        else:
            runs.append((i, i))
    return runs


# --------------------------------------------------------------------------
# Main detection
# --------------------------------------------------------------------------
def detect(rows: List[Dict[str, Any]], window: int = DEFAULT_WINDOW, lookback: int = DEFAULT_LOOKBACK,
           min_std: float = DEFAULT_MIN_STD, tiers: Optional[Dict[int, Dict[str, Any]]] = None,
           metric: str = "metric") -> Dict[str, Any]:
    tiers = tiers or DEFAULT_TIERS
    values = [r["value"] for r in rows]
    stats = rolling_zscores(values, window, min_std)
    z = [s[2] if s else None for s in stats]

    violations: List[Dict[str, Any]] = []
    for rule, fn in RULE_FUNCS.items():
        for first_end, last_end in _merge_runs(fn(z)):
            start = max(0, first_end - RULE_SPAN[rule] + 1)
            tier = RULES[rule]["tier"]
            worst = max(range(start, last_end + 1), key=lambda k: abs(z[k]) if z[k] is not None else -1)
            violations.append({
                "rule": rule,
                "description": RULES[rule]["description"],
                "tier": tier,
                "action": tiers.get(tier, {}).get("action", DEFAULT_TIERS[tier]["action"]),
                "start_index": start,
                "end_index": last_end,
                "start_timestamp": rows[start]["timestamp"],
                "end_timestamp": rows[last_end]["timestamp"],
                "peak": {
                    "timestamp": rows[worst]["timestamp"],
                    "value": values[worst],
                    "z": round(z[worst], 3) if z[worst] is not None else None,
                    "baseline_mean": round(stats[worst][0], 6) if stats[worst] else None,
                    "baseline_std": round(stats[worst][1], 6) if stats[worst] else None,
                },
                "active": last_end >= len(rows) - lookback,
            })
    violations.sort(key=lambda v: (v["end_index"], -v["tier"], v["rule"]))

    active = [v for v in violations if v["active"]]
    highest = max((v["tier"] for v in active), default=0)
    last = len(rows) - 1
    latest = None
    if rows:
        latest = {
            "timestamp": rows[last]["timestamp"],
            "value": values[last],
            "baseline_mean": round(stats[last][0], 6) if stats[last] else None,
            "baseline_std": round(stats[last][1], 6) if stats[last] else None,
            "z": round(z[last], 3) if z[last] is not None else None,
        }

    return {
        "metric": metric,
        "generated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "method": "rolling mean/std + Western Electric rules (deterministic, no model)",
        "parameters": {"window": window, "lookback": lookback, "min_std": min_std},
        "points": len(rows),
        "evaluated_points": sum(1 for v in z if v is not None),
        "latest": latest,
        "violations": violations,
        "active_violations": active,
        "highest_active_tier": highest,
        "response": {
            "tier": highest,
            "action": tiers.get(highest, {}).get("action", "none") if highest else "none",
            "tools": tiers.get(highest, {}).get("tools") if highest else None,
            "routes": tiers.get(highest, {}).get("routes") if highest else None,
        },
    }


def _tiers_from_bands(cfg: Dict[str, Any]) -> Dict[int, Dict[str, Any]]:
    """Map bands.yaml keys '1sigma','2sigma','3sigma' to tier numbers."""
    out: Dict[int, Dict[str, Any]] = {}
    for key, val in (cfg.get("tiers") or {}).items():
        digits = "".join(ch for ch in str(key) if ch.isdigit())
        if digits:
            out[int(digits)] = dict(val or {})
    return out or DEFAULT_TIERS


def main(argv: Optional[Sequence[str]] = None) -> int:
    ap = argparse.ArgumentParser(description="Deterministic control-band anomaly detection (no LLM).")
    ap.add_argument("csv", help="CSV file with timestamp,value columns")
    ap.add_argument("--bands", help="bands.yaml path")
    ap.add_argument("--metric", help="metric name in bands.yaml (also used as the output label)")
    ap.add_argument("--window", type=int, help="rolling baseline window (points)")
    ap.add_argument("--lookback", type=int, help="points at the end considered 'active'")
    ap.add_argument("--min-std", type=float, help="floor for the baseline standard deviation")
    ap.add_argument("--out", help="write JSON here instead of stdout")
    ap.add_argument("--exit-code", action="store_true", help="exit with the highest active tier (0-3)")
    args = ap.parse_args(argv)

    cfg: Dict[str, Any] = {}
    extra: Dict[str, Any] = {}
    if args.bands:
        if not args.metric:
            ap.error("--metric is required with --bands")
        cfg = load_bands(args.bands, args.metric)
        extra = {k: cfg.get(k) for k in ("description", "owner", "unit", "source", "affected_systems") if k in cfg}
    base = cfg.get("baseline") or {}
    window = args.window or int(base.get("window", DEFAULT_WINDOW))
    lookback = args.lookback or int(cfg.get("lookback", DEFAULT_LOOKBACK))
    min_std = args.min_std if args.min_std is not None else float(base.get("min_std", DEFAULT_MIN_STD))
    tiers = _tiers_from_bands(cfg) if cfg else DEFAULT_TIERS

    rows = load_csv(args.csv)
    result = detect(rows, window=window, lookback=lookback, min_std=min_std, tiers=tiers,
                    metric=args.metric or "metric")
    if extra:
        result["metric_info"] = extra
        if base.get("label"):
            result["parameters"]["baseline_label"] = base["label"]
    result["input"] = args.csv

    text = json.dumps(result, indent=2)
    if args.out:
        with open(args.out, "w", encoding="utf-8") as fh:
            fh.write(text + "\n")
    else:
        print(text)
    return result["highest_active_tier"] if args.exit_code else 0


if __name__ == "__main__":
    sys.exit(main())
