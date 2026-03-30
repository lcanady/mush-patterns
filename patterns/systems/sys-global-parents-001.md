---
id: sys-global-parents-001
domain: systems
server: RhostMUSH
source: volundmush/rhostcode (CORE 10 - Global Parents.txt)
complexity: high
tags: [parent, inheritance, hierarchy, globobj, room, thing, exit, player, zone]
date_added: "2026-03-30"
tested: false
---

# Pattern: Layered global parent hierarchy

Establish a tree of parent objects that give every in-game object a consistent set of attributes, commands, locks, and format strings — without touching individual objects. All parents inherit from a single root `#globobj` that holds the most general overrides.

This is the rhostcode approach: one parent chain per object type, each specialising the type further.

## Object tree

```
#globobj           — root parent (SAFE INHERIT)
├── #globroom      — parent for all rooms
├── #globthing     — parent for all THING objects
├── #globexit      — parent for all exits
├── #globplayer    — parent for all players
│   ├── #char_parent
│   │   ├── #npc_parent   — NPC characters
│   │   └── #pc_parent    — Player characters
├── #stat_parent   — objects that hold stats
├── #reg_parent    — region zones
├── #obj_parent    — in-world objects (items, structures, vehicles)
│   ├── #item_parent
│   ├── #structure_parent
│   └── #vehicle_parent
```

## Bootstrap

```mushcode
@@ Root parent — everything inherits from here
@create Global Object Parent<P>
@set Global Object Parent<P>=safe inherit
@parent Global Object Parent<P>=Global Object Parent<P>   @@ self-parent

@@ Room parent
@create Global Room Parent<R>
@set Global Room Parent<R>=safe inherit
@parent Global Room Parent<R>=Global Object Parent<P>

@@ Player parent
@create Global Player Parent<P>
@set Global Player Parent<P>=safe inherit
@parent Global Player Parent<P>=Global Object Parent<P>

@@ Char parent (inherits from player parent)
@create Char Parent<P>
@set Char Parent<P>=safe inherit
@parent Char Parent<P>=Global Player Parent<P>

@@ PC parent (inherits from char parent)
@create PC Parent<P>
@set PC Parent<P>=safe inherit
@parent PC Parent<P>=Char Parent<P>
```

## Room display overrides on `#globroom`

```mushcode
@@ Custom room name display:
&@NAMEFORMAT #globroom=
  [setq(0, name(%!))]
  [setq(1, upzones(%!))]
  [ansi(hw, %q0)]
  [if(strlen(%q1), %b[ansi(h, %(%q1%))], )]

@@ Contents list with columns:
&@CONFORMAT #globroom=
  [header(Contents)]
  [if(strlen(lcon(%!,all)),
    [setq(0,lcon(%!,all))]
    [iter(%q0,
      [printf($-20s %s, name(%i0), [if(isstaff(%i0),ansi(r,STAFF),)])],
      , %r)],
    %b(empty)
  )]

@@ Exits display:
&@EXITFORMAT #globroom=
  [if(strlen(lexits(%!)),
    [header(Exits)][iter(lexits(%!), [ljust(name(%i0),15)], , %r)],
    )]
```

## PC-specific attributes on `#pc_parent`

```mushcode
@@ Fail message when someone looks at a PC who is using dark/private mode:
&@LFAIL #pc_parent=
  [if(hasflag(%!,DARK), That person prefers privacy., )]

@@ Auto-strip problematic flags on connection:
&@ACONNECT #pc_parent=
  @switch [hasflag(%!,DARK)]=
    1, @switch [not(isstaff(%!))]=1, @flag %!=!dark

@@ Inherit stat-display UDF:
&FN.SHEET #pc_parent=
  [u(tag(global_obj)/FN.RENDER_SHEET, %!)]
```

## Zone parent for regions

```mushcode
@@ #reg_parent — every region zone inherits this
@create Region Parent<Z>
@set Region Parent<Z>=safe inherit

@@ Eval lock: only BUILDERS list members can build here
&ZoneToLock #reg_parent=
  [or(isstaff(%@), member(default(%!/BUILDERS,), objid(%@)))]

@@ Wiz-only zone entry lock:
&ZoneWizLock #reg_parent=
  [isstaff(%@)]

@@ @aenter trigger — announce to zone channel:
&@AENTER #reg_parent=
  @switch [strlen(default(%!/ZONE_CHANNEL,))]=
    0, ,
    @cemit [default(%!/ZONE_CHANNEL,)]=
      [ansi(h,name(%#))] enters [name(loc(%#))].
```

## Notes

- Set all parents `SAFE INHERIT` — `SAFE` prevents `@destroy`, `INHERIT` allows child objects to use parent attrs as if their own (needed for eval locks).
- Use `@parent` on newly created rooms/things/players during `@clone` or init scripts. PennMUSH and TinyMUX call this `@parent`; RhostMUSH is the same.
- The parent chain resolves bottom-up: `#pc_parent` → `#char_parent` → `#globplayer` → `#globobj`. An attr on `#pc_parent` shadows the same attr on `#globplayer`.
- Keep `#globobj` lightweight — only universal behaviors (e.g., default `@desc`, catch-all `$+help:` command) belong there.
- Store parent dbrefs in `objects.conf` via the `tag()` system so that `@parent <obj>=tag(pc_parent)` works everywhere.
- `@nameformat`, `@conformat`, `@exitformat` on `#globroom` affect ALL rooms. Test carefully before deploying — a crash here crashes room display globally.

## upzones() helper (referenced in @NAMEFORMAT)

```mushcode
@@ Returns the zone-chain above an object as a space-delimited name list
&GFN.UPZONES #func=
  [setq(0, zone(%0))]
  [if(
    isdbref(%q0),
    [name(%q0)] [upzones(%q0)],

  )]

@@ Registered as global: upzones(obj)
```

## When NOT to use

- Small games where all players are the same type — a single `#globplayer` is enough, skip `#char_parent`/`#pc_parent`.
- When the parent chain would be more than 5 deep — attribute resolution slows with each hop.

## Source

Extracted from: `CORE 10 - Global Parents.txt` in https://github.com/volundmush/rhostcode
