---
id: systems-rhost-config-admin-001
domain: systems
server: RhostMUSH
source: wizhelp.txt (@admin, admin_object)
complexity: medium
tags: [config, admin, persistence, @admin, rhost_ingame.conf, admin_object]
date_added: "2026-03-28"
tested: false
---

# Persistent In-Game Config via @admin + admin_object

## Problem

`@admin param=value` changes config at runtime but the change is **lost on reboot**. To make runtime config changes survive restarts, you must use the `admin_object` pattern with `rhost_ingame.conf`.

## Prerequisites

1. `netrhost.conf` must contain `include rhost_ingame.conf` near the bottom (above local aliases section).
2. The admin object must be owned by an Immortal-level player.
3. `admin_object <dbref>` must be set in `netrhost.conf` and a `@reboot` performed after adding it.

## Pattern

### Step 1 — One-time server setup (shell)

Add to `netrhost.conf` (once, requires shell access and `@reboot`):
```
admin_object #123
include rhost_ingame.conf
```

### Step 2 — Create the admin object (in-game, Immortal)

```mushcode
@create Admin Config <cfg>
@set Admin Config <cfg>=inherit safe
@lock Admin Config <cfg>=#<immortal-dbref>
@fo me=&D.ADMINCFG me=search(name=Admin Config <cfg>)
@@(note dbref — use it in netrhost.conf as admin_object)
```

The object's dbref must match `admin_object` in `netrhost.conf`. The conf change + `@reboot` must happen **before** @admin/save will work.

### Step 3 — Write config lines onto the admin object

Each config parameter is stored as a `_LINE#` attribute. Lines must be:
- Numbered sequentially starting at `_LINE0`
- No gaps in numbering (gaps stop loading)
- Syntax matches what you would put in `netrhost.conf`

```mushcode
&_LINE0 #123=function_invocation_limit 100000
&_LINE1 #123=idle_timeout -1
&_LINE2 #123=mud_name My Cool MUSH
&_LINE3 #123=player_queue_limit 100
```

### Step 4 — Save to disk

```mushcode
@admin/save
@@(writes all _LINE# attrs to rhost_ingame.conf, overwriting it completely)
@@(invalid config params are skipped with a warning)
```

### Step 5 — Execute (apply without reboot)

```mushcode
@admin/execute
@@(runs every line in rhost_ingame.conf — same as setting each @admin param)
```

### Step 6 — Verify

```mushcode
@admin/list
@@(shows what is currently in rhost_ingame.conf)
@@(output: "0000 : function_invocation_limit 100000", etc.)

think config(function_invocation_limit)
@@(reads current live value — confirms the change is active)
```

## Reading config values (softcode)

```mushcode
@@(read any config param at runtime:)
think config(mud_name)
think config(player_queue_limit)

@@(list all available config param names:)
think config()
@@(or for a compact single-lbuf list:)
think config(1)
```

## Full lifecycle (adding a new persistent param)

```mushcode
@@(1. Check current value)
think config(function_invocation_limit)

@@(2. Set immediately — takes effect now but lost on reboot)
@admin function_invocation_limit=100000

@@(3. Add to admin object as next _LINE# in sequence)
@@(find the next available line number first:)
think lattr(#123/_LINE*)

@@(4. Set the attribute)
&_LINE4 #123=function_invocation_limit 100000

@@(5. Save to rhost_ingame.conf)
@admin/save

@@(6. Confirm saved)
@admin/list
```

## Rebuilding _LINE# after edits

If you delete or reorder lines, the numbering must be re-sequenced or @admin/load will stop at the gap. Safe rebuild:

```mushcode
@@(list current lines in order)
think lattr(#123/_LINE*)

@@(delete all and re-add in order — or use iter to rebuild)
@dolist lattr(#123/_LINE*)={@del #123/##}
@@(then re-add &_LINE0 through &_LINEN in correct sequence)
```

## Switche reference

| Switch | Effect |
|--------|--------|
| `@admin/save` | Writes `_LINE#` attrs → `rhost_ingame.conf` (overwrites file) |
| `@admin/load` | Reads `rhost_ingame.conf` → populates `_LINE#` attrs on admin_object |
| `@admin/execute` | Executes all lines in `rhost_ingame.conf` (applies params live) |
| `@admin/list` | Displays current contents of `rhost_ingame.conf` |
| `@admin <param>=<val>` | Sets param live only — not persistent without /save |

## When NOT to use

- Some config params are locked to shell-only (system-level changes that could cause harm). `@admin` will skip these with a warning.
- Any change to `admin_object` itself requires a shell edit + `@reboot`.
- Do not exceed 1000 `_LINE#` attributes — lines beyond 1000 are not read.

## Security notes

- The admin object **must** be owned by an Immortal. Non-Immortal owners cause silent failure.
- Lock the admin object: `@lock/use #123=#<immortal>` to prevent non-Immortals from setting `_LINE#` attributes.
- `rhost_ingame.conf` is a plain text file on disk — protect it at the OS level.

## See also

- `wizhelp @admin` — full command reference
- `wizhelp admin_object` — config parameter setup
- `wizhelp config parameters` — full list of configurable params
- `help config()` — reading config values in softcode
