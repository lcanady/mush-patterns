---
id: medusa-site-block-001
domain: systems
server: RhostMUSH
source: RhostMUSH/trunk Mushcode/MedusaObject
complexity: low
tags: [security, site-ban, aconnect, adisconnect, lookup_site, wildmatch, slave, fubar]
date_added: "2026-03-27"
tested: true
---

# Pattern: Medusa Object (Site-Based Player Immobilization)

An alternative to hard site-banning. Instead of blocking the connection, the Medusa Object silently sets banned players to `SLAVE FUBAR` on connect, making them unable to do anything. On disconnect, the flags are removed (so their character object isn't permanently affected).

## Use case

Countering trolls who treat sitelocks as "badges of honor." Being turned into a helpless object is more demoralizing and confusing than a clean ban.

## Object

```mushcode
@create Global: The Medusa Object=10
@set Global: The Medusa Object=INDESTRUCTABLE SAFE INHERIT
```

## Core hooks

```mushcode
@@ On connect: if site matches and player not exempt → immobilize
@Aconnect Global: The Medusa Object=
  @swi/f [!!and(wildmatch(v(sites),lookup_site(%#)), !match(v(exempt),%#))]=
  1,{@set %#=slave fubar}

@@ On disconnect: remove flags (clean up, don't permanently flag)
@Adisconnect Global: The Medusa Object=
  @swi/f [!!wildmatch(v(sites),lookup_site(%#))]=
  1,{@set %#=!slave !fubar}

@@ On startup: clean up any stuck flags from crashed sessions
@Startup Global: The Medusa Object=
  @dolist search(eplayer=[lit([hasflag(##,guest)])])={
    @swi/f [hasflag(##,connect)]=0, @set ##=!fubar !slave
  }
```

## Configuration attributes

```mushcode
@@ Wildcard-matched site patterns (space-separated)
&SITES Global: The Medusa Object=*.example-troll.com *static.badhost.net 192.168.1.*

@@ Exempt player dbrefs (space-separated) — skip medusa for good players from bad sites
&EXEMPT Global: The Medusa Object=#123 #456
```

## Key functions used

### lookup_site()
Returns the connecting hostname or IP of a connected player:

```mushcode
[lookup_site(%#)]    @@ "host.example.com" or "12.34.56.78"
```

### wildmatch()
Pattern matching with wildcards (`*`, `?`):

```mushcode
[wildmatch(*.badhost.net, lookup_site(%#))]   @@ 1 if site matches pattern
[wildmatch(v(sites), lookup_site(%#))]         @@ match against space-sep list of patterns
```

### SLAVE and FUBAR flags

| Flag | Effect |
|------|--------|
| `SLAVE` | Player cannot execute commands |
| `FUBAR` | Player cannot use any softcode/commands (complete lockout) |

These are set/unset with `@set`:

```mushcode
@set %#=slave fubar       @@ immobilize
@set %#=!slave !fubar     @@ restore
```

## @Aconnect / @Adisconnect hooks

These fire on **any** player connecting/disconnecting, regardless of location. The object needs to be in the Master Room or have INHERIT.

```mushcode
@Aconnect Obj=<code run when any player connects>
@Adisconnect Obj=<code run when any player disconnects>
```

`%#` inside these hooks = the player connecting/disconnecting.

## Extending: log to file

```mushcode
@Aconnect Global: The Medusa Object=
  @swi/f [!!and(wildmatch(v(sites),lookup_site(%#)), !match(v(exempt),%#))]=
  1,{@set %#=slave fubar; @pemit/list [v(notify_list)]=%[MEDUSA%] [name(%#)] immobilized from [lookup_site(%#)]}
```
