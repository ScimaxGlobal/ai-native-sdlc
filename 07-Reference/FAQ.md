# Frequently Asked Questions

Answers are grouped by audience, but most readers will find useful material in every section. Terms are defined in [Glossary.md](Glossary.md).

---

## For executives

**1. What is an AI-native SDLC, in one sentence?**
A delivery lifecycle where AI works inside every stage, each stage produces a version-controlled artifact the next stage reads, and humans decide at the gates that matter.

**2. Why change the process at all? Can we not just give engineers a coding assistant?**
You can, and code will get written faster. But planning, review, security, and release governance are sized for human output. When code volume multiplies, those stages become the bottleneck, and security in particular cannot keep up. The AI-native model redesigns those stages so they scale too.

**3. Are we removing controls to go faster?**
No. The control objectives stay the same: segregation of duties, change approval, review, traceability, release authorization. The mechanisms change from meetings and manual sign-offs to artifacts, hooks, managed settings, and branch protection, which enforce the controls at the moment of action. See [Controls-Matrix.md](../04-Governance/Controls-Matrix.md).

**4. What results should we expect, and how will we know?**
Faster idea-to-production time, faster first review, less rework, and stable or better change failure rates. Track DORA four keys plus stage metrics in [Metrics-and-KPIs.md](../04-Governance/Metrics-and-KPIs.md). Pair every speed metric with a quality metric.

**5. How long does adoption take?**
A pilot team can reach plan-first, self-verifying work in about two to three months. Reaching closed-loop operations across many services typically takes most of a year. See [Adoption-Roadmap.md](../04-Governance/Adoption-Roadmap.md).

**6. What does it cost?**
Costs are seats or API usage, platform engineering time (hooks, evals, CI), and training. Nightly evals and recurring scans add usage; set budgets and spend limits and watch cost per merged PR.

**7. What happens to our people?**
Roles shift toward judgment: product owners review and decide rather than write first drafts; engineers write and interrogate plans and steer several sessions; tech leads tune review; platform engineers build guardrails. See [Roles-and-RACI.md](../04-Governance/Roles-and-RACI.md).

**8. What is the biggest risk?**
Over-trust. Review rubber-stamping and automation bias rank alongside prompt injection and secret leakage. Mitigations are in [Risk-Register.md](../04-Governance/Risk-Register.md).

## For engineers

**9. Do I have to use plan mode for everything?**
For any non-trivial change, yes: nothing gets implemented without an accepted written plan. Small, obvious fixes can skip `plan.md` if your team agrees, but still need the feedback loop.

**10. How detailed should `plan.md` be?**
Detailed enough that someone who did not write it could implement the change from the plan alone: files that change, order of work, risks, and how you will prove it works.

**11. What goes in `CLAUDE.md` versus a skill?**
`CLAUDE.md` holds project context a new team member needs on day one (commands, conventions, architecture, common mistakes). A skill holds institutional knowledge that is enforced inconsistently across teams and has an owner (for example, a secure API review policy). See [CLAUDE-md-Guide.md](../02-Guides/CLAUDE-md-Guide.md) and [Skills-Guide.md](../02-Guides/Skills-Guide.md).

**12. My `CLAUDE.md` keeps growing. Is that a problem?**
Yes. Keep it under a page. Add a correction when a mistake appears twice, and prune anything Claude reliably gets right or that belongs in a skill.

**13. How many parallel sessions should I run?**
Start with two or three in separate worktrees. Increase only while your review quality and rework rate hold.

**14. What is a subagent for?**
A scoped helper with its own context window and restricted tools, such as a verifier that runs the app and exercises the changed flow and two neighbors, then reports without fixing.

**15. Why can Claude not edit the tests when fixing a bug?**
Because the failing test is the specification of the fix. If the agent can edit the test, it can make it pass without fixing the bug. A hook or review rule blocks test edits during a fix.

**16. Who is responsible for code Claude wrote?**
The engineer who steered the session and submitted the PR. Sessions are attributed to the steering engineer.

**17. Does Claude's review replace human review?**
No. Claude's findings neither approve nor block. A code owner still approves, and should focus on intent and risk. See [PR-Review-Guide.md](../02-Guides/PR-Review-Guide.md).

**18. When should I tag `@claude` on a review comment?**
When a comment asks for a change that is clear and bounded. Claude fixes and pushes, and the exchange stays in the thread as a record.

