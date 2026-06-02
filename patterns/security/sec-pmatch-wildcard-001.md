---
id: sec-pmatch-wildcard-001
domain: functions
server: RhostMUSH
source: mush-security audit (GMCCG Phase 1 migration, 2026-03-27)
complexity: low
tags: [security, anti-pattern, information-disclosure, pmatch]
date_added: "2026-03-27"
---

# Pattern: Wildcard in search() fallback returns unintended player

When a player-lookup function falls back to `search()` for offline players,
an empty or `*`-only name argument will match ALL players. The `first()` call
makes this silently return an arbitrary player dbref.

## Code (anti-pattern)

```mushcode
@@ RISKY — empty %0 makes %0* = '*', matching all players
&.pmatch obj=
  localize( strcat(
    setq( p, if( strmatch(%0,me), %#, objeval(%#, pmatch(%0)))),
    if( cor( t(%qp), not(t(%1))),
      %qp,
      first( search( eplayer=strmatch( name(##), %0* )))
    )
  ))
```

## Why this matters

- If `%0` is empty, `%0*` expands to `*`, which matches all player names.
- `first()` on that result returns the lowest-dbref player — typically an
  admin character.
- Any code that then operates on that dbref as the "target player" may
  perform actions on the wrong character.

## Fix

Guard against empty input before the search fallback:

```mushcode
&.pmatch obj=
  localize( strcat(
    setq( p, if( strmatch(%0,me), %#, objeval(%#, pmatch(%0)))),
    if( cor( t(%qp), not(t(%1))),
      %qp,
      if( not(t(%0)),
        #-1 No player name given,
        first( search( eplayer=strmatch( name(##), %0* )))
      )
    )
  ))
```

## @rhost/testkit snippet

```typescript
r.test(".pmatch with empty arg returns error, not a player dbref", async () => {
  const out = await r.eval(`u(v(d.sfp)/.pmatch,)`);
  r.expect(out).toBe("#-1 No player name given");
});
```
