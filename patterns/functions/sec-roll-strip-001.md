---
id: sec-roll-strip-001
domain: functions
server: RhostMUSH
source: mush-security audit (phase2, 2026-03-27)
complexity: low
tags: [security, safe, input-sanitization, strip]
date_added: "2026-03-27"
---

# Pattern: strip() to remove MUSH injection characters from roll input

The nWoD roller sanitizes user input with `strip()` to remove characters that could open evaluation contexts (`[`, `]`), act as command separators (`;`), or cause display corruption (`<`, `>`, `%`). Applied before any processing.

## Code

```mushcode
// 6e-command-and-function.mu — SECURE PATTERN
// Applied in both c.roll (command level) and f.roll (function level)

// In c.roll — sanitize before passing to workhorse:
setq( 7,
    squish( edit(
        strip( %2, %%%,;<>%[%] ),   // strip: %, comma, ;, <, >, [, ]
        %(, %b%(                      // normalize parens
    ))
),

// In f.roll — sanitize at function entry:
setq( 0, squish( edit( strip( %0, %%%,;<>%[%] ), %(, %b%( )))
```

## Why this matters

- `[` and `]` open MUSH evaluation contexts. A roll string `[delete(me/ATTR)]` would execute `delete(me/ATTR)` if not stripped.
- `;` is a command separator — `some dice;@pemit all=hacked` would run both.
- `<` and `>` can cause display/parsing issues in some contexts.
- `%` introduces MUSH substitutions (`%#`, `%!`, `%r` etc.).
- `squish()` collapses extra spaces that appear after stripping commas.
- `edit(%(, %b%()` normalizes parentheses to have a space before `(`, preventing some edge cases in stat parsing.
- Applied at both the command and function boundary — defense in depth.

## Characters commonly needing strip for user-facing inputs

| Char | Risk |
|------|------|
| `[` `]` | Opens evaluation context |
| `;` | Command separator |
| `%` | MUSH substitution prefix |
| `<` `>` | Display/tag confusion |
| `` ` `` | Used as delimiter in some systems |
| `\|` | Used as delimiter in many list functions |

## @rhost/testkit snippet

```typescript
it('strips brackets from roll input', async ({ client }) => {
    const lines = await client.command('roll [delete(me/ATTR)]');
    // Should process as a dice expression (likely 0 dice / error), not execute delete()
    expect(lines.some(l => l.includes('delete'))).toBe(false);
});

it('strips semicolons from roll input', async ({ client }) => {
    const lines = await client.command('roll 5;think hacked');
    // Second command should not execute
    expect(lines.some(l => l.includes('hacked'))).toBe(false);
});
```
