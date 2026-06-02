---
id: cmd-feedback-shape-001
domain: commands
server: RhostMUSH
source: community conventions, mush-architect corpus upgrade 2026-06-02
complexity: low
tags: [feedback, error, success, message, pemit, format, output, convention, game-prefix]
date_added: "2026-06-02"
tested: false
see_also: [func-ansi-colors-001, sys-visual-frame-001, sec-command-lock-001]
---

# Pattern: Standard command feedback messages — success, error, and usage

Consistent `@pemit` shapes for success confirmations, error messages, and usage hints. Visual differentiation via `ansi()` and a system-name prefix keeps all command output scannable at a glance. Single-line messages route through `@pemit %#` and never interpolate user input directly — all `%0`–`%9` values must pass through `secure()` before appearing in any feedback string.

## Signal

```
USE:  all @pemit output in CMD_ attrs | success=hg prefix | error=hr prefix | usage=hw hint
RULE: @pemit %# for player-only | @pemit/list for multi-line | never bare %0-%9 in @pemit
WARN: always route %0-%9 through secure() before embedding in any feedback message
TEST: –
```

## Code

### Message shape templates

```mushcode
/* SUCCESS — bright green prefix, confirms what changed */
@pemit %#=[ansi(hg,+STAT:)] Strength set to [secure(%0)].

/* ERROR — bright red prefix, tells player what to do differently */
@pemit %#=[ansi(hr,+STAT:)] Invalid value. Usage: +stat/set <stat>=<value>

/* USAGE hint — bright white prefix, neutral reminder */
@pemit %#=[ansi(hw,+STAT:)] Usage: +stat/set <stat>=<value>
```

### Full command example with all three feedback types

```mushcode
/* +stat/set <stat>=<value>
   Sets a character stat. Demonstrates all three feedback shapes
   in a single @switch/first dispatch.
*/
& CMD_STAT_SET #1=$+stat/set *=*:
  @switch/first 1=
    /* guard: connected players only */
    not(hasflag(%#,connected)),
      { @pemit %#=[ansi(hr,+STAT:)] You must be a connected player. },

    /* guard: stat name must be non-empty */
    not(%0),
      { @pemit %#=[ansi(hw,+STAT:)] Usage: +stat/set <stat>=<value> },

    /* guard: value must be numeric */
    not(isnum(%1)),
      { @pemit %#=[ansi(hr,+STAT:)] '[secure(%0)]' requires a numeric value. Usage: +stat/set <stat>=<number> },

    /* guard: stat must exist on the sheet */
    not(member(get(#1/VALID_STATS),lcstr(secure(%0)))),
      { @pemit %#=[ansi(hr,+STAT:)] '[secure(%0)]' is not a valid stat. See: +stat/list },

    /* all checks pass — perform the write */
    {
      @set %#=STAT_[lcstr(secure(%0))]:[secure(%1)];
      @pemit %#=[ansi(hg,+STAT:)] [capstr(secure(%0))] set to [secure(%1)].
    }
```

### Multi-line output using @pemit/list

```mushcode
/* Use @pemit/list when a response spans multiple conceptual lines.
   %r is the separator; leading/trailing whitespace is stripped per line.
   Never use @pemit in a loop — build the string first, then emit once.
*/
& CMD_STAT_LIST #1=$+stat/list:
  @switch/first 1=
    not(hasflag(%#,connected)),
      { @pemit %#=[ansi(hr,+STAT:)] You must be a connected player. },
    {
      @pemit/list %#=
        [ansi(hw,+STAT: --- Your Stats ---)]%r
        [iter(get(#1/VALID_STATS),
          [ansi(hc,  [capstr(##)])]%b= %b[default(%#/STAT_##,0)],
          , %r)]%r
        [ansi(hw,+STAT: --- End Stats ---)]
    }
```

### Staff notification side-channel

```mushcode
/* Tell the player, then notify a staff room separately.
   Never send both messages to the same target in a single @pemit.
   The staff channel should receive context the player does not see.
*/
& CMD_APPROVE #1=$+approve *:
  @switch/first 1=
    not(hasflag(%#,wizard)),
      { @pemit %#=[ansi(hr,+STAFF:)] Permission denied. },
    not(pmatch(%0)),
      { @pemit %#=[ansi(hr,+STAFF:)] No player found matching '[secure(%0)]'. },
    {
      /* 1. tell the approved player */
      @pemit [pmatch(secure(%0))]=[ansi(hg,+STAFF:)] You have been approved! Welcome to the game.;

      /* 2. confirm to the approving staffer */
      @pemit %#=[ansi(hg,+STAFF:)] [name(pmatch(secure(%0)))] approved.;

      /* 3. log to the staff room — separate @pemit, separate target */
      @pemit [get(#1/STAFF_ROOM)]=[ansi(hw,+STAFF:)] [name(%#)] approved [name(pmatch(secure(%0)))] at [convsecs(secs())].
    }
```

## Why this matters

- **Scannable output.** Green = good, red = problem, white = neutral. Players learn the color contract after a few interactions and stop reading every word.
- **Consistent prefix.** Using the same prefix (e.g., `+STAT:`) across all commands in a system makes it trivial to grep logs or mute a channel programmatically.
- **`secure()` everywhere.** Without `secure()`, a value like `[think(wizardcommand)]` in `%0` executes in the enactor's permission context when interpolated. `secure()` strips function calls before embedding user content in any string.
- **`@pemit %#` not `@pemit enactor.`** `%#` is the enactor at the time the attribute fires. Hardcoding a dbref or using `%L` instead risks mis-routing when the command is triggered from a non-standard context.
- **Single emit, not looped emits.** Multiple `@pemit` calls in a tight loop produce a flood of individual lines with no ordering guarantee under high load. Build the full string with `iter()` or `setunion()` first, emit once.

## When NOT to use

- **Background automated processes** with no connected player target — use `@trigger` side-effects that write to an attribute or log object instead of `@pemit`.
- **Room-wide announcements** — use `@emit` (sends to everyone in the room) rather than `@pemit` (sends only to one object).
- **Channel or bulletin board output** — those systems have their own formatting conventions and emit functions.

## Notes

Keep the system prefix consistent across every command in a system (e.g., `+STAT:` for all stat commands, `+JOB:` for all job commands). Mixing prefixes within a system makes it impossible for players to filter or recognize output at a glance.

- Success messages confirm what changed, not what the player typed.
- Error messages tell the player what to do differently — not just that something went wrong.
- Usage hints should be the minimum needed to correct the mistake; do not dump the full help text inline.
