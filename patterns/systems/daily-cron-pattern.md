---
id: daily-cron-pattern-001
domain: systems
server: RhostMUSH
source: RhostMUSH/trunk Mushcode/daily, Mushcode/MyrddinCRON
complexity: medium
tags: [cron, daily, scheduling, totem, wait-until, convtime, @startup]
date_added: "2026-03-27"
tested: true
---

# Pattern: Daily Emulator / Cron Scheduling

RhostMUSH provides two approaches to scheduled tasks: the lightweight `Daily Emulator` using `@wait/until`, and Myrddin's full CRON system.

## Approach 1: Daily Emulator (`@wait/until convtime()`)

Simple daily trigger at a fixed time. Uses RhostMUSH's `@wait/until` and the `totem` system.

### netrhost.conf setup (required)

```
totem_add daily 7 0x80000000
totem_letter daily 0 d
```

This creates a `d` totem letter that marks objects as "run daily".

### Softcode

```mushcode
@create Daily Emulator <DE>
@tag/add daily=Daily Emulator <DE>      @@ mark this object with the daily totem
@set Daily Emulator <DE>=safe ind inh !halt

@@ On startup, begin the polling loop
@startup Daily Emulator <DE>=@wait 300=@tr/quiet me/do_daily

@@ Fire daily attr on all objects tagged with totem 'd', then re-arm
&DO_DAILY Daily Emulator <DE>=
  @wait/until [convtime([extract(time(),1,3)] [v(DAILY_TRIGGER)] [extract(time(),5,1)])]={
    @dolist [search(totem=d)]={@tr/quiet ##/daily};
    @wait 300=@tr/quiet me/do_daily
  }

@@ Set trigger time (24-hour HH:MM:SS)
&DAILY_TRIGGER Daily Emulator <DE>=23:59:59
```

### How `convtime()` works here

```mushcode
convtime(<date> <time> <timezone>)
```

- `extract(time(),1,3)` → current date string ("Mon Jan 01 2026")
- `v(DAILY_TRIGGER)` → "23:59:59"
- `extract(time(),5,1)` → current timezone string ("PST")

Result: seconds-since-epoch for midnight tonight. `@wait/until <secs>` fires when server clock reaches that moment.

### Marking objects to run daily

Any object with the `daily` totem will have its `&DAILY` attribute triggered:

```mushcode
@tag/add daily=My Object         @@ mark for daily runs
&DAILY My Object=@pemit #1=Daily check fired!
```

## Approach 2: @wait/until re-arm loop (no totem)

Without the totem system, poll with a loop:

```mushcode
@startup Obj=@wait 60=@tr/quiet me/check_loop

&CHECK_LOOP Obj=
  @wait/until [convtime([extract(time(),1,3)] 06:00:00 [extract(time(),5,1)])]={
    @tr me/do_morning_task;
    @wait 300=@tr/quiet me/check_loop
  }
```

The 300-second `@wait` before re-arming prevents immediate re-trigger when the wait resolves.

## Approach 3: Myrddin's CRON

Full cron-style scheduling. Install via `Mushcode/MyrddinCRON`. Provides:
- Minute, hour, day, weekday, month scheduling
- Per-object `&CRON` attributes
- Separate cron object manages the schedule

Objects register themselves with the CRON system; the CRON object polls and fires triggers based on schedule expressions.

> See `Mushcode/MyrddinCRON` for the full install file.

## Startup loop pattern (general)

The standard RhostMUSH pattern for any repeating background task:

```mushcode
@startup Obj=@wait <initial_delay>=@tr/quiet me/do_loop

&DO_LOOP Obj=
  <... do work ...>;
  @wait <interval>=@tr/quiet me/do_loop
```

- `@tr/quiet` — trigger without echoing the trigger to the room
- Always re-arm at the **end** of the handler (not the beginning)
- Use `@wait 1` not `@wait 0` to avoid synchronous execution issues

## @startup best practices

```mushcode
@@ Good: quiet trigger to prevent spam
@startup Obj=@wait 1=@tr/quiet me/init

@@ Good: chain multiple startup actions
@startup Obj=
  @wait 1=@tr/quiet me/init_data;
  @wait 2=@tr/quiet me/init_cmds

@@ Bad: long-running code directly in @startup (blocks server)
@@ @startup Obj=[iter(huge_list, ...)]    ← don't do this
```

## time() format in RhostMUSH

`time()` returns a string like: `"Mon Mar 27 14:30:00 2026 PST"`

| `extract(time(), N, 1)` | Value |
|------------------------|-------|
| 1 | Day-of-week ("Mon") |
| 2 | Month name ("Mar") |
| 3 | Day number ("27") |
| 4 | Time ("14:30:00") |
| 5 | Timezone ("PST") |
| 6 | Year ("2026") |

`extract(time(),1,3)` grabs fields 1–3: `"Mon Mar 27"` — the date portion for `convtime()`.
