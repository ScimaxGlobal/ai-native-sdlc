# Sources and Further Reading

## Primary source

This kit expands on concepts from Anthropic's blog post:

- **The AI-Native SDLC Playbook** - https://claude.com/blog/the-ai-native-sdlc-playbook

The playbook describes the stage-by-stage model (intent, spec, plan, feedback loops and evals, bi-directional review and gates, closed-loop maintenance), the artifact chain, and the governance principle that control objectives are kept while enforcement mechanisms change. This kit's text is original elaboration and implementation guidance; for the authors' own framing, read the source.

A related post referenced in the source discusses AI-assisted CI/CD and on-call practice at Anthropic ("AI-CI/CD on call at Anthropic").

## Claude Code documentation

Documentation root: https://code.claude.com/docs (also available via docs.claude.com).

| Topic | Link | Used in this kit for |
|---|---|---|
| Overview | https://code.claude.com/docs/en/overview | Product capabilities and surfaces |
| Settings | https://code.claude.com/docs/en/settings | Settings files, precedence, managed-only keys |
| Hooks | https://code.claude.com/docs/en/hooks | PreToolUse/PostToolUse, exit codes, approval gates |
| Skills | https://code.claude.com/docs/en/skills | `SKILL.md` structure and triggering |
| Sub-agents | https://code.claude.com/docs/en/sub-agents | `.claude/agents/`, tool restrictions |
| Identity and access (IAM) | https://code.claude.com/docs/en/iam | Authentication, permissions |
| Sandboxing | https://code.claude.com/docs/en/sandboxing | Filesystem and network isolation |
| GitHub Actions | https://code.claude.com/docs/en/github-actions | `claude-code-action`, CI integration |
| Monitoring usage | https://code.claude.com/docs/en/monitoring-usage | OpenTelemetry metrics and events |
| MCP | https://code.claude.com/docs/en/mcp | MCP servers, managed MCP |
| Plugins | https://code.claude.com/docs/en/plugins | Plugins and marketplaces |

The source also points readers, in rough adoption order, to: the admin setup decision map, server-managed settings via the admin console, permissions, the hooks guide and reference, private plugin marketplaces, enterprise deployment (Amazon Bedrock, Google Vertex AI, Microsoft Foundry), enterprise network configuration, the analytics dashboard, the Compliance API, and the security model. Find these from the documentation root.

## Delivery performance

- **DORA** (DevOps Research and Assessment) - https://dora.dev - research program behind the four key metrics (deployment frequency, lead time for changes, change failure rate, time to restore service) and the annual State of DevOps reports.

## Secure development

- **NIST SP 800-218, Secure Software Development Framework (SSDF) Version 1.1** - https://csrc.nist.gov/pubs/sp/800/218/final - practice groups Prepare the Organization (PO), Protect the Software (PS), Produce Well-Secured Software (PW), and Respond to Vulnerabilities (RV). Used for the indicative mapping in [Controls-Matrix.md](../04-Governance/Controls-Matrix.md).
- **AICPA Trust Services Criteria** (SOC 2) and **ISO/IEC 27001:2022** - consult the official publications from AICPA and ISO for the authoritative control text.

## Statistical process control

- **Western Electric rules** - decision rules for detecting non-random patterns on control charts, originally published in the Western Electric *Statistical Quality Control Handbook* (1956). Overview: https://en.wikipedia.org/wiki/Western_Electric_rules
- **NIST/SEMATECH e-Handbook of Statistical Methods**, section on control charts - https://www.itl.nist.gov/div898/handbook/pmc/section3/pmc3.htm

## Related material in this kit

- [../00-Playbook/AI-Native-SDLC-Playbook.md](../00-Playbook/AI-Native-SDLC-Playbook.md)
- [../01-Stages/](../01-Stages/01-Plan-Intent.md) - six stage guides
- [../02-Guides/](../02-Guides/CLAUDE-md-Guide.md) - implementation guides
- [../04-Governance/README.md](../04-Governance/README.md)

## Acknowledgments

The source playbook credits **Jim Blackhurst**, **Will Steuk**, and **Jamal Arif**. Their framing of the AI-native SDLC is the foundation for this kit. Any errors or extensions in this expanded guidance are the responsibility of the kit's maintainers, not the original authors.

## Notes on currency

Product features referenced here (for example, managed Code Review, Claude Security, Claude Tag) were described in the source as available or in public beta at the time of writing. Check current documentation for availability, plan requirements, and exact configuration keys before relying on them.

---

*Based on concepts from Anthropic's AI-Native SDLC Playbook; expanded guidance for implementation.*
