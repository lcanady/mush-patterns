---
id: sec-dual-wizard-guard-001
domain: commands
server: RhostMUSH
source: mush-security audit 2026-03-28
complexity: medium
tags: [security, safe, privilege, wizard, trigger]
date_added: "2026-03-28"
tested: true
---

# Pattern: Dual-layer wizard guard — command and trigger

When a `$command` handler delegates work to a `TR_*` trigger attribute, both the command and the trigger must independently verify the enactor's wizard flag. The `@lock/use` blocks direct command access, but `@trigger` bypasses the use lock — the trigger must re-check.

## Code

```mushcode
# Layer 1: $command handler — uses @lock/use AND explicit hasflag check
&CMD_LOAD #sys=$+load *:
  @switch/first 1=
    [not(hasflag(%#,wizard))], {
      @pemit %#=Permission denied.
    },
    [not(%0)], {
      @pemit %#=Usage: +load <file.mush>
    },
    {
      @trigger #sys/TR_EXEC_LOAD=%0,%#
    }

# Layer 2: trigger target — re-checks wizard flag because @trigger bypasses use lock
# %1 = dbref of original enactor (passed explicitly by the command handler)
&TR_EXEC_LOAD #sys=
  @switch/first 1=
    [not(u(#sys/FN_WIZARD_CHECK,%1))], {
      @pemit %1=Permission denied.
    },
    {
      ... actual work here ...
    }

# UDF used in triggers (accepts dbref, not implicit %#)
&FN_WIZARD_CHECK #sys= [hasflag(%0,wizard)]
```

## Why this matters

- `@lock/use` on an object prevents direct `$command` matches from running for non-wizards, but it does NOT block `@trigger`.
- Any player who can reach the object (or any code that runs `@trigger obj/TR_EXEC_LOAD=...`) bypasses the use lock entirely.
- Without a re-check in `TR_EXEC_LOAD`, a mortal can call `@trigger #sys/TR_EXEC_LOAD=/etc/passwd,#42` and the trigger executes with no guard.
- The trigger re-check accepts the enactor dbref as an explicit argument (`%1`) because `%#` inside a triggered attribute is the object that ran the trigger, not the original command sender.

## Attack scenario blocked

```
# Without the re-check in TR_EXEC_LOAD:
@trigger #MushLoader <sys>/TR_EXEC_LOAD=/etc/passwd,#1
# → executes load with no permission check
```

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

it('non-wizard cannot trigger commands via use lock', async ({ client, world }) => {
  const mortal = await world.create('LockTestMortal');
  const passes = await client.eval(`elock(${loader}/use,${mortal})`);
  if (passes !== '0') {
    throw new Error(`UseLock passed for non-wizard — lock key is wrong`);
  }
});
```
