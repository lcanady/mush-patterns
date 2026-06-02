---
id: sec-isnum-guard-001
domain: commands
server: RhostMUSH
source: mush-security audit (RockJobs 2026-03-27)
complexity: low
tags: [security, guard, isnum, injection, defense-in-depth]
date_added: "2026-03-27"
---

# Pattern: Always isnum() guard numeric %0 inputs before passing to fn`get-job

Any command that accepts a job/request number from a player should place an
`isnum()`/`isint()` guard at the very start of the command body, before
`fn`get-job` (or any other function that uses the number) is called.

## Code

```mushcode
@@ CORRECT: isnum guard placed first
&CMD`VIEW-REQ Rockpath's Jobs System=$+request *:
  @break [isnum(%0)]={
    @pemit %#=[u([v(database)]/fn`prompt, Req)] Request must be a number.
  };
  @skip/ifelse [t([setr(0, [u([v(database)]/fn`get-job, %0)])])]= ...

@@ CORRECT: using isint() — same semantics for non-negative integers
&CMD`REQ-COMMENT Rockpath's Jobs System=$+request/comment *=*:
  @skip/ifelse [isint(%0)]={ ... }; @pemit %#=... must be a number.
```

```mushcode
@@ fn`get-job on the database object
&FN`GET-JOB Rockpath's Job Database=[num(Job %0)]
```

## Why this matters

- `fn`get-job` expands to `[num(Job %0)]`.  If `%0 = [evil()]`, the server
  evaluates `[evil()]` first, then looks up `num(Job <result of evil>)`.
- The `isnum()` guard does **not** prevent `[evil()]` from executing during
  the substitution of `%0`.  In RhostMUSH, `%0` is evaluated before `isnum()`
  ever sees it.
- What the guard **does** prevent:
  1. The secondary evaluation inside `fn`get-job` — if `evil()` returned a
     non-integer string, `isnum()` catches it and aborts before `fn`get-job`
     is reached.
  2. Downstream processing on junk data that could cause additional function
     calls or attribute lookups with untrusted values.
- Combined with INHERIT removal (see sec-inherit-player-commands-001), the
  initial evaluation of `%0` happens at player privilege.  The guard then
  prevents the fn`get-job path from running with the (now-empty) result.

## Placement rules

1. Place the `isnum()`/`isint()` guard as the **first** logical step in any
   command that uses `%0` as a job number.
2. Do not call `fn`get-job` or `u(db/fn`...)` before the guard.
3. Use `isint()` when only non-negative integers are valid (request/job
   numbers are always positive); `isnum()` accepts negative numbers and
   floats too.

## Anti-pattern

```mushcode
@@ WRONG: fn`get-job is called before isnum check
&CMD`VIEW-REQ Rockpath's Jobs System=$+request *:
  @skip/ifelse [t([setr(0, [u([v(database)]/fn`get-job, %0)])])]={
    @break [isnum(%0)]= ...   @@ too late — fn`get-job already evaluated %0
  }
```

## @rhost/testkit snippet

```typescript
describe("+request non-numeric guard", ({ it, beforeAll, afterAll }) => {
  let mortal: RhostClient;
  beforeAll(async () => { mortal = await mortalClient(); });
  afterAll(async ()  => { await mortal.disconnect(); });

  it("+request with non-numeric number is rejected cleanly", async () => {
    const lines = await mortal.command("+request notanumber");
    assertOut(lines, "number");
    refuteOut(lines, "Error");
  });

  it("+request/cancel with non-numeric number is rejected cleanly", async () => {
    const lines = await mortal.command("+request/cancel notanumber");
    assertOut(lines, "number");
    refuteOut(lines, "Error");
  });
});
```
