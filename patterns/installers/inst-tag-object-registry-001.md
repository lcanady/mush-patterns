---
id: inst-tag-object-registry-001
domain: installers
server: RhostMUSH
source: city-of-roses, session 2026-03-29
complexity: low
tags: [tag, installer, object-registry, dbref, lookup, lastcreate]
date_added: "2026-03-29"
tested: true
---

# Pattern: Tag-based object registry for cross-object references

Use RhostMUSH's `@tag/add` command immediately after `@create` to register every system object under a stable tag name. Code on other objects can then reference `#tag_name` instead of hardcoded dbrefs.

## Signal
USE:  stable cross-object refs via #tag_name | @tag/add name=[lastcreate(me,t)] immediately after @create
RULE: tag names→project-prefix (cor_sys, cor_dd) to avoid collisions | tags survive renames/moves
WARN: single-object codebase→no benefit | servers without @tag→check @config/list first
TEST: ✓

## Code

```mushcode
@@ Installer sequence:
@create Example System <sys>
@tag/add example_sys=[lastcreate(me,t)]
@set #example_sys=SAFE INHERIT

@@ On a sibling object, call a UDF on the registered object:
[ulocal(#example_dd/F.GETDEF,talent,athletics)]

@@ Or get/set attributes using the tag dbref:
[get(#example_sys/GAMELINE)]
[set(#example_sys,GAMELINE:wta)]
```

## Notes

- `lastcreate(me,t)` returns the dbref of the most recently created thing — safe to use immediately after `@create` in the same installer block.
- `@tag/add <tagname>=<dbref>` registers the object so `#tagname` resolves globally.
- Tag names should follow a project prefix convention (e.g., `cor_sys`, `cor_dd`) to avoid collisions with other packages on the same server.
- Tags survive object moves and renames; hardcoded dbrefs do not.
- Cross-object `ulocal()` calls using `#tag` notation avoid the need to store dbrefs anywhere — the tag IS the pointer.

## Variants

- **Multiple packages**: each package registers its own tags (e.g., `cor_stat`, `cor_dd`, `cor_sheet`), creating a flat object namespace for the whole codebase.
- **Version guard**: store `&VER #example_sys=1.0.0` immediately after setup to allow upgrade scripts to compare installed vs. new version.

## When NOT to use

- Single-object codebases — no benefit if nothing needs to cross-reference.
- Servers that do not support `@tag` — check with `@config/list` or equivalent.

## Source

Extracted from: city-of-roses, session 2026-03-29
