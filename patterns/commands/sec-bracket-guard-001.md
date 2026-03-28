---
id: sec-bracket-guard-001
domain: commands
server: RhostMUSH
source: mush-security audit
complexity: low
tags: [security, safe, injection, guard]
date_added: "2026-03-28"
---

# Pattern: Bracket-rejection guard for user-supplied free text

Reject any input that contains `[` or `]` before writing it to storage or
forwarding it to functions that may interpolate it. This is the standard
injection guard for RhostMUSH free-text fields (job topics, comments, names).

## RhostMUSH @break semantics (critical)

`@break <cond>={action}` — if condition is **falsy (0)**, execute `action` and halt.
If condition is truthy, continue past to the next statement (do not break).

This means `{action}` is the **error/rejection handler**, not the success path.

## Code

```mushcode
@@ Safe — reject input containing brackets before any write
@break [strmatch(%1, [edit(%1, [, %[, ], %])])]={
  @pemit %#=Input may not contain [ characters.
};
@@ Only reaches here if no brackets present — safe to write
@eval [set(%q0, body:%1)];
@pemit %#=Saved.
```

## How it works

1. `edit(%1, [, %[, ], %])` — replaces every `[` with `%[` and `]` with `%]`
2. `strmatch(%1, <result>)` — returns 1 if identical (no brackets in `%1`),
   0 if different (brackets were present and got replaced)
3. `@break [strmatch(...)]={@pemit error}` —
   - strmatch=1 (truthy, no brackets): `@break` does NOT fire → continues to write ✓
   - strmatch=0 (falsy, brackets present): `@break` fires the pemit rejection and halts ✓

## Important caveat

In RhostMUSH, `%1` is evaluated by the server **before** the command body runs.
So `[evil()]` in user input executes at the point the server parses the command
argument — the bracket guard cannot prevent that initial evaluation. What it
prevents is:

- Storing bracket-containing strings in DB attributes (preventing stored injection)
- Passing them to functions like `fn\`create-job` (preventing downstream re-evaluation)

Remove `INHERIT` from command-dispatch objects so that any unavoidable initial
evaluation runs at player-privilege, not wizard-privilege.

## Full example from RockJobs security.mush

```mushcode
&CMD`REQ-ADD Rockpath's Jobs System=$+request/create */*=*:
  @break [t([match([get([v(database)]/list`categories)], %0)])]={
    @break [strmatch(%1, [edit(%1, [, %[, ], %])])]={
      @pemit %#=Requests may not contain [ characters in the topic.
    };
    @break [strmatch(%2, [edit(%2, [, %[, ], %])])]={
      @pemit %#=Requests may not contain [ characters in the body.
    };
    @eval [u([v(database)]/fn`create-job, %0, %1, %2)];
    @pemit %#=You have created a new Request.
  };
  @pemit %#=Invalid Category.
```

## @rhost/testkit snippet

```typescript
it('allows clean input through', async ({ expect }) => {
    await client.command('+request/create APP/Test=Clean body text');
    // request created — list shows it
    await expect('lcon(rjdb/object)').not.toBe('');
});

it('rejects bracket input in topic', async ({ expect }) => {
    // capture output — should see rejection message
    // bracket input should NOT create a job
    const before = await client.eval('v(rjdb/count)');
    await client.command('+request/create APP/[evil()]=body');
    const after = await client.eval('v(rjdb/count)');
    // count unchanged = no job created
    expect(after).toBe(before);
});
```
