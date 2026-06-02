---
id: func-ansi-colors-001
domain: functions
server: RhostMUSH
source: rhost-help.txt, community conventions
complexity: low
tags: [ansi, color, display, convention, config, theme, format]
date_added: "2026-06-02"
tested: false
see_also: [func-printf-001, sys-visual-frame-001]
---

# Pattern: ANSI color conventions and re-themeable _COLOR.* config attributes

Store color codes in underscore-prefixed `_COLOR.*` attributes on the system object rather than hardcoding them in display UDFs. This lets the game admin retheme a system without touching code.

## Signal
USE:  store colors as _COLOR.* config attrs on sys object | use ansi(get(%!/_COLOR.HEADER),...) not ansi(hw,...)
WARN: hardcoded color literals make every cosmetic change a code edit | _ prefix keeps them wiz-only/hidden
TEST: ✗

## Code

```mushcode
@@ ---------------------------------------------------------------
@@ Step 1: Set color config attributes on your system object.
@@ _ prefix keeps them hidden from players (wiz-only in RhostMUSH).
@@ ---------------------------------------------------------------
&_COLOR.HEADER #sys=hw
&_COLOR.ACCENT  #sys=hc
&_COLOR.WARN    #sys=hy
&_COLOR.RESET   #sys=n

@@ ---------------------------------------------------------------
@@ Step 2: Display UDF references config attrs via get(%!/_COLOR.*)
@@ ---------------------------------------------------------------
&FUN_HEADER #sys=
  [ansi(get(%!/_COLOR.RESET),+)]
  [ansi(get(%!/_COLOR.HEADER), %0 )]
  [ansi(get(%!/_COLOR.RESET),+)]

@@ ---------------------------------------------------------------
@@ Step 3: Direct ansi() call examples (hardcoded — for quick use)
@@ ---------------------------------------------------------------
@@ ansi(hw, text)     -- bright white (hilite white)
@@ ansi(hc, text)     -- bright cyan  (hilite cyan)
@@ ansi(hr, text)     -- bright red
@@ ansi(hy, text)     -- bright yellow
@@ ansi(hg, text)     -- bright green
@@ ansi(n,  text)     -- reset / normal (end color)
@@ ansi(u,  text)     -- underline
@@ ansi(i,  text)     -- inverse (reverse video)
@@ ansi(f,  text)     -- flash/blink (requires NO_FLASH not set)

@@ ---------------------------------------------------------------
@@ Color letter code reference (for use as first arg to ansi())
@@ ---------------------------------------------------------------
@@ Foreground:
@@   r=red  g=green  b=blue  c=cyan  y=yellow  m=magenta
@@   w=white  x=black  n=normal/reset
@@ Attributes:
@@   h=hilite/bold  u=underline  i=inverse  f=flash
@@ Bright foreground (h + color letter):
@@   hr=bright red  hg=bright green  hb=bright blue
@@   hc=bright cyan  hy=bright yellow  hm=bright magenta
@@   hw=bright white  hx=dark grey
@@ Background (uppercase letter):
@@   R=bg-red  G=bg-green  B=bg-blue  C=bg-cyan
@@   Y=bg-yellow  M=bg-magenta  W=bg-white  X=bg-black

@@ ---------------------------------------------------------------
@@ Step 4: Always reset after color output to prevent bleed
@@ ---------------------------------------------------------------
@@ Pattern: ansi(n, text)  or  %cntext%cn
@@ Every emit that uses color should end with ansi(n,) or %cn.
@@
@@ Example header emit using reset pattern:
&CMD_SHOWHEADER #sys=$+header *:
  @pemit %#=
    [ansi(get(%!/_COLOR.RESET),-)]
    [ansi(get(%!/_COLOR.HEADER), %0 )]
    [ansi(get(%!/_COLOR.RESET),-)]
    [ansi(n,)]
```

## Notes

- The `_` prefix on attributes is a RhostMUSH convention that makes attributes wiz-only and hidden from `examine` output visible to non-wizards. This prevents players from seeing raw escape codes when they look at the system object.
- `colors()` — the built-in RhostMUSH function — lists available named colors on the server or returns the value for a specific color. Use `think colors()` to see what is available. Use `think colors(+pink,h)` to look up the hex code for a named 256-color entry. This is useful when building advanced XTERM themes.
- **Advanced — 256-color FANSI:** RhostMUSH supports 256-color (XTERM) mode when players have the `ANSI`, `ANSICOLOR`, and `XTERMCOLOR` flags set. Use numeric codes via `ansi(0xNN, text)` for foreground or `ansi(0XNN, text)` for background, where `NN` is the two-digit hex color index from the XTERM 256-color table. Example: `ansi(0xda, this is pink)`. 24-bit color is also supported with `%c<#rrggbb>` substitutions. Stick to the base 16-color set (`ansi(hw,...)` style) for maximum client compatibility.
- Players must have both `ANSI` and `ANSICOLOR` flags set to see color. Code that relies on color for readability should always render acceptably in plain text as well.
