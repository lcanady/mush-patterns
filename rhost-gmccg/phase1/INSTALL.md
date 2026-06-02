# GMCCG Phase 1 — RhostMUSH Install Guide

## Prerequisites

- RhostMUSH server running
- A `Code Object Data Parent <codp>` object already created; its dbref stored as `&d.codp` on your installer character
- Wizard or Immortal bit on the installing character

## Install order

Upload and execute in this exact order:

```
1. 1a-data-dictionary-setup.mu   — creates Data Dictionary <dd> and Data Tags <d:t>
2. 1b-core.mu                    — core CoD stats (attributes, skills, merits, advantages)
3. 1c-tags.mu                    — tag data for all core stats
4. 2a-sfp-setup.mu               — creates Stat Functions Prototype <sfp>
5. 2b source directly            — Statpath Functions (no changes from source)
6. 2c source directly            — Support Functions (no changes from source)
7. 2d-udf-registration.mu        — UDF registration + @startup
```

Files `2b` and `2c` from the original GMCCG source are fully compatible with
RhostMUSH and can be uploaded without modification.

After installing 2d, trigger the startup:

```mushcode
@tr v(d.sfp)=startup:
```

Verify UDFs registered:

```mushcode
think statpath(strength)
```

Should return `attribute.strength`.

## What changed from source

| File | Change |
|------|--------|
| 2d | `@function/preserve/privileged` → `@function/preserve/privilege` |
| Everything else | No changes |

## Running tests

```bash
cd /path/to/rhost-gmccg/phase1/tests
npx @rhost/testkit phase1.test.ts
```

All 8 suites (34 tests) must pass before proceeding to Phase 2.
