# ARCHITECTURE.md

## Overview

A multi-agent development system where three primary agents (Planner, Coder, Debugger)
coordinate through shared coordination files. Sub-agents handle focused tasks — file writes,
archiving, bug fixing, and codebase scanning. Skills provide domain knowledge on demand.
Human reviews and approves at every checkpoint.

All file writes flow exclusively through the Writer sub-agent using structured
`<write_request>` blocks. No primary agent ever touches a coordination file directly.

---

## System Layers

```
┌─────────────────────────────────────────┐
│                  Human                  │  starts · reviews · approves
└─────────────────────────────────────────┘
                     │
┌─────────────────────────────────────────┐
│             Primary Agents              │
│  Planner ──► Coder ──► Debugger         │  plan · build · verify
└─────────────────────────────────────────┘
                     │ spawns
┌─────────────────────────────────────────┐
│              Sub-Agents                 │
│  Writer · Archivist · Bug Fixer         │  execute · write · fix
│  Code Explorer                          │
└─────────────────────────────────────────┘
                     │ writes via Writer
┌─────────────────────────────────────────┐
│          Coordination Files             │
│  STATE.md · TASKS.md · DECISIONS.md     │  shared project state
│  ISSUES.md                              │
└─────────────────────────────────────────┘
                     │ loaded on demand
┌─────────────────────────────────────────┐
│          Skills (read-only)             │
│  api-contracts · db-schema              │  domain knowledge
│  architecture · test-patterns           │
└─────────────────────────────────────────┘
```

---

## Primary Agents

### Planner

The entry point for every session. Understands project state, creates tasks, and
writes prompts for Coder and Debugger. Never writes code or edits files directly.

**Responsibilities**
- Reads STATE.md, TASKS.md, DECISIONS.md, ISSUES.md at the start of every session
- Determines what to build next and creates small, focused task prompts
- Spawns Code Explorer when STATE.md is insufficient
- Spawns Bug Fixer (with exact instructions) when REPLAN-NEEDED flag is set
- Prints session summary for Human before any work begins
- Updates STATE.md at the end of every session via Writer

**Constraints**
- Runs in plan mode only — cannot edit any file directly
- Never reads source files in src/, pipeline/, prisma/ — uses Code Explorer instead
- All file writes must go through Writer using `<write_request>` blocks

**Batch size rules**

| Situation | Max tasks |
|---|---|
| Sequential, files clearly known | 3 |
| New module or significant new code | 2 |
| Task that changes what comes after | 1 |
| After CRITICAL bug found | fix first |

---

### Coder

Receives task prompts from Planner and implements exactly what is described.
One task. One commit. Spawn Writer. Stop.

**Responsibilities**
- Confirms task is PENDING in TASKS.md before starting
- Reads only DECISIONS.md entries tagged CODER or ALL
- Reads only source files explicitly named in the task prompt
- Writes code, tests, runs build/vet/test, commits
- Spawns Writer after every commit to update TASKS.md Done row
- Spawns Writer with a clarification block if prompt is ambiguous

**Constraints**
- Never edits coordination files directly
- Never reads source files not named in the prompt
- Never makes architecture decisions
- Never commits if build, vet, or any test fails
- Never accesses env vars outside src/config/env
- Never uses fmt.Println or log.Print in production paths
- Never returns sensitive fields in any response or log

**Hard quality gates — never commit if any fail**
- Build fails
- Vet warnings present
- Any test fails (skipped is acceptable only if env is missing — must note it)
- Input validation missing at handler or service layer
- Sensitive field in any response or log
- Env var accessed outside src/config/env

---

### Debugger

Reviews every task in a batch after Coder finishes. Runs two passes — tests and
criteria first, then static analysis. Never writes source code or makes architectural
decisions.

**Responsibilities**
- Confirms all tasks from the prompt exist in TASKS.md Done
- Reads DECISIONS.md entries tagged DEBUGGER or ALL
- Reads ISSUES.md Open Bugs to avoid duplicate bug IDs
- Runs Pass 1: tests + DONE WHEN criteria per task
- Runs Pass 2: security, contracts, schema, secrets, conventions
- Sets REPLAN-NEEDED flag via Writer if any CRITICAL bug is found
- Spawns Writer with full debug output after both passes

**Constraints**
- Never writes or edits source code
- Never edits coordination files directly
- Never skips Pass 2 even if Pass 1 fails — always runs both
- Never writes a bug that is already approved in DECISIONS.md

**Bug severity**

| Level | Meaning |
|---|---|
| CRITICAL | Security vuln, data loss, broken core path, missing auth |
| MEDIUM | Wrong behavior, missing error handling, info leak |
| LOW | Missing test coverage, convention violation, godoc missing |

---

## Sub-Agents

### Writer

