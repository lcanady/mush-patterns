---
id: rhost-utility-functions-001
domain: functions
server: RhostMUSH
source: RhostMUSH/trunk Mushcode/* (scan, softfunctions.minmax, Roster, AccountSubsystem, comsys)
complexity: medium
tags: [functions, utility, iter, lists, search, nsiter, lzone, lattrp, lcmds, ifelse, elist, cname]
date_added: "2026-03-27"
tested: true
---

# RhostMUSH Utility Functions Reference

Functions confirmed present in RhostMUSH, extracted from official Mushcode examples.

## List / iter functions

### nsiter() — non-spaced iter
Like `iter()` but output items are not separated by spaces (no separator injected):

```mushcode
[nsiter(list, expression)]

@@ Example: list all connected players' names
[nsiter(lwho(), %r[name(%i0)])]
```

### itext() and inum()
Inside `iter()` or `list()`, access the current item and index:

```mushcode
[iter(mylist, %r Item [inum(0)]: [itext(0)])]
@@ inum(0) = current iteration number (1-based)
@@ itext(0) = current item value
```

### ibreak()
Break out of an `iter()` early:

```mushcode
[iter(mylist, ifelse(strmatch(%i0,target), found[ibreak(0)], ))]
```

### elist()
Confirmed available in RhostMUSH. Formats a list with Oxford-comma style join:

```mushcode
[elist(mylist)]             @@ "a, b, and c"
[elist(mylist, or)]         @@ "a, b, or c"
[elist(mylist,and,,,,ansi(y,%0))]  @@ with item formatter
```

> **Note:** `elist()` in RhostMUSH is equivalent to `itemize()` in PennMUSH. The `softfunctions.minmax` file implements `itemize()` as `elist(%0,%2,%1,%4,%3)` — confirming both exist.

### graball()
Filter a space-separated list, returning items matching a wildcard:

```mushcode
[graball(mylist, *pattern*)]
```

### lmax() / lmin()
Maximum or minimum value in a list:

```mushcode
[lmax(iter(mylist, somevalue))]
```

## Search functions

### search()
Search the database with various filters:

```mushcode
search(eplayer=[lit([hasflag(##,connect)])])   @@ all connected players
search(eplayer=[lit([hastoggle(##,monitor)])])  @@ players with monitor toggle
search(totem=d)                                  @@ objects with daily totem
search(eval=%[grep%(##,*,%0*)%])                @@ grep across all attrs
```

### lzone() — list zones
Returns space-separated list of zones applied to an object:

```mushcode
[lzone(%#)]           @@ zones on the player
[lzone(loc(%#))]      @@ zones on the player's location
```

### lattrp() — list attributes including parent chain
Unlike `lattr()`, includes attributes inherited from parents:

```mushcode
[lattrp(%0,,%3)]      @@ all attrs on %0 matching pattern %3, including parents
```

### lcmds() — list command attributes
Returns list of `$`-command attributes (pattern attributes):

```mushcode
[lcmds(%0, beep())]   @@ list of command attrs on %0, beep() as separator
```

## Object / player functions

### cname() — colored name
Returns a player's name with their personal name color applied:

```mushcode
[cname(%0)]           @@ colored display name
[cname(%#)]           @@ colored name of the acting player
```

> Confirmed present in RhostMUSH (used in AccountSubsystem, Roster, comsys).

### title()
Returns a player's title attribute:

```mushcode
[title(%0)]           @@ player's @title
```

### lookup_site()
Returns the connecting site (IP/hostname) of a connected player:

```mushcode
[lookup_site(%#)]     @@ "12.34.56.78" or "hostname.example.com"

@@ Used in MedusaObject for site-based banning:
[wildmatch(v(sites), lookup_site(%#))]
```

### objeval()
Evaluate an expression in the security context of a specific object:

```mushcode
[objeval(%#, lcon(here))]    @@ lcon() as seen by %#
[objeval(%0, hastype(*name, player))]
```

### @lfunction — local softcode functions
Register a softcode attribute as a callable function (local to the game):

```mushcode
@startup Obj=@lfunction header=me/fn_header;@lfunction footer=me/fn_footer;@lfunction/priv title=me/fn_title
```

After startup, any softcode can call `header(arg)`, `footer()`, `title(name)` etc.

## String functions

### ifelse()
Ternary — returns %1 if %0 is true, %2 otherwise. Confirmed available:

```mushcode
[ifelse(condition, true-value, false-value)]

@@ Example:
[ifelse(hasflag(%#,connect), Online, Offline)]
```

> In early RhostMUSH versions, `ifelse()` may not exist; `softfunctions.minmax` provides it as a soft fallback via `@function/priv ifelse`.

### pedit()
Multi-pair edit (replace multiple substrings in one call):

```mushcode
[pedit(string, old1, new1, old2, new2, ...)]

@@ Example: remove multiple flag chars
[pedit(%0, =, _, -, ^, <, -)]
```

### regeditall() / regeditalli()
Regex-based global substitution (case-insensitive for `i` variant):

```mushcode
[regeditall(string, pattern, replacement)]
[regeditalli(string, pattern1, repl1, pattern2, repl2)]

@@ Example from RockJobs fn`formathelp:
[regeditalli(%0, (\+(\w)+(/(\w)+)?), [ansi(hg,$1)], (<(.*?)>), [ansi(hr,$1)])]
```

### squish()
Collapse multiple spaces to single space:

```mushcode
[squish(text with   extra   spaces)]
```

### pack() / unpack()
Base-conversion functions:

```mushcode
[pack(unpack(%0,%1,1),%2,1)]    @@ convert from base %1 to base %2
```

## Timing functions

### convtime() / @wait/until
Schedule execution at a specific time of day:

```mushcode
&DO_DAILY Obj=@wait/until [convtime([extract(time(),1,3)] [v(DAILY_TRIGGER)] [extract(time(),5,1)])]={...code...;@wait 300=@tr/quiet me/do_daily}

&DAILY_TRIGGER Obj=23:59:59
```

### timefmt()
Format seconds into human-readable time. Key format codes:

| Code | Meaning |
|------|---------|
| `$02H` | Hours (zero-padded 2 digits) |
| `$02T` | Minutes |
| `$02S` | Seconds |
| `$02M` | Month |
| `$02D` | Day |
| `$y` | 2-digit year |
| `$Y` | 4-digit year |
| `$p` | am/pm |
| `$!Z` | Years (suppress if 0) |
| `$!E` | Months (suppress if 0) |
| `$!C` | Days (suppress if 0) |

```mushcode
[timefmt($M/$D/$Y $H:$02T$p, secs())]   @@ "3/27/2026 2:45pm"
[timefmt($02H:$02T:$02S, secs())]        @@ "14:45:00"
```

## Totem system (RhostMUSH-specific)

Totems are bitmask flags for objects/players, configurable per-game:

```mushcode
@@ netrhost.conf setup:
totem_add daily 7 0x80000000
totem_letter daily 0 d

@@ Search for objects with the 'daily' totem (letter 'd'):
search(totem=d)

@@ Trigger daily attr on all matching objects:
@dolist [search(totem=d)]={@tr/quiet ##/daily}
```

## @dynhelp — indexed help files

Serve help from a pre-indexed text file (`mkindx` run beforehand):

```mushcode
$bmail:@dynhelp brandymailer_rho=%#
$bmail *:@dynhelp brandymailer_rho/%0=%#
@set Obj/MAIN_HELP_ARG=no_parse    @@ prevent arg from being evaluated
```

## @progprompt / @program — interactive input

Collect a single line of input from a player:

```mushcode
@progprompt me=<M>ux, <B>randy, <P>enn, <O>ther, <X>it:
@program %#=[v(DB)]/vb
```
`@progprompt` sets the prompt string; `@program` installs a one-shot input handler. The handler attribute receives the player's input as `%0`.

## @sudo

Execute a command as another player (requires wizard power on the object):

```mushcode
@sudo %#={mail/send Player=Subject//Body}
@sudo %#={mail/reply 3*=Reply body}
```

Different from `@fo` in that `@sudo` preserves the caller's permission context for nested evaluations.

## @include / @include/command / @include/localize

```mushcode
@include obj/attr           @@ run attr as if inline (shares context)
@include/command obj/attr   @@ run as a command (not inline)
@include/localize obj/attr  @@ localize registers before running
```

Used in ColoredSpeech:
```mushcode
&CMD_SAY Obj=$say *:@dolist [lcon(%l/connect)]={@include/localize %!/inc_colortext_prefix=##,%0,%#,...}
```
