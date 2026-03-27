---
id: sec-regex-template-001
domain: functions
server: RhostMUSH
source: mush-security audit (GMCCG Phase 1 migration, 2026-03-27)
complexity: low
tags: [security, low, regex, grepi, template-value]
date_added: "2026-03-27"
---

# Pattern: Template value used as grepi() pattern without regex escaping

When a stat value (like bio.template) is interpolated directly into a
`grepi()` or `regrab()` pattern, regex metacharacters in the value can
cause incorrect matches. No code execution risk, but wrong sphere detection.

## Code (risky)

```mushcode
@@ bio.template value inserted directly as grepi value-pattern
&.sphere [v( d.dd )]=
  localize( strcat(
    setq( s,
      lcstr( last(
        grepi(%!, .sphere.*, edit(u(.value_full,%0,bio.template),%b,_)),
        .
      ))
    ),
    if(t(%qs),%qs)
  ))
```

## Why this matters

- Template names like "Demon" contain no metacharacters — but custom templates
  (e.g., "Half+Demon", "Were[wolf]") could confuse the regex engine.
- In GMCCG the template list is DD-constrained so the risk is low, but
  the pattern is worth avoiding in general.

## Fix

If the template list is unbounded or admin-editable, escape before use:

```mushcode
@@ Use regeditall() to escape regex metacharacters in the value
setq(t, regeditall(u(.value_full,%0,bio.template), ([.+*?\[\]^$()|{}\\]), \$1))
grepi(%!, .sphere.*, %qt)
```

## Notes

- In GMCCG specifically, `bio.template` values are validated against a fixed
  list (`Human.Vampire.Werewolf...`) before being stored — so metacharacters
  cannot be introduced. The risk is theoretical for this codebase.
- If your game allows custom template names set by staff, apply the fix above.
