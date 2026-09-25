"""
Unit tests for detect_anomaly.py (and a smoke test for render_intent.py).

Run:  python -m pytest monitoring/test_detect_anomaly.py -q
The detector is part of the control system, so it is tested like any other
code: each Western Electric rule has a positive and a negative case, and the
tier mapping and CLI contract are pinned.
"""
import json
import os
import sys

import pytest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import detect_anomaly as da  # noqa: E402
import render_intent as ri  # noqa: E402

WINDOW = 10


def baseline(n=WINDOW):
    """Alternating 9/11 series: mean 10, population std exactly 1."""
    return [9.0 if i % 2 == 0 else 11.0 for i in range(n)]


def rows_from(values):
    return [{"timestamp": f"t{i:03d}", "value": float(v)} for i, v in enumerate(values)]


def zs(values, window=WINDOW):
    return [s[2] if s else None for s in da.rolling_zscores(values, window, 1e-9)]


# ---------------------------------------------------------------- statistics
def test_rolling_baseline_excludes_current_point():
    vals = baseline() + [14.0]
    stats = da.rolling_zscores(vals, WINDOW, 1e-9)
    assert all(s is None for s in stats[:WINDOW])
    mean, std, z = stats[WINDOW]
    assert mean == pytest.approx(10.0)
    assert std == pytest.approx(1.0)
    assert z == pytest.approx(4.0)


def test_min_std_floor_prevents_division_by_zero():
    vals = [5.0] * WINDOW + [5.5]
    (_, std, z) = da.rolling_zscores(vals, WINDOW, 0.1)[WINDOW]
    assert std == 0.0
    assert z == pytest.approx(5.0)


def test_window_must_be_at_least_two():
    with pytest.raises(ValueError):
        da.rolling_zscores([1.0, 2.0, 3.0], 1, 1e-9)


# ---------------------------------------------------------------- rule WE1
def test_we1_fires_beyond_three_sigma():
    z = [None, 0.5, -3.2, 2.9, 3.01]
    assert da.rule_we1(z) == [2, 4]


def test_we1_does_not_fire_at_exactly_three():
    assert da.rule_we1([3.0, -3.0, 2.99]) == []


# ---------------------------------------------------------------- rule WE2
def test_we2_two_of_three_beyond_two_sigma_same_side():
    z = [0.0, 2.5, 0.3, 2.4]
    assert 3 in da.rule_we2(z)


def test_we2_requires_same_side():
    z = [0.0, 2.5, 0.3, -2.4]
    assert da.rule_we2(z) == []


def test_we2_negative_side():
    z = [0.0, -2.1, -2.2]
    assert da.rule_we2(z) == [2]


# ---------------------------------------------------------------- rule WE3
def test_we3_four_of_five_beyond_one_sigma():
    z = [1.5, 1.2, 0.2, 1.1, 1.3]
    assert da.rule_we3(z) == [4]


def test_we3_three_of_five_is_not_enough():
    z = [1.5, 0.2, 0.2, 1.1, 1.3]
    assert da.rule_we3(z) == []


# ---------------------------------------------------------------- rule WE4
def test_we4_eight_in_a_row_same_side():
    z = [0.1, 0.2, 0.3, 0.1, 0.4, 0.2, 0.3, 0.5]
    assert da.rule_we4(z) == [7]


def test_we4_seven_in_a_row_is_not_enough():
    z = [0.1] * 7 + [-0.1]
    assert da.rule_we4(z) == []


def test_rules_ignore_unevaluated_points():
    z = [None] * 7 + [0.5]
    assert da.rule_we4(z) == []
    assert da.rule_we3([None, 1.5, 1.5, 1.5, 1.5]) == []


# ---------------------------------------------------------------- detect()
def test_spike_maps_to_tier_three_and_is_active():
    vals = baseline() + [10.0, 10.0, 16.0]
    res = da.detect(rows_from(vals), window=WINDOW, lookback=1)
    rules = {v["rule"] for v in res["active_violations"]}
    assert "WE1" in rules
    assert res["highest_active_tier"] == 3
    assert res["response"]["action"] == "propose"


def test_drift_detected_by_we4_as_tier_one():
    # Small sustained shift (+0.5 sigma) that never crosses 1 sigma: only WE4 can see it.
    vals = baseline(20) + [10.5] * 8
    res = da.detect(rows_from(vals), window=20, lookback=1)
    rules = {v["rule"] for v in res["active_violations"]}
    assert rules == {"WE4"}
    assert res["highest_active_tier"] == 1
    assert res["response"]["action"] == "log"


