---
id: cmd-two-arg-pattern-001
domain: commands
server: RhostMUSH
source: community conventions, mush-architect corpus upgrade 2026-06-02
complexity: low
tags: [command, two-arg, setter, target, value, pattern, wildcard, equals]
date_added: "2026-06-02"
tested: false
see_also: [cmd-switch-pattern-001, func-udf-guard-001, func-chargen-status-guard-001]
---

# Pattern: Two-argument command — $+cmd <target>=<value>

The `$+cmd *=*` pattern captures two wildcards split on the first `=` character: `%0` is everything before `=`, `%1` is everything after. This is the canonical setter shape for any command where both a target name and a value are required.

## Signal

USE:  $+cmd *=* for (target, value) setters | %0=before-first-= %1=after-first-=
WARN: = splits on FIRST = only -- %1 can contain further = characters (check before stripping)
ALT:  $+cmd/* *=* for (switch, target, value) triples | separate patterns per category for clarity
TEST: ✗

## How it works

The MUSH parser scans the input string for the first `=` character. Everything before it becomes `%0`; everything from after it to the end of the input becomes `%1`. Crucially, only the *first* `=` acts as the split point — any additional `=` characters end up verbatim inside `%1`.

This means:

| Input            | `%0`       | `%1`      | Notes                         |
|------------------|------------|-----------|-------------------------------|
| `+stat strength=3`    | `strength` | `3`       | Normal case                   |
| `+stat str=5=note`    | `str`      | `5=note`  | Extra `=` lives inside `%1`   |
| `+stat =3`            | *(empty)*  | `3`       | Empty `%0` — caught by guard  |
| `+stat strength=`     | `strength` | *(empty)* | Empty `%1` — caught by guard  |

Always validate both wildcards before dispatching.

## Code — standard setter shape

```mushcode
@create Sys <commands>
@set Sys <commands>=inherit safe

&CMD_STAT Sys <commands>=$+stat *=*:
  @assert isconn(%#)={@pemit %#=You must be connected to use this command.}
  @assert strlen(%0)={@pemit %#=Usage: +stat <name>=<value>}
  @assert strlen(%1)={@pemit %#=Usage: +stat <name>=<value>}
  @pemit %#=[ulocal(%!/UDF_STAT_SET,%#,%0,%1)]

&UDF_STAT_SET Sys <commands>=
  [setq(0,%1)][setq(1,%2)][setq(2,%3)]
  [if(strlen(%q0),
    [pemit(%q0,Stat %q1 set to: %q2)],
    Error: no executor.
  )]
```

Key points:
- `@assert` short-circuits with a `@pemit` if the condition is false — keep the CMD_ attr thin.
- Dispatch to a UDF (`ulocal()`) for all real logic; the command attr is a guard + dispatch only.
- Use `ulocal()` (not `u()`) so registers are scoped to the UDF call and do not leak.

## Code — three-wildcard variant (switch, target, value)

When you need a sub-command category alongside the setter pair, add a `/switch` wildcard before the `*=*` pair:

```mushcode
&CMD_STAT_SET Sys <commands>=$+stat/* *=*:
  @assert isconn(%#)={@pemit %#=You must be connected.}
  @assert strlen(%1)={@pemit %#=Usage: +stat/<category> <name>=<value>}
  @assert strlen(%2)={@pemit %#=Usage: +stat/<category> <name>=<value>}
  @pemit %#=[ulocal(%!/UDF_STAT_SET,%#,%0,%1,%2)]
```

Here `%0` is the switch (the part after `/`), `%1` is the target, `%2` is the value.

## Code — optional-value variant (empty %1 means "clear")

When an empty `%1` is meaningful (e.g. "clear this stat"), skip the empty-value guard and branch inside the UDF:

```mushcode
&CMD_STAT Sys <commands>=$+stat *=*:
  @assert isconn(%#)={@pemit %#=You must be connected.}
  @assert strlen(%0)={@pemit %#=Usage: +stat <name>=[value] (omit value to clear)}
  @pemit %#=[ulocal(%!/UDF_STAT_SET,%#,%0,%1)]

&UDF_STAT_SET Sys <commands>=
  [setq(0,%2)][setq(1,%3)]
  [if(strlen(%q1),
    Stat %q0 set to %q1.,
    Stat %q0 cleared.
  )]
```

## When NOT to use

- When only one argument is needed — use `$+cmd *:` instead.
- When `=` appears legitimately in the target name and would conflict with the split.
- When argument order or delimiters are ambiguous — consider a different delimiter or switch-based dispatch (see `cmd-switch-pattern-001`).

## Notes

- Keep CMD_ attributes thin: connected check → empty-arg guards → `ulocal()` dispatch. No game logic inline.
- `%1` can contain `=` characters — never blindly strip or re-split without checking.
- Lock the object: `@set <obj>=safe` prevents accidental `@destroy`.
- For multi-step chargen setters, combine with the chargen status guard (see `func-chargen-status-guard-001`).

## @rhost/testkit snippet

```typescript
it('+stat basic set works', async ({ client }) => {
    const lines = await client.command('+stat strength=3');
    if (!lines.some(l => l.includes('set'))) throw new Error('Expected set confirmation');
});

it('+stat value containing = is preserved', async ({ client }) => {
    const lines = await client.command('+stat note=a=b');
    if (!lines.some(l => l.includes('a=b'))) throw new Error('Expected value with = to survive');
});

it('+stat empty target is rejected', async ({ client }) => {
    const lines = await client.command('+stat =3');
    if (!lines.some(l => l.includes('Usage'))) throw new Error('Expected usage error for empty target');
});

it('+stat empty value is rejected', async ({ client }) => {
    const lines = await client.command('+stat strength=');
    if (!lines.some(l => l.includes('Usage'))) throw new Error('Expected usage error for empty value');
});
```
