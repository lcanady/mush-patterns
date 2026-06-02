---
id: roster-object-001
domain: systems
server: RhostMUSH
source: RhostMUSH/trunk Mushcode/Roster
complexity: medium
tags: [roster, info, finger, printf, list, lfunction, startup, configurable]
date_added: "2026-03-27"
tested: true
---

# Pattern: Roster / +Info Object

A configurable player info display system. Admins define which attributes to show and how to format them via a `LIST_ORDER` attribute. Players use `+info <name>` and `+roster`.

## Object setup

```mushcode
@create Roster Object <RO>=10
@set Roster Object <RO>=INDESTRUCTABLE SAFE INHERIT

@@ Register local functions on startup
@startup Roster Object <RO>=
  @lfunction header=me/fn_header;
  @lfunction footer=me/fn_footer;
  @lfunction/priv title=me/fn_title
```

After startup, `header()`, `footer()`, and `title()` are callable from any softcode as soft functions.

## Configuration

```mushcode
@@ Color for borders/labels
&COLOR Roster Object <RO>=r

@@ LIST_ORDER format: ATTR|ROW|COL_PRIORITY|PADDING|LABEL|JUSTIFY|
@@ Use @ prefix to call a function instead of reading an attribute
&LIST_ORDER Roster Object <RO>=
  FULLNAME|2|1|40||-|
  AGE|2|2|10||-|
  POSITION|4|2|32||-|
  INFO|3|1|78||-|
  SEX|2|3|10|Moany|-|
  @GUILD|1|1|40||-|
  @NAME|1|2|30||-|

@@ Players listed in the roster (space-sep dbrefs)
&LIST_ROSTER Roster Object <RO>=#123 #456 #789
```

### LIST_ORDER field format

```
<ATTR_OR_FUNC>|<ROW>|<COL_PRIORITY>|<PADDING>|<OPTIONAL_LABEL>|<JUSTIFY>|
```

| Field | Meaning |
|-------|---------|
| `ATTR` | Read this attribute from the target player |
| `@FUNC` | Call softcode function `func(target_dbref)` |
| `@FUNC:arg1:arg2` | Call `func(target, arg1, arg2)` |
| ROW | Display row number |
| COL_PRIORITY | Column order within the row |
| PADDING | Width for this field |
| OPTIONAL_LABEL | Override display label (use `NH` to suppress label entirely) |
| JUSTIFY | `-` = left, `^` = center, `_` = right |

## Commands

```mushcode
+info <player>           @@ show player info sheet
+roster                  @@ show roster list
+roster/info <num|name>  @@ show info for roster entry by number or name
+roster/set <attr>=<val> @@ set your own roster attribute (or wizard sets others')
+set <attr>=<val>        @@ alias for +roster/set
```

## Header/footer functions

```mushcode
&FN_HEADER Roster Object <RO>=
  [setq(z,v(color))]
  [printf($68:[ansi(h%qz,-)]:s[ansi(h%qz,----------)], %b %0 %b)]

&FN_FOOTER Roster Object <RO>=
  [setq(z,v(color))]
  [ansi(h%qz,repeat(-,78))]
```

After `@lfunction header=me/fn_header`, any softcode can call `header(Title Text)` directly.

## @lfunction — registering local softfunctions

```mushcode
@startup Obj=@lfunction funcname=me/attr_name
@startup Obj=@lfunction/priv funcname=me/attr_name    @@ privileged variant
```

Unlike global `@function`, `@lfunction` is game-local and doesn't persist across restarts without being re-registered in `@startup`.

## Roster format output

```mushcode
&F_FORMAT_ROSTER Roster Object <RO>=
  [printf(%($-4s%) $-40s $-30s, %1, trim([title(%0)] [cname(%0)]), get(%0/faction))]
```

- `cname(%0)` — player's name with personal color applied (confirmed RhostMUSH)
- `title(%0)` — player's `@title`
- `printf()` — ANSI-aware column formatting

## Dynamic attribute dispatch in F_FORMAT

The object reads `LIST_ORDER` and dispatches to either an attribute read or a function call:

```mushcode
@@ Attribute starting with @ → call as function
@@ Example: @NAME → call name(target_dbref)
@@ Example: @ADD:1:2:3 → call add(target_dbref, 1, 2, 3)

&F_FORMAT_SUB Roster Object <RO>=
  [default(%0/[setr(9,extract(%q5,%1,1))],
    [ifelse(pos(@,%q9),
      [setq(8,ifelse(!!$after(%q9,:),
        pedit(after(%q9,:), %%#,%0, %%l,[loc(%0)], %%L,[loc(%0)]),
        %0))]
      [setq(9,before(%q9,:))]
      [strfunc(lcstr(after(%q9,@)), %q8, :)],
      %ch%c%qyN/A%cn
    )]
  )]
```

## Wizard +roster/set (set attributes on others)

```mushcode
&CMD_ROSTER_SET Roster Object <RO>=$+roster/set *=*:
  @break [and(lte(bittype(%#),1), pos(/,%0))]=@pemit %#=Sorry, you're not a wizard.;
  @eval [setq(0,ifelse(pos(/,%0), pmatch(before(%0,/)), %#))]
        [setq(2,trim(ifelse(pos(/,%0), after(%0,/), %0)))];
  @break [!match(%q1,%q2)]=@pemit %#=Attribute '%q2' is not settable here.;
  &%q2 %q0=%1;
  @pemit %#=+roster/set: '%q2' set on [ifelse(match(%q0,%#),yourself,name(%q0))].
```

Pattern: `+roster/set <attr>=<val>` for self; `+roster/set <player>/<attr>=<val>` for wizard setting on another.
