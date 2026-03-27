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
