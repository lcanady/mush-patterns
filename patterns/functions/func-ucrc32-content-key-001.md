---
id: func-ucrc32-content-key-001
domain: functions
server: RhostMUSH
source: volundmush/rhostcode (CORE 04 - Help System.txt, CORE 14 - Info Lib.txt)
complexity: medium
tags: [crc32, ucrc32, content-addressed, attribute-naming, hash, key]
date_added: "2026-03-30"
tested: false
---

# Pattern: CRC32-based content-addressed attribute naming

Use `ucrc32()` to derive a stable, short numeric key from a variable-length string (typically a name or title). Store the data in attributes named `<PREFIX>_<ucrc32(name)>_<FIELD>` so that lookups are O(1) (`hasattr()` / `get()`) rather than requiring a linear `lattr()` scan.

This is the rhostcode approach in the Help System and Info Lib: file names (which may contain spaces and punctuation) are hashed to CRC32 integers, producing safe attribute names that can be checked directly.

## Pattern

```mushcode
@@ Store a help entry for topic "Character Generation":
[setq(0, ucrc32(lcstr(Character Generation)))]   @@ → 1827463910 (example)
[set(#help, HELP_%q0_NAME:Character Generation)]
[set(#help, HELP_%q0_BODY:This is the help text.)]
[set(#help, HELP_%q0_CAT:Basics)]

@@ Retrieve the help entry:
[setq(0, ucrc32(lcstr(%0)))]
[if(
  hasattr(#help, HELP_%q0_NAME),
  [get(#help/HELP_%q0_NAME)]%r[get(#help/HELP_%q0_BODY)],
  No help entry for '%0'.
)]

@@ List all topics (iterate NAME attrs):
[iter(
  lattr(#help/HELP_*_NAME),
  [get(#help/%i0)],
  , %r
)]
```

## Help system usage (CORE 04 pattern)

```mushcode
@create Help DB
@set Help DB=safe inherit

@@ Add a help file:
&FN.ADD_HELP #help_lib=
  [setq(k, ucrc32(lcstr(%0)))]
  [set(tag(help_db), HELP_%qk_NAME:%0)]
  [set(tag(help_db), HELP_%qk_BODY:%1)]
  [set(tag(help_db), HELP_%qk_CAT:[default(%2,General)])]
  [set(tag(help_db), HELP_%qk_SUMMARY:[first(%1,.)])]

@@ Look up a help file:
&FN.GET_HELP #help_lib=
  [setq(k, ucrc32(lcstr(%0)))]
  [if(
    hasattr(tag(help_db), HELP_%qk_NAME),
    [u(tag(help_db)/HELP_%qk_BODY)],
    #-1 NOT FOUND
  )]

@@ Prefix search (fallback when exact match fails):
&FN.SEARCH_HELP #help_lib=
  [setq(r, filter(#help_lib/FLT.HELP_PREFIX, lattr(tag(help_db)/HELP_*_NAME), , %0))]
  [if(strlen(%qr), iter(%qr, get(tag(help_db)/%i0), , %r), #-1 NOT FOUND)]

&FLT.HELP_PREFIX #help_lib=
  [strmatch(lcstr(get(tag(help_db)/%0)), lcstr(%1)*)]
```

## Info Lib variation (CORE 14 pattern)

rhostcode's Info Lib stores five fields per entry:

```mushcode
INFO.<objid>.<ucrc32(name)>.NAME
INFO.<objid>.<ucrc32(name)>.BODY
INFO.<objid>.<ucrc32(name)>.SUMMARY   @@ first sentence of body
INFO.<objid>.<ucrc32(name)>.META      @@ JSON blob of owner, locked, etc.
INFO.<objid>.<ucrc32(name)>.ORDER     @@ integer sort position
```

```mushcode
@@ Store an info entry on a faction object:
[setq(k, ucrc32(lcstr(%0)))]
[set(%!, INFO.[objid(%1)].[%qk].NAME:%0)]
[set(%!, INFO.[objid(%1)].[%qk].BODY:%2)]
[set(%!, INFO.[objid(%1)].[%qk].ORDER:[default(
  add(1, max(0, iter(lattr(%!/INFO.[objid(%1)].*.ORDER), u(%!/INFO.[objid(%1)].[%i0].ORDER)))),
  1)])]
```

## Notes

- `ucrc32(str)` returns an unsigned 32-bit integer as a decimal string — safe for use as an attribute name component.
- **Lowercase before hashing:** always `ucrc32(lcstr(name))` so `Character Generation` and `character generation` resolve to the same key.
- CRC32 has a small but non-zero collision probability. For a typical MUSH help system (< 10,000 topics), collisions are negligible. For critical systems, add a post-check: `if(strmatch(get(#help/HELP_%qk_NAME), %0), ...)`.
- Compared to `lattr()` scan, `hasattr()` is O(1) — much faster for systems with hundreds of entries.
- The multi-field approach (`_NAME`, `_BODY`, `_CAT`) is preferable to storing all data in one attribute when individual fields need to be updated independently.
- For decomp / backup, iterate `lattr(#help/HELP_*_NAME)` to reconstruct the full table.

## When NOT to use

- Small static sets (< 20 entries) where a simple `lattr()` scan is fast enough.
- Keys that are already short safe attribute-name strings (e.g. `STAT_STRENGTH`) — no need to hash.
- When you need the actual name as the attribute suffix for readability in `@decompile` output.

## Source

Extracted from: `CORE 04 - Help System.txt`, `CORE 14 - Info Lib.txt` in https://github.com/volundmush/rhostcode
