# DATABASE_SCHEMA.md
> Only read this file if your task involves a model, query, or migration.

## Summary
```
db:         [database engine — e.g. PostgreSQL, MySQL]
orm:        [ORM — e.g. Prisma, SQLAlchemy, GORM]
schema:     [path/to/schema file]  ← source of truth
migrations: [path/to/migrations/] — never edit manually
ids:        [UUID | auto-increment] auto-generated — never passed by client
timestamps: [createdAt / created_at] on every table — set automatically
never:      select [sensitive field] outside [specific query]
never:      return [field list] to client
```

---

## Tables

### [table name]
```
model [ModelName] {
  id         [type]   @id @default([strategy])
  [field]    [type]   [constraints]
  [field]    [type]?  // nullable
  createdAt  DateTime @default(now())
  @@map("[table_name]")
}

fields:
  [field] — [purpose and constraints]
  [field] — [purpose and constraints]

security:
  [what to never select or return for this table]
```

---

## Standard query patterns

### [pattern name]
```[language]
// [brief description]
[example query]
```

---

## Migration rules
- generate: `[migration command]`
- after schema change: `[generate command]`
- never run production migration autonomously — write CLR entry, wait for Human
- new field or table needed → write CLR entry in ISSUES.md first

---

## Test data rules
- each test creates and cleans its own data
- no shared state between test files
- reset relevant tables in beforeEach / setUp
