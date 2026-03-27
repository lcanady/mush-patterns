# mush-patterns

A community RAG corpus of MUSHcode patterns — documented softcode from real servers, organized for AI-assisted development.

Pulled automatically by mush-* skills at the start of every session. New patterns are contributed back via PR after each session where a help file from an unknown server is analyzed.

## Structure

```
patterns/
  functions/     — Reusable UDFs and function patterns
  commands/      — Command implementations (+cmd, @cmd patterns)
  systems/       — Complete game systems (bboard, chargen, stats, etc.)
  server-help/   — Annotated help files from specific servers
```

## Pattern Format

Each pattern file uses YAML frontmatter:

```markdown
---
id: func-strformat-001
domain: functions
server: RhostMUSH
source: help.txt
complexity: medium
tags: [string, formatting, display]
date_added: "2026-03-27"
---

# Pattern: strformat wrapper

Brief description of what this pattern does and when to use it.

## Code

```mushcode
...
```

## Notes

- When to use this
- Caveats, server compatibility
- @rhost/testkit test snippet (if applicable)
```

## Contributing

Patterns are added via PR from the mush-* skills after analyzing help files from servers not yet in this corpus. To add manually, follow the frontmatter format above.

To contribute via PR from a skill session:

```bash
git checkout -b patterns/server-name-YYYY-MM-DD
# add pattern files
git add patterns/
git commit -m "feat: add patterns from <server-name>"
gh pr create --title "feat: patterns from <server-name>" --body "..."
```

## Using with @rhost/testkit

Pattern test snippets in this repo are meant to be run directly:

```typescript
import { RhostRunner } from '@rhost/testkit';
// copy the test snippet from the pattern file
```

## License

CC0 — public domain. Patterns are facts about how softcode works; they aren't copyrightable.
