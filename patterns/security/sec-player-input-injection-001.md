---
id: sec-player-input-injection-001
domain: commands
server: RhostMUSH
source: mush-security audit (RockJobs 2026-03-27)
complexity: high
tags: [security, anti-pattern, injection, inherit, sidefx, player-input]
date_added: "2026-03-27"
---

# Pattern: Player string input on INHERIT+SIDEFX object executes as wizard-level code

In RhostMUSH, `%0`–`%9` substitution and `[func()]` evaluation happen in the
same pass.  Any player-controlled input that contains `[...]` will execute
before any sanitization check can inspect it — the check then runs on the
(now-empty or already-mutated) result, not the original input.

## Code (vulnerable)

```mushcode
@@ Jobs System has INHERIT SIDEFX — player $-commands run with wizard privilege
&CMD`REQ-ADD Rockpath's Jobs System=$+request/create */*=*:
  @eval [u([v(database)]/fn`create-job, %0, %1, %2)]

@@ fn`create-job on the INHERIT Job Database:
&FN`CREATE-JOB Rockpath's Job Database=
  [set(%q0, JName:%1)]
  [set(%q0, desc:%2)]
  ...
```

A mortal player can type:

```
+request/create APP/[pemit #1=You are owned]=normal body
```

The server substitutes `%1` → `[pemit #1=You are owned]`, evaluates it, then
`fn`create-job` receives an empty string as the topic.  With INHERIT on the
dispatch object, `pemit` ran at wizard level.

## Why the "check first" approach does not work

```mushcode
@@ WRONG — isnum(), regmatchi(), and edit() all come too late
@break [regmatchi(%1, \[)]={ ... reject ... }
```

By the time `regmatchi(%1, \[)` is evaluated, `%1` has already been
substituted and `[evil()]` has already run.  `regmatchi` then inspects the
result of `evil()`, not the literal `[evil()]` string.  The same is true for
`isnum(%0)`, `edit(%1, ...)`, `secure(%1)`, and any other function that
receives the already-evaluated value.

## Correct mitigations

### 1. Remove INHERIT from the player-facing dispatch object (primary fix)

```mushcode
@@ Remove INHERIT from Jobs System — player $-commands drop to player privilege.
@@ SIDEFX is kept for legitimate pemit/list calls in those commands.
@@ The Job Database (fn`create-job, mailsend, etc.) retains INHERIT because
@@ mortals cannot reach its functions via $-commands.
@set Rockpath's Jobs System=!inherit
```

This does not prevent the injection from running, but it caps the damage: the
injected code now executes with the player's own privilege rather than wizard
privilege.

### 2. Bracket-rejection strmatch guard (layered defense — see sec-bracket-reject-strmatch-001)

```mushcode
&CMD`REQ-ADD Rockpath's Jobs System=$+request/create */*=*:
  @@ Reject if topic contains brackets.  NOTE: %1 is still evaluated here —
  @@ injection executes at player level (after fix #1) — but @break stops
  @@ fn`create-job from being called with the injected input.
  @break [strmatch(%1, [edit(%1, [, %[, ], %])])]={
    @pemit %#=Requests may not contain [ characters in the topic.
  };
  @break [strmatch(%2, [edit(%2, [, %[, ], %])])]={
    @pemit %#=Requests may not contain [ characters in the body.
  };
  @eval [u([v(database)]/fn`create-job, %0, %1, %2)]
```

### 3. isnum() guard for numeric fields (see sec-isnum-guard-001)

For fields that must be integers, an `isnum()`/`isint()` guard prevents the
fn`get-job path from executing a second time on the already-empty result,
adding defense in depth without preventing the initial evaluation.

## Summary

| Fix | Prevents initial execution? | Caps damage | Prevents storage |
|---|---|---|---|
| Remove INHERIT from dispatch object | No | Yes (player level) | No |
| Bracket-rejection @break | No | Only with fix 1 | Yes |
| isnum() guard | No | Only with fix 1 | Yes (stops 2nd eval) |

## @rhost/testkit snippet

```typescript
runner.describe("RockJobs — Security hardening", ({ it, describe }) => {
  describe("+request/create injection rejection", ({ it, beforeAll, afterAll }) => {
    let mortal: RhostClient;
    beforeAll(async () => { mortal = await mortalClient(); });
    afterAll(async ()  => { await mortal.disconnect(); });

    it("+request/create rejects [ in topic", async () => {
      const lines = await mortal.command(
        "+request/create APP/Test[pemit me=INJECTED]=Body"
      );
      refuteOut(lines, "created");
      refuteOut(lines, "INJECTED");
    });
  });
});
```