The only agent that writes to coordination files. Receives structured `<write_request>`
blocks from primary agents and executes them exactly — no inference, no formatting
decisions, no silent failures.

**Triggered by** any primary agent that needs to update a coordination file.

**Input format — required for every write**
```
<write_request>
  from: PLANNER | CODER | DEBUGGER | BUG-FIXER
  file: [exact filename]
  section: [exact section name]
  operation: append | overwrite | set-flag | full-overwrite
  content: [exact content to write, verbatim]
</write_request>
```

One `<write_request>` block per file. Multiple blocks are processed sequentially.
Writer waits for each to succeed before processing the next.

**Acknowledgment — mandatory after every write**
```
WRITE_SUCCESS: [filename] — [section] — [operation]
WRITE_FAILED:  [filename] — [exact error]
WRITE_BLOCKED: [filename] — missing field: [field name]
```

On `WRITE_FAILED` or `WRITE_BLOCKED` → stops all remaining requests and waits for Human.

**Identity routing**

| From | Writes to |
|---|---|
| PLANNER | TASKS.md Queue, DECISIONS.md, STATE.md, ISSUES.md Planner Responses |
| CODER | TASKS.md Done row, ISSUES.md Open Clarifications |
| DEBUGGER | ISSUES.md Open Bugs, ISSUES.md Resolved, ISSUES.md DEBUG-LOG, TASKS.md Notes, TASKS.md REPLAN-NEEDED |
| BUG-FIXER | TASKS.md Done row, TASKS.md REPLAN-NEEDED (clear) |

**Operation types**

| Operation | Behaviour |
|---|---|
| `append` | Adds content at the end of the named section only |
| `overwrite` | Replaces only the specified line or cell |
| `set-flag` | Updates the flag value on the specified line only |
| `full-overwrite` | Replaces entire file — only valid for STATE.md |

**Hard rules**
- Never writes without a valid `<write_request>` block
- Never infers missing fields — outputs `WRITE_BLOCKED` and stops
- Never deletes content unless instructed by `full-overwrite` on STATE.md or moving a bug to Resolved
- Processes one `<write_request>` at a time — stops on any failure

---

### Archivist

Keeps active coordination files short after every debug pass completes.

**Reads** TASKS.md Done, ISSUES.md Resolved  
**Moves** closed tasks → TASKS_ARCHIVE.md, resolved bugs → ISSUES_ARCHIVE.md  
**Rule** only moves entries where Debugger has written PASSED and bugs are in Resolved.
Never deletes — only moves.

---

### Bug Fixer

Spawned by Planner when REPLAN-NEEDED flag is set. Receives exact fix instructions
and does not make its own decisions about what to fix or how.

**Receives from Planner** affected file paths, exact fix description, test to run  
**Does** implements fix, runs build/vet/test, commits  
**Then** hands back to Debugger for re-check  
**Does not** read full coordination files, make architectural decisions, touch other files

---

### Code Explorer

On-demand only. Never runs automatically on every session.

**Triggered by** Planner when STATE.md is insufficient or a task involves unknown files  
**Does** scans specified paths, returns a short structured summary (max 20 lines)

**Output format**
```
files:        [list of relevant files found]
exports:      [key functions/types exposed]
dependencies: [imports that matter for the task]
gaps:         [anything missing that the task needs]
```

---

## Coordination Files

All files are kept short by the Archivist. Primary agents read only what is relevant
to their current task — not full file history.

### STATE.md
Current project snapshot. Hard limit: 30 lines.  
Written by Planner (via Writer) at the end of every session.  
First file Planner reads at the start of every session.

```
updated: [date]
ticket: [TICKET-N] | status: [status]

## What exists
## What does not exist yet
## Last session stopped at
## Known constraints
## Open blockers
```

### TASKS.md
Active task queue and current batch Done rows only.

```
status: OPEN | IN PROGRESS | CLOSED          ← line 1
REPLAN-NEEDED: true | false                  ← line 2

## Queue
| TASK-[N] | [description] | [agent] | PENDING |

## Done
| TASK-[N] | [hash7] | [files] | [notes] | PENDING |
```

Older Done rows are moved to TASKS_ARCHIVE.md by Archivist.

### DECISIONS.md
Anything important Planner wants the system to know and remember.
- Architectural decisions
- Patterns agents must follow
- Feedback about agent behaviour
- Instructions that apply to future sessions

Entry format includes an `agents:` field — Coder and Debugger read only entries
tagged for them. Planner is the only writer. Entries are never deleted, only superseded.

```
DEC-[N] | [AREA] | ACTIVE | [date]
agents: [CODER / DEBUGGER / ALL]
decision: [one sentence]
reason: [one line]
affects: [files or modules]
```

### ISSUES.md
Four sections:

