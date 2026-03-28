---
id: func-rhost-config-read-001
domain: functions
server: RhostMUSH
source: help.txt (CONFIG())
complexity: low
tags: [config, config(), @admin, read, runtime, introspection]
date_added: "2026-03-28"
tested: false
---

# Reading Config Parameters with config()

## Problem

You need to read the current value of a server config parameter at runtime — for conditionals, display, or logging — without shell access.

## Pattern

```mushcode
@@(read a single config param:)
think config(mud_name)
@@(→ "My Cool MUSH")

think config(function_invocation_limit)
@@(→ "100000")

@@(list all config param names as a space-delimited string:)
think config()

@@(compact form — fits in a single LBUF:)
think config(1)

@@(common useful params to check:)
think config(player_queue_limit)
think config(function_recursion_limit)
think config(iter_loop_max)
think config(stack_limit)
think config(lock_recursion_limit)
```

## In a UDF

```mushcode
&FN_CONFCHECK <obj>=
  [if(lt(config(function_invocation_limit), 50000),
    #-1 FUNCTION LIMIT TOO LOW,
    config(function_invocation_limit)
  )]
```

## In an installer — guard against under-powered servers

```mushcode
@@(check server limits before installing — emit warning if too restrictive:)
@switch/first 1=
  lt(config(function_invocation_limit), 10000),
    @pemit %#=WARNING: function_invocation_limit is [config(function_invocation_limit)] — this system requires at least 10000.,
  lt(config(iter_loop_max), 100),
    @pemit %#=WARNING: iter_loop_max is [config(iter_loop_max)] — this system requires at least 100.,
  @pemit %#=Server config OK. Proceeding with install.
```

## Variants

```mushcode
@@(check if a feature is enabled via config:)
think if(config(sideeffects), Side effects enabled., Side effects disabled.)

@@(read buffer sizes for compatibility:)
think config(lbuf_size)   @@(→ typically 8000 in Rhost)
think config(mbuf_size)
think config(sbuf_size)
```

## Notes

- `config()` is read-only — it cannot set values. Use `@admin` to set.
- Returns the live runtime value, which may differ from `netrhost.conf` if `@admin` was used without `/save`.
- Special arguments `lbuf_size`, `mbuf_size`, `sbuf_size` return buffer sizes for cross-codebase compatibility.
- `config()` with no args returns a long space-delimited list — use `config(1)` if you need it to fit in one LBUF.

## See also

- `wizhelp @admin` — setting config values
- `wizhelp config parameters` — full configurable param list
- Pattern: `systems/rhost-config-admin-001.md` — persistent config setup
