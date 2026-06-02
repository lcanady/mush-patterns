---
id: sec-isnum-match-anti-001
domain: functions
server: RhostMUSH
source: mush-security audit 2026-03-28
complexity: low
tags: [security, anti-pattern, injection, input-validation, match]
date_added: "2026-03-28"
tested: true
---

# Anti-pattern: `isnum(match())` always returns 1 — broken injection guard

Using `isnum(match(string, pattern))` to detect a substring is always true, because `match()` returns an integer (0 for no match, position for a match), and `isnum()` returns 1 for any integer including 0. This makes the guard fire for all inputs — either blocking everything (if guarding against injection) or allowing everything (if used as a positive access check).

## Broken code

```mushcode
# BROKEN: isnum(0) = 1, so the semicolon check always fires
# This means ALL lock expressions are rejected, even safe ones like "wizard"
[or(
  isnum(match(%1,*;*)),          ← ALWAYS 1 — match() always returns a number
  gt(strlen(%1),strlen(edit(%1,%[,))),
  gt(strlen(%1),strlen(edit(%1,],))))
], {
  @pemit %2=Lock expressions may not contain semicolons or brackets.
}
```

## Correct code

```mushcode
# FIXED: use gt(...,0) to distinguish "found" (>0) from "not found" (=0)
# Matches the same pattern used by the bracket checks beside it
[or(
  gt(match(%1,*;*),0),           ← correct: position > 0 means a match was found
  gt(strlen(%1),strlen(edit(%1,%[,))),
  gt(strlen(%1),strlen(edit(%1,],))))
], {
  @pemit %2=Lock expressions may not contain semicolons or brackets.
}
```

## Why this matters

- `match(string, *;*)` returns 0 if no word in `string` contains `;`. `isnum(0)` = 1.
- With `isnum()` wrapping, the condition is tautologically true: every input looks like "has a semicolon".
- When this is an injection guard, the result is a **broken security control**: the guard blocks legitimate use entirely (over-rejection), making the feature non-functional.
- The correct idiom for "match found at least one result" is `gt(match(...),0)` or `neq(match(...),0)` — same pattern used by `strsearch()` comparisons.

## Rule

Never use `isnum(match(...))` as a truthy test. `match()` always returns a number; `isnum()` adds nothing.

| Intended test | Wrong | Correct |
|--------------|-------|---------|
| "string contains `;`" | `isnum(match(str,*;*))` | `gt(match(str,*;*),0)` |
| "string contains `[`" | `isnum(strsearch(str,[))` | `gte(strsearch(str,[),0)` |
| "function returned error" | `isnum(result)` | `not(isnum(before(result,%b)))` |

## @rhost/testkit snippet

```typescript
it('valid lock preset "wizard" can be stored', async ({ client }) => {
  await client.command('+help/set LockedTopic=text');
  await client.command('+help/set/lock LockedTopic=wizard');
  const lock = await client.eval(`get(${helpObj}/HELPLOCK_LOCKEDTOPIC)`);
  if (!lock.includes('hasflag') && !lock.includes('wizard')) {
    throw new Error(`Lock expression not stored — isnum(match()) bug still present: ${lock}`);
  }
  await client.command('+help/delete LockedTopic');
});

it('semicolon injection is still rejected', async ({ client }) => {
  await client.command('+help/set InjTest=text');
  const lines = await client.command('+help/set/lock InjTest=1;@pemit %#=INJECTED');
  const output = lines.join(' ');
  await client.command('+help/delete InjTest');
  if (output.includes('INJECTED')) {
    throw new Error('Semicolon injection in lock expression executed');
  }
});
```
