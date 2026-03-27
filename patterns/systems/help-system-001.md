---
id: system-help-system-001
domain: systems
server: RhostMUSH
source: mush-loader project
complexity: high
tags: [help, hooks, external-db, https, public-commands, wizard-commands]
date_added: "2026-03-27"
tested: false
---

# Pattern: +help system with external DB hooks

A self-contained in-game help system. Topics stored as attributes on a `HelpSystem <sys>` object. Two hook attributes (`HOOK_FETCH`, `HOOK_SYNC`) provide clean extension points for connecting to an external database (HTTPS-accessible help via `execscript`).

## Key design decisions

- **Use lock open to all**: `@lock/use obj=1` so public commands fire for non-wizards. Wizard-only access enforced per-trigger via `[hasflag(%#,wizard)]`, not at the use-lock level.
- **Topic normalization**: `FN_SAFE_TOPIC` lowercases, trims, and validates via `regmatchi` before any storage or lookup. Blocks `[`, `]`, `;`, `%` etc.
- **Dynamic attribute name**: `FN_ATTR_NAME` converts topic "combat tips" → `HELP_COMBAT_TIPS` via `edit(%0,%b,_)` + `ucstr()`.
- **Index attribute**: `HELP__INDEX` holds pipe-separated normalized topic names. Updated on every set/delete.
- **Hook-first miss**: `FN_GET_HELP` checks local attr first, then falls through to `HOOK_FETCH` on cache miss. Empty return = not found.
- **Delayed wizard re-check in triggers**: `@trigger` bypasses use lock, so wizard-only triggers re-verify `FN_WIZARD_CHECK` on `%0` (the passed-in enactor dbref).

## Code skeleton

```mushcode
@create HelpSystem <sys>
@set HelpSystem <sys>=inherit safe
@fo me=&d.help me=search(name=HelpSystem <sys>)
@lock HelpSystem <sys>=hasflag(%#,wizard)
@lock/use HelpSystem <sys>=1

# Hook stubs — override to connect external DB
&HOOK_FETCH [v(d.help)]=
&HOOK_SYNC [v(d.help)]=

# Topic validation: letters, digits, spaces, hyphens, underscores only
&FN_SAFE_TOPIC [v(d.help)]= [setq(0,lcstr(trim(%0)))][if(and(gt(strlen(%q0),0),regmatchi(%q0,^[a-z0-9 _-]+$)),%q0,)]

# Attribute name: "combat tips" → HELP_COMBAT_TIPS
&FN_ATTR_NAME [v(d.help)]= [strcat(HELP_,ucstr(edit(%0,%b,_)))]

# Local lookup with hook fallback
&FN_GET_HELP [v(d.help)]= [setq(1,get(v(d.help)/[u(v(d.help)/FN_ATTR_NAME,%0)]))][if(%q1,%q1,[setq(2,u(v(d.help)/HOOK_FETCH,%0))][if(%q2,%q2,)])]

# Wizard re-check in triggers (use lock bypass protection)
&FN_WIZARD_CHECK [v(d.help)]= [hasflag(%0,wizard)]
```

## Hook: HTTPS integration via execscript

### Read-only web mirror (push on write)
```mushcode
&HOOK_SYNC <dbref>=[execscript(helpsync, %0, %1, %2)]
```
`scripts/helpsync` receives `(op, topic, text)` and writes to your web DB.

### Web service as source of truth (pull on read)
```mushcode
&HOOK_FETCH <dbref>=[execscript(helpfetch, %0)]
```
`scripts/helpfetch` GETs `https://yoursite.com/api/help/<topic>` and prints the result.

Both require `@power <dbref>=@a execscript` (ARCHITECT level to pass args).

## Notes

- Add a `@rhost/testkit` test snippet here before marking `tested: true`
- Full implementation: `softcode/help-system.mush` in the `mush-loader` project
- Tests: `tests/help-system.test.ts`
