---
id: sys-data-dictionary-001
domain: systems
server: RhostMUSH
source: city-of-roses, session 2026-03-29
complexity: medium
tags: [data-dictionary, stat, chargen, attribute-namespace, lattr, getdef, validation]
date_added: "2026-03-29"
tested: true
---

# Pattern: Data dictionary object (stat definitions as attribute namespace)

Centralise all stat definitions on a dedicated "DD" object using a `STATDEF.<CATEGORY>.<STATNAME>` attribute namespace. UDFs on the DD object provide validated lookups; callers never access the attributes directly.

## Code

```mushcode
@@ DD object setup
@create Example DD <sys>
@tag/add example_dd=[lastcreate(me,t)]
@set #example_dd=SAFE INHERIT
@lock #example_dd=WIZARD
@lock/attribute #example_dd=WIZARD

@@ Stat definition attributes (min|max|default format):
&STATDEF.TALENT.ATHLETICS #example_dd=0|5|0
&STATDEF.ATTR.STRENGTH    #example_dd=1|5|1|physical
&STATDEF.BG.RESOURCES     #example_dd=0|5|0

@@ Lookup UDF — returns definition string or error:
&F.GETDEF #example_dd=
  [if(
    not(and(t(%0),t(%1))),
    #-3 WRONG NUMBER OF ARGUMENTS,
    [setq(0,get(%!/STATDEF.[ucstr(%0)].[ucstr(%1)]))]
    [if(t(%q0),%q0,#-1 INVALID STAT)]
  )]

@@ List all stats in a category:
&F.LIST.STATS #example_dd=
  [if(
    not(t(%0)),
    #-3 WRONG NUMBER OF ARGUMENTS,
    [setq(0,lattr(%!/STATDEF.[ucstr(%0)].*))]
    [if(not(t(%q0)),#-1 INVALID CATEGORY,
      [iter(%q0,extract(##,3,1,.))]
    )]
  )]

@@ Caller pattern (in stat setter UDF on another object):
[setq(a,ulocal(#example_dd/F.GETDEF,%1,%2))]
[if(strmatch(%qa,#-*),%qa,
  [setq(min,extract(%qa,1,1,|))]
  [setq(max,extract(%qa,2,1,|))]
  [setq(def,extract(%qa,3,1,|))]
)]
```

## Notes

- The `STATDEF.CATEGORY.STATNAME` namespace lets you use `lattr(#dd/STATDEF.TALENT.*)` to enumerate all stats in a category — no separate list attributes needed.
- The third field (column position 3 in the pipe-delimited string) is the default value; getters fall back to this when the player's attribute is unset, so unset = default, not zero.
- `@lock/attribute #example_dd=WIZARD` prevents players from writing stat definitions directly; all writes go through installer scripts only.
- The DD object holds no command patterns — it is purely a data store with accessor UDFs.
- Separating data from logic (DD object vs stat-handler object) means you can reload stat definitions without touching the command code.

## Variants

- **Subcategory field**: add a 4th pipe field for grouping within a category (e.g., physical/social/mental for attributes).
- **Template data on the DD**: store `TMPL.<LINE>.<TYPE>.<VALUE>` attributes on the same DD object for game-line template defaults (breed, auspice, tribe, etc.).
- **Cost tables**: add `FREEBIECOST.<CATEGORY>` and `CGPOOL.<GROUP>` attributes for point-buy validation at chargen.

## When NOT to use

- Very small codebases with fewer than ~10 stats — the overhead of the DD layer isn't worth it.
- When stats are dynamic and player-definable — the attribute namespace assumes a fixed schema.

## Source

Extracted from: city-of-roses, session 2026-03-29
