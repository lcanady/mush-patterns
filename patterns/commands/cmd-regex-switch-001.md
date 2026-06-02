---
id: cmd-regex-switch-001
domain: commands
server: RhostMUSH
source: volundmush/rhostcode (multiple system files)
complexity: high
tags: [command, regex, switch, args, pattern, regexp, dispatch]
date_added: "2026-03-30"
tested: false
---

# Pattern: Regex command with optional switch and arguments

Use a single `$^...$` regexp pattern on a `@set ... regexp` object to capture an optional `/switch`, optional leading args, and an optional `=value` segment — all in one command definition. This gives you `+cmd`, `+cmd/switch`, `+cmd args`, `+cmd/switch args=value` from a single attr.

This is cleaner than multiple `$+cmd*:` wildcard patterns when the arg structure is irregular or when you need named capture groups.

## The canonical regex

```
$^(?s)(?\:\+)command(?\:/(\\S+)?)?(?\: +(.+?))?(?\:=(.*))?$:
```

Breakdown:
- `(?s)` — DOTALL: `.` matches newlines (handles multi-line input)
- `(?\:\+)command` — non-capturing match of the literal `+command`
- `(?\:/(\\S+))?` — optional `/switch`, captured in `%1`
- `(?\: +(.+?))?` — optional space-separated arguments, captured in `%2`
- `(?\:=(.*))?` — optional `=value` segment, captured in `%3`

## Full example

```mushcode
@create Scene System<C>
@set Scene System<C>=regexp inherit safe

&CMD_SCENE Scene System<C>=
  $^(?s)(?\:\+)scene(?\:/(\\S+)?)?(?\: +(.+?))?(?\:=(.*))?$:
  @switch/first 1=
    [strmatch(%1,new)],     @attach %!/SW.SCENE.NEW=%2,%3,
    [strmatch(%1,join)],    @attach %!/SW.SCENE.JOIN=%2,%3,
    [strmatch(%1,leave)],   @attach %!/SW.SCENE.LEAVE=%2,%3,
    [strmatch(%1,close)],   @attach %!/SW.SCENE.CLOSE=%2,%3,
    [strmatch(%1,list)],    @attach %!/SW.SCENE.LIST=%2,%3,
    [not(strlen(%1))],      @attach %!/SW.SCENE.DEFAULT=%2,%3,
    @pemit %#=Unknown switch '%1'. Try +scene/list.

@@ — Switch handlers ——————————————————————————————————————————
&SW.SCENE.NEW Scene System<C>=
  @switch [strlen(%0)]=
    0, @pemit %#=Usage: +scene/new <title>,
    @attach %!/DO.SCENE.CREATE=%0

&SW.SCENE.LIST Scene System<C>=
  @pemit %#=[header(Open Scenes)]
  [iter(
    mysql(u(%!/Q.SELECT.OPEN_SCENES),sqlformat(u(%!/Q.SELECT.OPEN_SCENES))),
    @pemit %#=[ljust(extract(%i0,1,1,^),5)] [extract(%i0,2,1,^)],
    |)]
  @pemit %#=[footer()]
```

## Input examples and what captures

| Input | `%1` (switch) | `%2` (args) | `%3` (=value) |
|-------|--------------|------------|--------------|
| `+scene` | `` | `` | `` |
| `+scene/list` | `list` | `` | `` |
| `+scene/new Autumn Crisis` | `new` | `Autumn Crisis` | `` |
| `+scene/set title=New Title` | `set` | `title` | `New Title` |
| `+scene/add player=Volund` | `add` | `player` | `Volund` |

## Object flags required

```mushcode
@set Scene System<C>=regexp
@set Scene System<C>=inherit safe
```

`regexp` is required for `$^...$` patterns. Without it, the pattern is treated as a literal glob.

## Notes

- `(?s)` at the start is important — without it, a player using a client that appends `\r\n` to input will fail to match.
- The `(?\:...)` non-capturing groups avoid shifting capture numbering — `%1`, `%2`, `%3` stay fixed regardless of how many non-capturing groups precede them.
- The `\\S+` in the switch group: `\\S` in the pattern text becomes `\S` in the regex engine (one backslash consumed by softcode parser).
- Dispatch via `@attach %!/SW.*` keeps each switch handler in its own attr — easier to read, test, and lock individually than a giant `@switch` block.
- Always provide a `[not(strlen(%1))]` (no-switch) case and a fallback unknown-switch error.
- For the `=value` segment: `%3` will be empty string if no `=` was typed — guard with `if(strlen(%3),...)`.

## When NOT to use

- Simple commands with no switches → use `$+cmd *:` glob pattern — simpler and faster.
- Commands where switch list is very long (>10) → consider a dedicated `SW.<CMD>.<SWITCH>` dispatch table iterated via `hasattr()`.

## @rhost/testkit snippet

```typescript
it('+scene/new creates a scene', async ({ client }) => {
  const lines = await client.command('+scene/new Test Scene');
  if (!lines.some(l => l.includes('Scene'))) throw new Error('Expected confirmation');
});

it('+scene with unknown switch gives error', async ({ client }) => {
  const lines = await client.command('+scene/florp');
  if (!lines.some(l => l.includes('Unknown switch'))) throw new Error('Expected error');
});

it('+scene with no switch shows default view', async ({ client }) => {
  const lines = await client.command('+scene');
  if (!lines.length) throw new Error('Expected default output');
});
```

## Source

Extracted from: Multiple system files in https://github.com/volundmush/rhostcode
