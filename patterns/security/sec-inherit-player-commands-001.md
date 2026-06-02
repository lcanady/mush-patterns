---
id: sec-inherit-player-commands-001
domain: commands
server: RhostMUSH
source: mush-security audit (RockJobs 2026-03-27)
complexity: medium
tags: [security, anti-pattern, inherit, player-commands, privilege-escalation]
date_added: "2026-03-27"
---

# Pattern: Player-accessible $-commands must not live on an INHERIT object

Any `$`-command that a mortal player can trigger (`+request/create`,
`+request/comment`, etc.) should never be defined on an object with the
`INHERIT` flag.  If a player succeeds in injecting code via `%0`–`%9`, the
injected code executes with wizard-level privilege.

## Code (anti-pattern)

```mushcode
@@ WRONG: one object carries both player-accessible commands AND INHERIT
&CMD`REQ-ADD Rockpath's Jobs System=$+request/create */*=*:
  @eval [u([v(database)]/fn`create-job, %0, %1, %2)]

&CMD`VIEW-REQ Rockpath's Jobs System=$+request *:
  @skip/ifelse [t([setr(0, [u([v(database)]/fn`get-job, %0)])])]= ...

@set Rockpath's Jobs System=INHERIT SIDEFX
```

Any successful injection in `%0`, `%1`, or `%2` runs with wizard privilege
because the Jobs System object is `INHERIT`.

## Code (correct pattern)

```mushcode
@@ Player-facing dispatch object: no INHERIT, SIDEFX kept for pemit/list
@set Rockpath's Jobs System=!inherit

@@ Separate database/function object: retains INHERIT, but has no
@@ player-accessible $-commands; mortals cannot reach these functions directly.
@set Rockpath's Job Database=INHERIT SIDEFX
@lock/use Rockpath's Job Database=haspower(me,Wizard)
```

- Player-triggered `$`-commands live on the **non-INHERIT** dispatch object.
- Wizard-level operations (object creation, `mailsend`, `@destroy`) live on
  the **INHERIT** database/function object.
- Mortals can reach the dispatch object via `$`-commands but cannot call
  functions on the database object directly (use-locked to wizard).

## Why this matters

- With `INHERIT`, a successful `[pemit #1=...]` injection runs as wizard.
  This can be used to send forged mail, modify attributes on any object,
  or `@destroy` rooms and objects.
- Without `INHERIT`, the injected code runs at the **player's own privilege**
  level.  Most game-breaking operations (`@destroy`, `@force` on wizards,
  attribute writes on protected objects) will be blocked by normal permission
  checks.
- This is the single highest-value fix for MUSH injection vulnerabilities
  in player-accessible systems.

## Checklist

- [ ] Identify every object with `INHERIT` flag.
- [ ] For each, list all `$`-commands on it.
- [ ] Classify each command: staff-only or mortal-accessible?
- [ ] Move mortal-accessible commands to a non-INHERIT dispatch object.
- [ ] Add `@lock/use` on INHERIT objects to wizard-only.
- [ ] Retain `SIDEFX` on the dispatch object if `pemit`/`list` calls are needed.

## @rhost/testkit snippet

```typescript
it("Jobs System does not have INHERIT flag", async ({ expect }) => {
  await expect("hasflag(num(Rockpath's Jobs System), inherit)").toBe("0");
});

it("Job Database retains INHERIT flag", async ({ expect }) => {
  await expect("hasflag(num(Rockpath's Job Database), inherit)").toBe("1");
});
```
