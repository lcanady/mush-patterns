---
id: sys-visual-frame-001
domain: systems
server: RhostMUSH
source: community conventions, mush-architect corpus upgrade 2026-06-02
complexity: medium
tags: [display, header, footer, frame, output, format, visual, printf, standard, 78-char]
date_added: "2026-06-02"
tested: false
see_also: [func-printf-001, func-ansi-colors-001, cmd-printf-columns-001, sys-sheet-column-layout-001]
---

# Pattern: Standard command output frame -- shared display object with header/body/footer

Every +cmd with multi-line output should use a dedicated display object exposing `F.DISPLAY.HEADER`, `F.DISPLAY.ROW`, `F.DISPLAY.DIV`, `F.DISPLAY.FOOTER`, and `F.DISPLAY.PARA` UDFs. This centralises all visual decisions, enables re-theming via `_COLOR.*` config attrs, and enforces the 78-char width standard across the entire game.

## Signal

```
USE:  any +cmd with multi-line output | one display object per system shared across all CMD_ attrs
ARCH: _COLOR.* config attrs drive all display UDFs | CMD_ attrs call ulocal(disp/F.DISPLAY.*)
WARN: never inline printf() directly in CMD_ attrs -- all display through F.DISPLAY.* UDFs for consistency
TEST: ✗
```

## Key design decisions

- **One display object per system**: all `CMD_*` attrs on a system object call `ulocal(%q<disp>/F.DISPLAY.*)` rather than inlining `printf()`. Visual changes require editing only the display object.
- **`printf()` not `center()`/`repeat()`**: `printf()` is ANSI-aware and counts visible character width, not raw bytes. `center()` and `repeat()` count raw bytes, so they over-pad when ANSI escape codes are present. All frame UDFs use `printf()`.
- **`_COLOR.*` config attrs**: ANSI escape sequences live in `_COLOR.HEADER`, `_COLOR.ACCENT`, and `_COLOR.WARN` on the display object. CMD_ attrs never hardcode a color. Re-theming is a single `&_COLOR.* <disp>=` pass.
- **78-char standard**: RhostMUSH default terminal width is 78 columns. All frame UDFs target exactly 78 visible characters. The two-column ROW layout uses 30 + 1 + 46 + 1 (trailing space) = 78.
- **`ulocal()` not `u()`**: keeps `%q` register pollution out of the calling CMD_ attr scope.

## Code

```mushcode
@create Display <disp>
@tag/add Display <disp>=DISPLAY
@set Display <disp>=SAFE INHERIT

# --- Color config attrs (edit to re-theme) ---
# %ch = bold, %cn = normal reset, %ch%cy = bold cyan, %ch%cm = bold magenta, %ch%cr = bold red
&_COLOR.HEADER Display <disp>=%ch%cy
&_COLOR.ACCENT  Display <disp>=%ch%cm
&_COLOR.WARN    Display <disp>=%ch%cr

# Store dbref for self-reference inside UDFs
&d.disp Display <disp>=[num(Display <disp>)]

# --- F.DISPLAY.HEADER ---
# %0 = title string
# Produces a 78-char centered = bar with the title in bold color, e.g.:
#   =====================[ My Command ]=====================
&F.DISPLAY.HEADER Display <disp>=%
  [u(v(d.disp)/_COLOR.HEADER)]%
  [printf($^78:=:s,%b%0%b)]%
  %cn

# --- F.DISPLAY.DIV ---
# %0 = optional section label (may be empty for a plain rule)
# Produces a 78-char centered - divider in accent color, e.g.:
#   -----------------------[ Section ]----------------------
&F.DISPLAY.DIV Display <disp>=%
  [u(v(d.disp)/_COLOR.ACCENT)]%
  [if(%0,printf($^78:-:s,%b%0%b),printf($78:-:s,))]%
  %cn

# --- F.DISPLAY.ROW ---
# %0 = label (left column, 30 chars)  %1 = value (right column, 46 chars)
# Produces a two-column line -- 30 + 1 space + 46 + 1 implicit trailing = 78 visible chars
# The label is printed in accent color; the value is normal.
&F.DISPLAY.ROW Display <disp>=%
  [u(v(d.disp)/_COLOR.ACCENT)][printf($-30s,%0)]%cn %
  [printf($-46s,%1)]

# --- F.DISPLAY.FOOTER ---
# %0 = optional hint line printed below the rule (plain text, no extra formatting)
# Produces a 78-char = rule in header color (matches header), then optional hint below.
&F.DISPLAY.FOOTER Display <disp>=%
  [u(v(d.disp)/_COLOR.HEADER)]%
  [printf($78:=:s,)]%
  %cn%
  [if(%0,%r%0,)]

# --- F.DISPLAY.PARA ---
# %0 = paragraph text (may be long -- printf word-wraps at 78 chars)
# Uses the | fill modifier: $-78|"s fills to 78 chars with word-wrap.
# Output is left-justified plain text -- no color applied at this level.
&F.DISPLAY.PARA Display <disp>=[printf($-78|"s,%0)]
```

