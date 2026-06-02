---
id: func-include-actionlist-001
domain: functions
server: RhostMUSH
source: volundmush/rhostcode (CORE 03 - Include Library.txt)
complexity: medium
tags: [include, actionlist, subroutine, dispatch, reuse, attach]
date_added: "2026-03-30"
tested: false
---

# Pattern: Action-list include library (`#inc`)

Centralise reusable softcode logic as named action-list attributes on a single "include object" (`#inc`). Call them with `@attach %!/HANDLER=%0,%1` from any context. Arguments arrive as `%0`, `%1`, etc. inside the action list, and results are returned via `%q` registers.

This is the rhostcode equivalent of function-call subroutines — more powerful than UDFs for multi-step logic because action lists can use `@pemit`, `@set`, `@switch`, `@trigger`, etc.

## Pattern structure

```mushcode
@create Include Library
@set Include Library=inherit safe

@@ A simple validator: sets %q0=1 if %0 is a valid dbref, 0 otherwise
&VALID.DBREF Include Library=
  [setq(0,if(isdbref(%0),1,0))]

@@ A messaging primitive: pemits %0 to player %1 with standard header
&MSG Include Library=
  @pemit %1=%[header()%] %0

@@ A player-lookup helper: sets %q0=dbref of player named %0, or pemits error
&GET_PLAYER Include Library=
  [setq(0,pmatch(%0))]
  @switch/first 1=
    [isdbref(%q0)],  ,
    @pemit %#=No player found matching '%0'.
```

## Invocation

```mushcode
@@ Call VALID.DBREF with one argument, result in %q0:
@attach %!/VALID.DBREF=#1234

@@ Call MSG with message and target:
@attach %!/MSG=Hello world,#42

@@ Call GET_PLAYER, then use %q0:
@attach %!/GET_PLAYER=Volund
@switch/first [isdbref(%q0)]=1,
  @pemit %#=Found: [name(%q0)](%q0).,
  @@ error already pemitted by GET_PLAYER
```

## Full include object bootstrap

```mushcode
@create #inc=Include Library
@set #inc=inherit safe

@@ — Validators (all set %q0=1/0) ——————————————————————————
&VALID.WORD   #inc= [setq(0,not(words(%0,!a-zA-Z0-9_-)))]
&VALID.POSINT #inc= [setq(0,and(isnum(%0),gte(%0,1)))]
&VALID.INT    #inc= [setq(0,isnum(%0))]
&VALID.BOOL   #inc= [setq(0,or(strmatch(%0,1),strmatch(%0,0),
                                strmatch(%0,yes),strmatch(%0,no),
                                strmatch(%0,true),strmatch(%0,false)))]
&VALID.DBREF  #inc= [setq(0,isdbref(%0))]
&VALID.FUTURE #inc= [setq(0,gt(%0,[secs()]))]

@@ — Messaging primitives —————————————————————————————————
&MSG       #inc= @pemit %1=[header()] %0
&MSG_ALERT #inc= @pemit %1=[u(#conf/FN.ALERT,%0)]

@@ — Lookup helpers ————————————————————————————————————————
&GET_PLAYER #inc=
  [setq(0,pmatch(%0))]
  @switch/first 1=
    [isdbref(%q0)],  ,
    @pemit %#=No player named '%0' found.

@@ — Config helpers ————————————————————————————————————————
&CONF_SET #inc=
  [setq(0,locate(#conf,%0,n))]
  @switch [isdbref(%q0)]=
    0, @pemit %#=Unknown config option '%0'.,
    @set %q0=%1:[secure(%2)]

&CONF_LIST #inc=
  @pemit %#=[header(Config Options)]
  [iter(lattr(#conf/OPT.*),
    @pemit %#=[ljust(after(%i0,OPT.),20)] [u(#conf/%i0)],
    , )]
```

## Notes

- Name validators `VALID.*`, messaging primitives `MSG*`, lookup helpers `GET_*`, config ops `CONF_*` — consistent naming makes callers readable.
- `@attach %!/HANDLER=args` — `%!` refers to the calling object, so the action list runs *in the caller's context* with the caller's `%#`, `%@`, etc. Use `@trigger #inc/HANDLER=args` instead if you want the action list to run as `#inc`.
- Unlike UDFs (`u()`), action lists can contain `@commands` — use them when you need side effects (setting attrs, pemitting, etc.).
- Keep `#inc` set `inherit safe` so players cannot `@trigger` it directly.
- Results go in `%q` registers by convention; `%q0` is the primary result, `%q1`–`%q9` for additional returns.

## When NOT to use

- Pure value-computation with no side effects → use a UDF (`&GFN.* #func`) instead.
- Logic that needs to run as a specific enactor — use `@trigger` with explicit `@switch/first` guards on `%@`.
- One-liner expressions — inline is clearer than a subroutine call.

## Source

Extracted from: `CORE 03 - Include Library.txt` in https://github.com/volundmush/rhostcode
