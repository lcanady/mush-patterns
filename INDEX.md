# mush-patterns INDEX

Auto-maintained by `/mush-learn`. One entry per pattern file.

## functions/

- [func-iter-map-001](patterns/functions/func-iter-map-001.md) — iter/map patterns for list processing
- [func-udf-guard-001](patterns/functions/func-udf-guard-001.md) — Input guard pattern for UDFs (`if(not(%0), #-1 MISSING ARG, ...)`)
- [rhost-config-read-001](patterns/functions/rhost-config-read-001.md) — Reading config parameters at runtime with `config()`
- [sec-isnum-match-anti-001](patterns/functions/sec-isnum-match-anti-001.md) — Anti-injection: `isnum()` and `match()` guards
- [sec-log-escape-001](patterns/functions/sec-log-escape-001.md) — Safe logging with `escape()` / `secure()`
- [sec-safe-path-001](patterns/functions/sec-safe-path-001.md) — Safe path construction for `execscript()`
- [sec-strsearch-not-match-001](patterns/functions/sec-strsearch-not-match-001.md) — `strsearch()` vs `match()` for safe substring checks

## commands/

*(none yet)*

## systems/

- [help-system-001](patterns/systems/help-system-001.md) — Softcoded help system patterns
- [rhost-config-admin-001](patterns/systems/rhost-config-admin-001.md) — Persistent in-game config via `@admin` + `admin_object` + `rhost_ingame.conf`
- [test-hooks.md](patterns/systems/test-hooks.md) — @rhost/testkit test hook patterns

## server-help/

- [rhost](patterns/server-help/rhost.md) — RhostMUSH server-specific patterns (locks, powers, flags)
- [rhost-config-params-001](patterns/server-help/rhost-config-params-001.md) — Key RhostMUSH config parameters reference (limits, side-effects, global objects)
