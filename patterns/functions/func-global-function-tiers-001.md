---
id: func-global-function-tiers-001
domain: functions
server: RhostMUSH
source: volundmush/rhostcode (CORE 02 - Global Functions.txt)
complexity: medium
tags: [global-functions, function, privilege, guildmaster, tiers, register, protect]
date_added: "2026-03-30"
tested: false
---

# Pattern: Tiered global function registration (GFN / GPFN / GMFN)

Register global UDFs at three privilege levels using a consistent naming convention and corresponding `@function` registration calls. Callers use the registered global name; the implementation lives in an attribute on the function object.

| Prefix | Registration | Who can call |
|--------|-------------|-------------|
| `GFN.*` | `@function/protect` | Everyone |
| `GPFN.*` | `@function/protect/privilege` | Wizards / privileged players |
| `GMFN.*` | `@function/protect` registered as `gm_<name>` | Guildmaster+ |

## Bootstrap pattern

```mushcode
@create Function Library
@set Function Library=inherit safe

@@ Register all GFN.* attrs as global functions (anyone can call):
@dolist lattr(Function Library/GFN.*)=
  @function/protect [after(%i0,GFN.)]=#func/[%i0]

@@ Register all GPFN.* attrs as privileged global functions (wiz only):
@dolist lattr(Function Library/GPFN.*)=
  @function/protect/privilege [after(%i0,GPFN.)]=#func/[%i0]

@@ Register all GMFN.* as gm_<name> (guildmaster level):
@dolist lattr(Function Library/GMFN.*)=
  @function/protect gm_[lcstr(after(%i0,GMFN.))]=#func/[%i0]
```

## Example implementations

```mushcode
@@ — Public function: anyone can call header() ——————————————
&GFN.HEADER #func=
  [center(if(strlen(%0), %0 , ), 78, %b, =)]

@@ — Privileged function: only wizards can call staffreport() —
&GPFN.STAFFREPORT #func=
  [header(Staff Report)]
  [iter(lwho(), [name(%i0)]: [conn(%i0)]s, , %r)]

@@ — Guildmaster function: gm_setstat() ————————————————————
&GMFN.SETSTAT #func=
  [if(
    and(isdbref(%0), strlen(%1), isnum(%2)),
    [set(%0,_STAT_[ucstr(%1)]:%2)] 1,
    #-1 INVALID ARGS
  )]
```

## Calling the registered functions

```mushcode
@@ Public — everyone:
[header(My Section)]

@@ Privileged — wiz only (returns #-1 PERMISSION DENIED to others):
[staffreport()]

@@ Guildmaster — gm+ only:
[gm_setstat(%0, strength, 3)]
```

## REGISTER_FUNCTIONS helper (batch install)

```mushcode
@@ On #inc: iterates all tiers and registers them in one call
&REGISTER_FUNCTIONS #inc=
  @dolist lattr(%0/GFN.*)=
    @function/protect [after(%i0,GFN.)]=%0/[%i0];
  @dolist lattr(%0/GPFN.*)=
    @function/protect/privilege [after(%i0,GPFN.)]=%0/[%i0];
  @dolist lattr(%0/GMFN.*)=
    @function/protect gm_[lcstr(after(%i0,GMFN.))]=%0/[%i0]
```

```mushcode
@@ Usage during install:
@attach #inc/REGISTER_FUNCTIONS=#func
```

## Notes

- Keep ALL implementations on a single `#func` (or `#gfunc`) object — this makes `lattr(#func/GFN.*)` reliable for batch registration.
- `@function/protect` means the function is callable by everyone but only the owner can redefine it — safe default.
- `@function/protect/privilege` means callers need the `PRIVILEGE` power — appropriate for admin-only utilities.
- The `gm_` prefix is a convention; RhostMUSH doesn't enforce it. You can restrict it via `@function/protect` + a lock if needed.
- Re-run the registration `@dolist` whenever a new function is added — it's idempotent (reregistering is safe).
- In rhostcode, global functions are split: formatting utilities are `GFN.*`, account/auth functions are `GPFN.*`, stat-mutation functions are `GMFN.*`.

## When NOT to use

- Functions used in only one system → define them locally on that system's object via `&FN.*` and call with `u()`.
- Functions that need `@commands` or side effects → use action-list include pattern (`#inc/HANDLER`) instead.

## Source

Extracted from: `CORE 02 - Global Functions.txt` in https://github.com/volundmush/rhostcode
