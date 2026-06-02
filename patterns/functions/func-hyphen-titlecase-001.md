---
id: func-hyphen-titlecase-001
domain: functions
server: RhostMUSH
source: city-of-roses, session 2026-03-29
complexity: low
tags: [string, format, titlecase, hyphen, iter, edit, capstr, display]
date_added: "2026-03-29"
tested: true
---

# Pattern: Hyphenated title-case formatter

Convert a hyphen-separated identifier (e.g. `get-of-fenris`, `primal-urge`) to a display-ready title-case string (e.g. `Get-Of-Fenris`, `Primal-Urge`). Standard `capstr()` only capitalises the first word; this pattern capitalises every word across hyphens.

## Signal
USE:  title-case across hyphens | get-of-fenris→Get-Of-Fenris | capstr() only does first word
ALGO: lcstr→edit(-,sp)→iter(capstr(##))→edit(sp,-)
WARN: input with spaces→collapse with hyphens in output | accented chars→may not cap on all servers
TEST: ✓

## Code

```mushcode
@@ F.SHEET.TITLE(name)
@@ Title-case with full hyphen support: get-of-fenris -> Get-Of-Fenris
&F.EXAMPLE.TITLE #example=
  [if(
    not(t(%0)),
    #-1 MISSING ARG,
    [edit(iter(edit(lcstr(%0),-,%b),capstr(##)),%b,-)]
  )]
```

## How it works

1. `lcstr(%0)` — normalise to lower-case so mixed-case input is safe.
2. `edit(...,-,%b)` — replace every hyphen with a space, producing a normal word list.
3. `iter(...,capstr(##))` — capitalise the first letter of each space-delimited word.
4. `edit(...,%b,-)` — restore spaces to hyphens, giving `Get-Of-Fenris`.

The two `edit()` calls use spaces as a pivot: hyphens out, capitalise, hyphens back.

## Variants

- **Space-separated output**: drop the final `edit(...,%b,-)` to get `Get Of Fenris` for use in display contexts that don't need the hyphen.
- **Underscore-separated identifiers**: replace `-` with `_` in both `edit()` calls to handle attribute-name-style keys.

## When NOT to use

- When the input already contains spaces (they will be collapsed with hyphens in the final output). Preprocess input with `squish()` and handle spaces separately.
- When you need locale-aware capitalisation — `capstr()` only capitalises the first character byte; accented letters may not be handled on all servers.

## Source

Extracted from: city-of-roses, session 2026-03-29
