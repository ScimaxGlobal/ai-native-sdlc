# Diagrams

All diagrams are hand-authored SVG (scalable, diff-able, editable in any text editor or tools such as Inkscape,
Figma or draw.io). A 2× PNG rendering of each is in [`png/`](png/) for use in slides, Word documents or wikis that
do not render SVG. Every diagram has a white background so it reads correctly in dark-mode viewers.

| # | Diagram | Shows | Used in |
|---|---|---|---|
| 1 | [01-ai-native-loop.svg](01-ai-native-loop.svg) | The six stages as a loop with human gates at the centre | Playbook §2, stage READMEs |
| 2 | [02-traditional-vs-ai-native.svg](02-traditional-vs-ai-native.svg) | Stage-by-stage comparison of mechanisms | Playbook §2 |
| 3 | [03-artifact-chain.svg](03-artifact-chain.svg) | `intent.md → spec.md → plan.md → code → PR`, with gates and feedback | Playbook §4 |
| 4 | [04-control-layers.svg](04-control-layers.svg) | Advisory vs deterministic vs non-overridable controls | Playbook §11.3, Governance |
| 5 | [05-response-tiers.svg](05-response-tiers.svg) | Control chart with 1σ/2σ/3σ bands and response tiers | Stage 6, Control Bands guide |
| 6 | [06-autonomy-by-environment.svg](06-autonomy-by-environment.svg) | What the agent may do in dev, staging and production | Stage 5, CI/CD guide |
| 7 | [07-adoption-roadmap.svg](07-adoption-roadmap.svg) | Phased rollout with deliverables | Playbook §14, Adoption Roadmap |
| 8 | [08-pr-review-flow.svg](08-pr-review-flow.svg) | Bi-directional AI review and human approval | Stage 5, PR Review guide |
| 9 | [09-metrics-by-stage.svg](09-metrics-by-stage.svg) | Leading and lagging metrics per stage | Playbook §12, Metrics & KPIs |

`05-response-tiers.svg` is generated from synthetic data (noise, a slow drift and a spike) purely to illustrate
the tiers; it is not real measurement data.

Additional diagrams are embedded as **Mermaid** code blocks directly in the markdown files (flowcharts, sequence
diagrams, Gantt charts). They render natively on GitHub, GitLab, Azure DevOps wikis, VS Code (with the Markdown
Preview Mermaid extension) and Obsidian.

## Regenerating the PNGs

```powershell
$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
Get-ChildItem *.svg | ForEach-Object {
  $c = Get-Content $_.FullName -Raw
  if ($c -match 'viewBox="0 0 (\d+) (\d+)"') { $w = $matches[1]; $h = $matches[2] }
  & $chrome --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=2 `
    --window-size=$w,$h --screenshot="$PWD\png\$($_.BaseName).png" "file:///$($_.FullName -replace '\\','/')"
}
```
