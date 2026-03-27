---
id: func-iter-map-001
domain: functions
server: RhostMUSH
source: rhost-testkit examples
complexity: low
tags: [iter, list, map, transform]
date_added: "2026-03-27"
tested: true
---

# Pattern: iter as map

Use `iter()` to transform every element in a space-delimited list. The loop variable `##` holds the current element; `#@` holds its 1-based index.

## Code

```mushcode
iter(1 2 3,mul(##,2))
```

Returns: `2 4 6`

To use a custom separator:

```mushcode
iter(a|b|c,strcat(##,!),|,|)
```

Returns: `a!|b!|c!`

## Notes

- `iter()` is lazy — it evaluates each element in sequence.
- Use `list()` (RhostMUSH) or `lmap()` (PennMUSH) for more control.
- For side-effects (emitting, DB writes) use `iter()` inside a `think` or `@dolist`.
- Empty list returns empty string, not an error.

## @rhost/testkit snippet

```typescript
it('iter doubles each element', async ({ expect }) => {
    await expect('iter(1 2 3,mul(##,2))').toBe('2 4 6');
});

it('iter with custom separator', async ({ expect }) => {
    await expect('iter(a|b|c,strcat(##,!),|,|)').toBe('a!|b!|c!');
});

it('iter on empty list returns empty', async ({ expect }) => {
    await expect('iter(,mul(##,2))').toBe('');
});
```
