---
id: cmd-switch-pattern-001
domain: commands
server: RhostMUSH
source: rhost-testkit examples
complexity: medium
tags: [command, switch, dispatch, pattern]
date_added: "2026-03-27"
tested: false
---

# Pattern: Switch-dispatched command

Use a `$+cmd[/<switch>] <args>:` pattern to handle multiple sub-commands from a single command object. Dispatch via `switch()` or separate `$` patterns per switch.

## Signal
USE:  route +cmd/switch to separate attribute handlers
PREFER: separate-patterns>single-switch (scale, per-attr @lock)
RULE: @switch/first not @switch | always add fallback case | %0..%1 from $ wildcards
TEST: ✗

## Code — single dispatcher

```mushcode
@create Sys <commands>
@set Sys <commands>=inherit safe

&CMD_VOTE Sys <commands>=$+vote*:
  @switch/first %0=
    /list, @pemit %#=Vote list: ...,
    /set *, @pemit %#=Vote set: %1,
    /clear, @pemit %#=Votes cleared.,
    @pemit %#=Unknown switch. Try +vote/list, +vote/set, +vote/clear.
```

## Code — separate patterns (cleaner for complex logic)

```mushcode
&CMD_VOTE_LIST    Sys=$+vote/list:    @pemit %#=Vote list: ...
&CMD_VOTE_SET     Sys=$+vote/set *=*: @pemit %#=Vote on %0 set to %1.
&CMD_VOTE_CLEAR   Sys=$+vote/clear:   @pemit %#=Votes cleared.
```

## Notes

- Separate patterns scale better than one big `switch()` — each attr can have its own `@lock`.
- Use `@switch/first` (not `@switch`) if cases might overlap.
- `%0`, `%1` etc. are set from the pattern wildcards `*`.
- Always provide a fallback case for unknown switches.
- Lock the object: `@set <obj>=safe` prevents accidental `@destroy`.

## @rhost/testkit snippet

```typescript
it('+vote/list works', async ({ client }) => {
    const lines = await client.command('+vote/list');
    if (!lines.length) throw new Error('Expected output from +vote/list');
});

it('+vote/set records a vote', async ({ client, world }) => {
    const obj = await world.create('VoteTarget');
    const lines = await client.command(`+vote/set ${obj}=yes`);
    if (!lines.some(l => l.includes('set'))) throw new Error('Expected confirmation');
});
```
