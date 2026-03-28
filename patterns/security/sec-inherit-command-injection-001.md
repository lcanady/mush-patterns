---
id: sec-inherit-command-injection-001
domain: commands
server: RhostMUSH
source: mush-security audit (GMCCG Phase 2 migration, 2026-03-27)
complexity: medium
tags: [security, anti-pattern, injection, inherit, regex-command]
date_added: "2026-03-27"
---

# Pattern: INHERIT object $-command passes raw regex capture to @pemit without sanitization

When a `$`-command on an INHERIT object passes its regex capture group (`%1`)
directly into a `@pemit` evaluation context, player input is evaluated with
wizard-level privilege before any dispatch logic can validate it.

## Code (risky)

```mushcode
@@ SS has INHERIT — this command runs with wizard powers
&c.stat [v( d.ss )]=$^\+?stat(.*)$:@pemit %#=
	[setq( 0, %1 )]
	[switch( strtrunc( %q0, 1 ),
		...
	)]

@set [v( d.ss )]/c.stat=regex
```

## Why this matters

- The SS object has `INHERIT` flag — any code it executes runs with wizard
  privilege.
- `%1` is the raw regex capture (player-controlled text).
- Inside `@pemit %#=[...]`, `%1` is substituted and then evaluated — if
  it contains `[maliciouscode]`, that code runs with wizard privilege.
- Example: player types `stat[pemit #1=You are hacked]` — `[pemit #1=...]`
  evaluates inside the @pemit context.

## Risk assessment for GMCCG

- **Low in practice**: the `switch(strtrunc(%q0, 1), ...)` dispatch
  checks only the first character of `%q0`, which IS already the injected
  result. But the injection already ran before the check.
- **Higher if SS has INHERIT**: execution is wizard-level.
- **Cannot inject shell commands**: MUSH has no shell access from softcode
  (unless `execscript()` is available and enabled).
- The risk is `@pemit`, `@force`, `@trig` or attribute writes on arbitrary
  objects by an attacker who can craft a valid `[...]` call.

## Fix

Escape or strip brackets before substituting player input into the evaluation
context:

```mushcode
@@ Option 1: escape brackets before storing in register
&c.stat [v( d.ss )]=$^\+?stat(.*)$:@pemit %#=
	[setq( 0, edit( %1, [, %[, ], %] ))]
	[switch( strtrunc( %q0, 1 ),
		...
	)]

@@ Option 2: use %L (literal) if available, or secure( ) to strip dangerous chars
&c.stat [v( d.ss )]=$^\+?stat(.*)$:@pemit %#=
	[setq( 0, secure( %1 ))]
	[switch( strtrunc( %q0, 1 ),
		...
	)]
```

## Notes

- GMCCG keeps this pattern throughout all `$`-commands on the SS.
- The risk is accepted by the GMCCG author because MUSH softcode injection
  doesn't give shell access, and all stat-writing functions validate inputs
  before writing to the sheet.
- If your game adds `execscript()` or other high-privilege functions, this
  pattern becomes significantly more dangerous.

## @rhost/testkit snippet

```typescript
r.test("stat command does not evaluate brackets in input", async () => {
  // If injection works, this would cause a side effect (e.g., noise to #1)
  // Instead we just verify the output is a stat-not-found message
  const out = await r.run(`stat [pemit #1=INJECTED]`);
  r.expect(out).not.toContain("INJECTED");
  r.expect(out).toContain("stat"); // some form of stat message
});
```
