---
id: sec-sql-ph2-001
domain: functions
server: RhostMUSH
source: mush-security audit (phase2, 2026-03-27)
complexity: medium
tags: [security, anti-pattern, sql-injection]
date_added: "2026-03-27"
---

# Anti-Pattern: Unescaped statpath in SQL LIKE clause

A SQL helper function accepts a statpath argument and interpolates it directly into a `WHERE ... LIKE` clause without calling `f.sql.escape`. In the current call chain the function receives numeric values (so injection is unexploitable), but the function signature allows statpaths — changing the call site would silently open a SQL injection vector.

## Code

```mushcode
// 4c1-xp-sql-functions.mu — VULNERABLE PATTERN
&sql.select.last-touched [v( d.xpas )]=
    SELECT MAX( log_time )
    FROM xp_log
    WHERE target_objid = '[u( .objid, %0 )]'
    AND trait_category = '[lcstr( first( %1, . ))]'
    AND trait_name LIKE
        '[if( strlen( rest( %1, . )), lcstr( rest( %1, . )), %% )]';
```

## Why this matters

- `%1` (the statpath) is split on `.` and interpolated directly into the SQL string inside single-quote delimiters.
- A crafted statpath like `skill'--` closes the SQL literal and allows injection.
- Example UNION attack: `%1 = "skill' UNION SELECT table_name FROM information_schema.tables WHERE '1'='1"` would leak schema information.
- The function is currently only called with numeric stat-from values (e.g., `2`), so the injection is latent — but any future caller passing a real statpath would be vulnerable.
- The fix is to wrap both interpolated values with `u(f.sql.escape, ...)`.

## Fixed version

```mushcode
&sql.select.last-touched [v( d.xpas )]=
    SELECT MAX( log_time )
    FROM xp_log
    WHERE target_objid = '[u( .objid, %0 )]'
    AND trait_category = '[u( f.sql.escape, lcstr( first( %1, . )))]'
    AND trait_name LIKE
        '[if( strlen( rest( %1, . )), u( f.sql.escape, lcstr( rest( %1, . ))), %% )]';
```

## @rhost/testkit snippet

```typescript
// Verify that a malicious statpath does not break the query
it('handles single quote in statpath gracefully', async ({ client }) => {
    // If vulnerable, this would return a SQL error or empty/wrong result
    const result = await client.eval(
        "u(v(d.xpas)/sql.select.last-touched,#1,skill'--)"
    );
    // Should return empty string or NULL (no match), not a SQL error
    expect(result).not.toMatch(/sql.*error/i);
    expect(result).not.toMatch(/#-/);
});
```
