---
id: func-layered-config-001
domain: functions
server: RhostMUSH
source: volundmush/rhostcode (CORE 02 - Global Functions.txt, CORE 05 - Config System.txt)
complexity: medium
tags: [config, layered, getconf, globalconf, accoption, override, settings]
date_added: "2026-03-30"
tested: false
---

# Pattern: Layered config lookup (GETCONF / GLOBALCONF / ACCOPTION)

Implement a three-tier config resolution:

1. **Object-level** — check the object itself for an override (`GETCONF`)
2. **Global** — fall back to the global config object (`GLOBALCONF`)
3. **Account-level** — per-player preferences that override global defaults (`ACCOPTION`)

Each tier can override the one below it, giving players per-account settings, admins a global default, and individual objects a hard override.

## Tier definitions

```mushcode
@@ GETCONF(object, option) — check object first, then global
&GFN.GETCONF #func=
  [default(%0/CONF.[ucstr(%1)], u(#conf/OPT.[ucstr(%1)]))]

@@ GLOBALCONF(option) — global config only
&GFN.GLOBALCONF #func=
  [u(#conf/OPT.[ucstr(%1)])]

@@ ACCOPTION(player, option) — account pref, falls back to global
&GFN.ACCOPTION #func=
  [default(
    u(locate(%0, ACCOPTS, n)/OPT.[ucstr(%1)]),
    u(#conf/OPT.[ucstr(%1)])
  )]
```

## Config object structure

```mushcode
@create Config
@set Config=safe inherit

@@ Each option has a value, a default, type, and description:
&OPT.ALLOW_REGISTRATION #conf= 1
&OPT.MAX_ALTS           #conf= 3
&OPT.IDLE_TIMEOUT       #conf= 3600
&OPT.THEME              #conf= default
&OPT.MOTD               #conf= Welcome to the game.

@@ Optional per-option metadata (used by +config list):
&OPT.ALLOW_REGISTRATION.DESC    #conf= Allow new player registration
&OPT.ALLOW_REGISTRATION.TYPE    #conf= bool
&OPT.ALLOW_REGISTRATION.DEFAULT #conf= 1
```

## Usage

```mushcode
@@ Check if registration is open (global):
[getconf(#conf, allow_registration)]     @@ → 1

@@ Check with per-object override (e.g. a specific region disables it):
[getconf(%0, allow_registration)]        @@ → object's CONF.ALLOW_REGISTRATION or global

@@ Get player's preferred theme:
[accoption(%#, theme)]                   @@ → player's theme pref or global default

@@ Guard a command behind a config option:
@switch [getconf(#conf, allow_registration)]=
  0, @pemit %#=Registration is currently closed.,
  @attach %!/DO.REGISTER=%0
```

## Full config system bootstrap

```mushcode
@@ Config object with generic +config command:
&CMD_CONFIG #conf_cmd=
  $+config*:
  @switch/first 1=
    [strmatch(%0,/list*)],
      @pemit %#=[header(Configuration)]
      [iter(filter(#conf_cmd/FLT.OPTS,lattr(#conf/OPT.*)),
        [ljust(after(%i0,OPT.),25)] [u(#conf/%i0)],
        , %r)]
      @pemit %#=[footer()],
    [strmatch(%0,/set *)],
      [setq(0,first(after(%0,/set ),=))]
      [setq(1,rest(after(%0,/set ),=))]
      @switch [hasattr(#conf,OPT.[ucstr(%q0)])]=
        0, @pemit %#=Unknown option '[ucstr(%q0)]'.,
        @set #conf=OPT.[ucstr(%q0)]:[secure(%q1)]
        @pemit %#=Config option [ucstr(%q0)] set to '[u(#conf/OPT.[ucstr(%q0)])]'.,
    @pemit %#=Usage: +config/list | +config/set <option>=<value>

&FLT.OPTS #conf_cmd= [not(strmatch(%0,*.DESC))]
```

## Account-level option storage

```mushcode
@@ Account has a child ACCOPTS object holding per-player settings:
@create AccOpts
@parent AccOpts=#acc_opts_parent
@chown AccOpts=%#

&OPT.THEME AccOpts=dark
&OPT.NOTIFY AccOpts=1

@@ ACCOPTION resolves: player's AccOpts object → global #conf
```

## Notes

- Keep all global defaults on `#conf` with the `OPT.*` prefix — makes `lattr(#conf/OPT.*)` iterable for config listings.
- `getconf(object, option)` checks `CONF.<OPTION>` on the object, not `OPT.<OPTION>` — the `CONF.` prefix on the object means "this object specifically overrides the global".
- `accoption()` needs to locate the player's AccOpts child object — store its dbref in the account or use a consistent parent so `locate()` works.
- Guard all `+config/set` calls with `@lock` or `@switch [isstaff(%#)]` — this writes to the global config object.
- The `.DESC`, `.TYPE`, `.DEFAULT` sub-attrs are optional but enable self-documenting `+config/list` output.

## When NOT to use

- Single-value settings that never vary per-player — a plain `@set #conf=SOME_FLAG:value` is simpler.
- Settings that change at runtime every minute — config is for admin-set, rarely-changed values; use attributes on transient objects for session state.

## Source

Extracted from: `CORE 02 - Global Functions.txt`, `CORE 05 - Config System.txt` in https://github.com/volundmush/rhostcode
