---
id: server-help-rhost-config-params-001
domain: server-help
server: RhostMUSH
source: wizhelp.txt (CONFIG PARAMETERS, individual param entries)
complexity: low
tags: [config, @admin, netrhost.conf, limits, hooks, queue, sideeffects, execscript]
date_added: "2026-03-28"
tested: false
---

# RhostMUSH Key Config Parameters Reference

Quick reference for the config parameters most relevant to softcode development.
Full list: `wizhelp config parameters` (6 pages). Read with `config(<param>)` in-game.

## Softcode limits (tune these for large systems)

| Parameter | Default | Description |
|-----------|---------|-------------|
| `function_invocation_limit` | 2500 | Max function calls per command. Raise for complex systems. Error: `#-1 FUNCTION INVOCATION LIMIT EXCEEDED` |
| `function_recursion_limit` | 50 | Max nested function depth. Error: `#-1 FUNCTION RECURSION LIMIT EXCEEDED` |
| `iter_loop_max` | 100000 | Max iterations for `iter()` range syntax (`:N:`). 1M+ triggers 1-sec CPU alarm |
| `stack_limit` | 10000 | Max recursive command calls before abort (DoS protection) |
| `lock_recursion_limit` | 20 | Max levels of indirect lock nesting |
| `notify_recursion_limit` | — | Max recursive notify depth |
| `player_queue_limit` | 100 | Max queued commands for non-wizard players |
| `wizard_queue_limit` | 100 | Max queued commands for wizard players |
| `function_max` | 1000 | Max global `@function` definitions (-1 = unlimited) |
| `lfunction_max` | — | Max local `@function` definitions per object |

### Recommended values for active softcode systems

```
@admin function_invocation_limit=100000
@admin function_recursion_limit=100
@admin player_queue_limit=500
@admin wizard_queue_limit=1000
```

## Side effects

| Parameter | Default | Description |
|-----------|---------|-------------|
| `sideeffects` | 32 (LIST only) | Bitmask of enabled side-effect functions. See below |
| `global_sideeffects` | 0 (off) | If enabled, SIDEFX flag *reverses* — set to block side-effects |
| `sidefx_maxcalls` | — | Max side-effect calls per command |
| `sidefx_returnval` | — | What side-effect functions return on success |
| `restrict_sidefx` | — | Restrict side-effects to specific player levels |

### sideeffects bitmask values

```
none=0       SET=1        CREATE=2     LINK=4
OPEN=128     EMIT=256     OEMIT=512    CLONE=1024
WIPE=32768   DESTROY=65536 ZEMIT=131072 NAME=262144
MOVE=8388608 MAILSEND=33554432 EXECSCRIPT=67108864
```

Example — enable SET, CREATE, EMIT, OEMIT, NAME:
```mushcode
@admin sideeffects=SET CREATE EMIT OEMIT NAME
@@(or by summing bitmask: 1+2+256+512+262144 = 262915)
@admin sideeffects=262915
```

## Global system objects

| Parameter | Default | Description |
|-----------|---------|-------------|
| `master_room` | (none) | Room searched for global `$`-commands when no local match |
| `hook_obj` | -1 | Object storing `@hook` attributes (`B_`, `A_`, `P_`, `I_`, `AF_` prefixes) |
| `hook_cmd` | — | Alternative to `@hook` for setting hooks via `@admin` or conf |
| `global_error_obj` | -1 | Object whose `&VA` fires on "Huh?" — receives `%0`=raw input |
| `global_error_cmd` | no | If yes, `global_error_obj` also handles unknown commands |
| `admin_object` | -1 | Object used for `@admin/save`, `/load`, `/execute` (see pattern `systems/rhost-config-admin-001.md`) |
| `file_object` | — | Object for file I/O operations |

### Setting the master_room

```mushcode
@@(from shell or netrhost.conf — or in-game with @admin:)
@admin master_room=#<dbref of master room>
@@(to make permanent:)
@admin master_room=#42
@admin/save
```

### Setting up a global error handler

```mushcode
@create Error Handler <err>
@set Error Handler <err>=inherit safe sidefx
@fo me=&D.ERR me=search(name=Error Handler <err>)

@@(the VA attribute fires on unmatched input:)
&VA Error Handler <err>=
  @switch/first 1=
    isnum(%0), @pemit %#=No command '#[%0]' found.,
    @pemit %#=Unrecognized command: [escape(%0)]

@@(set the config param:)
@admin global_error_obj=#<dbref>
@admin global_error_cmd=yes
@admin/save
```

## execscript configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `execscripthome` | (empty) | Override path to scripts directory (default: `~/game/scripts`) |
| `execscriptpath` | (empty) | Space-delimited list of allowed script subdirectories |

```mushcode
@@(allow scripts in scripts/mymod/ and scripts/tools/:)
@admin execscriptpath=mymod tools
@admin/save
```

## Other frequently tuned params

| Parameter | Default | Description |
|-----------|---------|-------------|
| `mud_name` | — | Server name shown in headers/who |
| `player_queue_limit` | 100 | Commands queued per non-wiz player |
| `space_compress` | — | Whether to compress multiple spaces in output |
| `idle_timeout` | — | Seconds before idle disconnect (-1 = never) |
| `dump_interval` | — | Seconds between database saves |
| `cpu_secure_lvl` | — | CPU security level |

## Reading config in softcode

```mushcode
@@(always verify a limit before writing code that depends on it:)
think config(function_invocation_limit)
think config(sideeffects)
think config(master_room)

@@(check if side-effects are on at all:)
think if(config(sideeffects), Side effects enabled., Side effects off.)
```

## See also

- `wizhelp config parameters` (pages 1–6) — full param list
- `wizhelp @admin` — setting params in-game
- `wizhelp @list` — `@list config_permissions` shows access levels
- `help config()` — reading params in softcode
- Pattern: `systems/rhost-config-admin-001.md` — persistent config setup
