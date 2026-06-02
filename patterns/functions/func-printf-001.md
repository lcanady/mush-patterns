---
id: func-printf-001
domain: functions
server: RhostMUSH
source: rhost-help.txt printf() entries
complexity: medium
tags: [printf, display, format, alignment, ansi, center, ljust, rjust, wrap, columns]
date_added: "2026-06-02"
tested: false
see_also: [func-ansi-colors-001, sys-visual-frame-001, cmd-printf-columns-001]
---

# Pattern: printf() -- ANSI-aware formatting function

`printf()` is RhostMUSH's canonical display function. It is fully ANSI-aware -- it measures display width after stripping color codes, so column alignment stays correct even when strings contain `ansi()` calls. Use it instead of `center()`/`ljust()`/`rjust()` whenever output may contain color.

## Signal

USE:  ANSI-aware center/ljust/rjust/wrap/columns in one call | replaces raw string-pad functions for colored output
ALT:  center()/ljust()/rjust() are fine for guaranteed plain-text-only output
WARN: center()/ljust()/rjust() measure raw byte length including ANSI escape sequences -- use printf() for colored output
COMPAT: RhostMUSH only -- use align() on PennMUSH
TEST: ✗

## Code

### Syntax

```
printf(<format string>, <arg1> [, <arg2>, ..., <argN>])
```

Format fields have the shape: `$[codes][width][filler][more-codes]s`

The `$` starts a field, `s` ends it (marks where the string argument is inserted).

---

### Equivalents to center / ljust / rjust

```mushcode
; center -- plain space fill
think center(- test -,70)
think printf($^70s,- test -)

; center -- custom fill char
think center(- test -,70,-)
think printf($^70:-:s,- test -)

; ljust -- plain space fill
think ljust(- test -,70)
think printf($-70s,- test -)

; ljust -- custom fill char
think ljust(- test -,70,-)
think printf($-70:-:s,- test -)

; rjust -- plain space fill
think rjust(- test -,70)
think printf($70s,- test -)

; rjust -- custom fill char
think rjust(- test -,70,-)
think printf($70:-:s,- test -)
```

---

### No-cut variant with +

By default printf() truncates a value that exceeds the field width. The `+` code disables cutting:

```mushcode
; center -- do NOT cut if string exceeds width
think printf($^4+:-:s,- test -)

; ljust -- do NOT cut
think printf($-4+:-:s,- test -)

; rjust -- do NOT cut
think printf($4+:-:s,- test -)
```

---

### ANSI-safe 78-char header and footer

These are the standard patterns for display borders. The `=` fill character is specified between the two colons.

```mushcode
; header with centered title (ANSI-safe -- color in Title is fine)
think printf($^78:=:s, Title )

; footer / separator (empty arg produces a solid rule)
think printf($78:=:s,)
```

Equivalent to -- but ANSI-safe unlike:

```mushcode
; NOT ANSI-safe (measures raw bytes including escape sequences):
think center( Title ,78,=)
```

---

### Two-column row

```mushcode
; Two columns: 20-char left-justified label, 56-char left-justified value
think printf($-20s $-56s, Label:, Value goes here)

; With fill chars and a pipe border:
think printf($-20:-:s|$-56s, [ansi(hg,Label)]:, Some value)
```

---

### & code -- repeat on carriage return (multi-line columns)

The `&` code tells printf() to process `%r` in an argument and keep repeating the column format for each resulting line. Combine it with `.` to suppress a trailing blank line.

```mushcode
; Border column using & so it repeats for every wrapped line of the center col
think printf($.1:|:&s $-10|"s $1.:|:&s, %r, test1 test2 test3, %r)
```

Output:
```
| test1      |
| test2      |
| test3      |
```

The `%r` arguments are placeholders that tell the border column to keep printing for as long as the center column has lines.

---

### | code -- word-wrap (auto-insert carriage returns)

The `|` code automatically wraps the argument at the field width, inserting line breaks without requiring explicit `%r` in the data. Combine with `"` to wrap on whitespace instead of hard-cutting at width.

