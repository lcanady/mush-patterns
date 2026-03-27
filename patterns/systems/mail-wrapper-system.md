---
id: mail-wrapper-system-001
domain: systems
server: RhostMUSH
source: RhostMUSH/trunk Mushcode/mailwrappers/
complexity: medium
tags: [mail, wrapper, sudo, fo, toggle, penn_mail, brandy_mail, startobject, program]
date_added: "2026-03-27"
tested: true
---

# Pattern: Mail Wrapper System (RhostMUSH)

RhostMUSH ships with three mail interface wrappers that let players choose their preferred `@mail` style. The wrappers live in `Mushcode/mailwrappers/` and are placed in the Master Room.

## Architecture

```
Master Room
├── brandymail.wrap    (Send Mail RhostAliases)  ← Brandy-style +mail commands
├── muxmail.wrap       (Send Mail RhostAliases)  ← MUX/TM3-style mail commands
└── pennmail.wrap      (Send Mail RhostAliases)  ← PennMUSH-style mail commands

Starting Room
└── StartObject                                   ← First-connect setup wizard
```

Each wrapper is gated by a player toggle:

| Wrapper | Toggle required |
|---------|----------------|
| brandymail | `hastoggle(%#, brandy_mail)` |
| muxmail | `hastoggle(%#, mux_mail)` (or no toggle — default) |
| pennmail | `hastoggle(%#, penn_mail)` |

## UseLock gate pattern

Each wrapper object locks itself so only players with the right toggle can trigger its `$`-commands:

```mushcode
&USEMAIL Send Mail RhostAliases <SMA>=[hastoggle(%#,brandy_mail)]
@Ufail  Send Mail RhostAliases <SMA>=You need to set the BRANDY_MAIL toggle (type: @toggle me=brandy_mail) to use this interface.
@lock/UseLock Send Mail RhostAliases <SMA>=USEMAIL/1
```

The `USEMAIL/1` lock calls the `USEMAIL` attribute with `%0=1` (indicating a `$`-command trigger) and passes if it returns true.

## How wrappers delegate to native mail

All wrappers delegate to RhostMUSH native `mail/` subcommands via `@fo` or `@sudo`:

```mushcode
@@ Reading
&CMD_+READ      Obj=$+read:      @fo %#={mail/quick}
&CMD_+READ_EXT  Obj=$+read *:   @dolist [switch(%0,n,new,u,unread,%0)]={@fo %#=mail/read ##;&MAILCURRENT %#=##}

@@ Sending
&CMD_+MAIL      Obj=$+mail *=*: @sudo %#={mail @%0=%1}
&CMD_+NOTE      Obj=$+note *:   @fo %#={mail/send %#=[ifelse(match(pos(%0,=),#-1),Personal Note//[escape(%0)],[before(%0,=)]//[escape(after(%0,=))])]}

@@ Reply (quotes whole message)
&CMD_+REPLY     Obj=$+reply:    @swi [words(get(%#/mailcurrent))]=0,{@pemit %#=+Mail: Reply to what message?},{@sudo [setq(0,get(%#/mailcurrent))]%#={mail/reply %q0*=Reply...}}

@@ Reply-all (@ prefix = reply to all)
&CMD_+REPLYALL  Obj=$+replyall *: @sudo %#={mail/reply @[first(%0)]*=Reply: [rest(%0)]}

@@ Forward
&CMD_+FORWARD   Obj=$+forward *=*: @sudo [setq(0,get(%#/mailcurrent))]%#={mail/forward %q0 @%0=%1}
```

### Key `mail/send` syntax

```
mail/send <recipients>=<subject>//<body>
```

Subject and body are separated by `//` (double-slash).

## Tracking "current message" per player

The wrappers store the last-read message number on the player:

```mushcode
&MAILCURRENT %#=<num>       @@ set when reading a message

@@ Then reply/forward use it:
@sudo [setq(0,get(%#/mailcurrent))]%#={mail/reply %q0=...}
```

## StartObject — first-connect setup wizard

`StartObject` lives in the **starting room** for new players. When a new player connects, it launches an interactive `@program` session to let them choose their mail interface.

```mushcode
@create StartObject=10
@toggle StartObject=prog               @@ enable @program capability
@set StartObject=DARK INHERIT SAFE INDESTRUCTABLE MONITOR SCLOAK UNFINDABLE COMMAND

@@ Trigger on new connects
&LISTEN1 StartObject=^* has connected*:
  @break [hasflag(%#,guest)];
  @wait 1=@swi/f
    [match(get(%#/did_start),DONE)]
    [match(WORKING WORKING2,get(%#/did_start))]=
    00,{&DID_START %#=WORKING; @tr me/va=%#},
    01,{@pemit %#=...You disconnected mid-setup...; @tr me/va=%#},
    02,{@pemit %#=...Resuming...; @tr me/vc=%#}

@@ Prompt player to choose mail system
@VA StartObject=
  @pemit %0=Welcome! Choose your mail system...;
  @progprompt me=<M>ux, <B>randy, <P>enn, <O>ther, <X>it:;
  @program %0=[v(DB)]/vb

@@ Handle the choice
@VB StartObject=@swi match(m b p o x,%0)=
  0,{@pemit %#=Invalid choice. Try again.; @tr me/va=%#},
  {
    @swi [match(x p m b,%0)]=
      1,{@pemit %#=Default set.;              &DID_START %#=DONE},
      2,{@toggle %#=penn_mail},
      >2,{@toggle %#=brandy_mail mail_stripreturn};
    @break [match(%0,x)];
    @tr me/vc=%#
  }
```

### @program / @progprompt pattern

```mushcode
@progprompt me=<prompt text here>:   @@ display this as the input prompt
@program %#=[v(DB)]/handler_attr     @@ next line player types goes to this attr
```

The handler attribute receives the player's typed input as `%0`. It is a one-shot handler — to chain, set another `@program` at the end.

## @ZA — disconnect-during-program recovery

```mushcode
@ZA StartObject=@pemit %0=You disconnected while initializing.
  [ifelse(match(get(%0/did_start),WORKING),
    Please enter your mail system choice.,
    Please answer the follow-up question.)];
  @tr me/[ifelse(match(get(%0/did_start),WORKING),va,vc)]=%0
```

`@ZA` fires when a player disconnects; use it to clean up or resume interrupted `@program` sessions on reconnect.

## Sending a notification mail from softcode

The pattern used throughout RhostMUSH systems — send mail from an NPC/system object to a player:

```mushcode
@@ Wizard-owned object: sudo the player to send mail
@sudo <player dbref>={mail/send <recipient>=<subject>//<body text>}

@@ Or, if the system object has @power no_pay and wizard:
@fo <player dbref>={mail/send <recipient>=<subject>//<body>}
```

## Help files

Each wrapper has a matching `@dynhelp` help file:
- `brandymailer_rho.txt` → `@dynhelp brandymailer_rho`
- `muxmail_rho.txt` → `@dynhelp muxmail_rho`
- `pennmail_rho.txt` → `@dynhelp pennmail_rho`

Must run `mkindx <filename>` on the server before `@dynhelp` can read it.
