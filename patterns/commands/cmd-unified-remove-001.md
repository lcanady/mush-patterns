---
id: cmd-unified-remove-001
domain: commands
server: RhostMUSH
source: city-of-roses, session 2026-03-29
complexity: low
tags: [command, remove, dispatch, case, udf, unified, wildcard]
date_added: "2026-03-29"
tested: true
---

# Pattern: Unified remove dispatcher via wildcard command

A single `$+cmd/*/remove *` command matches any category-qualified remove (e.g. `+stat/gift/remove`, `+stat/merit/remove`) and dispatches to the appropriate category-specific UDF via `case()`. One command attribute replaces N separate remove command patterns.

## Signal
USE:  N category removes → 1 $+cmd/*/remove * | dispatch via case(1,...) on lcstr(%0)
ALT:  dynamic dispatch: ulocal(%!/F.CMD.REMOVE.[ucstr(%qc)]) for open-ended categories
WARN: different arg signatures→don't unify | validate category with member() guard first
TEST: ✓

## Code

```mushcode
@@ One $-command handles all remove subcommands:
&CMD_EXAMPLE_REMOVE #example=$+example/*/remove *:
  @pemit %#=[ulocal(%!/F.CMD.REMOVE,%#,%0,%1)]

@@ Dispatcher UDF:
&F.CMD.REMOVE #example=
  [setq(c,lcstr(%1))]
  [case(1,
    eq(%qc,gift),   ulocal(%!/F.CMD.REMOVEGIFT,%0,%2),
    eq(%qc,rite),   ulocal(%!/F.CMD.REMOVERITE,%0,%2),
    eq(%qc,merit),  ulocal(%!/F.CMD.REMOVEMERIT,%0,%2),
    eq(%qc,flaw),   ulocal(%!/F.CMD.REMOVEFLAW,%0,%2),
    eq(%qc,specialty), ulocal(%!/F.CMD.REMOVESPEC,%0,%2),
    Invalid category '[secure(%1)]'. Valid: gift%, rite%, merit%, flaw%, specialty.
  )]

@@ Pattern matching:
@@ +example/gift/remove Mother's-Touch   -> %0=gift  %1=Mother's-Touch
@@ +example/merit/remove Acute-Senses    -> %0=merit %1=Acute-Senses
@@ +example/unknown/remove foo           -> error message
```

## How it works

- The `$+example/*/remove *` pattern captures two wildcards: `%0` = the category word, `%1` = the item name.
- `case(1,eq(%qc,gift),...,eq(%qc,rite),...)` is the standard MUSHcode `case(1,...)` dispatch: each pair is a boolean condition + value.
- `lcstr(%1)` normalises category input so `+example/Gift/remove` works identically to `+example/gift/remove`.
- The final unmatched arm of `case()` is the error message — no `default` keyword needed in the `case(1,...)` idiom.

## Variants

- **With permission check**: add `ulocal(%!/F.CANWRITE,%0)` before the `case()` dispatch and return an error early if the player can't edit.
- **Dynamic dispatch**: replace `case()` with `ulocal(%!/F.CMD.REMOVE.[ucstr(%qc)],%0,%2)` if you want to add new categories without editing the dispatcher — but only if all category names map cleanly to attribute-safe strings.

## When NOT to use

- When the categories have significantly different argument signatures — the unified pattern forces all remove UDFs to share the same `(actor, name)` signature.
- When you need the category word itself to be validated against a fixed list before dispatch — add an explicit `member(gift rite merit flaw,lcstr(%1))` guard before the `case()`.

## Source

Extracted from: city-of-roses, session 2026-03-29