```
## Open Bugs
BUG-[N] | [CRITICAL/MEDIUM/LOW] | TASK-[ID]
file: [path]:[line]
issue: [one sentence]
fix: [one sentence]

## Resolved
BUG-[N] | RESOLVED | TASK-[ID]
fix-applied: [one sentence]
passed-recheck: true

## Open Clarifications
CLARIFICATION-[N] | TASK-[ID] | [date]
question: [one sentence]
context: [what Coder assumed to proceed]

## Planner Responses
RESPONSE-[N] | CLARIFICATION-[N] | [date]
answer: [one sentence]

## DEBUG-LOG
DEBUG-LOG | TICKET-[N] | [date] | tasks: TASK-[X], TASK-[Y]
pass-1-tests: PASS | FAIL
pass-1-criteria: PASS | FAIL
pass-2-security: PASS | FAIL
pass-2-contracts: PASS | FAIL
pass-2-schema: PASS | FAIL
pass-2-secrets: PASS | FAIL
pass-2-conventions: PASS | FAIL
total-bugs-found: [N]
```

---

## Skills

Read-only. Updated by Human when contracts or schema change. Never written by agents.
Loaded only when the current task touches that domain.

| Skill | Load when |
|---|---|
| `skills/api-contracts.md` | task involves an endpoint |
| `skills/db-schema.md` | task involves database |
| `skills/architecture.md` | task involves a new module or structural change |
| `skills/test-patterns.md` | writing or reviewing tests |

---

## Archive Files

Managed exclusively by Archivist. Never read by primary agents.

- `TASKS_ARCHIVE.md` — full history of all completed tasks
- `ISSUES_ARCHIVE.md` — full history of all resolved bugs

---

## Hooks

`hooks/on-ticket-closed.sh` — runs git push when Planner sets TASKS.md status to CLOSED.

---

## Normal Session Flow

```
1.  Human starts Planner session
2.  Planner reads: STATE.md → TASKS.md → DECISIONS.md → ISSUES.md
3.  Planner prints session summary → Human reviews and approves
4.  Planner writes tasks + decisions via Writer, updates STATE.md via Writer
5.  Human pastes task prompts into Coder (one at a time)
6.  Coder works each task → spawns Writer (<write_request>) → Writer updates TASKS.md Done
7.  Human pastes debug prompt into Debugger
8.  Debugger runs Pass 1 + Pass 2 → spawns Writer (<write_request>) → Writer updates ISSUES.md + TASKS.md
9.  Archivist runs → prunes active files
10. Human reviews debug report
11. If PASSED → Human starts next Planner session (go to step 1)
12. If REPLAN-NEEDED → Planner reads flag → spawns Bug Fixer with instructions → Debugger re-checks
13. On ticket CLOSED → git push hook fires
```

---

## Bug Fix Loop

```
Debugger finds CRITICAL bug
  → spawns Writer to set REPLAN-NEEDED: true
  → Human notifies Planner

Planner reads REPLAN-NEEDED
  → reads the bug details from ISSUES.md
  → thinks about fix approach
  → spawns Bug Fixer with: affected files, exact fix, test to run
  → spawns Writer to clear REPLAN-NEEDED: false

Bug Fixer implements fix → commits → signals done

Debugger re-checks the affected files only
  → if PASSED: spawns Writer to move bug to Resolved → Archivist runs
  → if still failing: spawns Writer to set REPLAN-NEEDED: true again
```

---

## Write Request Flow

Every coordination file update follows this exact path:

```
Primary Agent
  → outputs <write_request> block
    → Writer receives block
      → Writer executes operation
        → Writer outputs WRITE_SUCCESS / WRITE_FAILED / WRITE_BLOCKED
          → on failure: stop + wait for Human
          → on success: proceed to next block
```

No agent ever writes to a coordination file directly.
No write ever happens without an explicit acknowledgment.

---

## File Map

```
/
├── PLANNER.md            primary agent
├── CODER.md              primary agent
├── DEBUGGER.md           primary agent
├── WRITER.md             sub-agent
├── ARCHIVIST.md          sub-agent
├── BUG_FIXER.md          sub-agent
├── CODE_EXPLORER.md      sub-agent
├── coordination/
│   ├── STATE.md          current snapshot (max 30 lines)
│   ├── TASKS.md          active queue + current batch
│   ├── DECISIONS.md      decisions + feedback (never deleted)
│   └── ISSUES.md         bugs + clarifications + debug logs
├── archive/
│   ├── TASKS_ARCHIVE.md  full task history
│   └── ISSUES_ARCHIVE.md full bug history
├── skills/
│   ├── api-contracts.md
│   ├── db-schema.md
│   ├── architecture.md
│   └── test-patterns.md
└── hooks/
    └── on-ticket-closed.sh
```
