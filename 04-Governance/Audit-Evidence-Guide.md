# Audit Evidence Guide

In a traditional SDLC much audit evidence is assembled after the fact: meeting minutes, signed change forms, screenshots of approvals. In an AI-native SDLC most evidence is a **by-product of doing the work**. Every stage commits an artifact to git; every review happens in a PR thread; every gate is a hook, a branch rule, or an environment approval that leaves a record; every session emits telemetry. This guide lists, gate by gate, what evidence exists and how an auditor retrieves it.

> This guide describes evidence sources and retrieval techniques. It is not a statement of what any particular audit standard requires. Confirm scope and sufficiency with your auditors.

## Evidence sources at a glance

| Source | What it proves | Retention driver | Access for auditors |
|---|---|---|---|
| **Git history** | Who authored each artifact, when, and every revision | Repository retention; protect from force-push on main | Read-only repo access or exported bundle |
| **PR thread** | Review comments (Claude and human), findings, fixes via `@claude`, approvals, required checks | Git host retention policy | Read-only repo access; API export |
| **Branch protection / CODEOWNERS** | That approval rules were in force | Git host audit log | Admin export or screenshot with date |
| **Hook logs** | Which gates fired, what was blocked, the reason given | Log pipeline retention | Log platform query |
| **Managed settings** | The non-overridable policy on endpoints | MDM and version control of the settings file | MDM report; settings file history |
| **OpenTelemetry** | Sessions, attribution, tool decisions, cost, timing | Telemetry backend retention | Dashboard or query access |
| **Compliance API** | Organization-level activity records (enterprise plans) | Per plan and export schedule | Export produced by admin |
| **CI/CD logs and environment approvals** | Which identity ran what; who authorized production | CI platform retention | CI API export |
| **Eval results** | That configuration changes passed the regression suite | Artifact retention in CI | CI artifacts, required check status |
| **Scan tool records** | Findings, confidence, dispositions with reasons | Scan tool retention; export to tracker | Export (CSV, Markdown) or tracker query |
| **Slack channel history** | On-call investigation, who steered, decisions | Workspace retention policy | Workspace export or eDiscovery |
| **Lessons folder** | Post-mortems and learnings | Git | Read-only repo access |

---

## Evidence by gate

### Gate 1 - Intent accepted (Plan)

| Evidence | Where | How to retrieve |
|---|---|---|
| Author and timestamp of `intent.md` | Git | `git log --format='%H %an %ae %aI %s' -- work/<slug>/intent.md` |
| PO approval (merge) or rejection (closed) | PR | `gh pr list --state all --search "<slug>" --json number,state,mergedBy,mergedAt,closedAt` |
| Revision history | Git | `git log -p -- work/<slug>/intent.md` |
| Link to legacy record, if Option B source of truth | Artifact header; legacy tool | `grep -i 'record' work/<slug>/intent.md`; check legacy record for commit SHA |

### Gate 2 - Spec signed off (Design)

| Evidence | Where | How to retrieve |
|---|---|---|
| Spec author and timestamp | Git | `git log --format='%an %aI' -- work/<slug>/spec.md` |
| Skills and versions applied in the design pass | Session logs / telemetry; PR description if recorded | Query telemetry for the session; check PR body |
| Flagged policy concerns and resolutions | PR review threads | `gh api repos/{owner}/{repo}/pulls/<n>/comments` |
| Policy owner decisions | PR thread (named reviewer) | `gh pr view <n> --json reviews` |
| PO decision to proceed | PR merge | `gh pr view <n> --json mergedBy,mergedAt` |

### Gate 3 - Plan accepted (Build)

| Evidence | Where | How to retrieve |
|---|---|---|
| `plan.md` committed before implementation | Git order of commits | `git log --format='%aI %s' --reverse -- work/<slug>/plan.md src/` and confirm plan precedes code |
| Plan revisions when implementation departed | Git (same commit as code change) | `git log -p -- work/<slug>/plan.md` |
| Attribution of steering engineer | Commit author; telemetry | `git log --format='%an' <range>`; session telemetry |
| Build-time hook enforcement (protected paths, lint) | Hook logs | Query log platform for hook name and repo |
| Configuration in force (`CLAUDE.md`, skills, hooks) | Git at commit SHA | `git show <sha>:CLAUDE.md`; `git show <sha>:.claude/settings.json` |

### Gate 4 - Verified (Test)

| Evidence | Where | How to retrieve |
|---|---|---|
| CI results on the PR | CI / required checks | `gh pr checks <n>` |
| Failing test committed before fix (bug fixes) | Git history | `git log --format='%h %s' -- tests/<file>` showing test commit precedes fix |
| No test edits during fix | Hook logs; PR diff | Hook block records; `gh pr diff <n> --name-only \| grep -i test` |
| Eval pass rate for config changes | CI artifacts and checks | `gh run list --workflow agent-evals.yml --json conclusion,createdAt,headSha` then download artifacts |

### Gate 5 - Merged (Deploy: review)

