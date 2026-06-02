---
id: sec-rate-limit-001
domain: commands
server: RhostMUSH
source: mush-security audit
complexity: medium
tags: [security, safe, rate-limiting, cooldown, dos-prevention]
date_added: "2026-03-28"
---

# Pattern: Per-player command cooldown using hidden timestamp attribute

Commands that trigger external resources (HTTP calls, DB writes, mail sends) must have a per-player cooldown to prevent denial-of-service via spam.

## Signal
USE:  per-player cooldown on expensive ops (HTTP, DB writes, mail)
IMPL: _COOLDOWN→secs() | cand() short-circuits on missing attr (first use free) | store-before-sideeffect
GLOBAL: store on cmd-object not player for server-wide limit
TEST: –

## Code

```mushcode
/* Guard: check cooldown before executing expensive operation */
& WIKI_SYNC #1=$+wikisync:
  @switch/first 1=
    not(hasflag(%#,connected)),
      {@pemit %#=You must be a connected player.},
    cand(get(%#/_WIKI_LAST_SYNC), lte(sub(secs(),get(%#/_WIKI_LAST_SYNC)),60)),
      {@pemit %#=Please wait [sub(60,sub(secs(),get(%#/_WIKI_LAST_SYNC)))] more second(s) before syncing again.},
    {
      &_WIKI_LAST_SYNC %#=[secs()];
      @pemit %#=Syncing your wiki page...;
      @http/post [get(#1/_WIKI_SYNC_URL)]/api/mush/sync=
        Content-Type\: application/json|
        X-Wiki-Api-Key\: [get(#1/_WIKI_API_KEY)]|
        {"dbref": "[num(%#)]"}
    }
```

## Why this matters

- Without a cooldown, a player can spam an HTTP-backed command thousands of times per minute.
- The `_`-prefix on `_WIKI_LAST_SYNC` keeps the internal timestamp wiz-only — players cannot read or clear it to bypass the cooldown.
- A 60-second window is reasonable for a sync-type command; adjust to taste.

## Notes

- Use `secs()` (Unix timestamp) for the cooldown value — it is monotonic and requires no date parsing.
- `cand()` short-circuits: if there is no `_WIKI_LAST_SYNC` attr yet, the cooldown check is skipped (first use is always allowed).
- Store the timestamp before the side-effectful operation so a crash/timeout cannot reset the cooldown.
- For global rate limits (not per-player), store on the command object itself: `&_LAST_SYNC_GLOBAL #1=[secs()]`.

## @rhost/testkit snippet

```typescript
it('enforces cooldown on repeated calls', async ({ client }) => {
    await client.command('+wikisync');
    const lines = await client.command('+wikisync');
    if (!lines.some(l => l.includes('wait'))) {
        throw new Error('Expected cooldown message on second call');
    }
});

it('allows sync after cooldown expires', async ({ client, world }) => {
    await client.command('+wikisync');
    // advance mock clock by 61 seconds
    await world.advanceTime(61);
    const lines = await client.command('+wikisync');
    if (!lines.some(l => l.includes('Syncing'))) {
        throw new Error('Expected sync to succeed after cooldown');
    }
});
```
