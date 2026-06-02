---
id: func-udf-guard-001
domain: functions
server: RhostMUSH
source: rhost-testkit examples
complexity: medium
tags: [udf, guard, error-handling, validation]
date_added: "2026-03-27"
tested: true
---

# Pattern: UDF argument guard

Always validate required arguments at the top of a UDF and return `#-1 <reason>` on bad input. Callers can detect errors with `isnum(before(result,<space>))` or `@rhost/testkit`'s `.toBeError()`.

## Signal
USE:  validate required args at top of every UDF | return #-1 REASON on bad input
DETECT: isnum(before(result,%b)) | .toBeError()
CODES: #-1=invalid | #-2=permission-denied | #-3=wrong-arg-count
WARN: propagate errors upstream — don't swallow #-N returns
TEST: ✓

## Code

```mushcode
&FN_DIVIDE #sys=
  [if(
    or(not(%0),not(%1),not(isnum(%0)),not(isnum(%1))),
    #-1 INVALID ARGS,
    if(not(%1), #-1 DIVISION BY ZERO, fdiv(%0,%1))
  )]
```

## Notes

- Return `#-1 REASON` (with a space and reason) rather than bare `#-1` — it aids debugging.
- Check both `not(%0)` (empty) AND `not(isnum(%0))` (non-numeric) for numeric guards.
- `#-2` = permission denied, `#-3` = invalid number of arguments — use these semantics correctly.
- Callers should propagate errors: `[setq(0,u(#sys/FN_DIVIDE,%0,%1))][if(isnum(%q0),%q0,#-1 ...)]`

## @rhost/testkit snippet

```typescript
it('divides correctly', async ({ expect }) => {
    await expect('u(#42/FN_DIVIDE,10,2)').toBe('5');
});

it('returns error on zero divisor', async ({ expect }) => {
    await expect('u(#42/FN_DIVIDE,10,0)').toBeError();
    await expect('u(#42/FN_DIVIDE,10,0)').toContain('DIVISION BY ZERO');
});

it('returns error on empty args', async ({ expect }) => {
    await expect('u(#42/FN_DIVIDE,,2)').toBeError();
});

it('returns error on non-numeric args', async ({ expect }) => {
    await expect('u(#42/FN_DIVIDE,foo,2)').toBeError();
});
```
