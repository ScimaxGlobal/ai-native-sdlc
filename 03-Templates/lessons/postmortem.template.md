---
# ---------------------------------------------------------------------------
# Post-mortem — Stage 6 (Maintain) artifact
# Copy to: lessons/<YYYY-MM-DD>-<service>-<short-slug>.md
# Written by: incident owner (human) or Claude as first responder, reviewed by
# the service owner. Blameless. Future investigations read this folder, so be
# specific about signals and fixes.
# ---------------------------------------------------------------------------
id: PM-YYYY-NNN
title: "<What broke, in user terms>"
service: "<service>"
severity: SEV-3              # SEV-1 | SEV-2 | SEV-3 | SEV-4
detected: YYYY-MM-DDTHH:MMZ
resolved: YYYY-MM-DDTHH:MMZ
detected_by: monitoring      # monitoring | customer | engineer | scan | claude-on-call
authors: ["<name>"]
legacy_record: ""            # incident ticket ID (e.g. INC0012345)
links:
  anomaly_intent: ""         # work/<ID>-<slug>/intent.md produced by monitoring, if any
  fix_pr: ""
  regression_eval: ""        # evals/<file>.json added for this incident class — REQUIRED before closing
  channel_thread: ""         # incident channel / Slack thread (audit trail)
---

# <Title>

## Summary

<!-- Three sentences: what users saw, how long, what fixed it. -->

## Impact

| Measure | Value |
|---|---|
| Duration |  |
| Users / requests affected |  |
| Error budget consumed |  |

## Timeline (UTC)

| Time | Event |
|---|---|
|  | Band breach detected (tier, metric, value vs baseline) |
|  |  |

## Signals

<!-- The exact metric, query, log line or trace that showed the problem. Future you will search for this. -->

## Root cause

<!-- Technical cause and the contributing conditions that let it reach production. -->

## What went well / what did not

- Went well:
- Did not:

## Actions

| Action | Type (fix / eval / hook / CLAUDE.md / band tuning) | Owner | Due | Status |
|---|---|---|---|---|
| Add regression eval for this incident class | eval |  |  |  |

## Lessons for future investigations

<!-- Short, reusable: "When X metric rises with Y, check Z first." -->
