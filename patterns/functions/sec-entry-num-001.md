---
id: sec-entry-num-001
domain: functions
server: RhostMUSH
source: mush-security audit (phase2, 2026-03-27)
complexity: low
tags: [security, safe, sql-injection, isint-guard]
date_added: "2026-03-27"
---

# Pattern: isint() + gt() guard before using user input as SQL row ID

Before passing a user-supplied entry number into a SQL `WHERE entry_num=%0` clause, validate with `cand(isint(%qe), gt(%qe, 0))`. This prevents SQL injection via a non-numeric entry number and ensures the value is a positive integer.

## Code

```mushcode
// 4c3-xp-unspend.mu and 4c4-xp-unaward.mu — SECURE PATTERN

// Extract entry number from raw input
think strcat(
    entry num:, setr( e, first( %1 )), %r,
    ...
);

// Validate before ANY SQL use
@assert cand( isint( %qe ), gt( %qe, 0 ))={
    @pemit %#=u( .msg, xp/unspend, Entry num must be positive integer )
};

// Only after validation, use in SQL
sql log:, setr( l, sql( u( sql.select.entry_num, %qe ), `, | )), %r,
```

And in the SQL function, the entry_num is used unquoted (because it is a numeric column):
```mushcode
&sql.select.entry_num [v( d.xpas )]=
    SELECT ...
    FROM xp_log
    WHERE entry_num=%0     // unquoted — numeric column, validated as isint first
```

## Why this matters

- `WHERE entry_num=%0` inserts the value unquoted into SQL. Without validation, a user supplying `1 UNION SELECT password FROM admin` would inject a UNION query.
- `isint(%qe)` rejects any non-integer string before it reaches SQL.
- `gt(%qe, 0)` also rejects `0` and negative values which are invalid entry IDs.
- The validation happens via `@assert` before any SQL call, so failure exits the command early.
- For numeric primary key columns: validate with `isint()`, use unquoted in SQL.
- For string columns: always use `f.sql.escape()` and quote the value.

## @rhost/testkit snippet

```typescript
it('rejects non-integer entry num', async ({ wizard }) => {
    const lines = await wizard.command("xp/unspend abc for test");
    expect(lines.some(l => l.includes('positive integer'))).toBe(true);
});

it('rejects SQL injection in entry num', async ({ wizard }) => {
    const lines = await wizard.command("xp/unspend 1 UNION SELECT 1 for test");
    // Should be rejected by isint() check, not reach SQL
    expect(lines.some(l => l.includes('positive integer'))).toBe(true);
});

it('accepts valid positive integer', async ({ wizard }) => {
    const lines = await wizard.command("xp/unspend 42 for test");
    // Should not produce a "positive integer" error (may give "no entry found" instead)
    expect(lines.some(l => l.includes('positive integer'))).toBe(false);
});
```
