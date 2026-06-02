---
id: func-kv-storage-001
domain: functions
server: RhostMUSH
source: volundmush/rhostcode (CORE 02 - Global Functions.txt)
complexity: medium
tags: [storage, kv, key-value, dict, pairs, set_kv, get_kv, del_kv]
date_added: "2026-03-30"
tested: false
---

# Pattern: KV pair storage in a single attribute

Store multiple key→value pairs in one attribute using `~` as the key/value separator and `|` as the pair list delimiter. Global `set_kv`/`get_kv`/`del_kv` UDFs wrap the manipulation.

This is the rhostcode alternative to parallel-list storage when keys are variable and lookup by name is preferred over index.

## Code — UDF implementations

```mushcode
@@ set_kv(attr_value, key, value) → updated attribute string
@@ Replaces the existing key entry (or appends if absent)
&GFN.SET_KV #func=
  [setq(0,filter(#func/FLT.KV_NOTKEY,%0,|,%q0~))]
  [if(strlen(%q0),[%q0|],)]%0~%1

&FLT.KV_NOTKEY #func=
  [not(strmatch(before(%0,~),%0))]

@@ get_kv(attr_value, key) → value or empty string
&GFN.GET_KV #func=
  [setq(0,filter(#func/FLT.KV_MATCHKEY,%0,|,%0~))]
  [after(first(%q0,|),~)]

&FLT.KV_MATCHKEY #func=
  [strmatch(before(%0,~),%1)]

@@ del_kv(attr_value, key) → updated attribute string (key removed)
&GFN.DEL_KV #func=
  [filter(#func/FLT.KV_NOTKEY,%0,|,%0~)]
```

## Usage

```mushcode
@@ Store two stats on a character:
[set(%#,_PREFS:[set_kv(default(%#/_PREFS,),theme,dark)])]
[set(%#,_PREFS:[set_kv(default(%#/_PREFS,),lang,en)])]

@@ Read back a key:
[get_kv(default(%#/_PREFS,),theme)]          @@ → dark

@@ Delete a key:
[set(%#,_PREFS:[del_kv(default(%#/_PREFS,),lang)])]

@@ Iterating all pairs:
[iter(default(%#/_PREFS,),
  Key=[before(%i0,~)] Value=[after(%i0,~)],
  |,|)]
```

## Storage format

```
theme~dark|lang~en|notify~1
```

- `~` separates key from value within a pair
- `|` separates pairs from each other
- Values can contain spaces but must not contain `~` or `|`
- An empty attribute is treated as an empty KV store (`default(...,)`)

## Notes

- `filter()` with `|` as the delimiter walks the pairs list; the filter attr receives each `key~value` pair as `%0` and the target key as `%1`.
- `set_kv` removes all existing entries for the key first, then appends the new one — ensures uniqueness.
- Store the full KV string back into the attribute after every mutation; the UDFs return the new string, they do not write it themselves.
- In rhostcode, KV attrs use the `_` prefix (e.g. `_PREFS`, `_ACCOUNT`) so they are wiz-only hidden from casual inspection.
- For large stores (>50 pairs), consider segmenting into multiple attributes by category.

## Variants

- **In-band default:** `get_kv(default(%#/_PREFS,),key,fallback_value)` — extend the UDF to accept a third arg.
- **Numeric increment:** `set_kv(store, key, [add(get_kv(store,key,0),1)])` for counters.

## When NOT to use

- When you need ordered list semantics — use `lcons()`/`ldelete()` on a simple space-delimited list instead.
- When keys are always the same fixed set — use separate named attributes for clarity.
- When values may contain `~` or `|` — escape them first or choose different delimiters.

## Source

Extracted from: `CORE 02 - Global Functions.txt` in https://github.com/volundmush/rhostcode
