---
name: api-contracts
description: Load this skill when your task involves any HTTP endpoint — reading, writing, or testing one.
---

# API contracts

base:        http://localhost:[PORT]/api
format:      JSON | Content-Type: application/json
auth header: Authorization: Bearer [token]
success:     { data: { } }
error:       { error: { message: string, code: string } }
public:      [list public routes — e.g. POST /auth/login, POST /auth/register]
protected:   all others require valid JWT

## Status codes
200 — GET/PUT/PATCH success
201 — POST creating a resource
202 — accepted for async processing
204 — DELETE success, no body
400 — missing or invalid body
401 — missing/invalid/expired JWT
403 — valid JWT, insufficient permissions
404 — not found
409 — already exists
429 — rate limit exceeded
500 — unhandled server error

## Endpoint index
[METHOD] [path] — [purpose], [success code]

## Key rules
- never return: stack traces, DB messages, file paths, secrets, embeddings
- [add project-specific rules here — rate limiting, pagination, dedup, etc.]
