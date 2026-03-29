---
id: sec-safe-object-flags-001
domain: commands
server: RhostMUSH
source: mush-security audit
complexity: low
tags: [security, safe, object-flags, safe-flag, inherit, privilege]
date_added: "2026-03-28"
---

# Pattern: SAFE + selective INHERIT for job/command system objects

System objects that hold player-accessible `$`-commands should be flagged
`SAFE` to prevent accidental destruction, but should have `INHERIT` removed
to prevent player-facing command paths from running at wizard privilege.
Objects that only hold trusted internal UDFs (no player `$`-commands) may
retain `INHERIT`.

## Code

```mushcode
# Applied to Rockpath's Jobs System (rockjobs.mush security patch):

@@ M1: SAFE flag prevents accidental @destroy of both system objects
@set Rockpath's Jobs System=safe
@set Rockpath's Job Database=safe

@@ M2: @lock/use on Job Database (INHERIT object must be wizard-only)
@lock/use Rockpath's Job Database=haspower(me,Wizard)

@@ INHERIT removal — Jobs System carries player-accessible $-commands (+request/*)
@@ Removing INHERIT means injection runs at player privilege, not wizard.
@@ Job Database retains INHERIT (fn`create-job, mailsend need wizard power).
@set Rockpath's Jobs System=!inherit
```

## Why this matters

- `INHERIT` causes the object to run softcode at the privilege of its owner
  (usually a wizard). Player-accessible commands like `+request/create` that
  accept free text are an injection surface. If injection succeeds on an INHERIT
  object, it executes at wizard level — Critical severity.
- Removing `INHERIT` from the object that holds player commands limits injection
  damage to player privilege, which is still bad but not game-breaking.
- The `SAFE` flag prevents `@destroy` from silently succeeding — without SAFE,
  a wizard accidentally running `@destroy Rockpath's Jobs System` would delete
  the entire system with no confirmation.
- Objects that only hold trusted internal UDFs (no player `$`-commands) can
  retain INHERIT because players never touch them directly.

## Privilege split pattern

| Object | Player commands | INHERIT | Rationale |
|--------|----------------|---------|-----------|
| Jobs System | Yes (+request/*, +jobs, +job/...) | No | Injection runs at player priv |
| Job Database | No (internal UDFs only) | Yes | mailsend() needs wiz power |

## @rhost/testkit snippet

```typescript
it('Jobs System does not have INHERIT flag', async ({ client, world }) => {
    const sys = await client.eval('search(name=Rockpath\'s Jobs System)');
    const hasInherit = await client.eval(`hasflag(${sys},inherit)`);
    if (hasInherit === '1') {
        throw new Error('Jobs System has INHERIT — player commands run at wizard priv');
    }
});

it('Jobs System has SAFE flag', async ({ client, world }) => {
    const sys = await client.eval('search(name=Rockpath\'s Jobs System)');
    const hasSafe = await client.eval(`hasflag(${sys},safe)`);
    if (hasSafe !== '1') {
        throw new Error('Jobs System is not SAFE — accidental @destroy is possible');
    }
});
```
