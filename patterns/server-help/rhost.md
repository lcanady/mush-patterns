# RhostMUSH Server Patterns

Source: `https://raw.githubusercontent.com/RhostMUSH/trunk/master/Server/game/txt/wizhelp.txt`
Extracted: 2026-03-27

---

## execscript

`execscript()` runs a **script file** from the game's `execscripthome` directory. It does NOT execute arbitrary binaries directly.

```
execscript(<scriptname>[, <arg0>, ..., <arg9>])
execscriptnr(<scriptname>[, <arg0>, ..., <arg9>])   # no-return variant
```

- `<scriptname>` is a filename relative to `execscripthome` — no path separators.
- Up to 10 arguments (`arg0`–`arg9`).
- All output sanitized to ASCII-7 printable; non-printable chars become `?`.
- Arguments are also sanitized to prevent shell injection.

### Enabling execscript

**Config** (`rhostmush.conf`):
```
execscripthome /path/to/game/scripts    # where script files live
execscriptpath /additional/search/path  # optional additional path
```

**Power** — granted per-object, NOT inheritable:
```
@power <object>=@g execscript   # GUILDMASTER: no arguments allowed
@power <object>=@a execscript   # ARCHITECT:   arguments allowed ← use this
@power <object>=@c execscript   # COUNCILOR:   same as ARCHITECT
```

`@a` (ARCHITECT) is the minimum bitlevel required to pass arguments to the script.

See in-game: `wizhelp POWER EXECSCRIPT`, `wizhelp execscripthome`

---

## Lock types

Valid lock types (`wizhelp @lock type <type>`):

| Lock | Syntax | Purpose |
|------|--------|---------|
| Default | `@lock <obj>=<key>` | `@force`, object control, attribute locks |
| UseLock | `@lock/use <obj>=<key>` | Gates `$cmd` triggers, `USE`, `PAY`/`COST`, `^listen` |
| EnterLock | `@lock/enter <obj>=<key>` | Who may `enter` the object |
| LeaveLock | `@lock/leave <obj>=<key>` | Who may leave the object |
| DropLock | `@lock/drop <obj>=<key>` | Controls `drop` |
| GiveLock | `@lock/give <obj>=<key>` | Controls `give` to object |
| PageLock | `@lock/page <obj>=<key>` | Who may page the player |
| LinkLock | `@lock/link <obj>=<key>` | Controls `@link` to this object |
| ParentLock | `@lock/parent <obj>=<key>` | Controls `@parent` to this object |
| TportLock | `@lock/tport <obj>=<key>` | Teleportation |
| MailLock | `@lock/mail <obj>=<key>` | `@mail` |
| UserLock | `@lock/user <obj>=<key>` | User-defined (custom use) |

**`@lock/interact` does NOT exist.** Use `@lock/use` to gate `$`-command execution.

UseLock `%0` in evaluation locks:
- `0` = default (neither `$cmd` nor `^listen`)
- `1` = `$command` triggered
- `2` = `^listen` triggered

---

## Flags

### INHERIT
```
@set <obj>=inherit
```
Gives the object access to the ROYALTY and IMMORTAL powers of its owner; allows it to control the owner and other INHERIT objects owned by that player. Required for Wizard-owned objects to carry wizard powers.

Do not set players INHERIT — their objects would gain control over them.

### SAFE
```
@set <obj>=safe
```
Prevents accidental `@destroy`. Requires `@destroy/override` to actually destroy. Ignored if the object also has `DESTROY_OK`.

---

## @power

```
@power[/switch] <object>=[@g|@a|@c|@w|@i] <powername>
```

Bitlevel prefixes (low → high): `@g` GUILDMASTER · `@a` ARCHITECT · `@c` COUNCILOR · `@w` WIZARD · `@i` IMMORTAL

Notable powers relevant to softcode:
- `execscript` — NOT inheritable; `@a` required to pass arguments

---

## Standard privileged system object pattern

