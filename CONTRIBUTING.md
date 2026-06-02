# Contributing to mush-patterns

## Who contributes

Patterns are contributed automatically by mush-* Claude Code skills when a user shares a help file from a server that isn't already represented in this corpus. They can also be added manually.

## Pattern frontmatter fields

| Field | Required | Description |
|-------|----------|-------------|
| `id` | yes | Unique ID: `<domain>-<slug>-<seq>` e.g. `func-strformat-001` |
| `domain` | yes | `functions` / `commands` / `systems` / `security` / `installers` / `server-help` |
| `server` | yes | Server name or type (e.g. `RhostMUSH`, `PennMUSH`, `TinyMUX`, `All`) |
| `source` | yes | Where the pattern came from (e.g. `help.txt`, `code review`) |
| `complexity` | yes | `low` / `medium` / `high` |
| `tags` | yes | Array of relevant tags |
| `date_added` | yes | ISO date |
| `tested` | no | `true` if a @rhost/testkit test exists |
| `see_also` | no | Array of related pattern IDs (cross-wing tunnels — see `PALACE.md`) |
| `supersedes` | no | ID of the older pattern this one replaces |
| `importance` | no | `1`–`5` stars — 5 = canonical, 1 = deprecated (see `AAAK_SPEC.md`) |

## PR workflow (automated from skills)

When a mush-* skill extracts patterns from an unknown server's help file:

1. Branch name: `patterns/<server-slug>-<date>`
2. Commit: `feat: add patterns from <server-name>`
3. PR title: `feat: patterns from <server-name>`
4. PR body: list of patterns added, source file, notes

## Signal block (mandatory)

Every pattern must include a `## Signal` block immediately after its
opening description. Follow the format in `AAAK_SPEC.md`. At minimum:

```
## Signal
USE:    <when to apply this — 1 line>
TEST:   ✓ | ✗ | –
```

The Signal block is how AI agents scan 20+ patterns quickly. Without it,
patterns are skipped during corpus load.

## What makes a good pattern

- Has a Signal block (see above and `AAAK_SPEC.md`)
- Captures a non-obvious technique or idiom
- Includes a working code snippet
- Explains the "why", not just the "what"
- Notes server compatibility where relevant
- Ideally includes a @rhost/testkit test snippet
- Lists `see_also` IDs for related patterns in other wings (`PALACE.md`)

## What NOT to include

- Entire codebases or game databases (summarize patterns instead)
- Code that can't be run on a standard RhostMUSH install without special setup
- Server-specific admin credentials or configuration
