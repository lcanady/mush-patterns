---
id: scan-object-001
domain: systems
server: RhostMUSH
source: RhostMUSH/trunk Mushcode/scan
complexity: medium
tags: [scan, debug, command-tree, search, lcmds, lattrp, nsiter, lzone, wizard]
date_added: "2026-03-27"
tested: true
---

# Pattern: Scan / Command-Tree Debug Object

The `scan` object provides `@scan`, `@listenscan`, `+commandtree`, `+searchtree`, and `+searchbyobj` — developer tools for discovering what softcode would match a given command or listen pattern.

## Gating access

```mushcode
&CANUSE Global: ScanObj <SO>=[gte(bittype(%#),2)]   @@ guildmaster or higher
@lock/UseLock Global: ScanObj <SO>=CANUSE/1
```

## @scan — find what handles a command

```mushcode
@scan <command>               @@ scan room, self, zone, master for $-command match
@scan/room <command>          @@ room contents only
@scan/self <command>          @@ self + carried objects
@scan/zone <command>          @@ zone objects only
@scan/global <command>        @@ master room only
@listenscan <listen-pattern>  @@ same but for ^listen patterns
```

## Key implementation patterns

### Dispatch via switch on switch presence

```mushcode
&CMD_SCAN Global: ScanObj <SO>=$@scan* *:
  @pemit %#=[u(do_scan[!$v(0)][match(/room /self /zone /global,%0)], %0,%1,%#,$,@scan)]
```

The attribute name is built dynamically: `do_scan` + `[!$v(0)]` (0 if switch present, 1 if not) + `[match(...)]` (1-4 for which scope). So `do_scan10` = switch present, room scope.

### Scanning object attributes with lattrp()

```mushcode
&SCAN_OBJ Global: ScanObj <SO>=
  [setq(v,0)]
  [setq(1,trim(nsiter(lattrp(%0,,%3), u(scan_obj[hasflag(%0/##,regexp)], %0,%1,%2,%3,##))))]
  [ifelse(!!$r(1), %r[name(%0)](%0[flags(%0)]%) %[%qv: %q1%])]
```

- `lattrp(%0,,%3)` — list attributes on `%0` matching pattern `%3`, including parents
- `hasflag(%0/##, regexp)` — check if the specific attribute has the REGEXP flag set
- Two handlers: `scan_obj0` (wildmatch) and `scan_obj1` (regex match)

```mushcode
&SCAN_OBJ0 Global: ScanObj <SO>=
  [ifelse(strmatch(%1, before(after(get(%0/%4),%3),:)), [setq(v,add(%qv,1))]%0/%4%b)]

&SCAN_OBJ1 Global: ScanObj <SO>=
  [ifelse(regmatch(%1, before(after(get(%0/%4),%3),:)), [setq(v,add(%qv,1))]%0/%4%b)]
```

### Zone scanning with lzone()

```mushcode
&SCAN_ZONE Global: ScanObj <SO>=
  %rMatching on zones in vicinity:
  [nsiter(setunion(lzone(loc(%2)), lzone(%2), u(dozone,[lcon(%2)] [lcon(loc(%2))])),
    u(scan_obj,##,%1,%2,%3,%4))]

&DOZONE Global: ScanObj <SO>=[iter(%0, lzone(##))]
```

## +commandtree — all commands on objects in master room

```mushcode
+commandtree              @@ list all $-commands on all objects in master room
+commandtree <dbref>      @@ list all $-commands on a specific object
```

```mushcode
&CMD_COMMANDTREE Global: ScanObj <SO>=$+commandtree*:
  @pemit %#=[switch(
    [!!^setr(1,locate(%#,%0,*))] [!!$v(0)],
    ?0, list(lcon(globalroom()), [ansi(hc,[name(%i0)]%(%i0[flags(%i0)]%))] [u(fn_pipe,%i0)]),
    01, CommandTree: Target not found[setq(1,X)],
    11, [ansi(hc,[name(%q1)]%(%q1[flags(%q1)]%))] [u(fn_pipe,%q1)] %r
  )] [ifelse(!match(X,%q1), ansi(hc,<--END))]

&FN_PIPE Global: ScanObj <SO>=
  [setq(0,lcmds(%0,beep()))]
  [iter(lattr(%0,,$),
    [ifelse(or(!$v(1), regmatch(extract(%q0,#@,1,beep()),%1)),
      %r[ljc(ifelse(hasflag(%0/%i0,noprog),ansi(hr,*LK*)),5)]
      [ansi([ifelse(hasflag(%0/%i0,regexp),+orange,+purple)],%i0)]
      -> [edit(edit(ansi(hg,extract(%q0,#@,1,beep())),*,ansi(hr,*)),?,ansi(hr,?))]
    )]
  )]
```

### lcmds() — extract command patterns

```mushcode
[lcmds(%0, beep())]
```

Returns the actual command patterns (the `$pattern:` parts) of all `$`-command attributes on `%0`, using `beep()` as separator. Then `extract(%q0, #@, 1, beep())` gets the pattern for the `#@`th command (where `#@` is the iter counter).

## +searchtree and +searchdb

```mushcode
+searchtree <cmd>         @@ search master room objects for partial command match
+searchbyobj <dbref>=<cmd>  @@ search object + location contents
+searchdb <cmd>           @@ search entire DB (wizard only)
```

```mushcode
&CMD_SEARCHDB Global: ScanObj <So>=$+searchdb *:
  @break [lt(bittype(%#),6)]=@pemit %#=Permission denied;
  @pemit %#=[list(search(eval=%[grep%(##%,*%,*%0*%)%]),
    [ansi(hc,[name(%i0)]%(%i0[flags(%i0)]%))]
    [u(fn_pipe,%i0,edit(%0,+,%[+%]))]
  )] [ifelse(!match(X,%q1),ansi(hc,<--END))]
```

Note: `grep(##,*,*pattern*)` searches all attributes of `##` for `pattern`. In a `search(eval=...)`, `##` refers to the object being evaluated.

## UseLock with bitlevel check (general pattern)

```mushcode
&CANUSE Obj=[gte(bittype(%#),2)]    @@ guildmaster or higher
@lock/UseLock Obj=CANUSE/1          @@ gate all $-commands on bitlevel
```

This is the preferred RhostMUSH pattern for "wizard/staff only" command objects over using `hasflag(%#,wizard)` inline, because it's configurable without editing individual commands.
