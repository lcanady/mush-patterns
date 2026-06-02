# The mush-patterns Palace

The corpus is organized as a **memory palace** — a spatial hierarchy of
Wings, Rooms, and Tunnels. Wings are top-level domains. Rooms are
specific topics within a wing. Tunnels are explicit cross-wing links
between patterns that share a concept.

This structure exists so that:
- A session starting from zero can orient quickly (`INDEX.md` → Wing → Room)
- An AI scanning for a pattern can skip irrelevant wings entirely
- Related patterns across domains surface via Tunnels rather than grep luck

---

## Wings

| Wing | Directory | What lives here |
|------|-----------|----------------|
| **Function Library** | `patterns/functions/` | UDFs, guard idioms, iter/map, formatters |
| **Command Gallery** | `patterns/commands/` | `$`-command patterns, dispatch, access control |
| **Systems Vault** | `patterns/systems/` | Complete system architectures |
| **Security Sanctum** | `patterns/security/` | Injection guards, lock patterns, anti-patterns |
| **Installer Workshop** | `patterns/installers/` | `@create` sequences, registration, version guards |
| **Server Archive** | `patterns/server-help/` | Per-server quirks, functions, flags, `@config` deps |

---

## Rooms

### Function Library

| Room | Pattern slug prefix | Contents |
|------|--------------------|----------|
| Guard Room | `func-*-guard-*` | Input validation, error propagation |
| Iter Room | `func-iter-*`, `func-list-*` | List processing: map, filter, lock-step multi-list; `func-list-rhost-001` |
| Storage Room | `func-*-storage-*` | Attribute layout, dot notation, index patterns |
| Formatter Room | `func-*-format-*`, `func-printf-*`, `func-ansi-*` | Display formatting, alignment, title-case, color; `func-printf-001`, `func-ansi-colors-001` |

### Command Gallery

| Room | Pattern slug prefix | Contents |
|------|--------------------|----------|
| Dispatch Room | `cmd-switch-*`, `cmd-unified-*` | Switch routing, category dispatch |
| Arg Room | `cmd-two-arg-*` | Two-argument `target=value` parsing; `cmd-two-arg-pattern-001` |
| Feedback Room | `cmd-feedback-*` | Success, error, and usage message shapes; `cmd-feedback-shape-001` |
| Column Room | `cmd-printf-*` | Multi-column printf display; `cmd-printf-columns-001` |
| Access Room | `sec-command-*` | Permission checks, lock patterns for commands |

### Systems Vault

| Room | Pattern slug prefix | Contents |
|------|--------------------|----------|
| Data Vault | `sys-data-*`, `sys-config-*` | Data dictionary, stat systems, accessor UDFs; `sys-config-object-001` |
| Display Room | `sys-sheet-*`, `sys-*-layout-*`, `sys-visual-*` | Sheet columns, fixed-width display, shared output frames; `sys-visual-frame-001` |
| Logic Room | `sys-rank-*`, `sys-gameline-*` | Cascade rules, dynamic UDF routing |
| UI Room | `help-system-*` | In-game help, player-facing interfaces |
| Test Room | `test-*` | Test infrastructure, CI hooks |

### Security Sanctum

| Room | Pattern slug prefix | Contents |
|------|--------------------|----------|
| Injection Hall | `sec-*-injection-*` | Sanitisation guards, structured attribute safety |
| Lock Hall | `sec-*-lock-*` | Command and attribute locks |
| Rate Hall | `sec-rate-*` | Cooldown, spam prevention, timestamp guards |
| Exposure Hall | `sec-attr-*` | Attribute exposure anti-patterns |

### Installer Workshop

| Room | Pattern slug prefix | Contents |
|------|--------------------|----------|
| Registry Hall | `inst-*-registry-*`, `inst-header-*` | Object registration, `@tag`, stable dbref patterns; installer file structure: `inst-header-format-001` |

### Server Archive

| Room | Contents |
|------|----------|
| RhostMUSH Room | RhostMUSH-specific functions, flags, `@config` quirks (`rhost.md`) |
| PennMUSH Room | PennMUSH-specific patterns (add as discovered) |
| TinyMUX Room | TinyMUX-specific patterns (add as discovered) |

---

## Tunnels

Tunnels are explicit cross-wing links between patterns that share a
concept. They are tracked in the `see_also` frontmatter field.

| Tunnel name | Wing A → Wing B | Pattern IDs |
|-------------|----------------|-------------|
| Error propagation | Function Library → Security Sanctum | `func-udf-guard-001` ↔ `sec-attr-exposure-001` |
| Access control | Command Gallery → Function Library | `sec-command-lock-001` ↔ `func-chargen-status-guard-001` |
| List processing | Function Library (Iter Room) | `func-iter-map-001` ↔ `func-parallel-list-iter-001` |
| Rate limiting | Security Sanctum → Command Gallery | `sec-rate-limit-001` ↔ `cmd-switch-pattern-001` |
| Display pipeline | Function Library → Systems Vault | `func-printf-001` ↔ `sys-visual-frame-001` ↔ `cmd-printf-columns-001` |
| Color + theme | Function Library → Systems Vault | `func-ansi-colors-001` ↔ `sys-visual-frame-001` ↔ `sys-config-object-001` |

To add a tunnel: add the partner pattern's `id` to the `see_also` array
in **both** patterns' frontmatter, then add a row to this table.

---

## Navigation guide

| I want to… | Go to |
|------------|-------|
| Scan all patterns quickly | `INDEX.md` |
| Find a UDF pattern | Function Library → Guard Room or Iter Room |
| Find a command pattern | Command Gallery → Dispatch Room |
| Build a complete system | Systems Vault → Data Vault + Logic Room |
| Audit code for security issues | Security Sanctum (all rooms) |
| Write an installer | Installer Workshop → Registry Hall |
| Look up a server-specific function | Server Archive |
| Find related patterns across wings | Look at `see_also` frontmatter or this Tunnels table |
| Can't find it anywhere | `grep -r "keyword" patterns/` |

---

## Adding a new Wing or Room

If a new domain doesn't fit into an existing Wing:
1. Propose the Wing name and directory in your PR description
2. Create the directory and add at least one pattern
3. Add the Wing row to this file
4. Update `INDEX.md` with the new section

New Rooms within existing Wings can be added without a proposal — just
use a consistent slug prefix and document it in the Room table above.
