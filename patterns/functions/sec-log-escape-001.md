---
id: sec-log-escape-001
domain: functions
server: RhostMUSH
source: mush-security audit 2026-03-28
complexity: low
tags: [security, safe, injection, log-poisoning, escape]
date_added: "2026-03-28"
tested: true
---

# Pattern: `escape()` before storing log entries to prevent log poisoning

Apply `escape()` to any user-controlled or external string before appending it to a stored log attribute. Stored MUSH attributes re-evaluate their content when `get()` or `u()` is called; without escaping, a stored `[pemit(%#=INJECTED)]` executes on display.

## Code

```mushcode
# Safe: escape() applied before storage — stored as literal, not live code
&FN_LOG #sys=
  [setq(0, strcat(convsecs(secs()), %b, escape(%0)))]
  [set(#sys, MLOAD_LOG:
    [if(get(#sys/MLOAD_LOG),
      trim(strcat(get(#sys/MLOAD_LOG), |, %q0)),
      %q0
    )]
  )]

# Display: iter() returns the escaped literals; @pemit renders them as text
&CMD_LOG #sys=$+log:
  @pemit %#=[iter(get(#sys/MLOAD_LOG), %i0, |, %r)]
```

## Anti-pattern — what NOT to do

```mushcode
# DANGEROUS: no escape() — stored mushcode re-evaluates on display
&FN_LOG_BAD #sys=
  [set(#sys, LOG:[get(#sys/LOG)]|[strcat(convsecs(secs()), %b, %0)])]
#
# If %0 = "[pemit(#1=INJECT)]"
# Then LOG contains: ... |12345 [pemit(#1=INJECT)]
# On display via get()/u(): [pemit(#1=INJECT)] EXECUTES
```

## Why this matters

- Any string sourced from user input, an external process (`execscript`), or an AI response is untrusted.
- `get()` and `u()` on an attribute re-evaluate its content in MUSHcode context.
- Without `escape()`, a log entry containing `[pemit(#1=INJECTED)]` will execute `@pemit` when the log is displayed.
- `escape()` prepends `\` to evaluation characters (`[`, `]`, `;`, `{`, `}`, `%`) so they display literally.

## @rhost/testkit snippet

```typescript
it('log entry with mushcode is stored escaped and not evaluated on display', async ({ client }) => {
  await client.command(`@trigger ${loader}/FN_LOG=[pemit(#1=POISON)]`);
  const lines = await client.command('+log');
  const output = lines.join(' ');
  // Literal [pemit text should appear, not have triggered a pemit to #1
  if (output.includes('POISON') && !output.includes('[pemit')) {
    throw new Error('Log entry was evaluated rather than displayed as literal text');
  }
});
```
