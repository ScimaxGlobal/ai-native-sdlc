# Metrics and KPIs

Each stage of the AI-native SDLC has at least one **leading** indicator (an early signal that the stage is working) and one **lagging** indicator (an outcome that confirms it over time). Because every stage produces a version-controlled artifact, most metrics can be computed from git and the git host without new instrumentation. The rest come from CI, OpenTelemetry, and your metrics store.

![](../05-Diagrams/09-metrics-by-stage.svg)

## Principles

1. **Measure the loop, not the model.** The question is whether ideas turn into safe production changes faster and with less rework, not how many lines Claude wrote.
2. **Pair every speed metric with a quality metric.** Faster first review is only good if pre-merge defects do not rise and production escapes fall.
3. **Prefer artifact-derived data.** Git timestamps and PR events are hard to game and already audited.
4. **Watch trends, not snapshots.** Many metrics here are expected to move in a direction (for example, policy-citing findings trending toward zero). Review the slope.
5. **Do not turn metrics into individual targets.** Use them to tune the system (skills, hooks, `CLAUDE.md`, bands), not to rank engineers.

## Conventions used in the examples

- Artifacts live at `work/<slug>/intent.md`, `work/<slug>/spec.md`, `work/<slug>/plan.md`. Adjust paths to your layout.
- Agent-authored PRs carry a label such as `agent-authored`, or are opened by the agent's bot identity.
- SQL examples assume PR and CI data has been exported to a warehouse table (for example, via the git host API or an ETL tool). Column names are illustrative.
- PromQL examples assume your OpenTelemetry collector exports to Prometheus. Metric names depend on your exporter and naming translation; check the [monitoring documentation](https://code.claude.com/docs/en/monitoring-usage) for the exact metric and attribute names your version emits.

---

## 1. Stage metrics

### Stage 1 - Plan (`intent.md`)

| Metric | Type | Definition | Formula | Data source | Target direction | Cadence |
|---|---|---|---|---|---|---|
| Conversation-to-intent time | Leading | Elapsed time from the start of the brainstorming conversation to the committed `intent.md` | `commit_time(intent.md) - conversation_start` | Git commit time; conversation start recorded in intent front matter (for example, `Started:` field) or session telemetry | Down (hours, not weeks) | Monthly |
| PO acceptance rate | Lagging | Share of submitted intents that the PO merges | `merged_intent_PRs / (merged + closed_unmerged)` | Git host PR data filtered to `work/**/intent.md` | Stable or up (a very high rate may mean the PO is not filtering) | Monthly |
| Intent churn after spec | Lagging | Number of changes to `intent.md` after `spec.md` exists | `count(commits to intent.md where time > first_commit(spec.md))` | Git history | Down | Monthly |

```bash
# Commits touching an intent after its spec first appeared
slug=claims-status-self-service
spec_first=$(git log --diff-filter=A --format=%ct -- work/$slug/spec.md | tail -1)
git log --format=%ct -- work/$slug/intent.md | awk -v t="$spec_first" '$1 > t' | wc -l

# PO acceptance rate for intent PRs in the last 90 days
gh pr list --state all --search "created:>=$(date -d '-90 days' +%F)" \
  --json number,state,files --limit 500 \
  | jq '[.[] | select(any(.files[]; .path | startswith("work/")))] 
        | {merged: map(select(.state=="MERGED")) | length,
           closed: map(select(.state=="CLOSED")) | length}'
```

### Stage 2 - Design (`spec.md`)

| Metric | Type | Definition | Formula | Data source | Target direction | Cadence |
|---|---|---|---|---|---|---|
| Intent-to-spec time | Leading | Elapsed time from `intent.md` commit to `spec.md` commit | `first_commit(spec.md) - first_commit(intent.md)` | Git history | Down | Monthly |
| Requirements rework | Lagging | Number of `spec.md` commits after the first `plan.md` commit | `count(commits to spec.md where time > first_commit(plan.md))` | Git history | Down | Monthly |
| Flag resolution time (supplementary) | Leading | Time from a policy flag raised in the spec PR to its resolution by a policy owner | `resolved_at - raised_at` | PR review threads | Down | Monthly |

```bash
slug=claims-status-self-service
i=$(git log --diff-filter=A --format=%ct -- work/$slug/intent.md | tail -1)
s=$(git log --diff-filter=A --format=%ct -- work/$slug/spec.md | tail -1)
echo "intent->spec hours: $(( (s - i) / 3600 ))"

p=$(git log --diff-filter=A --format=%ct -- work/$slug/plan.md | tail -1)
git log --format=%ct -- work/$slug/spec.md | awk -v t="$p" '$1 > t' | wc -l   # rework commits
```

### Stage 3 - Build (plan mode, `CLAUDE.md`, skills, parallel sessions)

| Metric | Type | Definition | Formula | Data source | Target direction | Cadence |
|---|---|---|---|---|---|---|
| First-pass merge share | Leading | Share of changes that merge on the first implementation pass (no second implementation cycle) | `changes_with_1_impl_cycle / all_changes` | PR data: count of "changes requested" reviews or re-implementation commits | Up | Bi-weekly |
| Rework cycles per change | Lagging | Average number of review-driven rework rounds per PR | `sum(changes_requested_reviews) / merged_PRs` | Git host reviews | Down | Monthly |
| Plan-to-diff consistency | Lagging | Share of files in the merged diff that were listed in `plan.md` "Files that change" | `files_in_diff ∩ files_in_plan / files_in_diff` | `plan.md` + PR diff | Up (and unplanned files explained by plan updates) | Monthly |
| Repeat-mistake rate | Leading | How often Claude repeats a mistake that `CLAUDE.md` should prevent | `review_findings_tagged("repeat") / merged_PRs` | PR comments tagged by reviewers; review tuning log | Down | Monthly |
| Time to first merged PR (new joiner) | Lagging | Days from a new team member's start to their first merged PR | `first_merge_date - start_date` | HR start date + git host | Down | Per cohort |
| Policy-to-skill lead time | Leading | Time from policy approval to the skill change merging | `skill_PR_merged_at - policy_approved_at` | Policy register + git host | Down | Per policy change |
| Policy-citing findings | Lagging | PR review findings that cite a policy a skill should enforce | `count(findings referencing policy X)` | PR comments (Claude and human) | Toward zero; if not, the skill is not triggering or has drifted | Monthly |
| Concurrent sessions per engineer | Leading | Parallel sessions an engineer runs while review quality holds | `avg(active_sessions per engineer per day)` with quality guard | OpenTelemetry session data | Up to the point where rework rises | Monthly |
| Throughput vs rework | Lagging | Changes merged per engineer per week, read against rework rate | `merged_PRs / engineer / week` paired with rework cycles | Git host | Throughput up with rework flat or down | Monthly |

```bash
# Plan-to-diff consistency for a PR
pr=1234
gh pr diff $pr --name-only | sort > /tmp/diff.txt
sed -n '/^## Files that change/,/^## /p' work/CLM-1427-claims-status-self-service/plan.md \
  | grep -oE '`[^`]+`' | tr -d '`' | sort > /tmp/plan.txt
echo "in plan: $(comm -12 /tmp/diff.txt /tmp/plan.txt | wc -l) / $(wc -l < /tmp/diff.txt)"
```

```sql
-- Rework cycles per merged PR, last 30 days
SELECT AVG(changes_requested_count) AS rework_cycles
FROM pull_requests
WHERE merged_at >= CURRENT_DATE - INTERVAL '30 days';
```

```promql
# Active sessions per engineer (illustrative metric and label names)
sum by (user_email) (increase(claude_code_session_count_total[1d]))
```

### Stage 4 - Test (feedback loops and evals)

| Metric | Type | Definition | Formula | Data source | Target direction | Cadence |
|---|---|---|---|---|---|---|
| First-pass CI success (agent changes) | Leading | Share of agent-written PRs whose first CI run passes | `agent_PRs_first_run_green / agent_PRs` | CI API, PR labels | Up | Weekly |
| Review time per PR | Lagging | Human review time from ready-for-review to approval | `approved_at - ready_at` | Git host | Down | Monthly |
| Change failure rate | Lagging | Share of deployments causing a failure in production (see DORA) | `failed_deploys / deploys` | Deploy log, incident tracker | Down | Monthly |
| Eval pass rate | Leading | Share of eval cases passing, tracked over time and per config change | `passed_cases / total_cases` | Eval CI job output | Stable high; drops on config change block merge | Per run, reviewed weekly |
| Incident-to-eval time | Lagging | Time from incident resolution to the regression eval merging | `eval_merged_at - incident_resolved_at` | Incident tracker + git | Down | Per incident |
| Regressions caught in CI vs production | Lagging | Ratio of config regressions caught by evals to those found in production | `ci_caught / (ci_caught + prod_found)` | Eval job history, incident tracker | Up | Quarterly |

```bash
# First CI run conclusion for recent agent-authored PRs
for pr in $(gh pr list --label agent-authored --state merged --limit 50 --json number -q '.[].number'); do
  sha=$(gh pr view $pr --json commits -q '.commits[0].oid')
  gh run list --commit "$sha" --limit 1 --json conclusion -q '.[0].conclusion'
done | sort | uniq -c

# Eval pass rate from the latest nightly run artifacts
jq -s '[.[] | .passed] | (map(select(.)) | length) / length' results/*.json
```

### Stage 5 - Deploy (review, gates, CI/CD)

| Metric | Type | Definition | Formula | Data source | Target direction | Cadence |
|---|---|---|---|---|---|---|
| Time to first review | Leading | Time from PR opened to the first review comment (Claude or human) | `first_review_at - opened_at` | Git host | Down (minutes) | Weekly |
| Comments resolved without human branch touch | Leading | Share of review comments resolved by Claude pushes, with no human commit on the branch | `resolved_by_agent / resolved_total` | PR timeline, commit authors | Up | Monthly |
| Pre-merge defects vs production escapes | Lagging | Defects found in review/CI versus defects found after release | `pre_merge / (pre_merge + escapes)` | PR findings tagged Important, incident tracker | Up | Monthly |
| Wait time per gate | Leading | Time an action waits at each approval gate | `gate_released_at - gate_requested_at` | OpenTelemetry events, hook logs, environment approvals | Down without increased violations | Monthly |
| Gate violations reaching production | Lagging | Count of changes that reached production without a required gate, before vs after hooks | `count(prod changes lacking gate evidence)` | Audit sampling, deploy log | Toward zero | Quarterly |
| Failures triaged without paging | Leading | Share of pipeline failures triaged by the agent without paging a human | `agent_triaged / pipeline_failures` | CI logs, `triage.md` outputs, paging system | Up | Monthly |
| DORA four keys | Lagging | See section 2 | | | | Monthly |

```bash
# Median minutes to first review for PRs opened in the last 14 days
gh pr list --state all --search "created:>=$(date -d '-14 days' +%F)" --limit 200 \
  --json number,createdAt,reviews \
  | jq '[.[] | select(.reviews|length>0)
        | ((.reviews[0].submittedAt|fromdateiso8601) - (.createdAt|fromdateiso8601))/60]
        | sort | .[length/2|floor]'
```

```sql
-- Share of review comments resolved with no human commit on the branch afterwards
SELECT
  SUM(CASE WHEN resolving_commit_author_type = 'bot' THEN 1 ELSE 0 END)::float
  / COUNT(*) AS resolved_without_human
FROM review_comments
WHERE resolved_at >= CURRENT_DATE - INTERVAL '30 days';
```

### Stage 6 - Maintain (close the loop)

| Metric | Type | Definition | Formula | Data source | Target direction | Cadence |
|---|---|---|---|---|---|---|
| Breach-to-intent time | Leading | Time from a control band breach to a diagnosis `intent.md` in the triage queue | `intent_committed_at - breach_detected_at` | Detection script log, git | Down | Monthly |
| Findings that become merged fixes | Lagging | Share of agent diagnoses that end as merged fixes | `diagnoses_with_merged_fix / diagnoses` | Triage decisions, git host | Up (dismissals feed band tuning) | Monthly |
| Repeat incidents | Lagging | Incidents of a class already seen and covered by an eval | `count(incidents with prior same class)` | Incident tracker | Down | Quarterly |
| Scan coverage | Leading | Share of in-scope repos on a recurring scan schedule | `scheduled_repos / in_scope_repos` | Scan tool | Up to 100% | Monthly |
| Finding-to-patch time | Leading | Time from scan finding to a patch PR | `patch_PR_opened_at - finding_at` | Scan export, git host | Down | Monthly |
| Scan-found vs externally found | Lagging | Vulnerabilities found by scans versus found in production or by external reporters | `scan_found / (scan_found + external)` | Scan tool, security tracker | Up | Quarterly |
| Findings per scan trend | Lagging | Findings per scheduled scan over time | `findings / scan` | Scan tool | Down | Monthly |

```promql
# Example control band input: CI test failure rate over 1h (your CI exporter's metric)
sum(rate(ci_test_failures_total[1h])) / sum(rate(ci_tests_total[1h]))

# Post-deploy 5xx rate
sum(rate(http_requests_total{code=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))
```

```bash
# Diagnosis intents created by the agent in the last 30 days, and how many led to merged fixes
gh pr list --state all --label agent-diagnosis --search "created:>=$(date -d '-30 days' +%F)" \
  --json number,state -q 'group_by(.state) | map({(.[0].state): length}) | add'
```

---

## 2. DORA four keys

The DORA metrics remain the outcome measures for delivery performance. The AI-native loop should improve throughput (deployment frequency, lead time) without harming stability (change failure rate, time to restore).

| Key | Definition | Formula | Data source | Direction |
|---|---|---|---|---|
| Deployment frequency | How often you deploy to production | `count(prod deploys) / period` | Deploy pipeline | Up |
| Lead time for changes | Time from commit to running in production | `median(deployed_at - first_commit_at)` | Git + deploy log | Down |
| Change failure rate | Share of deployments that cause a failure needing remediation | `failed_deploys / deploys` | Deploy log + incidents | Down |
| Time to restore service | Time to recover from a failure in production | `median(restored_at - started_at)` | Incident tracker | Down |

For AI-native teams it is also useful to extend lead time upstream: **idea-to-production time** from `intent.md` first commit to production deploy. This captures the planning and design acceleration that DORA's commit-based lead time misses.

```sql
-- Lead time for changes (median hours), last 30 days
SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (
  ORDER BY EXTRACT(EPOCH FROM (d.deployed_at - c.first_commit_at))/3600)
FROM deployments d JOIN changes c ON c.id = d.change_id
WHERE d.env = 'production' AND d.deployed_at >= CURRENT_DATE - INTERVAL '30 days';
```

---

## 3. Platform and cost metrics

These support operating decisions rather than stage outcomes.

| Metric | Why it matters | Source |
|---|---|---|
| Cost per merged PR | Detects cost overrun and inefficient sessions | OpenTelemetry cost metric divided by merged PRs |
| Token usage by model | Supports model selection and budget | OpenTelemetry |
| Tool permission decisions (accept/reject) | High rejection rates signal prompt fatigue or missing allow rules | OpenTelemetry tool decision data |
| Hook block count by hook | Shows which guardrails fire, and where teams hit friction | Hook logs |
| Managed settings compliance | Share of endpoints reporting the required minimum version and managed config | MDM, telemetry |

```promql
# Cost per day by model (illustrative names)
sum by (model) (increase(claude_code_cost_usage_total[1d]))
```

---

## 4. Review cadence

| Forum | Cadence | Metrics reviewed | Decision owner |
|---|---|---|---|
| Team retro | Bi-weekly | First-pass merge, rework, first-pass CI, repeat mistakes | Tech lead |
| Review tuning | Monthly | Finding ratings, nits, policy-citing findings, time to first review | Tech lead |
| Platform review | Monthly | Eval pass rate, hook blocks, gate wait times, cost | Platform lead |
| Service review | Monthly | Band breaches, breach-to-intent, fix rate, repeat incidents | Service owner |
| Security review | Monthly | Scan coverage, finding-to-patch, dismissals, scan vs external | Security lead |
| Leadership review | Quarterly | DORA, idea-to-production, adoption, cost, gate violations | Engineering leadership |

---

## 5. Sample dashboard layout

```
+------------------------------------------------------------------------------------+
| AI-NATIVE SDLC - Org overview                           [Team v] [Last 30 days v]  |
+--------------------+--------------------+--------------------+---------------------+
| Deploy frequency   | Lead time (median) | Change failure rate| Time to restore     |
|   42 / week  ^     |   19 h  v          |   4.1%  v          |   38 min  v         |
+--------------------+--------------------+--------------------+---------------------+
| PLAN / DESIGN                           | BUILD / TEST                              |
|  Conversation->intent (h)   [sparkline] |  First-pass merge share     [sparkline]   |
|  PO acceptance rate         [bar]       |  Rework cycles per PR       [sparkline]   |
|  Intent->spec (h)           [sparkline] |  First-pass CI (agent PRs)  [sparkline]   |
|  Spec rework after plan     [bar]       |  Eval pass rate + config changes [line]   |
+-----------------------------------------+-------------------------------------------+
| DEPLOY                                  | MAINTAIN                                  |
|  Time to first review (min) [line]      |  Band breaches by tier      [stacked bar] |
|  Resolved w/o human touch   [gauge]     |  Breach->intent (h)         [sparkline]   |
|  Pre-merge vs escapes       [ratio]     |  Diagnoses -> merged fixes  [gauge]       |
|  Gate wait time by gate     [box plot]  |  Scan coverage / find->patch [bars]       |
+-----------------------------------------+-------------------------------------------+
| PLATFORM: cost per merged PR | hook blocks by hook | sessions per engineer | version |
+------------------------------------------------------------------------------------+
```

Design notes:
- Top row: DORA, so the dashboard always leads with outcomes.
- Each stage panel shows one leading and one lagging metric side by side.
- Annotate configuration changes (model swap, `CLAUDE.md`, skill, hook changes) on time series so shifts can be attributed.
- Link each tile to the underlying query and to the owner in [Roles-and-RACI.md](Roles-and-RACI.md).

## Related

- [Control-Bands-and-Anomaly-Detection.md](../02-Guides/Control-Bands-and-Anomaly-Detection.md)
- [Evals-Guide.md](../02-Guides/Evals-Guide.md)
- [Adoption-Roadmap.md](Adoption-Roadmap.md) - which metrics to switch on in each phase

---

*Based on concepts from Anthropic's AI-Native SDLC Playbook; expanded guidance for implementation.*