```mushcode
@create MySystem <sys>
@set MySystem <sys>=inherit safe
@power MySystem <sys>=@a execscript
@lock MySystem <sys>=haspower(me,Wizard)
@lock/use MySystem <sys>=haspower(me,Wizard)
```

---

## printf() — ANSI-aware string formatting

`printf()` is RhostMUSH's canonical string formatting function. Unlike `center()`, `ljust()`, `rjust()`, and `repeat()`, it measures string width **after** stripping ANSI codes — so output is correct even when arguments contain color.

```
printf(<format>, <arg0>[, <arg1>, ...])
```

### Format string syntax

```
$[<codes>][<width>][:<filler>:]s
```

| Code | Effect |
|------|--------|
| `^`  | Center the argument within `<width>` |
| `-`  | Left-justify (default) |
| `_`  | Stretch: pad argument to fill `<width>` |
| `&`  | CR-wrap at `<width>` |
| `\|` | Auto-wrap at `<width>` |
| `"`  | Word-wrap at `<width>` |

- `<width>` — column width in characters
- `:<filler>:` — single fill character (default space). Use `%<058>` for a literal `:` as filler (`:` is the format delimiter).
- `s` — marks the end of the format token; remaining text is output as-is.

### Common display patterns

#### 78-char centered header with `=` fill

```mushcode
# Output: ================[ Help ]================  (78 chars wide)
&FN_HEADER <obj>= %ch[printf($^78:=:s,%[%b%0%b[chr(93)])]%cn
```

- `%[` = literal `[` (escape — no function call opened)
- `chr(93)` = literal `]` — avoids `%]` which is unreliable in nested bracket contexts
- `%ch` / `%cn` = bold on/off for visual weight

#### 78-char full-width rule (`=` fill, no argument)

```mushcode
# Output: ============================================ (78 `=` chars)
&FN_FOOTER <obj>= [printf($78:=:s,)][if(%0,%r%0,)]
```

Passing an empty string `,` makes printf produce only the fill characters.

#### 78-char centered category divider with `-` fill

```mushcode
# Output: ----------------  Combat  ---------------- (78 chars wide)
&FN_CAT_HEADER <obj>= [printf($^78:-:s,%b%0%b)]
```

The leading/trailing `%b` (space) adds a one-space margin between the filler and the label.

### Escaping `:` in format strings

`:` is the filler delimiter. To use a literal `:` as the filler character:

```mushcode
printf($^78%<058>:%<058>s, text)   # center in 78 chars, filler = :
```

`%<058>` = chr(58) = `:`. The sequence `%<NNN>` produces the character with decimal ASCII code NNN.

### Why prefer printf over center()/repeat()

| Function | ANSI-aware? | Notes |
|----------|-------------|-------|
| `printf()` | Yes | Correct width even with color codes in args |
| `center()` | No | Miscounts width when arg contains ANSI codes |
| `repeat()` | N/A | No width-aware centering |
| `ljust()`/`rjust()` | No | Same miscounting issue as center() |

Always use `printf()` when the argument may contain ANSI color or bold codes.

---

## hasflag() / haspower()

Both work as expected on RhostMUSH despite not appearing in wizhelp:

```
hasflag(<object>, <flagname>)   → 1 if object has the flag
haspower(<object>, <power>)     → 1 if object has the named power
```

Common flag names: `wizard`, `royalty`, `immortal`, `inherit`, `safe`

---

## Mail API

Source: `RhostMUSH/trunk/Mushcode/mailwrappers/`

RhostMUSH mail can be accessed two ways. See `patterns/functions/rhost-mail-api.md` for the complete reference.

### Via subcommands (all access levels)

```mushcode
@fo %#={mail/send <recipient>=<subject>//<body>}          @@ send as the player
@sudo <player>={mail/send <recipient>=<subject>//<body>}  @@ send as another player
```

Subject/body separator in `mail/send` is `//` (double-slash).

### Via side-effect functions (wizard-only; object needs INHERIT + SIDEFX)

