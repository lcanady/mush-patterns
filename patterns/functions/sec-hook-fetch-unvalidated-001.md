---
id: sec-hook-fetch-unvalidated-001
domain: functions
server: RhostMUSH
source: mush-security audit
complexity: medium
tags: [security, anti-pattern, hook, stored-injection, trust-boundary]
date_added: "2026-03-28"
---

# Pattern: HOOK_FETCH return value stored without bracket sanitization

When a help system calls an external hook (`HOOK_FETCH`) on cache miss and
stores the returned text directly as attribute content, any brackets in the
hook's return value become a stored injection vector if that text is later
displayed inside an evaluation context.

## Code

```mushcode
# Current code in help-system — HOOK_FETCH return is stored directly:
&FN_GET_HELP <sys>=
  [if(
    u(<sys>/FN_CAN_READ,%1,%0),
    [setq(2,if(get(<sys>/%q7),get(<sys>/%q7),if(hasflag(%1,wizard),get(<sys>/%q8),)))]
    [if(%q2,%q2,
      [setq(3,u(<sys>/HOOK_FETCH,%0))]
      [if(%q3,%q3,)]   ← hook return value passed through for display unvalidated
    )],
  )]

# +help/reload also stores HOOK_FETCH return unescaped:
&TR_HELP_RELOAD <sys>=
  ...
  [setq(2,u(<sys>/HOOK_FETCH,%q0))]
  [if(
    %q2,
    &[u(<sys>/FN_ATTR_NAME,%q0)] <sys>=%q2;  ← stores bracket content verbatim
    @pemit %1=Reloaded from hook: %q0,
    ...
  )]
```

## Why this matters

- `FN_GET_HELP` returns hook text which is then passed to `FN_RENDER_TOPIC`,
  which wraps it in `%r%1%r` and `@pemit`s it. This is a read-time evaluation
  pass — any `[func()]` in the hook text executes at the privilege of the
  help-system object.
- `TR_HELP_RELOAD` (wizard-only) stores hook text as an attribute. Once stored,
  every future reader's `[get()]` call evaluates the brackets.
- The hook stubs ship empty and must be set by the administrator, so the risk
  depends on whether HOOK_FETCH is ever wired to an untrusted external source
  (HTTP API, player-editable wiki, etc.).

## Risk level

- **Low** if HOOK_FETCH is empty (default, as shipped) or wired only to a
  trusted internal source.
- **Medium to High** if HOOK_FETCH is wired to an HTTP endpoint or
  player-editable content.

## Recommended mitigation

Sanitize HOOK_FETCH output before storage and before display:

```mushcode
# Option A: strip brackets before storing (loses legitimate bracket display)
[setq(2, edit(edit(u(<sys>/HOOK_FETCH,%q0),%[,),(],)))]

# Option B: escape brackets on store; display via get() without re-evaluation
[setq(2, escape(u(<sys>/HOOK_FETCH,%q0)))]
&[u(<sys>/FN_ATTR_NAME,%q0)] <sys>=%q2

# On display, use get() outside [ ] brackets (or use a non-eval pemit path)
```

## @rhost/testkit snippet

```typescript
it('HOOK_FETCH bracket content does not execute on help display', async ({ client, world }) => {
    // Wire HOOK_FETCH to return injected content
    await client.command(`&HOOK_FETCH ${helpSys}=[if(1,pemit(%#=INJECTED),)]`);
    const lines = await client.command('+help testinjection');
    const output = lines.join(' ');
    if (output.includes('INJECTED') && !output.includes('[if(')) {
        throw new Error('HOOK_FETCH bracket injection executed on display');
    }
    // Cleanup
    await client.command(`&HOOK_FETCH ${helpSys}=`);
});
```
