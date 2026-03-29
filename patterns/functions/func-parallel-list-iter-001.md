---
id: func-parallel-list-iter-001
domain: functions
server: RhostMUSH
source: city-of-roses, session 2026-03-29
complexity: medium
tags: [iter, lnum, extract, parallel, list, columns, multi-list, display]
date_added: "2026-03-29"
tested: true
---

# Pattern: Parallel multi-list iteration with `iter(lnum())`

Walk N space-delimited lists in lock-step using `iter(lnum(1,N),extract(list,##,1))` to produce multi-column output. This avoids `map()`, separate loop objects, or recursion when the lists are equal-length and the column count is fixed.

## Code

```mushcode
@@ Three lists of equal length, displayed as 3 side-by-side columns.
@@ Each column slot is 26 chars; 10 rows = 10 stats per list.

&F.EXAMPLE.ABILITIES #example=
  [setq(a,get(%!/LIST.COL1))]   @@ e.g. alertness athletics brawl ...
  [setq(b,get(%!/LIST.COL2))]   @@ e.g. animal-ken crafts drive ...
  [setq(c,get(%!/LIST.COL3))]   @@ e.g. academics computer enigmas ...
  [iter(
    1 2 3 4 5 6 7 8 9 10,
    [ulocal(%!/F.EXAMPLE.COL,%0,col1,extract(%qa,##,1),26)]
    [ulocal(%!/F.EXAMPLE.COL,%0,col2,extract(%qb,##,1),26)]
    [ulocal(%!/F.EXAMPLE.COL,%0,col3,extract(%qc,##,1),26)],
    %b,
    %r
  )]

@@ Dynamic length — when list length is not known at write time:
  [setq(n,words(%qa))]
  [iter(lnum(1,%qn),
    [ulocal(%!/F.EXAMPLE.COL,%0,col1,extract(%qa,##,1),39)]
    [ulocal(%!/F.EXAMPLE.COL,%0,col2,extract(%qb,##,1),39)],
    %b,
    %r
  )]
```

## How it works

- `iter()` walks a list of integers (1 through N) rather than the data lists directly.
- `##` is the current integer index; `extract(list,##,1)` retrieves the Nth word from each list in parallel.
- Rows are separated by `%r` (newline) as the output separator; columns are separated by the fixed-width padding built into the column UDF.
- The literal integer sequence `1 2 3 ... N` is fine for fixed-length lists; use `lnum(1,words(list))` for dynamic lengths.

## Variants

- **Paired two-column layout**: `lnum(1,max(words(%qa),words(%qb)))` handles lists of unequal length — use `if(lte(##,words(%qa)),...)` to skip empty slots.
- **Stepped index for alternating 2-col**: use `iter(1 3 5 7 ...` and pair `##` with `add(##,1)` to display two entries per row from a single list (compact backgrounds display).

## When NOT to use

- When the lists can contain different numbers of entries and empty slots need special handling — use the stepped variant or a recursive UDF instead.
- Lists longer than ~30 items risk hitting the `iter()` recursion depth on some servers; consider chunking with `extract(list,from,count)`.

## Source

Extracted from: city-of-roses, session 2026-03-29