```mushcode
[mailsend(recipient, subject, body)]          @@ send from system object
[mailsend(recipient, subject, body, sender)]  @@ with sender override
```

`mailsend()` is confirmed present in RhostMUSH (wizhelp only — not in player help.txt). Used in SIDEFX system objects like job trackers. The original RockJobs code uses `mailsend()` correctly for this purpose.

### Mail query functions

| Function | Access | Returns |
|----------|--------|---------|
| `mailquick(player[,folder][,type])` | All | `type=0`: `total new unread old marked saved`; `type=1`: MUX compat; `type=2`: total count |
| `mailstatus(player[,filter])` | Wizard | List of status strings |
| `mailread(player, N, field)` | Wizard | Fields: `g`=num, `f`=from, `d`=date, `k`=size, `s`=subject, `b`=body |
| `mailread(player, N, s, 1)` | Wizard+SIDEFX | Mark message as read |
| `mailsize(player, 2)` | All | Mailbox size in bytes |
| `mailalias(name)` | All | Dbrefs for a mail alias |
| `msizetot()` | Wizard | Total mail system bytes |

---

## @toggle / hastoggle()

Source: `RhostMUSH/trunk/Mushcode/mailwrappers/`

RhostMUSH distinguishes player **toggles** (configurable preferences) from **flags** (object properties).

```mushcode
@toggle %#=brandy_mail          @@ set
@toggle %#=!brandy_mail         @@ unset
[hastoggle(%#, brandy_mail)]    @@ check → 1 or 0
```

Common toggles: `brandy_mail`, `penn_mail`, `mail_stripreturn`, `muxpage`, `monitor`, `monitor_site`, `prog`

**`@toggle` is NOT the same as `@set`** and not PennMUSH-specific: it's the correct RhostMUSH mechanism for player-configurable behaviors.

---

## bittype() — numeric bitlevel

Source: `RhostMUSH/trunk/Mushcode/scan, AccountSubsystem`

```
bittype(<player>) → integer
```

| Value | Level |
|-------|-------|
| 1 | Mortal |
| 2 | GuildMaster |
| 3 | Architect |
| 4 | Councilor |
| 5 | Wizard |
| 6 | Royalty |
| 7 | Immortal |
| 8 | God |

```mushcode
[gte(bittype(%#), 5)]   @@ true for Wizard+
@break [lt(bittype(%#), 5)]=@pemit %#=Permission denied.
```

---

## TinyMUX → RhostMUSH migration notes

Confirmed via wizhelp.txt + help.txt from RhostMUSH trunk. These functions exist in **both** TinyMUX and RhostMUSH with identical or compatible semantics — no changes needed when migrating:

| Function | Rhost status | Notes |
|----------|-------------|-------|
| `strcat(a,b,c,...)` | **Native** | Concatenates all args with no separator. `strcat(v1,:,v2,:,v3)` → `v1:v2:v3`. Same behavior as TinyMUX. |
| `regraball(str,regexp)` | **Native** | Returns all words in `str` matching `regexp`. Identical to TinyMUX. Case-insensitive variant: `regraballi()`. |
| `cor(a,b,c)` | **Native** | Lazy/short-circuit OR — stops at first truthy value. Identical to TinyMUX. Complement: `cand()`. |
| `localize(str)` | **Native** | Preserves setq registers across UDF calls. Rhost extends with optional register-list and key args. |
| `lnum(from,to,sep,step)` | **Native** | Range-aware. `lnum(1,11,\|)` → `1\|2\|...\|11`. Stepping supported. |
| `lrand(lo,hi,count,sep)` | **Native** | Same as TinyMUX. |
| `setr()` / `setq()` | **Native** | Same as TinyMUX. |

### Key incompatibility: `@function` switch name

TinyMUX uses `/privileged`; RhostMUSH uses `/privilege` (abbreviated `/priv`):

```mushcode
@@ TinyMUX:
@function/preserve/privileged funcname=obj/ATTR

@@ RhostMUSH:
@function/preserve/privilege funcname=obj/ATTR
@@ or abbreviated:
@function/pres/priv funcname=obj/ATTR
```

