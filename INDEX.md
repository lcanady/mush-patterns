# mush-patterns INDEX

All patterns in the corpus, one line each.

## functions

- [UDF argument guard](patterns/functions/func-udf-guard-001.md) — validate args and return `#-1 REASON` at top of every UDF
- [iter as map](patterns/functions/func-iter-map-001.md) — transform a space-delimited list with `iter()` and `##`
- [Perm/temp dual-value storage](patterns/functions/func-perm-temp-storage-001.md) — store permanent and temporary pool values in one attribute using `perm.temp` dot notation
- [Chargen status guard (CANWRITE)](patterns/functions/func-chargen-status-guard-001.md) — gate setter UDFs on `status=unapproved` OR WIZARD flag
- [Attribute exposure guard](patterns/functions/sec-attr-exposure-001.md) — prevent leaking wiz-only attribute names through UDF return values
- [JSON injection guard](patterns/functions/sec-json-injection-001.md) — sanitise player input before embedding in structured attribute strings

## commands

- [Switch-dispatched command](patterns/commands/cmd-switch-pattern-001.md) — route `+cmd/switch` patterns to separate attribute handlers
- [Command object lock](patterns/commands/sec-command-lock-001.md) — lock a command object so only the correct enactor can trigger `$`-patterns
- [Rate-limit guard](patterns/commands/sec-rate-limit-001.md) — prevent command spam with a per-player timestamp check

## systems

- [Data dictionary object](patterns/systems/sys-data-dictionary-001.md) — centralise stat definitions as `STATDEF.CATEGORY.STATNAME` attributes with accessor UDFs
- [Rank cascade](patterns/systems/sys-rank-cascade-001.md) — auto-raise dependent stats to minimum values when a rank/tier stat is set
- [Help system](patterns/systems/help-system-001.md) — server-agnostic help text storage and display pattern
- [Test hooks](patterns/systems/test-hooks.md) — attach @rhost/testkit hooks to system objects for CI testing

## installers

- [Tag-based object registry](patterns/installers/inst-tag-object-registry-001.md) — use `@tag/add` + `lastcreate()` to register system objects for stable cross-object references

## server-help

- [RhostMUSH reference](patterns/server-help/rhost.md) — annotated RhostMUSH-specific functions, flags, and config quirks
