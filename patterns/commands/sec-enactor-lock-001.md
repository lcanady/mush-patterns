---
id: sec-enactor-lock-001
domain: commands
server: RhostMUSH
source: mush-security audit 2026-03-28
complexity: low
tags: [security, safe, privilege, lock, wizard]
date_added: "2026-03-28"
tested: true
---

# Pattern: Lock keys must test the enactor (`%#`), not the object (`me`)

When writing wizard-only lock expressions, always use `hasflag(%#,wizard)` — not `hasflag(me,wizard)`. The lock is evaluated against whoever is trying to pass it. A lock that tests `me` (the locked object itself) passes for anyone if the object happens to have the wizard flag.

## Code

```mushcode
# CORRECT: tests the ENACTOR (%#)
@lock #sys=hasflag(%#,wizard)
@lock/use #sys=hasflag(%#,wizard)

# Inside triggers and UDFs — always pass the enactor explicitly
&FN_WIZARD_CHECK #sys= [hasflag(%0,wizard)]
```

## Anti-pattern — what NOT to do

```mushcode
# WRONG: tests the OBJECT (me) — passes for everyone if the object is wizard-flagged
@lock #sys=hasflag(me,wizard)
@lock/use #sys=hasflag(me,wizard)
```

## Why this matters

- RhostMUSH lock expressions are evaluated with the attempting player as context.
- `%#` inside a lock expression refers to the player attempting to pass the lock.
- `me` inside a lock expression refers to the **locked object itself**.
- If `me` (the system object) has the WIZARD flag (common for objects that need `@power`), `hasflag(me,wizard)` returns 1 for **everyone** — the lock is wide open.
- This is a privilege escalation path: any player can trigger wizard-only commands.

## Verification test

```typescript
it('default lock key tests enactor, not object', async ({ expect }) => {
  const key = await expect(`lock(${sys})`);
  if (key.includes('hasflag(me') || key.includes('haspower(me')) {
    throw new Error(`Lock tests the object, not the enactor: ${key}`);
  }
});

it('non-wizard fails use lock', async ({ client, world }) => {
  const mortal = await world.create('LockMortal');
  const passes = await client.eval(`elock(${sys}/use,${mortal})`);
  if (passes !== '0') {
    throw new Error(`UseLock passed for non-wizard — lock expression is wrong`);
  }
});
```
