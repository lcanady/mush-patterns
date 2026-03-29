---
id: sys-gameline-dispatcher-001
domain: systems
server: RhostMUSH
source: city-of-roses, session 2026-03-29
complexity: medium
tags: [dispatch, game-line, template, multi-game, handler, ulocal, dynamic-dispatch]
date_added: "2026-03-29"
tested: true
---

# Pattern: Game-line dispatcher — dynamic UDF routing by stored template prefix

Read a game-line key from a player's stored template attribute and dynamically dispatch to a game-line-specific UDF by constructing its name at runtime (`F.HANDLER.<LINE>`). This lets a single codebase support multiple game lines (WtA, VtM, MtA, etc.) with zero branching in shared code.

## Code

```mushcode
@@ Template attribute format stored on the player:
@@   _EXAMPLE_TEMPLATE = <line>/<part1>/<part2>/<part3>
@@   e.g. wta/homid/ahroun/silver-fangs

@@ Generic dispatcher — reads line prefix and routes to line-specific handler:
&F.SHEET.TEMPLATE #example=
  [setq(0,extract(get(%0/_EXAMPLE_TEMPLATE),1,1,/))]
  [if(t(%q0),
    ulocal(%!/F.SHEET.TEMPLATE.[ucstr(%q0)],%0),
  )]

@@ WtA-specific handler:
&F.SHEET.TEMPLATE.WTA #example=
  [ulocal(%!/F.SHEET.GIFTS,%0)]%r
  [ulocal(%!/F.SHEET.RENOWN,%0)]

@@ VtM-specific handler (different sections):
&F.SHEET.TEMPLATE.VTM #example=
  [ulocal(%!/F.SHEET.DISCIPLINES,%0)]%r
  [ulocal(%!/F.SHEET.BLOOD,%0)]

@@ DD-level dispatcher for template defaults (same pattern, different object):
&F.TMPL.DEFAULTS #example_dd=
  [if(not(t(%0)),#-3 WRONG NUMBER OF ARGUMENTS,
    [setq(0,ulocal(%!/F.TMPL.DEFAULTS.[ucstr(%0)],%1,%2,%3))]
    [if(strmatch(%q0,#-*),%q0,%q0)]
  )]

@@ WtA-specific defaults handler — validates breed/auspice/tribe and returns defaults:
&F.TMPL.DEFAULTS.WTA #example_dd=
  [if(not(and(t(%0),t(%1),t(%2))),#-3 WRONG NUMBER OF ARGUMENTS,
    @@ validate all three parts exist in DD, return pipe-delimited defaults string
    ...
  )]
```

## How it works

- The template string stored on the player always begins with the game-line key as its first `/`-delimited field.
- `extract(get(%0/_EXAMPLE_TEMPLATE),1,1,/)` reliably peels off just the line key regardless of how many template parts follow.
- `ulocal(%!/F.HANDLER.[ucstr(%q0)],...)` dynamically constructs the attribute name from the line key — no `if/case` dispatch tree needed.
- Returning empty string (not an error) when no template is set lets callers suppress template-specific sections cleanly with `[if(t(%qtm),%r%qtm,)]`.
- The same pattern applies at the DD level for defaults, at the sheet level for display, and at the chargen level for validation — one architecture, many contexts.

## Variants

- **Safe fallback**: add `if(hasattr(%!/F.HANDLER.[ucstr(%q0)]),ulocal(...),#-1 UNKNOWN GAME LINE)` to return an error rather than empty string when no handler exists.
- **Centrally registered lines**: maintain a `GAMELINES` attribute (e.g. `wta vtm mta`) on the sys object and validate the line key against it before dispatching.

## When NOT to use

- When you only ever support one game line — the indirection adds complexity with no benefit.
- When the line-specific handlers share so much code that the dispatcher approach duplicates more than it separates — prefer a single UDF with a `case(1,...)` on the line key.

## Source

Extracted from: city-of-roses, session 2026-03-29
