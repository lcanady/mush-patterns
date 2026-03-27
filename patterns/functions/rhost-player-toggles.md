---
id: rhost-player-toggles-001
domain: functions
server: RhostMUSH
source: RhostMUSH/trunk Mushcode/mailwrappers, comsys, ColoredSpeech
complexity: low
tags: [toggles, hasflag, hastoggle, player, bittype, flags]
date_added: "2026-03-27"
tested: true
---

# RhostMUSH: Player Toggles and Flag System

RhostMUSH distinguishes between **flags** (`hasflag()`) and **toggles** (`hastoggle()`). Toggles are player-configurable behaviors; flags are server-set object properties.

## Toggles vs Flags

| Concept | Set with | Check with | Example |
|---------|----------|-----------|---------|
| Flag | `@set obj=flagname` | `hasflag(obj, flagname)` | `hasflag(%#, wizard)` |
| Toggle | `@toggle obj=togglename` | `hastoggle(obj, togglename)` | `hastoggle(%#, brandy_mail)` |

## Common player toggles

| Toggle | Meaning |
|--------|---------|
| `brandy_mail` | Brandy +mail interface active |
| `penn_mail` | PennMUSH-style mail interface |
| `mail_stripreturn` | Mail separator = space (not newline) |
| `muxpage` | TM3/MUX-compatible page behavior |
| `monitor` | Wizard sees connect/disconnect events |
| `monitor_site` | Wizard sees site info on connect |
| `prog` | Player can use `@program` |

## Setting and checking toggles in softcode

```mushcode
@@ Set a toggle on the acting player
@toggle %#=muxpage

@@ Unset a toggle
@toggle %#=!muxpage

@@ Check in an expression
[hastoggle(%#, monitor)]         →  1 if set, 0 if not

@@ Gate a command on a toggle
&USEMAIL Obj=[hastoggle(%#,brandy_mail)]
@lock/UseLock Obj=USEMAIL/1
```

## bittype() — numeric bitlevel

`bittype(<player>)` returns a number indicating the player's privilege level:

| Value | Level |
|-------|-------|
| 1 | Mortal (player) |
| 2 | GuildMaster |
| 3 | Architect |
| 4 | Councilor |
| 5 | Wizard |
| 6 | Royalty |
| 7 | Immortal |
| 8 | God |

```mushcode
@@ Check if player is wizard or higher (bitlevel >= 5)
[gte(bittype(%#), 5)]

@@ Check if guildmaster or higher (bitlevel >= 2)
[gte(bittype(%#), 2)]

@@ Common: only wizards may proceed
@break [lt(bittype(%#), 5)]=@pemit %#=Permission denied.
```

## hasflag() for standard flags

```mushcode
[hasflag(%#, wizard)]      @@ player is set WIZARD
[hasflag(%#, connect)]     @@ player is currently connected
[hasflag(%#, guest)]       @@ player is a guest
[hasflag(%#, robot)]       @@ player has ROBOT flag (bot)
[hasflag(%#, dark)]        @@ object is DARK
[hasflag(%#, inherit)]     @@ object has INHERIT flag
```

## Monitor toggle pattern (broadcast to wizards)

From AccountShare and comsys — send a message to all connected wizards with MONITOR:

```mushcode
&FN_TARGETS Obj=[iter(lwho(), ifelse(and(hastoggle(%i0,monitor), gte(bittype(%i0),5)), %i0))]

@@ Then pemit to them:
@pemit/list [u(fn_targets)]=[u(fn_prompt)] Something happened.
```

## flags() and objflags()

```mushcode
[flags(%0)]          @@ returns flag string like "Wcp"
[objflags(%0)]       @@ similar — check help for difference
```

## @set vs @toggle

```mushcode
@set obj=DARK              @@ sets a flag (most flags work this way)
@toggle me=monitor         @@ sets a toggle (player behavioral prefs)
```

Both can be unset with `!`:
```mushcode
@set obj=!DARK
@toggle me=!monitor
```
