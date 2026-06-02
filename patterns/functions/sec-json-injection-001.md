---
id: sec-json-injection-001
domain: functions
server: RhostMUSH
source: mush-security audit
complexity: medium
tags: [security, anti-pattern, injection, json, http]
date_added: "2026-03-28"
---

# Pattern: User-controlled value interpolated into hand-assembled JSON

Building a JSON body by string concatenation without validation creates an injection path. Even "safe" values like `num(%#)` can produce unexpected output and the pattern is one refactor away from a critical injection bug.

## Signal
TYPE: anti-pattern | fix
RISK: num(%#)→#-1 for non-players | user-string→JSON injection on future edits
FIX:  isnum(num(%#))??abort | strip ["\] from user input before JSON embed
RULE: JSON body→server-controlled values only (dbrefs, timestamps, trusted attrs)
TEST: –

## Code

```mushcode
/* ANTI-PATTERN — num(%#) unchecked, hand-assembled JSON */
@http/post [get(#1/WIKI_SYNC_URL)]/api/mush/sync=
  Content-Type\: application/json|
  {"dbref": "[num(%#)]"}

/* Safer — validate before interpolation */
@switch/first 1=
  not(isnum(num(%#))), {@pemit %#=Error: could not determine your dbref.},
  {
    @http/post [get(#1/_WIKI_SYNC_URL)]/api/mush/sync=
      Content-Type\: application/json|
      X-Wiki-Api-Key\: [get(#1/_WIKI_API_KEY)]|
      {"dbref": "[num(%#)]"}
  }
```

## Why this matters

- `num(%#)` returns `#-1` for non-player enactors. Without a guard, `{"dbref": "#-1"}` is sent to the external API, which may cause unexpected behavior or error leakage.
- Hand-assembled JSON means any future addition of a user-supplied field (e.g., a custom message) becomes an injection vector immediately unless the pattern is already defensive.
- Attacker could potentially break out of the JSON value and inject additional fields if a user-controlled string is ever added without escaping.

## The fix

1. Always validate `num(%#)` with `isnum()` before use.
2. Never interpolate `%0`–`%9` or `%+` directly into JSON without stripping `[`, `]`, `"`, and `\`.
3. Keep the JSON body to server-controlled values only (dbrefs, timestamps, attribute values from trusted objects).

### Safe sanitizer for user strings in JSON context

```mushcode
/* strip chars that break JSON string values */
[edit(edit(edit(%0,\,\\\\),",\"),
          %r,\n)]
```

## @rhost/testkit snippet

```typescript
it('does not send #-1 dbref when triggered by non-player', async ({ world, client }) => {
    // Monitor outbound HTTP calls in test mode; ensure no call is made with dbref=#-1
    const puppet = await world.create('TestPuppet');
    await client.command(`@trigger ${puppet}=WIKI_SYNC`);
    // if the guard works, no HTTP request should have fired
    // (testkit HTTP mock will record calls)
    const calls = await world.httpMock.calls('/api/mush/sync');
    if (calls.some(c => c.body.includes('#-1'))) {
        throw new Error('Sent invalid dbref to wiki API');
    }
});
```
