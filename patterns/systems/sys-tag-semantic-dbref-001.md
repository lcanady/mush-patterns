---
id: sys-tag-semantic-dbref-001
domain: systems
server: RhostMUSH
source: volundmush/rhostcode (codesuite.conf, objects.conf, CORE 01)
complexity: medium
tags: [dbref, tag, lookup, objects.conf, semantic, portability]
date_added: "2026-03-30"
tested: false
---

# Pattern: Semantic dbref lookup via `tag()`

Instead of hard-coding dbrefs like `#42` throughout softcode, register meaningful names for key objects using the `tag` system (via `objects.conf` / `@tag`). Resolve them at runtime with `tag(<name>)`.

This makes code portable across different server instances: the tag → dbref mapping lives in one config file, and all softcode uses the symbolic name.

## Configuration (`objects.conf` / codesuite.conf)

```
# objects.conf — maps tag names to dbrefs (set to -1 as placeholder, filled at install)
master_room         -1
file_object         -1
global_error_obj    -1
hook_obj            -1
global_obj          -1
global_room         -1
global_thing        -1
global_exit         -1
global_player       -1
char_parent         -1
npc_parent          -1
pc_parent           -1
item_parent         -1
```

In `codesuite.conf` (or `mush.conf`):
```
# Point the tag system at the objects.conf file
objects_file        objects.conf
```

## Softcode usage

```mushcode
@@ Resolve the master room dbref:
[tag(master_room)]         @@ → #2 (or whatever dbref was set)

@@ Use in a lock:
@lock #target=tag(master_room)/owner

@@ Use in teleport:
@tel %0=tag(global_room)

@@ Use in pemit routing:
@trigger tag(file_object)/MSG_ALERT=%0,%#

@@ Check if an object has the right parent:
@switch [isparent(tag(pc_parent),%0)]=1, @pemit %#=Is a PC., @pemit %#=Not a PC.
```

## Installation workflow

```mushcode
@@ After creating each required object, register its tag:
@create Master Room<R>
@set here=SAFE INHERIT
@tag Master Room<R>=master_room

@@ For programmatic tagging during installer:
@tag [%0]=file_object
```

## Totem system (related — type classification)

rhostcode also uses `totem()` for object-type classification — similar idea, stored differently:

```
# codesuite.conf
totem ACCOUNT  1
totem CHARACTER 2
totem NPC      3
totem PC       4
totem ITEM     5
totem REGION   6
totem FACTION  7
```

```mushcode
@@ Check if an object is a PC:
[hastotem(%0,PC)]          @@ → 1/0

@@ Set a totem on an object:
@totem %0=PC

@@ Filter a list to only PCs:
[filter(fn/FLT.IS_PC,%0)]
&FLT.IS_PC fn= [hastotem(%0,PC)]
```

## Notes

- `tag()` is a RhostMUSH built-in — it returns the dbref registered under that name or `#-1` if unregistered. Always guard: `[if(isdbref(tag(master_room)),...),$]`
- Place all `objects.conf` mappings in one file; during install, update the mappings as objects are created.
- Totems are mutually exclusive one-per-object type markers (like flags but semantic). Tags are global single-dbref pointers.
- Prefer `tag()` over storing dbrefs in config attributes — the tag system is faster (direct lookup) and survives `@dump`/`@load` as long as `objects.conf` is updated.
- In code, document the expected tag: `@@ expects tag(file_object) to be registered` at the top of any attr that uses a tag.

## When NOT to use

- For objects that are created/destroyed frequently — tags are for permanent, session-spanning objects only.
- For per-player or per-room data — use attributes on the owning object instead.

## Source

Extracted from: `codesuite.conf`, `objects.conf`, `CORE 01 - Initial.txt` in https://github.com/volundmush/rhostcode
