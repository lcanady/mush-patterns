---
id: sec-trigger-wizard-recheck-001
domain: functions
server: RhostMUSH
source: mush-security audit
complexity: low
tags: [security, safe, privilege, trigger, wizard-check]
date_added: "2026-03-28"
---

# Pattern: Re-check wizard flag inside @trigger targets

`@trigger` bypasses the `@lock/use` on the source object, so a trigger
target that assumes its caller already passed the use lock is vulnerable to
privilege escalation. The fix is a FN_WIZARD_CHECK call at the top of every
trigger that performs privileged work.

## Code

```mushcode
# FN_WIZARD_CHECK: returns 1 if enactor is wizard, 0 otherwise
# Call this at the top of every TR_* attribute that performs privileged work.
# %0 = the dbref of the player who initiated the chain (passed via @trigger)
&FN_WIZARD_CHECK <sys>=
  [hasflag(%0, wizard)]

# --- Safe trigger target ---
&TR_EXEC_LOAD <sys>=
  @switch/first 1=
    [not(u(<sys>/FN_WIZARD_CHECK, %#))], {
      @pemit %1=Permission denied.
    },
    [not(get(<sys>/MLOAD_INSTALL_PATH))], {
      @pemit %1=Error: MLOAD_INSTALL_PATH not set.
    },
    {
      # ... real work here ...
    }
```

## Why this matters

- In RhostMUSH, `@trigger <obj>/<attr>=arg1,arg2` calls the attribute directly
  and passes the triggering enactor as `%#`. It does NOT check `@lock/use`.
- A non-wizard could call `@trigger <sys>/TR_EXEC_LOAD=<path>,#1` if the
  object's use lock only gates `$`-commands, not trigger targets.
- The FN_WIZARD_CHECK re-validates `%#` (or the passed-in enactor dbref) inside
  the trigger, closing the gap.

## Anti-pattern (vulnerable)

```mushcode
# ANTI-PATTERN: assumes the @lock/use already filtered the caller
&TR_EXEC_LOAD <sys>=
  @pemit %1=[escape(u(<sys>/FN_EXEC, load, %0))];
  @trigger <sys>/TR_LOG=Loaded by [name(%1)]
```

Any player can call `@trigger <sys>/TR_EXEC_LOAD=<evil>,#1` and the load
executes with wizard-level execscript power because the trigger target has none
of its own access checks.

## @rhost/testkit snippet

```typescript
it('TR_EXEC_LOAD denies non-wizard enactor', async ({ client, world }) => {
    const mortal = await world.create('TestMortal');
    const lines = await client.command(`@trigger ${loader}/TR_EXEC_LOAD=/tmp/test.mush,${mortal}`);
    const output = lines.join(' ');
    if (!output.toLowerCase().includes('permission')) {
        throw new Error(`Expected permission denial, got: ${output}`);
    }
});
```