GMCCG's `@startup` on the SFP object uses this pattern — change `/privileged` → `/privilege` in all `@startup` and `@dolist` UDF registration code.

### Functions NOT in RhostMUSH (TinyMUX-only)

| TinyMUX feature | RhostMUSH alternative |
|----------------|----------------------|
| `@rxlevel` / `@txlevel` (reality layers) | No equivalent — requires full subsystem redesign |

---

## Functions confirmed present in RhostMUSH

Source: `RhostMUSH/trunk/Mushcode/softfunctions.minmax` (implements PennMUSH shims for missing functions — the ones NOT shimmed are confirmed native)

| Function | Notes |
|----------|-------|
| `elist()` | **Native** — PennMUSH calls it `itemize()`. Both names work in RhostMUSH. |
| `cname()` | **Native** — returns colored display name of player |
| `title()` | **Native** — returns player `@title` |
| `ifelse()` | **Native** (shimmed only as fallback for very old versions) |
| `setr()` | **Native** |
| `timefmt()` | **Native** |
| `randextract()` | **Native** |
| `columns()` | **Native** |
| `ofparse()` | **Native** |
| `spellnum()` | **Native** |
| `mask()` | **Native** |
| `size()` | **Native** |
| `creplace()` | **Native** |
| `sortlist()` | **Native** |
| `pack()` / `unpack()` | **Native** |
| `nsiter()` | **Native** — like `iter()` but no separator injected between items |
| `itext()` / `inum()` | **Native** — current item/index inside `iter()` or `list()` |
| `ibreak()` | **Native** — break out of `iter()` early |
| `lattrp()` | **Native** — `lattr()` including parent chain |
| `lcmds()` | **Native** — list `$`-command attributes |
| `lzone()` | **Native** — list zones on an object |
| `objeval()` | **Native** — evaluate expression in another object's security context |
| `lookup_site()` | **Native** — get connecting hostname/IP for a connected player |
| `wildmatch()` | **Native** — wildcard match against a list of patterns |
| `strfunc()` | **Native** — build a function call string dynamically |
| `pushregs()` / `nameq()` | **Native** — register stack operations |
| `pedit()` | **Native** — multi-pair edit |
| `squish()` | **Native** — collapse multiple spaces |
| `graball()` | **Native** — filter list by wildcard |
| `convtime()` | **Native** — convert date/time string to seconds |
| `regeditall()` / `regeditalli()` | **Native** — regex global substitution |

---

## Functions NOT in RhostMUSH (PennMUSH only)

These appear in PennMUSH softcode but **do not exist** natively in RhostMUSH. `softfunctions.minmax` provides soft replacements.

| PennMUSH function | RhostMUSH equivalent |
|-------------------|---------------------|
| `itemize()` | `elist()` |
| `timestring()` | `timefmt($!cd $!2Xh $!2Fm $2Gs, secs)` |
| `poll()` | `doing()` |
| `band()` / `bor()` | `mask(%0,%1,&)` / `mask(%0,%1,|)` |
| `objmem()` | `size(%0,3)` |
| `strinsert()` | `creplace(%0,add(%1,1),%2,i)` |
| `lpos()` | `setdiff(totpos(%1,%0),#-1)` |
| `pickrand()` | `randextract(%0,1,%1)` |
| `vmax()` / `vmin()` | `sortlist(+n,%2,%0,%1)` / `sortlist(-n,%2,%0,%1)` |
| `cpad()` / `rpad()` / `lpad()` | `printf($^%1:%2:+s,%0)` etc. |
| `exptime()` | `timefmt($!Zy $!EM $!Cd $!Xh $!Fm $Gs,%0)` |
| `writetime()` | `timefmt($!Z years $!e months $!C days ...)` |
| `firstof()` / `allof()` | `ofparse(1,...)` / `ofparse(2,...)` |
| `align()` | Available via softfunctions shim |

