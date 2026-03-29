---
id: func-chargen-status-guard-001
domain: functions
server: RhostMUSH
source: city-of-roses, session 2026-03-29
complexity: low
tags: [guard, chargen, status, permission, wizard, udf]
date_added: "2026-03-29"
tested: true
---

# Pattern: Chargen status guard (CANWRITE)

A simple UDF that returns 1 if a player is allowed to edit their own sheet — either because they are in chargen (status = unapproved) or because the caller is staff (WIZARD flag). Use at the top of every chargen-phase setter UDF.

## Code

```mushcode
@@ On the stat handler object:
&F.CANWRITE #example_stat=
  [if(
    not(t(%0)),
    0,
    or(
      hasflag(%0,WIZARD),
      eq(lcstr(get(%0/_EXAMPLE_STATUS)),unapproved)
    )
  )]

@@ Usage inside any setter UDF:
&F.CMD.SETSTAT #example_stat=
  [if(
    not(ulocal(%!/F.CANWRITE,%0)),
    You cannot set stats. Your sheet is not in chargen.,
    [... actual setter logic ...]
  )]
```

## Notes

- The guard checks two independent conditions: staff flag OR chargen status. Either is sufficient.
- `lcstr()` normalises the stored status value against the string literal — avoids case mismatches from mixed-case input or legacy data.
- `t(%0)` guards against an empty first argument (no player passed) before calling `hasflag()` or `get()`.
- Use `ulocal()` not `u()` so the UDF cannot write to the calling object's qregs by accident.
- The failure message should be human-readable and tell the player what to do next.

## Variants

- **Unapproved-only (no staff bypass)**: drop the `hasflag(%0,WIZARD)` branch for pure player-only chargen commands.
- **Multi-status**: replace the `eq(...,unapproved)` with `member(unapproved review,%q_status)` if your workflow has intermediate states.

## When NOT to use

- Read-only commands (viewing a sheet) — anyone should be able to read.
- Admin-only commands — check `hasflag(%0,WIZARD)` directly; don't involve status at all.

## Source

Extracted from: city-of-roses, session 2026-03-29
