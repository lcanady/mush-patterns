---
id: sys-rank-cascade-001
domain: systems
server: RhostMUSH
source: city-of-roses, session 2026-03-29
complexity: high
tags: [rank, cascade, renown, chargen, wta, minimum, auto-raise, template]
date_added: "2026-03-29"
tested: true
---

# Pattern: Rank cascade — auto-raise dependent stats when a parent value is set

When a "rank" or "tier" stat is set by staff, automatically raise dependent stats (e.g., renown, experience, reputation) to their minimum values for that rank. Returns a human-readable change log so the setter sees exactly what was adjusted.

## Signal
USE:  auto-raise dependent stats when rank set | returns change-log string (empty if no changes)
ARCH: TMPL.RANK.SLOT.<line> on DD → rank-key position | RANKMIN.<line>.<key>.<rank> → minimums
MODES: any|total (warn only, no auto-raise) | specific-per-stat (auto-raise each to minimum)
WARN: perm-only raises, temp preserved | only worth it with 5+ rank levels or multiple rank-key types
TEST: ✓

## Code

```mushcode
@@ F.RANK.CASCADE(player, new-rank)
@@ On the stat handler object. Reads template from the player's _TEMPLATE attr,
@@ looks up rank minimums from the DD object, and raises each dependent stat
@@ as needed. Returns a change-log string (empty string if no changes needed).

&F.RANK.CASCADE #example_stat=
  [if(
    not(and(t(%0),isnum(%1))),
    #-3 WRONG NUMBER OF ARGUMENTS,
    [setq(0,if(isdbref(%0),%0,pmatch(%0)))]
    [if(
      not(isdbref(%q0)),
      #-1 INVALID PLAYER,
      [setq(1,get(%q0/_EXAMPLE_TEMPLATE))]
      [if(t(%q1),
        @@ Extract line and rank-key from stored template string (line/part1/part2/...)
        [setq(2,extract(%q1,1,1,/))]
        @@ TMPL.RANK.SLOT.<line> stores which position in the template is rank-determining
        [setq(3,default(#example_dd/TMPL.RANK.SLOT.[ucstr(%q2)],2))]
        [setq(4,extract(%q1,%q3,1,/))]
        @@ Look up minimum renown/dependent stats for this rank-key at this rank
        [setq(5,ulocal(#example_dd/F.RANKMIN,%q2,%q4,%1))]
        [if(
          not(strmatch(%q5,#-*)),
          @@ "any|<total>" variant: informational only (no specific distribution required)
          [if(
            eq(extract(%q5,1,1,|),any),
            [setq(6,extract(%q5,2,1,|))]
            [setq(current,add(
              extract(default(%q0/_EXAMPLE_STAT_A,0.0),1,1,.),
              extract(default(%q0/_EXAMPLE_STAT_B,0.0),1,1,.),
              extract(default(%q0/_EXAMPLE_STAT_C,0.0),1,1,.)
            ))]
            [if(lt(%qcurrent,%q6),
              Note: Total dependent stat (%qcurrent) is below minimum (%q6) for Rank %1.,
            )],
            @@ Specific minimums: raise each stat individually
            [setq(minA,extract(%q5,1,1,|))]
            [setq(minB,extract(%q5,2,1,|))]
            [setq(minC,extract(%q5,3,1,|))]
            [setq(log,)]
            [setq(curA,extract(default(%q0/_EXAMPLE_STAT_A,0.0),1,1,.))]
            [if(lt(%qcurA,%qminA),
              [setq(tmp,extract(default(%q0/_EXAMPLE_STAT_A,0.0),2,1,.))]
              [set(%q0,_EXAMPLE_STAT_A:%qminA.%qtmp)]
              [setq(log,%qlogStat-A raised to minimum %qminA.%r)],
            )]
            [setq(curB,extract(default(%q0/_EXAMPLE_STAT_B,0.0),1,1,.))]
            [if(lt(%qcurB,%qminB),
              [setq(tmp,extract(default(%q0/_EXAMPLE_STAT_B,0.0),2,1,.))]
              [set(%q0,_EXAMPLE_STAT_B:%qminB.%qtmp)]
              [setq(log,%qlogStat-B raised to minimum %qminB.%r)],
            )]
            [trim(%qlog)]
          )],
        )]
      ,)]
    )]
  )]

@@ Integration: call cascade from the rank setter, append its output to the response
&F.CMD.SETSTAT #example_stat=
  ... [if(and(eq(lcstr(category),pool),eq(ucstr(statname),RANK)),
    [setq(cascade,ulocal(%!/F.RANK.CASCADE,%0,newvalue))]
    [if(t(%qcascade),%r%qcascade,)],
  )]
```

## Notes

- `TMPL.RANK.SLOT.<line>` on the DD object stores which position (1-based) in the template string is the rank-determining key. This keeps the cascade UDF generic across multiple game lines.
- The "any|total" variant handles cases where the game system allows any combination of dependent stats (e.g., Ragabash in WtA), giving a total minimum rather than per-stat minimums.
- Only permanent values are raised — temporary values are left alone, preserving spend state.
- The cascade returns an empty string if no raises were needed; callers can check `t()` before appending a newline.
- Store rank minimums as `RANKMIN.<line>.<rank-key>.<rank>` attributes on the DD object using pipe-delimited per-stat values.

## Variants

- **Simple linear cascade**: if all rank-keys have the same minimum structure, skip the `TMPL.RANK.SLOT` lookup and use a fixed position.
- **Experience thresholds**: adapt for XP-based systems — check if total XP spent meets the minimum, log a warning but don't auto-spend.

## When NOT to use

- Games where rank advancement is purely narrative with no mechanical dependencies.
- When the minimum table is simple enough to inline — the lookup overhead is only worth it with 5+ rank levels or multiple rank-key types.

## Source

Extracted from: city-of-roses, session 2026-03-29
