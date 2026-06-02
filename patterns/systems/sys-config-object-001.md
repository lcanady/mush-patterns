---
id: sys-config-object-001
domain: systems
server: RhostMUSH
source: community conventions, mush-architect corpus upgrade 2026-06-02
complexity: medium
tags: [config, admin, configuration, wizard, settings, attribute-namespace, runtime]
date_added: "2026-06-02"
tested: false
see_also: [inst-tag-object-registry-001, sys-data-dictionary-001]
---

# Pattern: System configuration object with CONFIG.* namespace

Centralise system-wide runtime settings using a `CONFIG.*` attribute namespace on the main system object. A wizard-only `+system/config` command lets admins read and set values without reloading the installer.

## Signal
USE:  runtime-configurable settings on sys object | CONFIG.* namespace | wiz +cmd interface
ARCH: CONFIG.* attrs (world-readable) | secrets in _ prefixed attrs (wiz-only) | F.CONFIG.GET/SET UDFs
WARN: CONFIG.* is world-readable by default -- never store API keys or tokens there; use _ prefix for secrets
TEST: ✗

## Code

```mushcode
@@ ---------------------------------------------------------------
@@ CONFIG attribute definitions on the system object
@@ ---------------------------------------------------------------

@@ Enable/disable the whole system (1=on, 0=off):
&CONFIG.ENABLED #sys=1

@@ Maximum number of active entries (integer):
&CONFIG.MAX_ENTRIES #sys=50

@@ Room dbref where system announcements are broadcast:
&CONFIG.ANNOUNCE_ROOM #sys=#0

@@ Name prefix used in player-facing output:
&CONFIG.PREFIX #sys=System

@@ Cooldown in seconds between player actions:
&CONFIG.COOLDOWN #sys=30

@@ ---------------------------------------------------------------
@@ F.CONFIG.GET -- read a named config key
@@ %0 = key name (without CONFIG. prefix)
@@ Returns value string or error token
@@ ---------------------------------------------------------------
&F.CONFIG.GET #sys=
  [if(
    not(t(%0)),
    #-3 WRONG NUMBER OF ARGUMENTS,
    [setq(0,get(%!/CONFIG.[ucstr(%0)]))]
    [if(t(%q0),%q0,#-1 INVALID KEY)]
  )]

@@ ---------------------------------------------------------------
@@ F.CONFIG.SET -- write a named config key (wizard-only)
@@ %0 = key name (without CONFIG. prefix)
@@ %1 = new value
@@ %# = enactor dbref (for wizard check)
@@ Returns: OK | error token
@@ ---------------------------------------------------------------
&F.CONFIG.SET #sys=
  [if(
    not(isstaff(%#)),
    #-2 PERMISSION DENIED,
    [if(
      not(t(%0)),
      #-3 WRONG NUMBER OF ARGUMENTS,
      [if(
        not(hasattr(%!,CONFIG.[ucstr(%0)])),
        #-1 INVALID KEY,
        [attrib_set(%!/CONFIG.[ucstr(%0)],%1)]
        OK
      )]
    )]
  )]

@@ ---------------------------------------------------------------
@@ Admin command -- list all CONFIG.* attributes
@@ $+<system>/config list
@@ ---------------------------------------------------------------
&CMD.CONFIG.LIST #sys=$+system/config list:
  @pemit %#=
    [setq(0,list(%!,CONFIG.*))]
    [if(not(t(%q0)),
      No CONFIG.* attributes found.,
      [setq(1,
        [iter(%q0,
          [rjust(after(##,CONFIG.),20,.)] = [get(%!/##)],%r
        )]
      )]
      -- [get(%!/CONFIG.PREFIX)] Config ---%r%q1
    )]

@@ ---------------------------------------------------------------
@@ Admin command -- set a config key
@@ $+<system>/config set <KEY>=<VALUE>
@@ ---------------------------------------------------------------
&CMD.CONFIG.SET #sys=$+system/config set *=*:
  @switch/first 1=
    [not(isstaff(%#))],
      @pemit %#=Permission denied.,
    [not(hasattr(%!,CONFIG.[ucstr(%0)]))],
      @pemit %#=Unknown config key: %0. Use +system/config list to see valid keys.,
    {
      @pemit %#=Setting CONFIG.[ucstr(%0)] to: %1;
      &CONFIG.[ucstr(%0)] %!=%;
      &CONFIG.[ucstr(%0)] %!=%1;
      @pemit %#=Done.
    }

@@ Lock so only wizards can trigger the commands:
@lock/use #sys=WIZARD
```

## Notes

- `CONFIG.*` attributes are world-readable by default on most RhostMUSH setups. Never store secrets (API tokens, passwords, signing keys) under this prefix. Use a `_SECRET.*` or `_KEY.*` attribute name instead; attributes beginning with `_` are invisible to non-wizards.
- The `hasattr()` guard in `F.CONFIG.SET` and `CMD.CONFIG.SET` is intentional. It means only keys that were seeded by the installer can ever be set at runtime. This prevents an admin typo or a malicious `pemit` injection from creating arbitrary `CONFIG.*` keys that callers might later trust.
- Use `list()` rather than `iter()` for the list subcommand. `list()` returns a newline-delimited output string in one call and does not iterate, which avoids queue flooding when the count of `CONFIG.*` attributes is large.
- `F.CONFIG.GET` and `F.CONFIG.SET` are UDFs so that other objects on the same system can read/write config via `ulocal(#sys/F.CONFIG.GET,KEY)` without duplicating the validation logic.
- If you need multiple systems on the same server each with their own config, give each system object its own `CONFIG.*` namespace. Do not share a single config object across systems -- the `hasattr()` guard only works cleanly when key ownership is unambiguous.

## Variants

- **Typed config**: store values as `type|value` (e.g., `int|50` or `dbref|#123`) and extend `F.CONFIG.GET` to validate the type on read.
- **Change log**: add a `&CONFIG._LOG` attribute and append `[name(%#)]:[ucstr(%0)]=[before]>[%1]` on each `F.CONFIG.SET` call to maintain a runtime audit trail.
- **Per-player overrides**: keep the global `CONFIG.*` namespace for defaults and add `PCONFIG.<DBREF>.<KEY>` attributes for per-player overrides resolved in a wrapper UDF.

## When NOT to use

- Systems with only 1-2 settings -- just hardcode them as attributes and document them with comments in the installer. The CONFIG layer adds ceremony without benefit at that scale.
- Player-accessible settings -- `CONFIG.*` is wiz-guarded at write time; build a separate player-settings object with its own `PREF.*` namespace and matching `+set` commands.

## Source

community conventions, mush-architect corpus upgrade 2026-06-02
