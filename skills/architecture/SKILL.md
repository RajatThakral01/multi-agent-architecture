---
name: architecture
description: Load this skill when your task involves a new module, new file location, or structural change.
---

# Architecture

product: [product name and one-line description]
stack:   [backend language/framework] | [data layer]
         [queue/async layer] | [any other infra]

## Layer rules
[layer name]/   — [what it receives/does]. Never: [what it must not do]
[layer name]/   — [what it receives/does]. Never: [what it must not do]

## Request flow
[client] → [middleware] → [handler] → [service] → [DB] → [response]

## File structure
[root]/
  [entry point]
  [layer]/  [resource].[ext]
  [layer]/  [resource].[ext]

## Naming conventions
[resource type]: [convention] — example: [example.ext]
Variables:     [convention]
Constants:     [convention]
Test files:    [convention]

## Hard rules
- [rule 1 — e.g. every src file needs matching test]
- [rule 2 — e.g. no business logic in routes]
- [rule 3 — e.g. env vars only in config/]
- new file path not in structure above → write CLR to ISSUES.md first
