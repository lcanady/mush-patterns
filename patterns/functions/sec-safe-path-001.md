---
id: sec-safe-path-001
domain: functions
server: RhostMUSH
source: mush-security audit 2026-03-28
complexity: low
tags: [security, safe, injection, input-validation, execscript]
date_added: "2026-03-28"
tested: true
---

# Pattern: Whitelist sanitization for execscript arguments

Sanitize all file-path and package-name arguments before passing to `execscript()`.
Use a whitelist regex with anchors (`^...$`), explicitly block `..`, and return `#-1` on failure so callers can detect it with `isnum()`.

## Code

```mushcode
# FN_SAFE_PATH: sanitize a file path argument before passing to execscript.
# Allows only: a-z A-Z 0-9 / . - _ @
# Blocks: shell metacharacters AND any path containing .. (traversal)
# Returns #-1 INVALID PATH if unsafe.
&FN_SAFE_PATH #sys=
  [if(
    and(
      regmatchi(%0, ^[a-zA-Z0-9/._@][a-zA-Z0-9/._@-]*$),
      not(regmatchi(%0, \.\.))
    ),
    %0,
    #-1 INVALID PATH
  )]

# FN_SAFE_PKG: sanitize a registry package name (no / or .. ever needed).
# Allows only: a-z A-Z 0-9 @ . - _
# Returns #-1 INVALID PACKAGE NAME if unsafe.
&FN_SAFE_PKG #sys=
  [if(
    regmatchi(%0, ^[a-zA-Z0-9@._-]+$),
    %0,
    #-1 INVALID PACKAGE NAME
  )]
```

## Why this matters

- `execscript()` passes arguments directly to a subprocess. Without sanitization, user-controlled input like `foo.mush; rm -rf /` would inject a shell command separator.
- Whitelist regex blocks `;`, `|`, `$`, backtick, `()`, `!`, `--flag` injection, and path traversal (`..`).
- Using `isdbref(%q0)` (which returns true for `#-1 …` strings) lets callers detect rejection without string comparison.
- The `^...$` anchors prevent partial matches that slip through without them.

## Attack vectors blocked

| Input | Risk | Blocked by |
|-------|------|-----------|
| `foo.mush;rm -rf /` | Shell command injection | `;` not in whitelist |
| `$(whoami)` | Shell substitution | `$()` not in whitelist |
| `../../etc/passwd` | Path traversal | `..` explicit block |
| `--help` | Argument injection | `-` only allowed after first char |
| `foo\|cat /etc/passwd` | Pipe injection | `\|` not in whitelist |

## @rhost/testkit snippet

```typescript
it('FN_SAFE_PATH passes a clean path', async ({ expect }) => {
  await expect(`u(${loader}/FN_SAFE_PATH,/opt/mush-loader/packages/bboard.mush)`).toBe('/opt/mush-loader/packages/bboard.mush');
});

it('FN_SAFE_PATH blocks semicolon', async ({ expect }) => {
  await expect(`u(${loader}/FN_SAFE_PATH,foo.mush;rm -rf /)`).toBeError();
});

it('FN_SAFE_PATH blocks path traversal', async ({ expect }) => {
  await expect(`u(${loader}/FN_SAFE_PATH,../../etc/passwd)`).toBeError();
});

it('FN_SAFE_PATH blocks argument injection via --flag', async ({ expect }) => {
  await expect(`u(${loader}/FN_SAFE_PATH,--help)`).toBeError();
});

it('FN_SAFE_PKG passes valid package name', async ({ expect }) => {
  await expect(`u(${loader}/FN_SAFE_PKG,bboard@1.0.0)`).toBe('bboard@1.0.0');
});

it('FN_SAFE_PKG blocks semicolon', async ({ expect }) => {
  await expect(`u(${loader}/FN_SAFE_PKG,foo;rm -rf /)`).toBeError();
});
```
