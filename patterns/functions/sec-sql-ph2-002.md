---
id: sec-sql-ph2-002
domain: functions
server: RhostMUSH
source: mush-security audit (phase2, 2026-03-27)
complexity: low
tags: [security, anti-pattern, sql-injection]
date_added: "2026-03-27"
---

# Anti-Pattern: Unescaped argument inside SQL function call string

A utility function wraps a SQL datetime string inside `SELECT UNIX_TIMESTAMP('%0')` without calling `f.sql.escape` on `%0`. The function is currently called only with results from a previous SQL `MAX()` query (server-controlled timestamps), so it is not directly exploitable. However, the pattern is dangerous: any caller passing user-derived text would introduce SQL injection.

## Code

```mushcode
// 4c-xp-and-advancement.mu — VULNERABLE PATTERN
&f.time.sql2unix [v( d.xpas )]=sql( SELECT UNIX_TIMESTAMP( '%0' ))
```

## Why this matters

- `'%0'` wraps the argument in single quotes but applies no escaping.
- If `%0` contains `'`, it closes the SQL string literal and allows injection.
- Example: `%0 = "2024-01-01' UNION SELECT @@version-- "` would execute the UNION query.
- Currently safe because `f.last-purchase` passes `sql(u(sql.select.last-touched,...))` — a server-returned timestamp. But this relies on the call chain staying narrow.
- The fix is either to validate that `%0` is a valid datetime format before use, or to escape it.

## Fixed version

```mushcode
// Option A: validate format (datetime strings don't need SQL-special chars)
&f.time.sql2unix [v( d.xpas )]=
    if(
        regmatch( %0, ^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$ ),
        sql( SELECT UNIX_TIMESTAMP( '%0' )),
        #-1 INVALID DATETIME FORMAT
    )

// Option B: escape (simpler, consistent with other SQL helpers)
&f.time.sql2unix [v( d.xpas )]=sql( SELECT UNIX_TIMESTAMP( '[u( f.sql.escape, %0 )]' ))
```

## @rhost/testkit snippet

```typescript
it('rejects non-datetime input', async ({ client }) => {
    const result = await client.eval(
        "u(v(d.xpas)/f.time.sql2unix,2024-01-01' UNION SELECT 1--)"
    );
    expect(result).toMatch(/#-1/);
});

it('accepts valid datetime', async ({ client }) => {
    const result = await client.eval(
        "u(v(d.xpas)/f.time.sql2unix,2024-01-15 12:34:56)"
    );
    expect(result).toMatch(/^\d+$/);  // unix timestamp
});
```
