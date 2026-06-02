---
id: sys-sheet-column-layout-001
domain: systems
server: RhostMUSH
source: city-of-roses, session 2026-03-29
complexity: medium
tags: [sheet, display, column, ljust, dot-fill, format, charsheet, width]
date_added: "2026-03-29"
tested: true
see_also: [cmd-printf-columns-001, func-printf-001]
---

# Pattern: Fixed-width column slot with dot-fill for character sheet display

Render one stat on a character sheet as a fixed-width slot: `StatName......5`. The label and value are padded apart with dots to fill the slot width, and the whole slot is `ljust()`-padded for clean column alignment. Composing multiple slots produces a multi-column sheet row with no explicit separator characters.

## Signal
USE:  stat column "StatName......5" | slot_width=26(3-col) or 39(2-col) for 78-char lines
CALC: dots=slot_width-strlen(label)-strlen(val)-2 | max(1,...) ensures ≥1 dot | ljust pads to exact width
WARN: ANSI codes bloat strlen→strip before measuring | line>output-width→wraps
TEST: ✓

## Code

```mushcode
@@ F.SHEET.COL(player, category, statname, slot_width)
@@ Renders one stat column. Two trailing spaces create column separation.
@@ 3-col sections: slot_width=26 (3*26=78)
@@ 2-col sections: slot_width=39 (2*39=78)

&F.EXAMPLE.COL #example=
  [setq(p,ulocal(#example_stat/F.GETSTAT,%0,%1,%2))]
  [setq(t,ulocal(#example_stat/F.GETTEMP,%0,%1,%2))]
  [setq(v,ulocal(%!/F.EXAMPLE.VAL,%qp,%qt))]
  [setq(n,ulocal(%!/F.EXAMPLE.TITLE,%2))]
  [setq(d,max(1,sub(%3,add(2,add(strlen(%qn),strlen(%qv))))))]
  [ljust(%qn[repeat(.,%qd)]%qv,%3)]

@@ F.SHEET.VAL(perm, temp) — show perm when at max, else perm(temp)
&F.EXAMPLE.VAL #example=
  [if(not(t(%0)),#-1 MISSING ARG,[if(eq(%0,%1),%0,%0(%1))])]

@@ Usage — build a 3-column row:
[ulocal(%!/F.EXAMPLE.COL,%0,attr,strength,26)]
[ulocal(%!/F.EXAMPLE.COL,%0,attr,dexterity,26)]
[ulocal(%!/F.EXAMPLE.COL,%0,attr,stamina,26)]
@@ => "Strength..........3  Dexterity.........4  Stamina...........3  "
```

## How it works

- `strlen(%qn)` + `strlen(%qv)` + 2 (for trailing spaces) subtracted from `slot_width` gives the dot count.
- `max(1,...)` ensures at least one dot separates label from value even if they nearly fill the slot.
- `ljust(...,%3)` pads the entire content to exactly `slot_width` characters — columns then abut cleanly.
- `F.SHEET.VAL` shows `perm(temp)` only when they differ; at full pool only the number is shown.

## Variants

- **Specialty indicator**: append `*` to the value string when a specialty is set on the stat — works naturally because `strlen(%qv)` accounts for the extra character.
- **Two-column layout**: use `slot_width=39` so two columns fill a 78-char line: `2*39=78`.
- **No temp track**: for stats with no temp value (e.g. rank, backgrounds), pass the same value for both perm and temp — `F.SHEET.VAL` will display a plain number.

## Alternatives

**cmd-printf-columns-001** is the ANSI-safe version of this pattern. Use it when any cell may contain ansi() color codes.

The core difference: ljust() and repeat() measure raw byte length -- ANSI escape sequences inflate the count, causing columns to mis-align when text contains color codes. printf() measures display width after stripping ANSI, so column alignment is always correct.

Use this pattern (ljust + repeat) when your stat sheet is guaranteed plain text with no ansi() calls. Switch to cmd-printf-columns-001 as soon as any cell is colored.

## When NOT to use

- When the MUSH client truncates ANSI colour codes before `strlen()` — colour tags will bloat `strlen()` and shrink the dot fill. Strip colour codes before measuring, or use ANSI-aware padding if available.
- Lines wider than your server's output width setting — output will wrap unpredictably.

## Source

Extracted from: city-of-roses, session 2026-03-29
