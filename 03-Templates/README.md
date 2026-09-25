# 03 — Templates

Copy-paste templates and working scripts for running the AI-native SDLC in a real
repository. Each stage produces a version-controlled artifact that the next stage
reads: **intent.md → spec.md → plan.md → code + tests → PR → production signals →
new intent.md**. This folder gives you the files for each of those steps and the
guardrails around them.

> Based on ideas from Anthropic's *The AI-Native SDLC Playbook* (claude.com/blog).
> All templates and scripts here are original. Claude Code syntax was checked
> against code.claude.com/docs in September 2026. Keys that could not be confirmed
> are marked **verify** in [`settings/README.md`](settings/README.md).

---

## Template index

| Template (this folder) | Purpose | Place it in a real repo at | Owner | Stage |
|---|---|---|---|---|
| [`intent.template.md`](intent.template.md) | One-page proto-spec of a problem and desired outcome | `work/_templates/intent.md`; instances in `work/<ID>-<slug>/intent.md` | Originator writes; product owner approves by merging | 1 Plan |
| [`spec.template.md`](spec.template.md) | Combined requirements + design, policy applied while writing | `work/_templates/spec.md`; instances in `work/<ID>-<slug>/spec.md` | Product owner; policy owners resolve flagged concerns | 2 Design |
| [`plan.template.md`](plan.template.md) | Accepted implementation plan from plan mode | `work/_templates/plan.md`; instances in `work/<ID>-<slug>/plan.md` | Implementing engineer (tech lead for high risk) | 3 Build |
| [`examples/intent.claims-status.md`](examples/intent.claims-status.md) | Worked example: claims-status self-service | reference only | — | 1 |
| [`examples/spec.claims-status.md`](examples/spec.claims-status.md) | Worked example spec (four claim states, 50 rps limit, deferred adjuster question) | reference only | — | 2 |
| [`examples/plan.claims-status.md`](examples/plan.claims-status.md) | Worked example plan (files, order, risks, proof) | reference only | — | 3 |
| [`CLAUDE.template.md`](CLAUDE.template.md) | Day-one context for Claude: commands, architecture, conventions, verification | `CLAUDE.md` (repo root) | Code owners | 3 Build / 4 Test |
| [`examples/CLAUDE.payments-java.md`](examples/CLAUDE.payments-java.md) | Filled CLAUDE.md for a Java 21 / Spring Boot 3 payments service | reference only | — | 3 |
| [`REVIEW.template.md`](REVIEW.template.md) | Instructions for automated PR review: three passes, severity, nit cap, skips | `REVIEW.md` (repo root) | Tech lead | 5 Deploy |
| [`skills/secure-api-review/SKILL.md`](skills/secure-api-review/SKILL.md) + [`scripts/check-endpoints.sh`](skills/secure-api-review/scripts/check-endpoints.sh) | API security policy as a skill, with a heuristic endpoint checker | `.claude/skills/secure-api-review/` or org plugin | AppSec (named policy owner) | 2, 3, 5 |
| [`skills/intent-writer/SKILL.md`](skills/intent-writer/SKILL.md) | Brainstorm-to-intent.md skill for non-engineers | `.claude/skills/intent-writer/` or org plugin | Product operations | 1 |
| [`skills/spec-writer/SKILL.md`](skills/spec-writer/SKILL.md) | intent.md → spec.md with policy skills applied | `.claude/skills/spec-writer/` or org plugin | Product ops + architecture | 2 |
| [`commands/write-spec.md`](commands/write-spec.md) | `/write-spec work/<ID>-<slug>/intent.md` slash command | `.claude/commands/write-spec.md` | Product operations | 2 |
| [`agents/verifier.md`](agents/verifier.md) | Subagent: runs the app, exercises change + 2 neighboring flows, never fixes | `.claude/agents/verifier.md` | Tech lead | 3, 4 |
| [`agents/test-writer.md`](agents/test-writer.md) | Subagent: writes failing tests first; test files only | `.claude/agents/test-writer.md` | Tech lead / QA | 4 |
| [`agents/security-reviewer.md`](agents/security-reviewer.md) | Read-only security review subagent, preloads secure-api-review | `.claude/agents/security-reviewer.md` | AppSec | 3, 5 |
| [`settings/project-settings.json`](settings/project-settings.json) | Team permissions + hook wiring | `.claude/settings.json` | Tech lead / platform | 3–5 |
| [`settings/managed-settings.json`](settings/managed-settings.json) | Regulated-enterprise policy engineers cannot override | MDM / admin console / system `managed-settings.json` | Platform + security, compliance sign-off | 5 |
| [`settings/README.md`](settings/README.md) | Explanation of every settings key, with verify notes | keep with your settings | Platform | — |
| [`hooks/production-gate.sh`](hooks/production-gate.sh) / [`.ps1`](hooks/production-gate.ps1) | PreToolUse: block production deploys without `RELEASE_APPROVAL` | `.claude/hooks/` (or managed path) | Platform, per change-management | 5 |
| [`hooks/protect-paths.sh`](hooks/protect-paths.sh) / [`.ps1`](hooks/protect-paths.ps1) + [`protected-paths.example.txt`](hooks/protected-paths.example.txt) | PreToolUse: block edits to listed paths | `.claude/hooks/` + `.claude/protected-paths.txt` | Code owners | 3 |
| [`hooks/protect-tests.sh`](hooks/protect-tests.sh) | PreToolUse: block test edits while fix mode is on | `.claude/hooks/` | Tech lead | 4 |
| [`hooks/post-edit-format.sh`](hooks/post-edit-format.sh) | PostToolUse: format only the changed file | `.claude/hooks/` | Tech lead | 3 |
| [`hooks/block-secrets.sh`](hooks/block-secrets.sh) | PreToolUse: keep secrets out of context and out of commits | `.claude/hooks/` (and managed) | Security | 3–5 |
| [`ci/agent-evals.yml`](ci/agent-evals.yml) | Eval suite on agent-config PRs + nightly; fails below threshold | `.github/workflows/` | Platform (config owners) | 4 |
| [`ci/claude-pr-review.yml`](ci/claude-pr-review.yml) | claude-code-action review + `@claude` responder | `.github/workflows/` | Tech lead + platform | 5 |
| [`ci/triage-on-failure.yml`](ci/triage-on-failure.yml) | Read-only CI failure triage (flaky vs real) | `.github/workflows/` | Platform | 5 |
| [`ci/scheduled-anomaly-check.yml`](ci/scheduled-anomaly-check.yml) | Deterministic detection → intent.md PR for triage | `.github/workflows/` | Service owner + platform | 6 |
| [`ci/gitlab-ci.example.yml`](ci/gitlab-ci.example.yml) | GitLab equivalents (evals, triage, anomaly) | merge into `.gitlab-ci.yml` | Platform | 4–6 |
| [`evals/schema.json`](evals/schema.json) | JSON Schema for an eval case | `evals/schema.json` | Platform | 4 |
| [`evals/example-eval.json`](evals/example-eval.json) | Example case: fix a bug without touching tests or logging PII | `evals/<id>.json` | Owning team | 4 |
| [`evals/run-evals.sh`](evals/run-evals.sh) | Runs every case in an isolated worktree, writes results, prints pass rate | `evals/` | Platform | 4 |
| [`evals/check.sh`](evals/check.sh) | Evaluates one case's checks against the result | `evals/` | Platform | 4 |
| [`monitoring/bands.yaml`](monitoring/bands.yaml) | Versioned control bands and tier → action mapping | `monitoring/` | Service owner | 6 |
| [`monitoring/detect_anomaly.py`](monitoring/detect_anomaly.py) | Deterministic detector: rolling mean/std + 4 Western Electric rules, no LLM | `monitoring/` | Service owner / SRE | 6 |
| [`monitoring/test_detect_anomaly.py`](monitoring/test_detect_anomaly.py) | pytest suite for the detector (26 tests) | `monitoring/` | Service owner / SRE | 6 |
| [`monitoring/sample-metric.csv`](monitoring/sample-metric.csv) | 60 days of sample data with a drift and a spike | test fixture | — | 6 |
| [`monitoring/render_intent.py`](monitoring/render_intent.py) | Detection JSON → Stage-1 intent.md draft | `monitoring/` | Service owner | 6 |
| [`lessons/postmortem.template.md`](lessons/postmortem.template.md) | Blameless post-mortem that feeds future investigations and evals | `lessons/<date>-<slug>.md` | Incident owner | 6 |

