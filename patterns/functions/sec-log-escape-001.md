---
id: sec-log-escape-001
domain: functions
server: RhostMUSH
source: mush-security audit
complexity: low
tags: [security, safe, log-poisoning, escape, stored-injection]
date_added: "2026-03-28"
---

# Pattern: Escape log entries before storage to prevent re-evaluation

When a log is stored as an attribute and later displayed with `iter()` or
`get()`+`@pemit`, any unescaped `[func()]` content in the stored value will
re-evaluate at display time. Use `escape()` on every user-controlled or
externally-sourced value before appending it to the log.

## Code

```mushcode
# FN_LOG: append a timestamped entry to MLOAD_LOG
# Log entries are escape()'d before storage to prevent re-evaluation on display.
# %0 = message (caller should already have escape()'d user-facing strings)
&FN_LOG <sys>=
  [setq(0, strcat(convsecs(secs()), %b, escape(%0)))]
  [set(<sys>, MLOAD_LOG:
    [if(get(<sys>/MLOAD_LOG),
      trim(strcat(get(<sys>/MLOAD_LOG), |, %q0)),
      %q0
    )]
  )]

# Display — iter splits on | and @pemit each entry.
# Because entries were stored with escape(), they display as literal text.
&CMD_LOG <sys>=$+log:
  @pemit %#=[iter(get(<sys>/MLOAD_LOG), %i0, |, %r)]
```

## Why this matters

- Without `escape()`, a filename like `[pemit(#1,INJECTED)]` gets stored
  verbatim in `MLOAD_LOG`. When `+log` iterates and `@pemit`s the log, that
  function call re-evaluates and the injection executes.
- This is a stored-injection (Medium severity): the attacker doesn't see
  immediate output, but code runs the next time any wizard views the log.
- `escape()` converts `[` → `%[` and `]` → `%]`, making the stored string
  display as the literal text the user typed.

## Caller pattern

Callers should `escape()` user-supplied values before passing to FN_LOG:

```mushcode
@trigger <sys>/TR_LOG=Loaded [escape(%q9)] by [name(%1)]
```

The double escape (caller escapes %q9, FN_LOG escapes the whole message) is
safe — a double-escaped string displays with one level of brackets, which is the
desired literal output.

## @rhost/testkit snippet

```typescript
it('log entries with mushcode are stored escaped and do not execute on display', async ({ client }) => {
    await client.command(`@trigger ${loader}/FN_LOG=[pemit(#1=POISON)]`);
    const lines = await client.command('+log');
    const output = lines.join(' ');
    if (output.includes('POISON') && !output.includes('[pemit')) {
        throw new Error('Log entry was evaluated rather than displayed as literal text');
    }
});
```
