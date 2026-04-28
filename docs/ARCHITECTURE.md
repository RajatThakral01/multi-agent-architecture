# ARCHITECTURE.md
> Read the summary block first. Only read further sections if your task needs them.

## Summary
```
product:    [Product name — one-line description]
users:      [Target users and their primary use case]
v1-scope:   [High-level feature list for the first release]

style:      [architectural style — e.g. layered monolith, microservices]
stack:      [backend] | [frontend if any]
            [database] | [queue/cache] | [other infra]
auth:       [auth mechanism — e.g. JWT access + refresh token]
layers:     [layer flow — e.g. routes → services → db]
errors:     [error handling pattern and format]
env:        [where env vars are accessed]
never:      [things agents must never do]
```

---

## What [Product] does
[One paragraph describing the end-to-end user journey and what the system produces.]

---

## Processing pipeline
```
1. [Step name]  — [what happens]
2. [Step name]  — [what happens]
3. [Step name]  — [what happens]
[Add more steps as needed]
```

---

## Layer rules
| Layer       | Does                                        | Never                           |
|-------------|---------------------------------------------|---------------------------------|
| [layer]/    | [what it receives and does]                 | [what it must not do]           |
| [layer]/    | [what it receives and does]                 | [what it must not do]           |

---

## Request flow
```
client → [middleware] → [handler] → [service] → [DB] → response
```
- Protected routes: [describe auth check]
- Public routes: [list public routes]
- Errors: [describe error propagation chain]
- Error format: { error: { message: string, code: string } }
- Never in errors: stack traces, file paths, DB messages, secrets

---

## Auth
```
access token:  [type], [expiry], [delivery mechanism]
refresh token: [type], [expiry], [delivery mechanism]
[any other auth notes]
```

---

## File structure
```
project-root/
├── [coordination files]
│
├── [layer]/
│   └── [files]
│
├── [layer]/
│   └── [files]
│
└── [config / env files]
```

---

## Naming conventions
| Type          | Convention            | Example               |
|---------------|-----------------------|-----------------------|
| [file type]   | [convention]          | [example]             |
| [file type]   | [convention]          | [example]             |
| Variables     | [convention]          | [example]             |
| Constants     | [convention]          | [example]             |

---

## File creation rules
- [rule 1 — e.g. every src file needs a matching test]
- [rule 2 — e.g. new path not in structure → write CLR entry first]
- [rule 3 — e.g. no business logic in routes]

---

## Env vars
| Variable                | Default     | Required |
|-------------------------|-------------|----------|
| [VAR_NAME]              | —           | yes      |
| [VAR_NAME]              | [default]   | no       |

- all accessed via [config location] only — never directly elsewhere
- new var needed → write CLR entry in ISSUES.md first, never invent names
- never log env values or return them in any response

---

## Security rules (Debugger checks every pass)
- [rule 1 — e.g. no env vars outside config/]
- [rule 2 — e.g. no stack traces in responses]
- [rule 3 — e.g. no sensitive fields in any response]
- [rule 4 — e.g. user ID always from request context]
