---
id: cmd-printf-columns-001
domain: commands
server: RhostMUSH
source: rhost-help.txt printf(), mush-architect corpus upgrade 2026-06-02
complexity: medium
tags: [display, columns, printf, table, charsheet, multi-column, ansi, format, 78-char]
date_added: "2026-06-02"
tested: false
see_also: [func-printf-001, sys-visual-frame-001, sys-sheet-column-layout-001, func-parallel-list-iter-001]
---

# Pattern: Multi-column display via printf() -- ANSI-safe table output

Build multi-column table rows using `printf()` instead of manual `ljust()`/`repeat()`. `printf()` is ANSI-aware so column widths stay correct when cells contain color codes. Use this instead of `sys-sheet-column-layout-001` when any cell may contain `ansi()` output.

## Signal

```
USE:  ANSI-safe column rows when cells may contain color | printf($-Ws $-Xs ...) with N fields
PREFER: this over sys-sheet-column-layout-001 whenever any cell uses ansi()
CALC: total column widths + spaces between = 78 for standard terminal width
WARN: sys-sheet-column-layout-001 uses ljust() which mis-measures ANSI strings
TEST: x
```

## Code

### 1. Three-column stat row (26 + 26 + 24 = 76 visible + 2 inter-column spaces = 78)

```mushcode
@@ F.ROW3(val1, val2, val3)
@@ Three equal-ish columns across a 78-char line.
@@ Column widths: 26, 26, 24. The two spaces between columns are part of the
@@ format string literal, not part of the field widths.
@@ Total: 26 + 1sp + 26 + 1sp + 24 = 78

&F.ROW3 #sheet=
  [printf($-26s $-26s $-24s,%0,%1,%2)]

@@ Example output (color stripped for illustration):
@@ "Strength..........3  Dexterity.........4  Stamina.........3 "
```

### 2. Two-column info row (38 + 38 + 2 inter-column spaces = 78)

```mushcode
@@ F.ROW2(val1, val2)
@@ Two equal columns. Each field is 38 chars; one space separator = 77... 
@@ so use 38 + space + 39 to reach exactly 78, or 38+38 with no separator
@@ if the calling code already supplies trailing space.
@@ Simplest: 38 + " " + 39 = 78

&F.ROW2 #sheet=
  [printf($-38s $-39s,%0,%1)]

@@ Or symmetric with a visible gutter (one space each side):
@@ printf($-38s $-38s, val1, val2)  => 38+1+38 = 77 (add 1 trailing space if needed)
```

### 3. Full-width paragraph with word-wrap (78-char soft-wrap)

```mushcode
@@ F.PARA(text)
@@ Word-wraps a paragraph to 78 chars, splitting on whitespace.
@@ $-78|"s  =>  left-justify | wrap on word boundary at 78 chars

&F.PARA #sheet=
  [printf($-78|"s,%0)]

@@ Example:
@@ think [u(#sheet/F.PARA,This is a long paragraph that will be wrapped at
@@         word boundaries so it fits cleanly inside a standard 78-char terminal.)]
```

### 4. Complete sheet section -- iter() over stat lists using column UDFs

```mushcode
@@ DISPLAY.STATS.SECTION(player, statlist)
@@ statlist is a space-separated list of stat names.
@@ Walks the list three at a time to build 3-column rows.

@@ Helper: one stat cell -- label + dots + value, total width W
@@ F.STATCELL(player, statname, width)
&F.STATCELL #sheet=
  [setq(n,capstr(%1))]
  [setq(v,default(%0/%1,-))]
  [setq(v,ansi(hg,%qv))]
  [setq(d,max(1,sub(%2,add(2,add(strlen(%qn),strlen(strip(%qv)))))))]
  [printf($-%2s,%qn[repeat(.,%qd)]%qv)]

@@ F.STAT.ROW3(player, s1, s2, s3)  -- one three-column stat row
&F.STAT.ROW3 #sheet=
  [setq(a,u(%!/F.STATCELL,%0,%1,26))]
  [setq(b,u(%!/F.STATCELL,%0,%2,26))]
  [setq(c,u(%!/F.STATCELL,%0,%3,24))]
  [printf($-26s $-26s $-24s,%qa,%qb,%qc)]

@@ DISPLAY.STATS.SECTION(player, statlist)
@@ statlist must be a multiple of 3 (pad with null entries if needed)
&DISPLAY.STATS.SECTION #sheet=
  [setq(p,%0)]
  [setq(l,setunion(%1,,|))]
  [iter(%ql,
    if(eq(mod(inum(0),3),0),
      u(%!/F.STAT.ROW3,%qp,
        extract(%ql,add(inum(0),1),1,|),
        extract(%ql,add(inum(0),2),1,|),
        extract(%ql,add(inum(0),3),1,|))%r
    ,),|)]

@@ Usage:
@@ think u(#sheet/DISPLAY.STATS.SECTION,%#,strength|dexterity|stamina|wits|resolve|composure)
```

## How it works

`printf()` in RhostMUSH is fully ANSI/color aware. When it measures a field for padding, it strips escape sequences before calculating how many fill characters are needed. This means a cell containing `ansi(hg,10)` (which renders as a colored "10" but has a raw strlen of many more chars due to escape codes) is still padded as if it were 2 characters wide.

By contrast, `ljust(ansi(hg,10),26)` measures the escape-inflated length and produces far fewer padding spaces than intended -- the column comes out visually narrow.

**Dot-fill caveat**: In `F.STATCELL` above, the dot count is still calculated manually using `strlen(strip(%qv))` (stripping ANSI before measuring) because the dots are part of the argument string passed *into* printf, not handled by printf's fill mechanism. The printf field `$-26s` then ANSI-safely pads the already-dotted string to exactly 26 visible characters.

**Column math**: For a standard 78-character terminal line:
- Three columns: `26 + 1sp + 26 + 1sp + 24 = 78`
- Two columns: `38 + 1sp + 39 = 78` (or `38 + 1sp + 38 = 77` + trailing space)
- One full-width: `78`

Always verify the sum. An off-by-one causes ragged right margins across the sheet.

**Word-wrap**: The `|"` modifier combination tells printf to auto-wrap at field width AND prefer splitting on whitespace. Use this for description or note fields that may contain sentences. Without `"`, wrapping cuts mid-word.

## When NOT to use

- When all cells are guaranteed plain text with no ANSI codes -- `ljust()`/`repeat()` (as in `sys-sheet-column-layout-001`) is simpler and has no external dependencies.
- When column widths need to be dynamic at runtime -- printf format strings are literals; you cannot interpolate the width value without building the format string via substitution, which is messy. For dynamic widths, `ljust()` on pre-stripped strings is cleaner.
- On servers other than RhostMUSH where `printf()` may not exist or may have different ANSI semantics.

## Source

Extracted from: rhost-help.txt printf(), mush-architect corpus upgrade 2026-06-02
