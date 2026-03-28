---
id: sec-stored-injection-001
domain: commands
server: RhostMUSH
source: mush-security audit
complexity: medium
tags: [security, anti-pattern, injection, stored-xss]
date_added: "2026-03-28"
---

# Pattern: Stored injection via unsanitized attribute write

User-supplied text written to a DB attribute without bracket-stripping will
re-evaluate every time another function reads and interpolates that attribute.
This is the MU* equivalent of stored XSS — the injection fires later, not at
input time.

## Code

```mushcode
@@ VULNERABLE — %1 stored verbatim; re-evaluates on get()
&CMD`RENAME SomeObj=$+cmd/rename *=*:
  @break [isnum(%0)]={
    @eval [set(%q0, name:%1)];
    @pemit %#=Renamed to '%1'.
  }

@@ Later, a display function does:
&FN`SHOW SomeObj=[get(%0/name)]    @@ brackets in name re-evaluate here
```

## Why this matters

- RhostMUSH evaluates `[...]` sequences inside `get()` interpolation whenever
  the result is placed inside another `[...]` context.
- A staff member types `+cmd/rename 3=[pemit(%#,HACKED)]` — the string is
  stored. Every subsequent `[get(%q0/name)]` call in display functions emits
  "HACKED" to the viewer.
- With `!INHERIT` on the command object, injected code runs at player-privilege.
  With `INHERIT`, it runs at wizard-privilege.
- The fix must happen at write time — stripping before storage prevents all
  future evaluation paths.

## The fix

Use the bracket-rejection guard from `sec-bracket-guard-001.md` before any
`set()` or `&attr` write that accepts user-supplied text:

```mushcode
&CMD`RENAME SomeObj=$+cmd/rename *=*:
  @break [isnum(%0)]={
    @break [strmatch(%1, [edit(%1, [, %[, ], %])])]={
      @pemit %#=Names may not contain [ characters.
    };
    @eval [set(%q0, name:%1)];
    @pemit %#=Renamed to '%1'.
  }
```

## Affected RockJobs commands (found in audit 2026-03-28)

- `CMD\`RENAME` — `%1` stored in `JName` (M-RJ-01)
- `CMD\`COMMENT` — `%1` appended to `desc` (M-RJ-02)
- Staff-only access limits blast radius, but stored values re-evaluate
  in `fn\`showjob`, `fn\`approve-job`, `fn\`deny-job` subject lines, etc.

## @rhost/testkit snippet

```typescript
it('rejects brackets in rename arg', async ({ expect }) => {
    // Set hook to write to temp attr so we can detect execution
    await client.eval(`&_HACK ${sys}=0`);
    // Try to inject via rename
    await client.command(`+job/rename 1=[set(${sys},_HACK:1)]`);
    // Verify injection did not execute (attr still 0)
    await expect(`get(${sys}/_HACK)`).toBe('0');
    // Verify command was rejected
    // (check name was not changed to empty/injected value)
});
```