---

## Recommended repository layout

```text
your-repo/
├── CLAUDE.md                      # day-one context (CLAUDE.template.md)
├── REVIEW.md                      # automated-review instructions (REVIEW.template.md)
├── work/                          # one folder per change: <ID>-<slug>/{intent,spec,plan}.md
│   ├── _templates/{intent,spec,plan}.md
│   └── CLM-1427-claims-status-self-service/{intent,spec,plan}.md
├── .claude/
│   ├── settings.json              # permissions + hook wiring (project-settings.json)
│   ├── protected-paths.txt        # read by protect-paths hook
│   ├── skills/
│   │   ├── secure-api-review/{SKILL.md,scripts/check-endpoints.sh}
│   │   ├── intent-writer/SKILL.md
│   │   └── spec-writer/SKILL.md
│   ├── agents/{verifier,test-writer,security-reviewer}.md
│   ├── commands/write-spec.md
│   └── hooks/{production-gate,protect-paths,protect-tests,post-edit-format,block-secrets}.sh
├── evals/                         # Stage 4: agent-config regression suite
│   ├── schema.json
│   ├── run-evals.sh
│   ├── check.sh
│   └── <case-id>.json
├── monitoring/                    # Stage 6: bands + deterministic detector
│   ├── bands.yaml
│   ├── detect_anomaly.py
│   ├── test_detect_anomaly.py
│   └── render_intent.py
├── lessons/                       # post-mortems read by future investigations
└── .github/workflows/{agent-evals,claude-pr-review,triage-on-failure,scheduled-anomaly-check}.yml
```

