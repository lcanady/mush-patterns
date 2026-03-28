---
id: sec-strsearch-not-match-001
domain: functions
server: RhostMUSH
source: mush-security audit 2026-03-28
complexity: low
tags: [security, safe, injection, search, strsearch, glob]
date_added: "2026-03-28"
tested: true
---

# Pattern: Use `strsearch()` not `match()` for literal substring search

When searching help text or other user-controlled content, use `strsearch()` (literal substring, returns position ≥ 0 on match or -1 on miss) instead of `match()` or `pmatch()` (glob/pattern matching). Glob-based search treats user input as a pattern — searching for `*` matches everything; searching for `[evil]` could inject evaluation.

## Code

```mushcode
# SAFE: strsearch() does literal substring matching — no glob interpretation
# Returns position >= 0 on match, -1 on miss
[setq(0,lcstr(trim(%0)))]   ← normalize search term once
[setq(1,trim(iter(%q9,
  [if(
    and(
      u(#sys/FN_CAN_READ,%1,##),
      or(
        gte(strsearch(##,%q0),0),               ← topic name contains keyword
        gte(strsearch(lcstr(get(#sys/[u(#sys/FN_ATTR_NAME,##)])),%q0),0)  ← text contains keyword
      )
    ),
    ucfirst(##),
  )],
  |,|
),b,|))]
```

## Anti-pattern — what NOT to do

```mushcode
# DANGEROUS: match() treats %0 as a glob pattern
# User searches for *  → matches all topics (glob wildcard)
# User searches for [pemit(%#=X)] → may inject code
[setq(1,trim(iter(%q9,
  [if(
    and(
      u(#sys/FN_CAN_READ,%1,##),
      match(lcstr(get(#sys/[u(#sys/FN_ATTR_NAME,##)])), *%q0*)   ← glob!
    ),
    ucfirst(##),
  )],
  |,|
),b,|))]
```

## Why this matters

- `match(text, *keyword*)` treats `keyword` as a glob pattern. Searching for `*` becomes `match(text, ***)` which matches every word.
- `strsearch(text, keyword)` does literal byte comparison — no special characters.
- For user-facing search commands, always use `strsearch()` for the content scan and normalize both strings to lowercase first.

## Comparison table

| Function | Interpretation | Safe for user input |
|---------|---------------|-------------------|
| `match(str, pat)` | Glob (space-separated word positions) | No — `*` matches everything |
| `pmatch(str, pat)` | Prefix/glob | No |
| `strsearch(str, sub)` | Literal substring, returns position | Yes |
| `regmatchi(str, re)` | Regex | Only with anchors + validation |

## @rhost/testkit snippet

```typescript
it('+help/search * does not match all topics (literal, not glob)', async ({ client }) => {
  await client.command('+help/set GlobSafeTest=no asterisk here');
  const lines = await client.command('+help/search *');
  await client.command('+help/delete GlobSafeTest');
  if (lines.join(' ').toLowerCase().includes('globsafetest')) {
    throw new Error('+help/search * matched topic with no asterisk — glob still active');
  }
});

it('+help/search finds literal substring correctly', async ({ client }) => {
  await client.command('+help/set LiteralTest=unique_xyz_substring here');
  const lines = await client.command('+help/search unique_xyz_substring');
  await client.command('+help/delete LiteralTest');
  if (!lines.join(' ').toLowerCase().includes('literaltest')) {
    throw new Error('+help/search did not find topic by literal substring');
  }
});
```