---

## @function — registering global softcode functions

Source: `RhostMUSH/trunk/Mushcode/softfunctions.minmax`

```mushcode
@function funcname=<dbref>/ATTR_NAME          @@ normal
@function/pres funcname=<dbref>/ATTR_NAME     @@ preserved registers
@function/priv funcname=<dbref>/ATTR_NAME     @@ privileged (wizard callers only)
@function/priv/pres funcname=<dbref>/ATTR_NAME
@function/priv/notrace funcname=<dbref>/ATTR_NAME
@function/min funcname=<N>                    @@ minimum argument count
@function/max funcname=<N>                    @@ maximum argument count
@admin function_access=funcname <flag>        @@ access flag (e.g. no_eval)
```

---

## @lfunction — local softcode functions

```mushcode
@startup Obj=@lfunction funcname=me/attr_name
@startup Obj=@lfunction/priv funcname=me/attr_name
```

Game-local functions, not global. Must be re-registered in `@startup`.

---

## @progprompt / @program — interactive input

Source: `RhostMUSH/trunk/Mushcode/mailwrappers/StartObject`

```mushcode
@progprompt me=<prompt text>:     @@ set prompt string shown to player
@program %#=<dbref>/<attr>        @@ next typed line goes to this attr as %0
```

One-shot handler — to chain, install another `@program` at the end of the handler. The `prog` toggle must be set on the object: `@toggle obj=prog`.

---

## @sudo — force command as another player

```mushcode
@sudo <player>={command args}
```

Executes `command` as if `<player>` typed it. Requires wizard power on the executing object. Different from `@fo` (force) in that `@sudo` preserves caller's security context for nested operations.

---

## Totem system

Source: `RhostMUSH/trunk/Mushcode/daily`

Totems are custom bitmask tags, defined in `netrhost.conf`:

```
totem_add daily 7 0x80000000
totem_letter daily 0 d
```

```mushcode
@tag/add daily=My Object       @@ tag an object with the 'daily' totem
search(totem=d)                 @@ find all objects tagged with 'd' totem
```

---

## @Aconnect / @Adisconnect

Source: `RhostMUSH/trunk/Mushcode/MedusaObject`

Fire on any player connecting/disconnecting game-wide. Object must be in Master Room or INHERIT.

```mushcode
@Aconnect Obj=<code>      @@ %# = connecting player
@Adisconnect Obj=<code>   @@ %# = disconnecting player
```

---

## SLAVE and FUBAR flags

```mushcode
@set %#=slave fubar     @@ player cannot execute any commands
@set %#=!slave !fubar   @@ restore normal operation
```

---

## @dynhelp — indexed help files

```mushcode
$help:@dynhelp helpfilename=%#
$help *:@dynhelp helpfilename/%0=%#
@set Obj/CMD_HELP_ARG=no_parse   @@ prevent arg evaluation before lookup
```

The help file must be indexed first with `mkindx <filename>` on the server.

---

## @wait/until

```mushcode
@wait/until <secs-epoch>={code}
```

Fires at a specific Unix timestamp. Used with `convtime()` to schedule at a clock time:

```mushcode
@wait/until [convtime([extract(time(),1,3)] 23:59:59 [extract(time(),5,1)])]={...}
```

`extract(time(),1,3)` = date portion; `extract(time(),5,1)` = timezone.

---

## Account system functions

Source: `RhostMUSH/trunk/Mushcode/AccountSubsystem`

RhostMUSH has a built-in multi-character account system:

```mushcode
account_owner(<port>)                   @@ dbref of master account for port
account_owner(<port>,logoff)            @@ log off account for port
account_owner(<player>,_ACCT,<port>,<pw>)  @@ authenticate and log in
account_login(<player>,_ACCT,<port>)    @@ login to account
account_su(<player>,<port>,_ACCT)       @@ switch to sub-character
```

Requires `file_object` set in `netrhost.conf`:
```
file_object <dbref>   @@ the File Object handles connection commands
```
