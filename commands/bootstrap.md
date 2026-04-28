---
description: Bootstrap an existing project into this architecture. Run once when bringing an unknown codebase in.
agent: planner
---

You are starting a bootstrap session on an existing codebase. STATE.md, TASKS.md, and ISSUES.md are empty. Follow these steps exactly:

1. Spawn graph-explorer with "full traversal" — wait for its structured output
2. Using graph-explorer output, write STATE.md via writer:
   - What exists: every module, route, service, and DB model found
   - What does not exist yet: gaps visible from the graph
   - Last session stopped at: "bootstrap — no prior sessions"
   - Known constraints: stack, module name, naming conventions observed
   - Open blockers: none

3. Print this for Human review:
BOOTSTRAP SUMMARY
=================
codebase:   [language, framework, size estimate]
found:      [list of modules/services discovered]
gaps:       [what appears incomplete or missing]
suggested ticket goal: [one sentence — what should be built next]
decisions needed: [any arch patterns you observed that should be recorded]
=================
Waiting for Human to confirm ticket goal before creating any tasks.

4. Stop — wait for Human to confirm or correct the summary before writing TASKS.md
