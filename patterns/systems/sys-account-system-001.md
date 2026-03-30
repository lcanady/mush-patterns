---
id: sys-account-system-001
domain: systems
server: RhostMUSH
source: volundmush/rhostcode (CORE 07 - Account System.txt, CORE 08 - File Object.txt)
complexity: high
tags: [account, alt, login, register, chargen, password, connect, player-management]
date_added: "2026-03-30"
tested: false
---

# Pattern: Account / alt management system

One account object holds multiple character objects. Characters authenticate to the account, not to themselves. Account data lives on a per-account THING object (`ACCOUNT` totem). Characters link back with `_ACCOUNT`. Password is shared at account level.

This separates "who you are" (account) from "what character you're playing" (PC/NPC object), enabling alt management, unified preferences, and single-password login.

## Data model

```
#acc (Account Library) — registers/manages all accounts
  │
  └── <AccountObj> [ACCOUNT totem]
        ├── _PASSWORD           = hashed password
        ├── CHARACTERS          = space-delimited list of objids
        ├── EMAIL               = player email
        ├── CREATED_AT          = secs() timestamp
        └── <AccOpts child>     = per-account preferences (OPT.* attrs)

Character object [PC or NPC totem]
  ├── _ACCOUNT                  = objid of parent account
  └── (all character-specific attrs)
```

## Login flow (on `#fobj` — the file/connect object)

```mushcode
@@ CONNECT attr — shown to all connecting players (the login screen)
&CONNECT #fobj=
  @pemit %#=[header(Welcome)]
  @pemit %#=Commands: connect <account> <password> | register <name> <email> | guest
  @pemit %#=[footer()]

@@ RUN_CONNECT — handles "connect <account> <password>"
&RUN_CONNECT #fobj=
  [setq(0, match(lattr(#acc/ACC.*), [first(%0)]))]
  @switch [strlen(%q0)]=
    0, @pemit %#=No account named '[first(%0)]'.,
    [setq(a, locate(#acc, ACC.[first(%0)], n))]
    @switch [attrpass(%qa, _PASSWORD, last(%0))]=
      0, @pemit %#=Incorrect password.,
      @attach %!/DO_LOGIN=%qa

@@ DO_LOGIN — pick-a-character or auto-connect if only one char
&DO_LOGIN #fobj=
  [setq(c, u(%0/CHARACTERS))]
  @switch [words(%qc)]=
    0, @pemit %#=This account has no characters. Use 'chargen' to create one.,
    1, @attach %!/DO_CONNECT_CHAR=[first(%qc)],
    @attach %!/SHOW_CHAR_LIST=%0
```

## Registration

```mushcode
&RUN_REGISTER #fobj=
  @switch [getconf(#conf, allow_registration)]=
    0, @pemit %#=Registration is closed.,
    [setq(0, first(%0))]    @@ account name
    [setq(1, last(%0))]     @@ email
    @switch [hasattr(#acc, ACC.[ucstr(%q0)])]=
      1, @pemit %#=That account name is taken.,
      @attach %!/DO_REGISTER=%q0,%q1

&DO_REGISTER #fobj=
  [setq(p, create([first(%0,%,)] Account, 10))]
  @totem %qp=ACCOUNT
  @parent %qp=#acc_parent
  @chown %qp=#acc
  @set %qp=_PASSWORD:[sha0(%1)]
  @set %qp=EMAIL:[secure(%1)]
  @set %qp=CREATED_AT:[secs()]
  @set #acc=ACC.[ucstr(first(%0,%,))]:1
  @pemit %#=Account created. Now use 'chargen' to create your first character.
```

## Character generation trigger

```mushcode
&RUN_CHARGEN #fobj=
  @switch [isdbref(setq(a, locate(#acc, ACC.[first(%0)], n)))]=
    0, @pemit %#=Log in first.,
    @switch [attrpass(%qa, _PASSWORD, last(%0))]=
      0, @pemit %#=Incorrect password.,
      @attach %!/DO_CHARGEN=%qa

&DO_CHARGEN #fobj=
  [setq(c, create([first(%0,%,)], 10))]
  @totem %qc=PC
  @parent %qc=tag(pc_parent)
  @chown %qc=tag(global_obj)
  @set %qc=_ACCOUNT:[objid(%0)]
  @set %0=CHARACTERS:[setunion(default(%0/CHARACTERS,), objid(%qc))]
  @tel %qc=tag(chargen_room)
  @force %qc=look
```

## Account connect helper

```mushcode
@@ account_login(account_obj, password) → 1 on success, 0 on fail
&GFN.ACCOUNT_LOGIN #func=
  [and(isdbref(%0), attrpass(%0, _PASSWORD, %1))]

@@ account_owner(character) → objid of account
&GFN.ACCOUNT_OWNER #func=
  [default(%0/_ACCOUNT, #-1)]
```

## Notes

- Store passwords via `@set obj=_PASSWORD:[sha0(pass)]` — use `attrpass()` to verify, never `get()`. The `_` prefix makes `_PASSWORD` wiz-only hidden from casual `examine`.
- `objid()` vs `num()` — always store `objid(%0)` in `CHARACTERS` lists and `_ACCOUNT`. `objid()` includes the creation timestamp, making it globally unique even across `@dump`/`@load` cycles that reassign dbrefs.
- Gate `DO_REGISTER` behind `getconf(#conf, allow_registration)` so staff can toggle registration without code changes.
- The `ACC.<NAME>` attribute on `#acc` acts as an index. Its value is just `1` (a flag); the real data is on the account object itself, found via `locate(#acc, ACC.<NAME>, n)`.
- Per-account preferences live on a child `AccOpts` object (not on the account itself) to keep the account object uncluttered. Resolve via `locate(account, AccOpts, n)`.
- In RhostMUSH, use `@totem <obj>=ACCOUNT` / `@totem <obj>=PC` with totems defined in `codesuite.conf` to type-tag objects for later `hastotem()` checks.

## Security notes

- Never store plaintext passwords. `sha0()` is the RhostMUSH built-in; consider using a salted scheme if your server supports it.
- `secure()` all user-provided strings before storing in attributes.
- Rate-limit the connect/register commands via the `sec-rate-limit-001` pattern to prevent brute-force attacks.

## Source

Extracted from: `CORE 07 - Account System.txt`, `CORE 08 - File Object.txt` in https://github.com/volundmush/rhostcode