**19. When is auto mode appropriate?**
For routine work once the guardrails are mature: a tuned `CLAUDE.md`, policy skills, safe-action hooks, and a strong test suite. Review then shifts to the artifacts produced after longer autonomous sessions.

## For security

**20. How do we keep secrets out of the model's context?**
Managed `permissions.deny` rules for credential paths (for example, `~/.ssh`, `~/.aws/credentials`), stripping secrets from the environment, secret-scan hooks, and short-lived CI tokens. See [Managed-Settings-Guide.md](../02-Guides/Managed-Settings-Guide.md).

**21. Can engineers turn the guardrails off?**
Not if they are in managed settings. Settings such as `disableBypassPermissionsMode`, `allowManagedPermissionRulesOnly`, and `allowManagedHooksOnly` prevent local overrides.

**22. How do we handle prompt injection?**
Assume untrusted content will contain instructions. Limit blast radius: sandbox with a domain allowlist, deny rules on secrets, read-only tools when processing untrusted input, no production credentials, and human approval for writes via PR.

**23. How do we stop unvetted plugins and MCP servers?**
Use `strictKnownMarketplaces` and `disableSideloadFlags` to restrict plugins to the org marketplace, and `allowManagedMcpServersOnly` for MCP. Review each addition with the [Security-Review-Checklist.md](../06-Checklists/Security-Review-Checklist.md).

**24. Can the agent deploy to production?**
It can prepare everything up to the production gate. A named release manager authorizes the production step, enforced by environment approvals and a gate hook. Autonomy is tiered by environment.

**25. What if the sandbox fails to start?**
With `failIfUnavailable`, the session refuses to start rather than running unsandboxed. This treats the sandbox as a gate.

**26. Are skills enough to enforce secure coding rules?**
No. Skills are advisory. Any rule that must hold needs a deterministic hook, setting, or CI check behind it.

**27. How are recurring security scans different from a one-off scan?**
A scan is a point-in-time snapshot, while code and models keep changing. Recurring scans run on a schedule with no human in the path and route findings through the same gates as any other change. See [Recurring-Security-Scans.md](../02-Guides/Recurring-Security-Scans.md).

## For compliance and audit

**28. Where is the evidence that a change was approved?**
In git and the git host: the merged `intent.md` PR (PO approval), the spec PR (PO sign-off with policy owner comments), the committed `plan.md`, and the code PR with code-owner approval. See [Audit-Evidence-Guide.md](../04-Governance/Audit-Evidence-Guide.md).

**29. How is segregation of duties preserved when an agent writes the code?**
The code-writing agent has no approval route. Branch protection requires a human code-owner approval, and non-interactive runs use a distinct agent identity that cannot approve.

**30. How do we show that the CAB's objectives are still met?**
Change management lists the gates that must survive; platform engineers express each as a hook, branch rule, or environment approval. The evidence (hook logs, PR records, approvals) is richer than meeting minutes.

**31. Does this map to SOC 2, ISO 27001, or NIST SSDF?**
At a high level, yes: the controls matrix includes an indicative mapping. It is not compliance advice; confirm scope and sufficiency with your auditors. See [Controls-Matrix.md](../04-Governance/Controls-Matrix.md).

**32. What if our requirements must live in Jira or ServiceNow?**
Choose one authoritative system per artifact. If the legacy tool is authoritative, markdown files are working copies. Either way, artifacts carry the record ID and records carry the commit SHA. See [Source-of-Truth-and-Legacy-Systems.md](../02-Guides/Source-of-Truth-and-Legacy-Systems.md).

**33. How are on-call investigations recorded?**
When Claude acts as first responder in a Slack channel, the channel history is the audit trail: who asked what, what Claude found, and what was decided. Post-mortems go to a versioned lessons folder.

**34. How do we know agent configuration changes did not degrade quality?**
Changes to `CLAUDE.md`, skills, hooks, prompts, or models trigger the eval suite, and the pass-rate threshold is a required merge check. See [Evals-Guide.md](../02-Guides/Evals-Guide.md).

**35. Does a model decide when something is anomalous in production?**
No. Detection is a deterministic, versioned, unit-tested script using rolling statistics and Western Electric rules. Claude only diagnoses and proposes within the tier the breach allows.

---

*Based on concepts from Anthropic's AI-Native SDLC Playbook; expanded guidance for implementation.*