### Usage example inside a CMD_ attr

```mushcode
# Assumes: &d.disp <system obj>=[num(Display <disp>)]
#
# CMD_INFO fires on "+info"
&CMD_INFO MySystem <sys>=$+info:
  @pemit %#=%
    [setq(D,v(d.disp))]%
    [ulocal(%qD/F.DISPLAY.HEADER,System Information)]%r%
    [ulocal(%qD/F.DISPLAY.ROW,Server,RhostMUSH 4.x)]%r%
    [ulocal(%qD/F.DISPLAY.ROW,Status,Online)]%r%
    [ulocal(%qD/F.DISPLAY.DIV,Notes)]%r%
    [ulocal(%qD/F.DISPLAY.PARA,This server uses the standard display frame. Edit _COLOR.* on the Display object to re-theme all output at once.)]%r%
    [ulocal(%qD/F.DISPLAY.FOOTER)]
```

Output (schematic, ANSI stripped):

```
=========================[ System Information ]=========================
Server                         RhostMUSH 4.x
Status                         Online
--------------------------[ Notes ]-----------------------------
This server uses the standard display frame. Edit _COLOR.* on
the Display object to re-theme all output at once.
========================================================================
```

## How it works

**Why isolate display from logic?**
A CMD_ attr that mixes business logic with `printf()` calls becomes hard to maintain: changing the visual theme requires auditing every command. The display object is a single seam -- change one UDF, every command picks it up automatically.

**Why `printf()` for colored output?**
RhostMUSH `printf()` counts *visible* characters (it ignores ANSI escape sequences when measuring width). `center()`, `ljust()`, `rjust()`, and `repeat()` count raw bytes, so they over-pad or under-pad when the string contains color codes. Any frame UDF that inlines color into the formatted string must use `printf()`.

**Why `_COLOR.*` attrs?**
Hardcoding `%ch%cy` inside a UDF ties the whole codebase to one color scheme. Storing ANSI sequences in config attrs means a wizard can re-theme the game by running `&_COLOR.HEADER <disp>=%ch%cg` without touching any command logic.

**printf() format reference (key specifiers used here)**

| Format string | Meaning |
|---|---|
| `$^78:=:s` | Center string in a 78-char field, padded with `=` |
| `$78:=:s`  | Left-fill 78-char field with `=` (empty arg = solid rule) |
| `$^78:-:s` | Center string in a 78-char field, padded with `-` |
| `$78:-:s`  | Left-fill 78-char field with `-` (solid rule) |
| `$-30s`    | Left-justify in 30-char field, space-padded |
| `$-46s`    | Left-justify in 46-char field, space-padded |
| `$-78\|"s`  | Left-justify 78-char field, word-wrap on spaces (`\|"`) |

## When NOT to use

- Single-line output commands (e.g. `+finger Name` returning one line): use inline `pemit` directly.
- Commands that output plain prose with no tabular structure and where the output width does not matter (e.g. raw narrative text piped through `wrap()`).
- System internals that emit to log files rather than to a player terminal.

## Notes

- Add a `@rhost/testkit` test snippet here before marking `tested: true`.
- The `F.DISPLAY.PARA` word-wrap modifier `|"` requires RhostMUSH 3.9.5+; verify server version before use.
- For sheet-style columnar layouts (stat blocks, character sheets) see `sys-sheet-column-layout-001` which extends this frame with grid math helpers.
