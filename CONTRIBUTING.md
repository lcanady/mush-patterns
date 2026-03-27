# Contributing to mush-patterns

## Who contributes

Patterns are contributed automatically by mush-* Claude Code skills when a user shares a help file from a server that isn't already represented in this corpus. They can also be added manually.

## Pattern frontmatter fields

| Field | Required | Description |
|-------|----------|-------------|
| `id` | yes | Unique ID: `<domain>-<slug>-<seq>` e.g. `func-strformat-001` |
| `domain` | yes | `functions` / `commands` / `systems` / `server-help` |
| `server` | yes | Server name or type (e.g. `RhostMUSH`, `PennMUSH`, `TinyMUX`) |
| `source` | yes | Where the pattern came from (e.g. `help.txt`, `code review`) |
| `complexity` | yes | `low` / `medium` / `high` |
| `tags` | yes | Array of relevant tags |
| `date_added` | yes | ISO date |
| `tested` | no | `true` if a @rhost/testkit test exists |

## PR workflow (automated from skills)

When a mush-* skill extracts patterns from an unknown server's help file:

1. Branch name: `patterns/<server-slug>-<date>`
2. Commit: `feat: add patterns from <server-name>`
3. PR title: `feat: patterns from <server-name>`
4. PR body: list of patterns added, source file, notes

## What makes a good pattern

- Captures a non-obvious technique or idiom
- Includes a working code snippet
- Explains the "why", not just the "what"
- Notes server compatibility where relevant
- Ideally includes a @rhost/testkit test snippet

## What NOT to include

- Entire codebases or game databases (summarize patterns instead)
- Code that can't be run on a standard RhostMUSH install without special setup
- Server-specific admin credentials or configuration
