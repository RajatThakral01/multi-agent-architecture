---
name: db-schema
description: Load this skill when your task involves any model, database query, or migration.
---

# Database schema

db:         [database engine — e.g. PostgreSQL, MySQL, SQLite]
orm:        [ORM — e.g. Prisma, SQLAlchemy, GORM]
schema:     [path to schema file] — source of truth
migrations: [path to migrations dir] — never edit manually
ids:        [UUID | auto-increment] auto-generated — never passed by client
timestamps: [createdAt / created_at] on every table — set automatically

## Tables

### [table name]
[field], [field] ([type, constraints])
[field] (nullable)
[field] (unique — dedup key)

## Security rules
- select [sensitive field] ONLY in [specific query] for [purpose]
- NEVER return [field list] to client
- [read-only fields] — never accept from request body
- user ID always from request context

## Key query patterns
[pattern name]:  [query description]
[pattern name]:  [query description]

## Migration rules
generate:  [migration command]
after change: [generate command]
never run production migration autonomously — write CLR entry, wait for Human
