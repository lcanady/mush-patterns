---
id: sec-stored-injection-bracket-reject-001
domain: functions
server: RhostMUSH
source: mush-security audit
complexity: medium
tags: [security, safe, injection, stored-injection, anti-pattern]
date_added: "2026-03-28"
---

# Pattern: Bracket-rejection guard for user input stored in evaluated attributes

When user-supplied text is written to an attribute that is later retrieved and
evaluated (via `get()` inside `[ ]` brackets, `u()`, or interpolated into a
`@pemit`/`@set` command), any `[func()]` content in the stored value
re-evaluates at read time. Rejecting input that contains `[` or `]` prevents
stored injection.

## Code

```mushcode
# Bracket-rejection using edit() length comparison.
# Does not use [ or ] literally in the pattern itself — safe in any context.
# Returns 1 (inject detected) if the string contains [ or ]
[or(
  gt(strlen(%0), strlen(edit(%0, %[, ))),
  gt(strlen(%0), strlen(edit(%0, %], )))
)]

# --- Applied to a command: reject topic and body before storage ---
&CMD`REQ-ADD <sys>=$+request/create */*=*:
  @break [t([match([get([v(database)]/list`categories)], %0)])]={
    @break [strmatch(%1, [edit(%1, [, %[, ], %])])]={
      @pemit %#=Requests may not contain [ characters in the topic.
    };
    @break [strmatch(%2, [edit(%2, [, %[, ], %])])]={
      @pemit %#=Requests may not contain [ characters in the body.
    };
    @eval [u([v(database)]/fn`create-job, %0, %1, %2)]
  };
  @pemit %#=Invalid Category.
```

## Why this matters

- RhostMUSH evaluates `[ ]` contents whenever a string containing them is
  passed through `pemit`, `@set`, `u()`, or stored into an attribute that is
  later retrieved inside evaluation brackets.
- `FN`SHOWJOB` displays job contents via `[get(%0/desc)]`. If a player stored
  `[cemit(staff=PWNED)]` in the job body or title, it executes every time any
  staff member views that job.
- This is a stored injection: low privilege input writes code that later runs
  at the privilege of the reader (potentially wizard).

## The fix

Two approaches:

1. **Bracket-rejection** (used here): reject any input containing `[` or `]`
   before storage. Simple, catches all injection. Users cannot type brackets in
   job fields.

2. **escape() on storage**: call `escape(%0)` before writing to the attribute.
   `escape()` converts `[` → `%[` preventing re-evaluation. Allows brackets as
   displayed content but requires every read path to handle escaped text.

The bracket-rejection approach is preferred when brackets have no legitimate use
in the input (job titles, request bodies). Use `escape()` when brackets must be
preserved as display text.

## Anti-pattern

```mushcode
# ANTI-PATTERN: stores user input directly into desc; fn`showjob does
# [get(%0/desc)] inside an evaluation context — injection executes on view.
&CMD`RENAME <sys>=$+job/rename *=*:@break [u([v(database)]/bool`is-staff)]={
  ...
  @eval [set(%qj, JName:%1)]   # %1 stored raw — [cemit(staff=EVIL)] works
```

## @rhost/testkit snippet

```typescript
it('bracket in job title is rejected before storage', async ({ client }) => {
    const lines = await client.command('+job/rename 1=[cemit(staff=INJECTED)]');
    const output = lines.join(' ');
    if (output.includes('Job Name to')) {
        throw new Error('Bracket injection was accepted into job title');
    }
    if (!output.toLowerCase().includes('bracket') && !output.toLowerCase().includes('[')) {
        throw new Error(`Expected rejection message, got: ${output}`);
    }
});

it('bracket in request body is rejected before storage', async ({ client }) => {
    const lines = await client.command('+request/create APP/test=[pemit(%#=INJECTED)]');
    const output = lines.join(' ');
    if (output.includes('created')) {
        throw new Error('Bracket injection was accepted into request body');
    }
});
```