```mushcode
; Hard wrap at 40 chars
think printf($-40|s, This is a long string that will be wrapped)

; Soft wrap on word boundary
think printf($-40|"s, This is a long string that will be wrapped)

; Word wrap with 4-space hanging indent after line 1
think printf($-40|";4.2;s, First line no indent subsequent lines indented)
```

---

### Multi-char filler and ANSI filler

```mushcode
; Multi-char filler (cycles through the string)
think printf($^78:|+=:s, Title )

; ANSI-colored filler
think printf($^78:[ansi(hg,.,hb,.)]:s, Title )
```

---

### Full borders example

```mushcode
think [repeat(-,26)]%r[printf($.7:|+=:&s $-10|"s $7.:|+=:&s, %r, test1 test2 test3, %r)]%r[repeat(-,26)]
```

Output:
```
--------------------------
|+=|+=| test1      |+=|+=|
|+=|+=| test2      |+=|+=|
|+=|+=| test3      |+=|+=|
--------------------------
```

---

### Complete format code reference

| Code | Meaning |
|------|---------|
| `$` | Start of a printf format field |
| `s` | End of field / string substitution point |
| `-` | Left justify (right is default) |
| `^` | Center justify |
| `_` | Stretch justify |
| `+` | Do not cut value if it exceeds field width |
| `*` | Cut from the right instead of the left |
| `&` | Process `%r` in value; repeat column on each carriage return |
| `\|` | Auto-wrap value at field width (inserts carriage returns) |
| `"` | With `\|`: wrap on whitespace instead of hard-cutting |
| `.` | On every field: suppress last line if all fields are empty |
| `!` | Omit column output entirely if value is null |
| `@` | Omit if this column or the previous column is null |
| `<` | Blank this column if the previous column was null |
| `>` | Blank this column if the next column is null |
| `'` | If this field is empty, shift RIGHT column to the LEFT |
| `` ` `` | If this field is empty, shift LEFT column to the RIGHT |
| `:filler:` | Use filler string between the two colons (cycles for multi-char) |
| `:!filler:` | Same but blank lines get a space filler instead |
| `/N/` | With `\|`: stop wrapping after N characters of input |
| `/wN/` | With `\|"`: stop wrapping after N lines |
| `#` | Convert tabs to spaces (default 4); `#N#` for N spaces |
| `;` | Hanging indent on wrapped lines (used with `\|`); `;N;` = N spaces; `;N.L;` = after line L; `;N.L+P;` = after line L, pad P |
| `0` (prefix) | Pad with zeros instead of spaces |

## How it works

### Why center()/ljust()/rjust() mis-measure ANSI strings

ANSI escape sequences are 4-7 raw bytes each but contribute **zero** visible characters. For example `\e[1;32m` (bold green) is 7 bytes. When `center()`, `ljust()`, or `rjust()` measure string length they count raw bytes, so a string containing even one `ansi()` call appears longer than it actually is. The padding calculation comes out short and the column no longer fills to the requested width.

Example of the problem:

```mushcode
; This string is visually 6 chars but raw-measures as ~18 bytes:
think ljust(ansi(hg,hello),20)
; Result: "hello" followed by only ~8 spaces instead of 14
```

### How printf() fixes it

`printf()` strips all ANSI escape sequences before measuring field width. It calculates how many padding characters are needed based on the visible display width, then re-inserts the original (colored) string into the padded field. The padding characters themselves are never colored unless you supply an `ansi()` call as the `:filler:` value.

This means:

```mushcode
; printf() correctly pads to 20 visible chars regardless of ANSI content:
think printf($-20s, ansi(hg,hello))
; Result: "hello" (green) followed by 15 spaces -- correct alignment
```

### Practical rule

- **Output may contain color** → use `printf()`
- **Guaranteed plain text only** → `center()`/`ljust()`/`rjust()` are acceptable
- **PennMUSH** → use `align()` instead; printf() is RhostMUSH-specific
