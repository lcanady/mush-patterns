---
id: func-list-rhost-001
domain: functions
server: RhostMUSH
source: rhost-help.txt
complexity: low
tags: [list, iter, buffer, safety, performance, rhost-specific, large-lists]
date_added: "2026-06-02"
tested: false
see_also: [func-iter-map-001, func-parallel-list-iter-001]
---

# Pattern: list() -- buffer-safe iter() for large lists

RhostMUSH's `list()` works like `iter()` but processes output in chunks to stay within the server's LBUF limit. Use `list()` instead of `iter()` when the input list may exceed ~30 items or when iterating over `lattr()` output.

## Signal

USE:  list() for large/unknown-size lists | lattr() output | iter() fine for short known-size lists
WARN: iter() on large lists can silently truncate output when total evaluation exceeds ~8000-char LBUF
COMPAT: RhostMUSH only -- list() does not exist on PennMUSH/TinyMUX
ALT:  iter() for short lists where buffer overflow is provably impossible
TEST: x

## Code

### 1. iter() -- fine for short, known-size lists

```mushcode
think iter(one two three four five,## is item #@)
```

Returns: `one is item 1 two is item 2 three is item 3 four is item 4 five is item 5`

Safe when the list is short and the total output is provably under the LBUF limit (~8000 chars).

### 2. list() equivalent -- same syntax, safe for large lists

```mushcode
@emit [list(one two three four five,## is item #@)]
```

Output (each result on its own line, emitted before the calling command's output):
```
one is item 1
two is item 2
three is item 3
four is item 4
five is item 5
```

`##` = element, `#@` = 1-based index, same as `iter()`.

### 3. list() iterating lattr() output -- the canonical safe pattern

```mushcode
@emit [list(lattr(#123),## = [v(#123/##)],,Attributes on #123:)]
```

This emits a header line (`Attributes on #123:`) followed by one `ATTRNAME = value` line per attribute. Because `lattr()` can return dozens or hundreds of attribute names, using `iter()` here risks truncation; `list()` handles arbitrarily long results safely.

### 4. The risky iter() equivalent that may truncate

```mushcode
think iter(lattr(#123),## = [v(#123/##)])
```

If `#123` has many attributes, the concatenated output string may exceed the LBUF limit and be silently cut off. No error is raised -- the result is just shorter than expected.

### 5. Side-effect version using think

```mushcode
think list(lattr(me),pemit(%#,## -> [v(me/##)]))
```

`list()` works without the SIDEFX flag (unlike most side-effect functions). Wrapping it in `think` suppresses the implicit output of the think command itself so only the `pemit` calls produce visible text.

## How it works

RhostMUSH evaluates functions inside a fixed-size Large Buffer (LBUF) of approximately 8000 characters. When `iter()` processes a list it builds the entire result string in a single evaluation pass -- if the concatenated output exceeds the LBUF limit the string is silently truncated at the boundary.

`list()` avoids this by emitting each element's result as a separate line immediately, before the calling command's output, rather than accumulating all results into one string. Because each line is flushed independently, the per-element output only needs to fit within one LBUF, not the total of all elements combined. This makes `list()` safe for arbitrarily long lists.

`##` and `#@` work identically in `list()` and `iter()`. `%i0`-`%i9` and `%il` (itext nesting) also work. The optional `<header>` argument emits a single header line before the first element. The optional `<target>` argument redirects output to another player you control.

Note that `list()` output appears *before* the surrounding command's output (see example 2 above -- `AABB` appears after the list lines in the help examples). Plan attribute and emit ordering accordingly.

## When NOT to use

- When the list size is always small and known at write time (5-10 items with short eval output) -- `iter()` is simpler and returns a value that can be embedded inline.
- On PennMUSH or TinyMUX codebases -- `list()` is RhostMUSH-specific. Use `iter()` with careful buffer budgeting, or `@dolist` for side-effect loops.
- When you need the result as an inline string (e.g. inside `set()` or as a function argument) -- `list()` emits to output, it does not return a concatenated string.
