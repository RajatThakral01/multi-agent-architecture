# API_CONTRACTS.md
> Only read this file if your task involves an endpoint.

## Summary
```
base:           http://localhost:[PORT]/api
format:         JSON | Content-Type: application/json
auth header:    Authorization: Bearer [token]
success shape:  { data: { } }
error shape:    { error: { message: string, code: string } }
public routes:  [list public routes]
all others:     require valid JWT
never in error: stack traces, DB messages, file paths, secrets
```

---

## Status codes
| Code | When                                        |
|------|---------------------------------------------|
| 200  | successful GET, PUT, PATCH                  |
| 201  | successful POST creating a resource         |
| 202  | accepted for async processing               |
| 204  | successful DELETE — no body                 |
| 400  | missing or invalid request body             |
| 401  | missing, invalid, or expired JWT            |
| 403  | valid JWT but insufficient permissions      |
| 404  | resource not found                          |
| 409  | resource already exists                     |
| 429  | rate limit exceeded                         |
| 500  | unhandled server error                      |

---

## [Resource group name] endpoints

### [METHOD] /api/[resource]/[action]
```
auth:    [none | yes]
body:    { [field]: [type] }
success: [status code] { data: { [response shape] } }
errors:
  [code] [ERROR_CODE] — [when this fires]
notes:
  - [project-specific constraint or behaviour]
```

---

## Endpoint index
| Method | Path                    | Auth | Purpose                    |
|--------|-------------------------|------|----------------------------|
| [METHOD] | /api/[path]           | [No/Yes] | [purpose]             |

---

## Key rules
- never return: stack traces, DB messages, file paths, secrets, [project-specific fields]
- [rate limiting rule]
- [deduplication rule if applicable]
- [pagination rule if applicable]
- [user ID source rule]
