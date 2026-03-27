---
id: system-test-hooks-001
domain: systems
server: RhostMUSH
source: mush-loader vet
complexity: medium
tags: []
date_added: "2026-03-27"
tested: false
---

# Pattern: test-hooks

Vetted from /tmp/test-hooks.mush

## Code

```mushcode
#!pre-install
# Verify we have wizard access before starting
think Pre-install: checking wizard access...

#!end-pre-install

# Main system
@create TestHooks <sys>
@set TestHooks <sys>=inherit safe
&VERSION [search(name=TestHooks <sys>)]=1.0.0

#!post-install
# Announce successful install
think Post-install: TestHooks installed at [search(name=TestHooks <sys>)].

#!end-post-install

```

## Vet result

Verdict: **pass**
Summary: [main] Static validation passed — no dangerous patterns found. (AI vetting skipped — no AI_PROVIDER configured)

_No findings._


## Notes

- Vetted by mush-loader on 2026-03-27
- Add a `@rhost/testkit` test snippet here before marking `tested: true`
