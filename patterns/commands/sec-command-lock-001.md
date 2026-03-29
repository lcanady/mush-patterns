---
id: sec-command-lock-001
domain: commands
server: RhostMUSH
source: mush-security audit
complexity: low
tags: [security, anti-pattern, lock, access-control]
date_added: "2026-03-28"
---

# Pattern: Command with no access lock

A `$+cmd:` pattern with no `@lock/use` can be triggered by any object on the MUSH — puppets, robots, zone objects, or players using `@force`. This bypasses any implied "this is a player command" assumption.

## Code

```mushcode
/* ANTI-PATTERN — any object can trigger this */
& WIKI_SYNC #1=$+wikisync:
  @pemit %#=Syncing your wiki page...;
  @http/post [get(#1/WIKI_SYNC_URL)]/api/mush/sync=
    Content-Type\: application/json|
    {"dbref": "[num(%#)]"}

/* Safe — restricted to connected players */
& WIKI_SYNC #1=$+wikisync:
  @switch/first 1=
    not(hasflag(%#,connected)), {@pemit %#=You must be a connected player.},
    {
      @pemit %#=Syncing your wiki page...;
      @http/post [get(#1/_WIKI_SYNC_URL)]/api/mush/sync=
        Content-Type\: application/json|
        X-Wiki-Api-Key\: [get(#1/_WIKI_API_KEY)]|
        {"dbref": "[num(%#)]"}
    }
```

## Why this matters

- Without a lock, a wizard can `@trigger` or `@force` the command with any enactor, including non-players.
- The command makes an outbound HTTP request. An unlocked command creates a denial-of-service vector against the external API.
- `num(%#)` in the request body depends on the enactor being a valid player; a non-player enactor can produce `#-1` or unexpected output.

## The fix

Add a `@lock/use` to the command object, or guard inside the command:

```mushcode
/* Option 1: object-level lock */
@lock/use #1=connected()

/* Option 2: inline guard (preferred — survives @trigger with wrong enactor) */
@switch/first 1=
  not(hasflag(%#,connected)), {@pemit %#=You must be a connected player.},
  { ... the real logic ... }
```

Prefer the inline guard because it fires even when the object-level lock is misconfigured or bypassed.

## @rhost/testkit snippet

```typescript
it('rejects non-player enactor', async ({ world, client }) => {
    const puppet = await world.create('TestPuppet');
    // @trigger from a non-connected object should produce an error, not a sync
    const lines = await client.command(`@trigger ${puppet}=WIKI_SYNC`);
    if (lines.some(l => l.includes('Syncing'))) {
        throw new Error('Command accepted non-player enactor');
    }
});

it('accepts connected player', async ({ client }) => {
    const lines = await client.command('+wikisync');
    if (!lines.some(l => l.includes('Syncing'))) {
        throw new Error('Expected sync confirmation');
    }
});
```
