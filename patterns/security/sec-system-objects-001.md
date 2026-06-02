---
id: sec-system-objects-001
domain: systems
server: RhostMUSH
source: mush-security audit (GMCCG Phase 1 migration, 2026-03-27)
complexity: low
tags: [security, safe, lock, system-objects]
date_added: "2026-03-27"
---

# Pattern: Lock system objects (DD, SFP, etc.) against non-wizard access

All central system objects (`Data Dictionary`, `Stat Functions Prototype`, etc.)
must have explicit `@lock` and `@lock/use` set to wizard-only, even if they
carry the `INHERIT SAFE` flags.

## Code

```mushcode
@create My System Object <mso>
@set My System Object <mso>=inherit safe
@lock My System Object <mso>=haspower(me,Wizard)
@lock/use My System Object <mso>=haspower(me,Wizard)
```

## Why this matters

- `INHERIT` gives the object wizard-level powers — an uncontrolled trigger on
  it would execute with those powers.
- `SAFE` only prevents accidental `@destroy` — it does nothing to gate
  `$`-command execution.
- Without an explicit `@lock/use`, any player triggering a `$`-command on the
  object (if one were ever added) would succeed.
- `haspower(me,Wizard)` gates both default (force/control) and use locks to
  wizard-tier only.

## Anti-pattern

```mushcode
@@ WRONG — INHERIT alone is not enough
@create My System Object <mso>
@set My System Object <mso>=inherit safe
@@ No @lock — UseLock is open by default
```

## @rhost/testkit snippet

```typescript
r.test("DD UseLock rejects non-wizard", async () => {
  // mortal character attempts to use the DD object
  const out = await r.asCharacter(mortalDbref, `use ${ddDbref}`);
  r.expect(out).toContain("Permission denied");
});
```