---

## Install into a repo

Run from the root of the target repository. `KIT` is this folder.

```bash
KIT=/path/to/AI-Native-SDLC/03-Templates

# 1. Artifact folders and templates
mkdir -p work/_templates lessons evals/results monitoring .claude/{skills,agents,commands,hooks} .github/workflows
cp "$KIT/intent.template.md" work/_templates/intent.md
cp "$KIT/spec.template.md"   work/_templates/spec.md
cp "$KIT/plan.template.md"   work/_templates/plan.md
cp "$KIT/lessons/postmortem.template.md" lessons/_template.md

# 2. Root files — then EDIT them for your service (keep CLAUDE.md under a page)
[ -f CLAUDE.md ] || cp "$KIT/CLAUDE.template.md" CLAUDE.md
[ -f REVIEW.md ] || cp "$KIT/REVIEW.template.md" REVIEW.md

# 3. Claude Code configuration
cp -r "$KIT/skills/"*   .claude/skills/
cp    "$KIT/agents/"*.md .claude/agents/
cp    "$KIT/commands/"*.md .claude/commands/
cp    "$KIT/hooks/"*.sh  .claude/hooks/            # add *.ps1 on Windows-native teams
chmod +x .claude/hooks/*.sh .claude/skills/secure-api-review/scripts/*.sh
cp "$KIT/hooks/protected-paths.example.txt" .claude/protected-paths.txt   # then edit
[ -f .claude/settings.json ] || cp "$KIT/settings/project-settings.json" .claude/settings.json

# 4. Evals and monitoring
cp "$KIT/evals/"{schema.json,run-evals.sh,check.sh} evals/ && chmod +x evals/*.sh
cp "$KIT/evals/example-eval.json" evals/    # replace with 20–50 real tasks
echo "evals/results/" >> .gitignore
cp "$KIT/monitoring/"{bands.yaml,detect_anomaly.py,test_detect_anomaly.py,render_intent.py,sample-metric.csv} monitoring/

# 5. CI (GitHub) — or merge ci/gitlab-ci.example.yml into .gitlab-ci.yml
cp "$KIT/ci/"{agent-evals,claude-pr-review,triage-on-failure,scheduled-anomaly-check}.yml .github/workflows/
```

Then:

1. **Install `jq`** on developer machines and CI (hooks fall back to Python if it is missing, which is slower — about 1–3 s per hook call on Windows).
2. **Edit** `CLAUDE.md`, `REVIEW.md`, `.claude/protected-paths.txt`, the `AUTH_PATTERN` in `check-endpoints.sh`, and the example hosts/metrics in `bands.yaml`.
3. **Secrets:** add `ANTHROPIC_API_KEY` (and `PROMETHEUS_URL` for anomaly checks) to CI; install the Claude GitHub App (`/install-github-app`).
4. **Branch protection:** require code-owner approval and make `agent-evals` a required check. Claude's review never approves.
5. **Managed settings** (regulated orgs): have platform/security deploy `settings/managed-settings.json` through MDM or the admin console after reading [`settings/README.md`](settings/README.md). With `allowManagedHooksOnly`, the project hooks stop running — list the hooks you need in managed settings.
6. **Verify:** start `claude` in the repo, run `/status`, `/permissions`, `/hooks`, and `/agents`; then run the self-tests below.

### Self-tests

```bash
# Hooks (each should print 2 then 0)
echo '{"tool_input":{"command":"deploy production"}}' | bash .claude/hooks/production-gate.sh; echo $?
echo '{"tool_input":{"command":"make test"}}'         | bash .claude/hooks/production-gate.sh; echo $?

# Detector
python -m pytest monitoring/test_detect_anomaly.py -q
python monitoring/detect_anomaly.py monitoring/sample-metric.csv \
  --bands monitoring/bands.yaml --metric ci_test_failure_rate --out /tmp/det.json --exit-code; echo "tier=$?"
python monitoring/render_intent.py /tmp/det.json

# Settings are valid JSON (a broken managed file stops Claude Code from starting)
python -m json.tool .claude/settings.json > /dev/null && echo settings OK
```

---

## Source of truth for legacy trackers

Pick **one** authoritative system per artifact and write it in the frontmatter
`source_of_truth` field:

- **Repo authoritative** — the markdown file is the record; the legacy ticket links to the commit.
- **Legacy authoritative** (Jira, ServiceNow) — the ticket is the record; markdown is a working copy.

Either way, the minimum linkage is: every artifact carries the legacy record ID
(`legacy_record`), and the legacy record carries the commit SHA.

## Advisory vs enforced

Skills and CLAUDE.md are **advisory** — they shape what Claude does. Hooks,
permissions, sandboxing and branch protection are **enforced**. Any rule that
must hold (secrets, protected paths, production gate, test integrity during
fixes) is backed here by a hook, and the non-negotiable ones belong in managed
settings.
