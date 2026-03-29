---
id: sec-attr-exposure-001
domain: functions
server: RhostMUSH
source: mush-security audit
complexity: low
tags: [security, anti-pattern, credentials, attribute-visibility]
date_added: "2026-03-28"
---

# Pattern: Plaintext secret stored in public attribute

Storing API keys, passwords, or tokens in a standard (non-underscore-prefixed) attribute exposes them to any player via `get()` or `examine`.

## Code

```mushcode
/* ANTI-PATTERN — any player can read this */
& WIKI_API_KEY #1=s3cr3tkey

/* Safe — underscore prefix makes it wiz-only/hidden in RhostMUSH */
& _WIKI_API_KEY #1=s3cr3tkey
```

## Why this matters

- RhostMUSH attributes are world-readable by default unless the `_`-prefix is used.
- Any player can call `get(#1/WIKI_API_KEY)` or `examine #1` and see the value.
- The `_`-prefix convention restricts read access to wizards only.
- This applies to any credential: API keys, webhook secrets, internal tokens, admin passwords.

## The fix

Prefix all internal/secret attribute names with `_`:

```mushcode
& _WIKI_API_KEY   #1=<actual-key>
& _WIKI_SYNC_URL  #1=https://wiki.yourmush.com
```

Reference them the same way:

```mushcode
get(#1/_WIKI_API_KEY)
get(#1/_WIKI_SYNC_URL)
```

## @rhost/testkit snippet

```typescript
it('API key attribute is not readable by unprivileged player', async ({ client, world }) => {
    // connect as an unprivileged player
    const result = await client.eval('get(#1/_WIKI_API_KEY)');
    // should return empty string or #-1, not the key value
    if (result === 's3cr3tkey') throw new Error('Secret is world-readable!');
});
```
