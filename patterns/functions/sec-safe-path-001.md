---
id: sec-safe-path-001
domain: functions
server: RhostMUSH
source: mush-security audit
complexity: low
tags: [security, safe, sanitization, execscript, shell-injection]
date_added: "2026-03-28"
---

# Pattern: FN_SAFE_PATH — allowlist sanitizer for execscript file paths

Validates a user-supplied file path before passing it to `execscript()`.
Anchors the first character to non-dash printable characters to block flag
injection, and explicitly rejects `..` traversal components.

## Code

```mushcode
# FN_SAFE_PATH: sanitize a file path argument before passing to execscript.
# Allows only: a-z A-Z 0-9 / . - _ @
# First character must be in [a-zA-Z0-9/._@] — rules out leading - flag injection.
# Blocks: shell metacharacters AND any path containing .. (traversal)
# Returns #-1 INVALID PATH if unsafe.
# %0 = raw path argument
&FN_SAFE_PATH <sys>=
  [if(
    and(
      regmatchi(%0, ^[a-zA-Z0-9/._@][a-zA-Z0-9/._@-]*$),
      not(regmatchi(%0, \.\.))
    ),
    %0,
    #-1 INVALID PATH
  )]
```

## Why this matters

- `execscript()` passes arguments directly to a shell script. Any shell
  metacharacter (`;`, `|`, `` ` ``, `$()`, `&`, etc.) in a path allows command
  injection at the OS level — this is a Critical severity risk.
- Path traversal (`../../etc/passwd`) allows reading arbitrary files even if the
  script is intended to stay inside a specific directory.
- A leading `-` in the path would be interpreted as a CLI flag by the called
  script, enabling flag injection (`--version`, `--config=<evil>`, etc.).
- The first-character anchor `[a-zA-Z0-9/._@]` (no `-`) blocks all three of
  these vectors at the regex level before `execscript()` is ever called.

## Caller pattern

The subcommand (`%0` to FN_EXEC) is hardcoded by each trigger; only `%1` (the
path or package) is user-supplied and must have passed through FN_SAFE_PATH
first:

```mushcode
&TR_EXEC_LOAD <sys>=
  [setq(9, u(<sys>/FN_SAFE_PATH, %0))]
  [if(
    isdbref(%q9),           # #-1 is a valid dbref — this is the error sentinel
    @pemit %1=Invalid path: [escape(%0)].,
    @pemit %1=[escape(u(<sys>/FN_EXEC, load, %q9))];
    @trigger <sys>/TR_LOG=Loaded [escape(%q9)] by [name(%1)]
  )]
```

## @rhost/testkit snippet

```typescript
it('FN_SAFE_PATH passes a clean path', async ({ expect }) => {
    await expect(`u(${loader}/FN_SAFE_PATH,/opt/mush-loader/packages/bboard.mush)`)
        .toBe('/opt/mush-loader/packages/bboard.mush');
});

it('FN_SAFE_PATH blocks semicolon (shell separator)', async ({ expect }) => {
    await expect(`u(${loader}/FN_SAFE_PATH,foo.mush;rm -rf /)`).toBeError();
});

it('FN_SAFE_PATH blocks path traversal', async ({ expect }) => {
    await expect(`u(${loader}/FN_SAFE_PATH,../../etc/passwd)`).toBeError();
});

it('FN_SAFE_PATH blocks leading dash (flag injection)', async ({ expect }) => {
    await expect(`u(${loader}/FN_SAFE_PATH,--help)`).toBeError();
});
```
