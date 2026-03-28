---
id: sec-bracket-reject-strmatch-001
domain: commands
server: RhostMUSH
source: mush-security audit (RockJobs 2026-03-27)
complexity: medium
tags: [security, defense-in-depth, bracket-rejection, strmatch, edit, injection]
date_added: "2026-03-27"
---

# Pattern: Use strmatch/edit to detect and reject inputs containing [ brackets

A command can detect whether player-supplied text contains bracket characters
(`[` / `]`) by comparing the raw input to an escaped copy.  If the strings
differ, brackets were present and the command should abort.  This pattern
does not prevent the injection from executing but prevents bracket-containing
input from being stored or processed further.

## Code

```mushcode
@@ strmatch(%1, edit(%1, [, %[, ], %])) returns:
@@   1  — %1 had no brackets (edit changed nothing; strings match)  → safe
@@   0  — %1 had brackets (edit escaped them; strings differ)       → reject
@@
@@ @break with a TRUTHY condition aborts the command in RhostMUSH.
@@ We @break when the strings DO NOT match (brackets were present).
@break [strmatch(%1, [edit(%1, [, %[, ], %])])]={
  @pemit %#=Requests may not contain [ characters in the topic.
};
@break [strmatch(%2, [edit(%2, [, %[, ], %])])]={
  @pemit %#=Requests may not contain [ characters in the body.
};
@eval [u([v(database)]/fn`create-job, %0, %1, %2)]
```

## Full example: CMD`REQ-ADD with both guards

```mushcode
&CMD`REQ-ADD Rockpath's Jobs System=$+request/create */*=*:
  @break [t([match([get([v(database)]/list`categories)], %0)])]={
    @break [strmatch(%1, [edit(%1, [, %[, ], %])])]={
      @pemit %#=[u([v(database)]/fn`prompt, req)] Requests may not contain [ characters in the topic.
    };
    @break [strmatch(%2, [edit(%2, [, %[, ], %])])]={
      @pemit %#=[u([v(database)]/fn`prompt, req)] Requests may not contain [ characters in the body.
    };
    @eval [u([v(database)]/fn`create-job, %0, %1, %2)];
    @pemit %#=[u([v(database)]/fn`prompt, req)] You have created a new Request under the [ansi(y, [ucstr(%0)])] category.
  };
  @pemit %#=[u([v(database)]/fn`prompt, jobs)] Invalid Category. Please choose from [elist([get([v(database)]/list`categories)], or)].
```

## Why this matters

- Bracket characters (`[` `]`) are the MUSHcode function-call delimiters.
  Any input containing `[...]` will be evaluated by the server when that
  string is later substituted into an evaluation context (e.g., inside
  `fn`create-job`, `mailsend()`, `set()` attribute writes).
- This guard prevents bracket-containing input from ever reaching those
  downstream contexts.
- It is a useful final line of defense **even though the injection already ran
  during the strmatch/edit check itself**.

## Execution-order caveat (important)

```
Player types:  +request/create APP/[pemit #1=INJECTED]=Body
Server sees:   %1 = [pemit #1=INJECTED]

Evaluation order:
  1. Server substitutes %1 → evaluates [pemit #1=INJECTED] → runs pemit
  2. strmatch(result_of_step1, edit(result_of_step1, ...)) is evaluated
  3. If %1 originally had brackets, the strings differ → @break fires
  4. fn`create-job is NEVER called

```

Step 1 happens unconditionally.  The guard is not injection-proof — it is
a **storage/propagation barrier**, not an execution barrier.  Its value is
that even though the injected code ran, the results are not stored in the
database, not sent via `mailsend()`, and not evaluated a second time inside
the database functions.

## When combined with INHERIT removal

After removing `INHERIT` from the dispatch object
(see sec-inherit-player-commands-001), step 1 executes at player privilege.
The two mitigations together mean:

| Without both fixes | With INHERIT removal only | With both fixes |
|---|---|---|
| Injection executes at wizard level, stored in DB | Injection executes at player level, stored in DB | Injection executes at player level, NOT stored |

## Limitations

- Does not protect against inputs that omit brackets but use other evaluation
  vectors (e.g., `%q` register references, percent-escape sequences).
- Does not protect staff-only commands where `%1` is the comment body and
  the command object retains `INHERIT` — those require separate guards.

## @rhost/testkit snippet

```typescript
describe("+request/create injection rejection", ({ it, beforeAll, afterAll }) => {
  let mortal: RhostClient;
  beforeAll(async () => { mortal = await mortalClient(); });
  afterAll(async ()  => { await mortal.disconnect(); });

  it("+request/create rejects [ in topic", async () => {
    const lines = await mortal.command(
      "+request/create APP/Test[pemit me=INJECTED]=Body text"
    );
    assertOut(lines, "[");       // bracket-rejection message expected
    refuteOut(lines, "created"); // command must not complete
    refuteOut(lines, "INJECTED");
  });

  it("+request/create rejects [ in body", async () => {
    const lines = await mortal.command(
      "+request/create APP/CleanTopic=Body[pemit me=INJECTED]"
    );
    assertOut(lines, "[");
    refuteOut(lines, "created");
    refuteOut(lines, "INJECTED");
  });

  it("+request/comment rejects [ in comment", async () => {
    await mortal.command("+request/create QUERY/SecurityTest=Body");
    const match = (await mortal.command("+requests")).join("\n").match(/Req\s+(\d+)/);
    if (!match) throw new Error("Could not find request number");
    const n = match[1];
    const lines = await mortal.command(
      `+request/comment ${n}=Safe text[pemit me=INJECTED]more text`
    );
    assertOut(lines, "[");
    refuteOut(lines, "INJECTED");
  });
});
```