| Evidence | Where | How to retrieve |
|---|---|---|
| Claude review findings | PR thread | `gh pr view <n> --comments` |
| Human code-owner approval | PR reviews | `gh pr view <n> --json reviews -q '.reviews[] \| select(.state=="APPROVED") \| .author.login'` |
| Approver differs from author; agent identity did not approve | PR metadata | Compare `author.login` with approvers; confirm bot identities absent from approvers |
| Branch protection in force at merge time | Git host audit log / settings | `gh api repos/{owner}/{repo}/branches/main/protection` (current) plus audit log for history |
| Fixes applied via `@claude` recorded in thread | PR timeline | `gh api repos/{owner}/{repo}/issues/<n>/timeline` |

### Gate 6 - Released to production (Deploy: authorization)

| Evidence | Where | How to retrieve |
|---|---|---|
| Named release manager authorization | CI environment approvals | CI platform API for deployment approvals (for GitHub: `gh api repos/{owner}/{repo}/actions/runs/<id>/approvals`) |
| Release gate hook decisions | Hook logs | Log query for `production-gate` blocks and allows |
| Agent acted only up to the gate | CI run identity and step logs | `gh run view <id> --log` |
| Wait time per gate | OpenTelemetry | Telemetry query for gate events |
| Rollback readiness (rehearsal in staging) | CI history for rollback workflow | `gh run list --workflow rollback.yml --json conclusion,createdAt` |

### Gate 7 - Anomaly detected and triaged (Maintain)

| Evidence | Where | How to retrieve |
|---|---|---|
| Detection rules and band config in force | Git (`bands.yaml`, detection script, unit tests) | `git log -p -- ops/bands.yaml` |
| Breach events and tier invoked | Detection script logs | Log query by metric and time window |
| Agent diagnosis as `intent.md` | Git | `git log --format='%an %aI' -- work/<anomaly-slug>/intent.md` |
| Triage decision (fix, schedule, dismiss) with reason | PR or tracker | `gh pr view <n> --json state,comments` |
| On-call investigation and steering | Slack channel history | Workspace export or eDiscovery search by channel and date |
| Post-mortem | Lessons folder | `git log -- lessons/` |
| Regression eval added after fix | Git | `git log --diff-filter=A -- evals/` around the fix date |

### Gate 8 - Vulnerability found and remediated (Maintain: scans)

| Evidence | Where | How to retrieve |
|---|---|---|
| Repo on scan schedule | Scan tool configuration | Admin view or export |
| Findings with confidence rating | Scan tool | Export as CSV or Markdown, or webhook into tracker |
| Dismissals with logged reasons | Scan tool / tracker | Export filtered to dismissed |
| Patch PR and approval | Git host | `gh pr list --label security --state merged` |
| Vulnerability-class eval added | Git | `git log --diff-filter=A -- evals/` |

---

## Platform-level evidence

| Control | Evidence | Retrieval |
|---|---|---|
| Managed settings baseline | Versioned settings file; MDM deployment report | `git log -p -- managed-settings/`; MDM compliance report |
| Minimum client version | `requiredMinimumVersion` in managed settings; telemetry version attribute | Settings history; telemetry query grouped by version |
| Marketplace restrictions | `strictKnownMarketplaces`, `disableSideloadFlags` in managed settings; marketplace repo history | Settings file; `git log` of marketplace repo |
| MCP allowlist | `allowManagedMcpServersOnly` and approved server list | Settings file history |
| Session attribution and usage | OpenTelemetry | Dashboard, or queries in [Metrics-and-KPIs.md](Metrics-and-KPIs.md) |
| Organization activity | Compliance API (where available) | Admin-produced export following the product documentation |

---

## Auditor walkthrough: tracing one change end to end

1. **Pick a production deployment** from the deploy log; note the commit SHA.
2. **Find the PR:** `gh pr list --search <sha> --state merged`.
3. **From the PR, find the plan and spec:** the PR description or `plan.md` header links to the intent slug. Open `work/<slug>/`.
4. **Confirm the chain order:** `git log --format='%aI %an %s' -- work/<slug>/` shows intent, then spec, then plan, before code commits.
5. **Confirm approvals:** intent PR merged by the PO; spec PR merged by the PO with policy owner comments; code PR approved by a code owner who is not the author.
6. **Confirm verification:** `gh pr checks <n>` shows required checks green; if the change touched `CLAUDE.md` or `.claude/`, the eval check is present.
7. **Confirm release authorization:** CI environment approval by a named release manager; no production credentials used by the agent identity.
8. **Confirm configuration in force:** `git show <sha>:.claude/settings.json` and the managed settings version on the date.
9. **Record the sample** with links for each step.

## Evidence retention checklist

- [ ] Force-push and branch deletion disabled on protected branches.
- [ ] Git host audit log retained for the audit period.
- [ ] CI logs and artifacts (including eval results) retained for the audit period, or exported.
- [ ] Hook logs shipped to a central log platform.
- [ ] OpenTelemetry backend retention matches policy.
- [ ] Slack retention for incident channels matches policy.
- [ ] Scan findings exported to the system of record.
- [ ] Managed settings file under version control with change approval.

## Related

- [Controls-Matrix.md](Controls-Matrix.md)
- [Source-of-Truth-and-Legacy-Systems.md](../02-Guides/Source-of-Truth-and-Legacy-Systems.md)
- [Stage-Gate-Checklists.md](../06-Checklists/Stage-Gate-Checklists.md)

---

*Based on concepts from Anthropic's AI-Native SDLC Playbook; expanded guidance for implementation.*
