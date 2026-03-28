---
id: sec-sql-ph2-003
domain: functions
server: RhostMUSH
source: mush-security audit (phase2, 2026-03-27)
complexity: high
tags: [security, anti-pattern, sql-injection, sql-escape]
date_added: "2026-03-27"
---

# Anti-Pattern: SQL escape function with unclear \\-sequence behavior

The `f.sql.escape` function uses nested `\\` sequences in `edit()` whose evaluated behavior is difficult to verify in RhostMUSH. The source comment admits the original nested-edit version was removed because "Rhost and TinyMUSH will choke here." The simplified replacement may not correctly escape single quotes in all cases.

## Code

```mushcode
// 4c-xp-and-advancement.mu — UNCLEAR ESCAPING
// Source comment: "I removed the nested edits, here. Rhost and TinyMUSH will choke here."
&f.sql.escape [v( d.xpas )]=edit( %0, \\, \\\\\\, ', \\\\', ", \\\\", \%, \\\\\\\% )
```

## Why this matters

- In MUSH softcode, `\\` in an attribute value is a literal backslash. The `edit()` pattern arguments are themselves subject to MUSH string evaluation, making the actual substitutions hard to reason about without testing.
- If `'` is not correctly replaced with `\'`, SQL injection remains possible for any caller of `f.sql.escape`.
- The comment explicitly flags this as a Rhost incompatibility issue — the original (pre-simplification) version was removed specifically because it caused problems.
- RhostMUSH's `sql()` interface may handle escaping differently from TinyMUX.
- **Verify by testing:** `think u(v(d.xpas)/f.sql.escape, Bob's Bar)` should return `Bob\'s Bar`. If it doesn't, SQL injection protection is broken for all reason/name fields.

## Verification test

```mushcode
// Run on live server to confirm correct behavior:
think u( v( d.xpas )/f.sql.escape, She said "hello". Bob's Bar. 50% off. )
// Expected: She said \"hello\". Bob\'s Bar. 50\% off.
// If ', " or % are not escaped → SQL injection is possible
```

## Safer alternative using RhostMUSH primitives

If RhostMUSH provides a native SQL escape function or if the server's `sql()` supports parameterized queries, prefer those over manual string escaping:

```mushcode
// If RhostMUSH exposes sqlesc() or similar:
&f.sql.escape [v( d.xpas )]=sqlesc( %0 )

// If not available, at minimum verify the edit() behavior in staging:
&f.sql.escape [v( d.xpas )]=
    edit( edit( edit( edit( %0,
        \,      \\),    // backslash → double-backslash (MUST be first)
        ',      \'),    // single quote → escaped single quote
        ",      \"),    // double quote → escaped double quote
        %%,     \%%)    // percent → escaped percent
```

## @rhost/testkit snippet

```typescript
it('escapes single quotes', async ({ client }) => {
    const result = await client.eval(
        "u(v(d.xpas)/f.sql.escape,Bob's)"
    );
    expect(result).toBe("Bob\\'s");
});

it('escapes double quotes', async ({ client }) => {
    const result = await client.eval(
        'u(v(d.xpas)/f.sql.escape,say "hello")'
    );
    expect(result).toContain('\\"');
});

it('escapes backslashes', async ({ client }) => {
    const result = await client.eval(
        'u(v(d.xpas)/f.sql.escape,path\\\\to\\\\thing)'
    );
    expect(result).toContain('\\\\\\\\');
});
```
