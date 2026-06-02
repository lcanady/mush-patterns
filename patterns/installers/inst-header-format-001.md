---
id: inst-header-format-001
domain: installers
server: RhostMUSH
source: mush-build Phase 6 spec, mush-lint C3/C4/C5 checks
complexity: low
tags: [installer, header, uninstall, progress, format, convention, structure, mush-lint]
date_added: "2026-06-02"
tested: false
see_also: [inst-tag-object-registry-001]
---

# Pattern: Canonical installer file structure — header, sections, progress banners, uninstall block

Every `dist/*.installer.txt` file must follow the canonical structure defined in `mush-build` Phase 6: a repo URL line, a `=`-bordered header block, plain-text `@pemit me=>>` banners (no ansi), `@@ ---[ SECTION ]---` dividers at exactly 78 chars, a `CHANGED:` block for version history, and an UNINSTALL section at the end. This is the template that mush-lint checks C3, C4, and C5 enforce.

## Signal

USE:  every installer file | canonical template from mush-build Phase 6 | enforced by mush-lint C3/C4/C5/F2
RULE: @pemit me=>> plain (no ansi) for banners | @pemit me=   (3 spaces) for section steps | separators exactly 78 chars | UNINSTALL last
WARN: @destroy (not @nuke) in uninstall — @destroy is safe for all wizard levels; @nuke requires ROYALTY
TEST: ✗

## Code

```mushcode
@@ https://github.com/[owner]/[repo]
@@
@@ ===========================================================================
@@ Mushcode Installer for: My System
@@
@@ Author:  Your Name
@@ Server:  RhostMUSH
@@ Version: 1.0.0
@@
@@ Requires:   None
@@ Objects Created:
@@   - My System <sys> (command handler + data store)
@@
@@ Usage: Paste directly into client or use @paste
@@ WARNING: Must be run as Wizard
@@ ===========================================================================
@@
@@ CHANGED:
@@   0.0.0 → 1.0.0  Initial release

@pemit me=>> Installing My System v1.0.0...

@@ --------------------------------[ CONFIG ]----------------------------------
@pemit me=   Creating objects...
@@ NOTE: Run '@search name=My System <sys>' first — reinstall overwrites, does not duplicate
@create My System <sys>
@set My System <sys>=inherit safe
@tag/add mysys_sys=[lastcreate(me,t)]
@fo me=&D_SYS me=search(name=My System <sys>)
&VER [v(D_SYS)]=1.0.0

@@ -----------------------------[ CONFIGURATION ]-----------------------------

&CONFIG.ENABLED [v(D_SYS)]=1
&CONFIG.MAX_ENTRIES [v(D_SYS)]=50

@@ -----------------------------[ FUNCTIONS ]---------------------------------
@pemit me=   Loading functions...

&FN_EXAMPLE [v(D_SYS)]=...

@@ -----------------------------[ COMMANDS ]---------------------------------
@pemit me=   Loading commands...

&CMD_EXAMPLE [v(D_SYS)]=$+example *:...

@@ ---------------------------------[ HELP ]---------------------------------
@pemit me=   Loading help...

&HELP_EXAMPLE [v(D_SYS)]=...

@pemit me=>> My System v1.0.0 installed. Type 'help my system' to get started.

@@ ==============================[ UNINSTALL ]================================
@@ To remove this installer completely, run:
@@   @tag/remove mysys_sys
@@   @destroy [v(D_SYS)]
@@
@@ Note: @tag/remove must be run BEFORE @destroy or the tag pointer orphans.

@@
@@ ===========================================================================
@@ Created with MUSH-ARCHITECT (https://github.com/lcanady/mush-architect)
@@ ===========================================================================
```

## How it works

- The first line is a raw `@@` URL comment — no label. It links to the source repo for traceability.
- `@@ ===...===` borders use 75 `=` signs after `@@ ` (3 chars) = exactly 78 chars total. mush-lint F2 enforces this.
- `@@ ---[ SECTION ]---` dividers: section label centered in 75 `-` dashes after `@@ ` = 78 chars. Formula: `floor((75 - len(label)) / 2)` left dashes, remainder right.
- `@pemit me=>>` (double `>`) — start banner and completion banner only.
- `@pemit me=   ` (3 leading spaces) — one per section, present-tense verb, trailing `...`
- `@fo me=&D_SYS me=search(...)` captures the dbref into `D_SYS` for use throughout the installer — safer than hardcoding.
- The `CHANGED:` block lists version deltas. Omit entirely on `0.0.0` initial releases.
- `@destroy` (not `@nuke`) in the uninstall block — `@destroy` works at wizard level; `@nuke` requires ROYALTY.

## Notes

- `@pemit me=` sends only to the installing wizard — no room broadcast.
- No `ansi()` in progress messages — the installing wizard's client may not have color; plain text is always legible.
- Store `&VER` immediately after `@create` so upgrade scripts can compare installed vs. new version without parsing the header.
- `@tag/remove` must precede `@destroy` — after destroy the dbref is gone and a lingering tag pointer causes `#-1` resolution errors.
- The closing `@@ Created with MUSH-ARCHITECT` footer is stripped by `mush-format compress` in future versions; leaving it in source is harmless.

## When NOT to use

- Single-attribute patches applied directly in a session — the header overhead is not worth it for a one-liner fix.
- Temporary test objects created during development — use a scratch installer without the full ceremony, then discard.

## Source

Extracted from: mush-lint C3/C4/C5 checks, community conventions
