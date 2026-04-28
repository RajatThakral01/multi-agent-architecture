---
name: db-schema
description: Load this skill when your task involves any model, database query, or migration.
---

# Database schema

db:         
orm:        
schema:     [path to schema file — source of truth]
migrations: [path — never edit manually]
ids:        
timestamps: 

## Tables
[table name]
[list fields with types and constraints]

## Security rules
[what to never return, what is read-only, where user ID comes from]

## Key query patterns
[common queries agents will need]

## Migration rules
[how to generate, when to run, what requires Human approval]
