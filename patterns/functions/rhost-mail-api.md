---
id: rhost-mail-api-001
domain: functions
server: RhostMUSH
source: RhostMUSH/trunk Mushcode/mailwrappers, Server/game/txt/help.txt
complexity: medium
tags: [mail, functions, native-api, sudo, fo, mailsend, mailquick, mailstatus, mailread]
date_added: "2026-03-27"
tested: true
---

# RhostMUSH Native Mail API

RhostMUSH has a rich built-in mail system accessible two ways:

1. **`mail/` subcommands** via `@fo`/`@sudo` — works for anyone
2. **Side-effect functions** (`mailsend()`, `mailread()`, etc.) — **wizard-only**; object must have SIDEFX + INHERIT flags

## Choosing an approach

| Approach | Requires | Best for |
|----------|----------|---------|
| `@fo target={mail/send ...}` | player permission | Sending as a specific player |
| `@sudo target={mail/send ...}` | wizard power on object | Sending as another player from a wiz object |
| `mailsend(to, subject, body)` | SIDEFX + INHERIT on object | Sending from a system object without a player context |

For **system objects** (job trackers, chargen, etc.) that send notifications on behalf of the game — `mailsend()` is the cleanest approach, provided the object is wizard-owned with `INHERIT SIDEFX`.

## Sending mail

```mushcode
@@ Send from the acting player (%#)
@fo %#={mail/send <recipient>=<subject>//<body>}

@@ Send from a specific player (requires wizard power)
@sudo <player>={mail/send <recipient>=<subject>//<body>}

@@ Send to multiple recipients (space-separated)
@fo %#={mail/send Player1 Player2=Subject//Body text here}

@@ Reply to current message (appends Re: to subject)
@fo %#={mail/reply <msgnum>=<body>}

@@ Reply-all: prefix recipient with @
@sudo %#={mail/reply @<msgnum>=Reply body}

@@ Forward a message
@sudo %#={mail/forward <msgnum> @<recipient>=<note>}
```

## mailsend() — wizard side-effect function

Confirmed present in RhostMUSH (wizhelp only — not in player help.txt). Allows a wizard-owned SIDEFX object to send mail without needing a player context.

**Requirements:** Object must have `INHERIT` and `SIDEFX` flags set.

```mushcode
@@ Basic send
[mailsend(recipient, subject, body)]

@@ With optional sender override (wizard only)
[mailsend(recipient, subject, body, sender)]
```

Arguments:
- `recipient` — player name, dbref, or space-separated list
- `subject` — mail subject line
- `body` — mail body text
- `sender` — optional; override the apparent sender (wizard privilege required)

Example from RockJobs:
```mushcode
[mailsend([get(%0/requester)], Del: [name(%0)], [cname(%#)] has deleted your request.%r%r[get(%0/describe)])]
```

> `mailsend()` is a **side-effect function** — it sends mail as a byproduct of evaluation, not via a command. The object calling it must have `SIDEFX` to use side-effect functions.

## Reading mail

```mushcode
@@ Quick list of inbox
@fo %#={mail/quick}

@@ Read a specific message number
@fo %#={mail/read <num>}

@@ Read all recalled (sent) mail
@fo %#={mail/recall/all}

@@ Read recalled mail from a specific player
@fo %#={mail/recall *<playername>}
```

## Marking / deleting

```mushcode
@@ Mark (soft-delete) a message
@sudo %#={mail/mark <num>}

@@ Unmark
@sudo %#={mail/unmark <num>}

@@ Purge marked messages
@sudo %#={mail/purge}
```

## Folders

```mushcode
@fo %#={folder/change <foldername>}
```

## Wizard mail commands

```mushcode
@@ Set quota for a player
@fo %#={wmail/size <player>=<quota>/<maxquota>}

@@ Wipe a player's mailbox
@fo %#={wmail/wipe <player>}
```

## Query functions

Softcode-callable (no `@fo` needed). Documented access levels noted.

### mailquick() — fully documented, available to all

```
mailquick(<player>[, <folder>][, <type>])
```

| `type` | Returns |
|--------|---------|
| `0` (default) | `<total> <new> <unread> <old> <marked> <saved>` |
| `1` | `<unread+old> <new> <marked>` (MUX `mail()` compat) |
| `2` | Single integer — total message count |
| `3` | Modified version of type 1 |

```mushcode
[mailquick(me)]         @@ "4 1 0 2 1 0"  (total new unread old marked saved)
[mailquick(me,,1)]      @@ "3 1 1"  (MUX compat)
[mailquick(me,,2)]      @@ "4"  (total count only)

@@ Check if player has new mail
[gt(extract(mailquick(%0),2,1), 0)]

@@ Total unread count
[extract(mailquick(%0), 3, 1)]
```

### mailstatus() — wizard-only

Mimics `mail/status` output — returns list of status strings for messages.

```mushcode
[mailstatus(%#)]               @@ all messages
[mailstatus(%#, trim(v(0)))]   @@ filtered (e.g. "U" for unread)
[mailstatus(%#, /%0)]          @@ subject search
```

### mailread() — wizard-only

Reads individual fields from a mail message. Object must have SIDEFX for the read-marking variant.

```mushcode
[mailread(%0, N, g)]    @@ global message number
[mailread(%0, N, f)]    @@ from field
[mailread(%0, N, d)]    @@ date
[mailread(%0, N, k)]    @@ size in bytes
[mailread(%0, N, s)]    @@ subject
[mailread(%0, N, b)]    @@ body
[mailread(%0, N, s, 1)] @@ mark as read (side effect — requires SIDEFX)
```

### mailsize() — confirmed present (used in brandymail.wrap)

```mushcode
[mailsize(%#, 2)]    @@ mailbox size in bytes
```

### mailalias() — resolve mail alias to dbrefs

```mushcode
[mailalias(aliasname)]    @@ returns space-separated dbrefs
```

### msizetot() — total mail system size

```mushcode
[msizetot()]    @@ total bytes used by entire mail system (wizard)
```

## Player mail toggles

RhostMUSH uses `@toggle` to select mail interface style. Check with `hastoggle()`:

| Toggle | Meaning |
|--------|---------|
| `brandy_mail` | Player uses Brandy/+mail interface |
| `penn_mail` | Player uses PennMUSH-style interface |
| `mail_stripreturn` | Message separator is space instead of newline |

```mushcode
@@ Set toggle on player
@toggle %#=brandy_mail

@@ Check toggle in softcode
[hastoggle(%#, brandy_mail)]   →  1 or 0

@@ Gate a command to only players with brandy toggle
&USEMAIL Obj=[hastoggle(%#,brandy_mail)]
@lock/UseLock Obj=USEMAIL/1
```

## AutoForward / Reject (vacation)

```mushcode
@fo %#={mail/autofor <player>}     @@ forward all mail to <player>
@fo %#={mail/reject <message>}     @@ set reject/vacation message
@fo %#={mail/reject +list}         @@ list current reject setting
@fo %#={mail/quota}                @@ show quota info
```

## Wizard mail functions (read other players' mail)

Wizards can pass a dbref to `mailquick()` etc.:

```mushcode
[mailquick(#123)]          @@ inbox of player #123
[mailread(#123, 1, b)]     @@ body of message 1 for player #123
```

## Notes

- `mail/send` subject and body are separated by `//` (double-slash), NOT `/`
- `@sudo` requires the softcode object to have wizard-level power
- `@fo` executes as the player (`%#`) — the player must have permission
- In-game help: `help mail`, `help mail/send`, `help wmail`
