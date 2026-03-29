---
id: func-perm-temp-storage-001
domain: functions
server: RhostMUSH
source: city-of-roses, session 2026-03-29
complexity: medium
tags: [storage, perm, temp, pools, dot-notation, extract]
date_added: "2026-03-29"
tested: true
---

# Pattern: Perm/temp dual-value storage in a single attribute

Store both the permanent (max) and temporary (current) value of a pool or stat in one attribute using dot-separated notation: `perm.temp`. Use `extract()` with `.` as the delimiter to read either field.

## Code

```mushcode
@@ Write both perm and temp at once (chargen set or staff override):
[set(%0,_STAT_WILLPOWER:5.5)]

@@ Read permanent value:
[extract(default(%0/_STAT_WILLPOWER,0.0),1,1,.)]

@@ Read temporary value:
[extract(default(%0/_STAT_WILLPOWER,0.0),2,1,.)]

@@ Set permanent only, preserve existing temp:
[setq(d,extract(default(%0/_STAT_WILLPOWER,0.0),2,1,.))]
[set(%0,_STAT_WILLPOWER:5.%qd)]

@@ Set temporary only (spend 1 point), capped to perm:
[setq(p,extract(default(%0/_STAT_WILLPOWER,0.0),1,1,.))]
[setq(t,extract(default(%0/_STAT_WILLPOWER,0.0),2,1,.))]
[set(%0,_STAT_WILLPOWER:%qp.[max(0,sub(%qt,1))])]
```

## Notes

- `default(%0/_STAT_WILLPOWER,0.0)` returns `0.0` if the attribute is missing, so `extract()` always gets a valid two-part string.
- Temp is always capped to `[0, perm]` by the setter — enforced in the UDF, not trusted from input.
- Works equally for any two-track resource (Health levels, Rage, Gnosis, Willpower, Blood Pool, etc.).
- `extract(str,1,1,.)` — field 1, 1 word, delimiter `.` — is the idiom; do not use `before()`/`after()` as they break if the value itself contains a dot.
- For stats with no meaningful temporary track (e.g. RANK), store a single integer directly.

## Variants

- **Three-track storage**: extend to `perm.temp.aggravated` for health levels.
- **Named pools UDF**: wrap in a UDF `FN_GETPOOL(player, pool)` / `FN_SETPOOL(player, pool, perm, temp)` to avoid repeating `extract()` everywhere.

## When NOT to use

- Attributes that only ever have one value — adds unnecessary complexity.
- When the two values have very different ranges (e.g., perm 1–10, temp 0–100) — consider separate attributes for clarity.

## Source

Extracted from: city-of-roses, session 2026-03-29
