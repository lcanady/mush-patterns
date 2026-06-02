# AAAK Signal Block Specification

AAAK is a compact, pipe-friendly notation for pattern Signal blocks.
It gives AI agents (and humans doing fast scans) a one-glance summary of
_when_ to use a pattern, _what_ to watch for, and whether it's tested.

---

## Signal block structure

Every pattern file MUST include a Signal block immediately after the
opening description:

```
## Signal
USE:    <when to apply this pattern — 1 tight line>
ALT:    <alternative if this doesn't fit — omit if none>
WARN:   <common pitfall or failure mode — omit if none>
COMPAT: <server compatibility — omit if RhostMUSH-only and that is clear>
TEST:   ✓ | ✗ | –   (✓ passing, ✗ no test, – not applicable)
★:      ★ to ★★★★★  (importance — omit if ★★★ average)
```

Fields after `TEST:` are optional. Mandatory fields: `USE:` and `TEST:`.

---

## Entity codes

Use 3-character codes when repeating the same concept inside Signal
blocks or Notes sections. Avoids verbose repetition.

| Code | Expands to |
|------|-----------|
| `UDF` | User-defined function (`u()` / `ulocal()` call target) |
| `CMD` | Softcoded command (`$+pattern` trigger) |
| `SYS` | System object (`@create`'d parent / data carrier) |
| `SEC` | Security or access-control construct |
| `INS` | Installer line (`@create`, `@set`, `&ATTR value`) |
| `IDX` | Index attribute (space-delimited list of keys / refs) |
| `REG` | Register (`%q0`–`%q9`, `setq()` / `setr()`) |
| `ERR` | Error return (`#-1 REASON` or `#-2`, `#-3`) |
| `LCK` | Lock expression (`@lock`, `P_` hook, inline `isstaff()`) |

Only introduce a code if you use it more than once in a single file.

---

## Importance ratings

Append a `★` rating to the `TEST:` line (or on its own `★:` line):

| Rating | Meaning |
|--------|---------|
| `★★★★★` | Canonical approach — always prefer this |
| `★★★★` | High-value, commonly needed |
| `★★★` | Useful in specific situations (default — may omit) |
| `★★` | Edge case or narrow use |
| `★` | Deprecated or superseded — use `supersedes` frontmatter |

---

## Cross-reference notation

Use these in the Notes section or inline to link related patterns:

| Glyph | Meaning |
|-------|---------|
| `→ [id]` | See also — related pattern (parallel concern) |
| `⇒ [id]` | This is superseded by [id] — prefer that one |
| `⟵ [id]` | This supersedes [id] |

Cross-references must match the `id` field in the target pattern's
frontmatter. Use the full id (e.g. `func-udf-guard-001`).

---

## Complete example

```markdown
## Signal
USE:    validate required args at top of every UDF | return ERR on bad input
DETECT: isnum(before(result,%b)) | .toBeError()
COMPAT: All
WARN:   propagate ERR upstream — never swallow #-N returns
TEST:   ✓ ★★★★★
```

Notes might then contain:
```
→ func-chargen-status-guard-001  (role-specific variant of this guard)
```

---

## Why AAAK for MUSH patterns

Softcode sessions are context-heavy. An AI scanning a 20-pattern corpus
before writing code needs to skip irrelevant patterns instantly. The
Signal block is the skip layer — if `USE:` does not match the current
task, the agent moves on without reading the full pattern.

`WARN:` and `COMPAT:` cover the two failure modes that show up most
in code review: "used this in the wrong situation" and "worked on
RhostMUSH, broke on PennMUSH." Putting them in the Signal block means
they get seen even when the full Notes are skipped.
