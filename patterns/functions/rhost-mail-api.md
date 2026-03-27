---
id: rhost-mail-api-001
domain: functions
server: RhostMUSH
source: RhostMUSH/trunk Mushcode/mailwrappers
complexity: medium
tags: [mail, functions, native-api, sudo, fo]
date_added: "2026-03-27"
tested: true
---

# RhostMUSH Native Mail API

RhostMUSH has a built-in mail system. It is **not** accessed via a `mailsend()` function call — it is accessed through `mail/` subcommands, either `@fo`'d as the player or via `@sudo`. There are also several query functions.

## Key principle

> Never call `mailsend()` directly in softcode. It doesn't exist as a standalone function in RhostMUSH. Use `@fo %#={mail/send ...}` or `@sudo %#={mail/send ...}` instead.

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

These ARE softcode-callable functions (no `@fo` needed):

| Function | Returns |
|----------|---------|
| `mailquick(<player>)` | Space-separated list of message numbers in inbox |
| `mailquick(<player>,new)` | Unread message numbers |
| `mailstatus(<player>)` | List of message numbers (alias of mailquick) |
| `mailstatus(<player>,<num>)` | Status flags for a specific message |
| `mailread(<player>,<num>,g)` | Message number (global) |
| `mailread(<player>,<num>,f)` | From field |
| `mailread(<player>,<num>,d)` | Date |
| `mailread(<player>,<num>,k)` | Size in bytes |
| `mailread(<player>,<num>,s)` | Subject |
| `mailread(<player>,<num>,b)` | Body |
| `mailread(<player>,<num>,s,1)` | Mark message as read (side effect) |
| `mailsize(<player>,2)` | Mailbox size in bytes |

### Example: check if player has new mail

```mushcode
&FN_HAS_MAIL Obj=[gt(words(mailquick(%0,new)),0)]
```

### Example: list unread count

```mushcode
&FN_UNREAD_COUNT Obj=[words(mailquick(%0,new))]
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