def test_stable_series_has_no_violations():
    vals = baseline(40)
    res = da.detect(rows_from(vals), window=WINDOW, lookback=5)
    # Alternating series never has 8 same-side points or points beyond 1 sigma.
    assert res["violations"] == []
    assert res["highest_active_tier"] == 0
    assert res["response"]["action"] == "none"


def test_old_violation_is_not_active():
    vals = baseline() + [16.0] + baseline()
    res = da.detect(rows_from(vals), window=WINDOW, lookback=3)
    assert any(v["rule"] == "WE1" for v in res["violations"])
    assert all(v["rule"] != "WE1" for v in res["active_violations"])


def test_consecutive_firings_are_merged():
    vals = baseline(20) + [10.5] * 12
    res = da.detect(rows_from(vals), window=20, lookback=1)
    we4 = [v for v in res["violations"] if v["rule"] == "WE4"]
    assert len(we4) == 1
    assert we4[0]["end_index"] == len(vals) - 1


def test_custom_tier_actions_are_used():
    tiers = {1: {"action": "log"}, 2: {"action": "diagnose"}, 3: {"action": "page", "routes": ["runbook:x"]}}
    vals = baseline() + [20.0]
    res = da.detect(rows_from(vals), window=WINDOW, lookback=1, tiers=tiers)
    assert res["response"] == {"tier": 3, "action": "page", "tools": None, "routes": ["runbook:x"]}


def test_detection_is_deterministic_apart_from_timestamp():
    vals = baseline() + [10.0, 13.0, 16.0]
    a = da.detect(rows_from(vals), window=WINDOW)
    b = da.detect(rows_from(vals), window=WINDOW)
    a.pop("generated_at"), b.pop("generated_at")
    assert a == b


# ---------------------------------------------------------------- I/O + config
def test_load_csv_skips_bad_rows(tmp_path):
    p = tmp_path / "m.csv"
    p.write_text("timestamp,value\nt1,1.5\nt2,\nt3,abc\nt4,2\n", encoding="utf-8")
    assert da.load_csv(str(p)) == [{"timestamp": "t1", "value": 1.5}, {"timestamp": "t4", "value": 2.0}]


def test_load_csv_requires_header(tmp_path):
    p = tmp_path / "m.csv"
    p.write_text("a,b\n1,2\n", encoding="utf-8")
    with pytest.raises(ValueError):
        da.load_csv(str(p))


def test_mini_yaml_parser_matches_bands_file():
    with open(os.path.join(HERE, "bands.yaml"), encoding="utf-8") as fh:
        doc = da._mini_yaml(fh.read())
    m = doc["metrics"]["ci_test_failure_rate"]
    assert m["baseline"]["window"] == 20
    assert m["tiers"]["2sigma"]["tools"] == "Read,Grep,Bash(gh run view *)"
    assert m["tiers"]["3sigma"]["routes"] == ["pull_request", "runbook:rollback-deploy"]
    assert m["affected_systems"] == ["ci-pipeline", "main-branch"]


def test_cli_on_sample_csv_finds_drift_and_spike(tmp_path, capsys):
    out = tmp_path / "det.json"
    rc = da.main([os.path.join(HERE, "sample-metric.csv"), "--bands", os.path.join(HERE, "bands.yaml"),
                  "--metric", "ci_test_failure_rate", "--out", str(out), "--exit-code"])
    res = json.loads(out.read_text(encoding="utf-8"))
    assert rc == 3 == res["highest_active_tier"]
    rules = {v["rule"] for v in res["violations"]}
    assert "WE4" in rules            # drift
    assert "WE1" in rules            # spike
    assert res["response"]["routes"] == ["pull_request", "runbook:rollback-deploy"]


# ---------------------------------------------------------------- render_intent
def test_render_intent_produces_stage1_sections():
    vals = baseline() + [20.0]
    det = da.detect(rows_from(vals), window=WINDOW, lookback=1, metric="ci_test_failure_rate")
    md = ri.render(det, author="bot", owner="platform-ci", today="2026-09-01")
    for heading in ("## Problem", "## Proposed outcome", "## Affected users and systems",
                    "## Constraints", "## Open questions", "status: draft"):
        assert heading in md
    assert "INT-AUTO-20260901-ci-test-failure-rate" in md
    assert "WE1" in md


def test_render_intent_returns_none_without_active_violation():
    det = da.detect(rows_from(baseline(30)), window=WINDOW)
    assert ri.render(det, author="bot") is None
    assert ri.render(det, author="bot", force=True) is not None
