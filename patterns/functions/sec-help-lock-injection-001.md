---
id: sec-help-lock-injection-001
domain: functions
server: RhostMUSH
source: mush-security audit
complexity: medium
tags: [security, safe, injection, lock-injection, help-system]
date_added: "2026-03-28"
---

# Pattern: Reject semicolons and brackets from user-supplied lock expressions

A help system that stores wizard-supplied lock expressions as attribute values
must validate those expressions before storage. A semicolon in a lock expression
stored via `& HELPLOCK_X <sys>=<expr>` breaks the `;`-delimited command chain
and injects arbitrary MUSH commands. Brackets allow function-call injection.

## Code

```mushcode
# Fix H1+H2: reject semicolons AND brackets in lock expressions.
# edit()-length comparison detects [ and ] without using them literally.
# match() with *;* detects semicolons without regex.
&TR_HELP_SET_LOCK <sys>=
  @switch/first 1=
    [not(u(<sys>/FN_WIZARD_CHECK,%2))], {
      @pemit %2=Permission denied.
    },
    [or(
      gt(match(%1,*;*),0),
      gt(strlen(%1),strlen(edit(%1,%[,))),
      gt(strlen(%1),strlen(edit(%1,],)))
    )], {
      @pemit %2=Lock expressions may not contain semicolons or brackets.
    },
    {
      [setq(0,u(<sys>/FN_SAFE_TOPIC,%0))]
      [setq(1,u(<sys>/FN_LOCK_ATTR_NAME,%q0))]
      [setq(2,u(<sys>/FN_RESOLVE_LOCK,%1))]
      &%q1 <sys>=%q2;
      @pemit %2=Lock set: %q0 -> %q2
    }
```

## Why this matters

- The lock value is stored with `& HELPLOCK_<topic> <sys>=<expr>`. The
  attribute-set command is `;`-delimited in the trigger chain. A semicolon in
  `%1` splits the command, so `hasflag(%#,wizard);@nuke me` would set the lock
  and then nuke the object in a single trigger evaluation.
- Brackets in the expression allow `[delete(me)]` or `[pemit(#1=PWNED)]` to
  execute at the moment the `&` command is processed.
- Even though `+help/set/lock` is wizard-only, a wizard typo or a compromised
  wizard session could inject commands. Defense in depth applies.
- The `FN_RESOLVE_LOCK` preset map (`public`, `staff`, `royalty`, `wizard`)
  provides safe pre-validated expressions that bypass this risk entirely.

## Anti-pattern

```mushcode
# ANTI-PATTERN: lock expression stored raw
&TR_HELP_SET_LOCK_UNSAFE <sys>=
  &HELPLOCK_[ucstr(%0)] <sys>=%1;   # %1 = "staff;@nuke me" → disaster
  @pemit %2=Lock set.
```

## @rhost/testkit snippet

```typescript
it('rejects semicolons in lock expressions', async ({ client }) => {
    const lines = await client.command('+help/set/lock combat=staff;@nuke me');
    const output = lines.join(' ');
    if (!output.includes('semicolon') && !output.includes('bracket')) {
        throw new Error(`Expected rejection, got: ${output}`);
    }
});

it('accepts valid preset lock', async ({ client }) => {
    const lines = await client.command('+help/set/lock combat=staff');
    if (!lines.some(l => l.includes('Lock set'))) {
        throw new Error('Expected lock-set confirmation');
    }
});

it('accepts valid freeform lock expression without special chars', async ({ client }) => {
    const lines = await client.command('+help/set/lock combat=hasflag(%#,wizard)');
    if (!lines.some(l => l.includes('Lock set'))) {
        throw new Error('Expected lock-set confirmation');
    }
});
```
