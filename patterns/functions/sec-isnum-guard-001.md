---
id: sec-isnum-guard-001
domain: functions
server: RhostMUSH
source: mush-security audit
complexity: low
tags: [security, safe, input-validation, isnum, numeric-guard]
date_added: "2026-03-28"
---

# Pattern: isnum() pre-guard for commands that expect a job/record number

Commands that take a numeric ID (job number, request number, etc.) must validate
the input with `isnum()` or `isint()` before passing it to `fn`get-job` or any
other lookup. Skipping this allows string input to reach `num()` or object name
lookups, which can produce confusing errors or unexpected matches.

## Code

```mushcode
# Safe: isnum() check before lookup
&CMD`VIEW-REQ <sys>=$+request *:
  @break [isnum(%0)]={
    @skip/ifelse [t([setr(0, [u([v(database)]/fn`get-job, %0)])])]={
      @break [strmatch(%#, [get(%q0/requester)])]={
        @eval [u([v(database)]/fn`showjob, %q0)]
      };
      @pemit %#=That request isn't yours.
    },
    @pemit %#=Invalid Request.
  };
  @pemit %#=Request must be a number.

# fn`get-job: expects a number; num(Job <N>) returns the dbref
&FN`GET-JOB <db>=[num(Job %0)]
```

## Why this matters

- `fn`get-job` calls `num(Job %0)`. If `%0` is a non-numeric string like
  `anything`, the lookup becomes `num(Job anything)`, which may match an
  unexpectedly named object or produce a confusing error.
- Without the isnum() guard, a player could pass a crafted string to probe the
  object namespace or trigger error paths that leak information.
- The isnum() guard short-circuits before any lookup runs, giving a clean user
  message and preventing unexpected code paths.

## Note on staff commands

Staff-side `+job *` commands (CMD`VIEW-JOB) that take numeric IDs benefit from
the same guard. In the original Rockpath's Jobs System, the player-side commands
receive isnum() guards in the security patch; the staff-side commands rely on the
`fn`get-job` lookup returning empty on non-numeric input and the `@break [t(...)]`
chain catching the empty result. This is adequate but less explicit than an
isnum() pre-check.

## @rhost/testkit snippet

```typescript
it('rejects non-numeric request number', async ({ client }) => {
    const lines = await client.command('+request notanumber');
    const output = lines.join(' ');
    if (!output.toLowerCase().includes('number')) {
        throw new Error(`Expected number-validation error, got: ${output}`);
    }
});

it('rejects injection attempt in request number field', async ({ client }) => {
    const lines = await client.command('+request [pemit(%#=INJECTED)]');
    const output = lines.join(' ');
    // Should be rejected by isnum() before any lookup runs
    if (output.includes('INJECTED')) {
        throw new Error('Injection in request number field was not caught');
    }
});
```
