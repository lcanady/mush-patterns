---
id: sec-noparse-001
domain: commands
server: RhostMUSH
source: mush-security audit (phase2, 2026-03-27)
complexity: low
tags: [security, safe, no_parse, injection-prevention]
date_added: "2026-03-27"
---

# Pattern: Use no_parse on commands that accept freeform text

Commands that take reason/comment fields from users should be flagged `no_parse` in addition to `regex`. This prevents `[func()]` and `%subst` sequences in the user's text from being evaluated at command-trigger time.

## Code

```mushcode
// GOOD — xp/award, xp/unspend, xp/deduct all protect reason fields with no_parse
&c.xp/award [v( d.xpas )]=$^\+?xp/award(.+)$:
    ...
@set v( d.xpas )/c.xp/award=regex
@set v( d.xpas )/c.xp/award=no_parse   // prevents [func()] in reason text

// BAD — inconsistent: these take freeform stat-name input but lack no_parse
@set [v( d.xpas )]/c.xp/cost=regex    // no no_parse
@set [v( d.xpas )]/c.xp/spend=regex   // no no_parse
@set [v( d.xpas )]/c.xp/freebie=regex // no no_parse
```

## Why this matters

- Without `no_parse`, when a player types `xp/spend [delete(me/ATTR)]=3`, the `[delete(me/ATTR)]` is evaluated before the command handler runs — with the player's own permissions.
- This is not a privilege escalation (the player can only do what they could do anyway), but it's surprising behavior and creates an inconsistent security model.
- Commands with `no_parse` receive the literal string `[delete(me/ATTR)]` as input, which is then safely processed as a stat name (and rejected by stat lookup).
- **Rule:** Any command that accepts freeform human text (names, reasons, descriptions) should have `no_parse`. Commands that only accept structured input (dbrefs, numbers) can omit it.

## @rhost/testkit snippet

```typescript
it('no_parse prevents function evaluation in reason', async ({ client, wizard }) => {
    // Attempt to embed a function call in the reason field
    // With no_parse, the [secs()] literal string is stored, not the timestamp
    await wizard.command('+xp/award TestPlayer=5 beats for test [secs()]');
    const log = await wizard.eval('u(v(d.xpas)/sql.select.type-character,...)');
    // reason in DB should be literal "test [secs()]", not "test 1234567890"
    expect(log).toContain('[secs()]');
});
```
