# mush-patterns INDEX

All patterns in the corpus, one line each.

**Navigation:** [PALACE.md](PALACE.md) — wings, rooms, and tunnels map | [AAAK_SPEC.md](AAAK_SPEC.md) — Signal block notation reference

## functions

- [UDF argument guard](patterns/functions/func-udf-guard-001.md) — validate args and return `#-1 REASON` at top of every UDF
- [iter as map](patterns/functions/func-iter-map-001.md) — transform a space-delimited list with `iter()` and `##`
- [list() buffer-safe iteration](patterns/functions/func-list-rhost-001.md) — buffer-safe `iter()` replacement for large lists using RhostMUSH `list()`
- [Perm/temp dual-value storage](patterns/functions/func-perm-temp-storage-001.md) — store permanent and temporary pool values in one attribute using `perm.temp` dot notation
- [Chargen status guard (CANWRITE)](patterns/functions/func-chargen-status-guard-001.md) — gate setter UDFs on `status=unapproved` OR WIZARD flag
- [Attribute exposure guard](patterns/functions/sec-attr-exposure-001.md) — prevent leaking wiz-only attribute names through UDF return values
- [JSON injection guard](patterns/functions/sec-json-injection-001.md) — sanitise player input before embedding in structured attribute strings
- [Hyphenated title-case formatter](patterns/functions/func-hyphen-titlecase-001.md) — capitalise every word across hyphens: `get-of-fenris` → `Get-Of-Fenris`
- [Parallel multi-list iteration](patterns/functions/func-parallel-list-iter-001.md) — walk N equal-length lists in lock-step using `iter(lnum())` + `extract(list,##,1)`
- [printf() ANSI-aware formatter](patterns/functions/func-printf-001.md) — fixed-width column output with ANSI escape awareness using RhostMUSH `printf()`
- [ANSI color conventions](patterns/functions/func-ansi-colors-001.md) — re-themeable color layer via `_COLOR.*` config attributes and ANSI wrapper UDFs

## commands

- [Switch-dispatched command](patterns/commands/cmd-switch-pattern-001.md) — route `+cmd/switch` patterns to separate attribute handlers
- [Command object lock](patterns/commands/sec-command-lock-001.md) — lock a command object so only the correct enactor can trigger `$`-patterns
- [Rate-limit guard](patterns/commands/sec-rate-limit-001.md) — prevent command spam with a per-player timestamp check
- [Unified remove dispatcher](patterns/commands/cmd-unified-remove-001.md) — one `$+cmd/*/remove *` command dispatches all category-qualified removes via `case()`
- [Two-argument command](patterns/commands/cmd-two-arg-pattern-001.md) — canonical `$+cmd <target>=<value>` parsing with guard and feedback
- [Standard command feedback](patterns/commands/cmd-feedback-shape-001.md) — consistent success, error, and usage messages across all commands
- [Multi-column printf display](patterns/commands/cmd-printf-columns-001.md) — ANSI-safe multi-column table output using `printf()`

## systems

- [Data dictionary object](patterns/systems/sys-data-dictionary-001.md) — centralise stat definitions as `STATDEF.CATEGORY.STATNAME` attributes with accessor UDFs
- [Rank cascade](patterns/systems/sys-rank-cascade-001.md) — auto-raise dependent stats to minimum values when a rank/tier stat is set
- [Help system](patterns/systems/help-system-001.md) — server-agnostic help text storage and display pattern
- [Test hooks](patterns/systems/test-hooks.md) — attach @rhost/testkit hooks to system objects for CI testing
- [Fixed-width sheet column with dot-fill](patterns/systems/sys-sheet-column-layout-001.md) — render stat columns as `StatName......5` using `ljust()` + `repeat(.)` for multi-column sheet display
- [Game-line dispatcher](patterns/systems/sys-gameline-dispatcher-001.md) — dynamically route to `F.HANDLER.<LINE>` UDFs based on a player's stored template prefix for multi-game support
- [Standard visual frame](patterns/systems/sys-visual-frame-001.md) — shared display object providing consistent header/body/footer for all command output
- [System configuration object](patterns/systems/sys-config-object-001.md) — centralised `CONFIG.*` namespace on a dedicated object for runtime-editable system settings

## installers

- [Tag-based object registry](patterns/installers/inst-tag-object-registry-001.md) — use `@tag/add` + `lastcreate()` to register system objects for stable cross-object references
- [Canonical installer structure](patterns/installers/inst-header-format-001.md) — standard header, section blocks, progress banners, and uninstall block for all installers

## server-help

- [RhostMUSH reference](patterns/server-help/rhost.md) — annotated RhostMUSH-specific functions, flags, and config quirks
