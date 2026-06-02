---
id: softfunctions-object-001
domain: systems
server: RhostMUSH
source: RhostMUSH/trunk Mushcode/softfunctions.minmax
complexity: high
tags: [softfunctions, function, global-function, @function, minmax, compat, pennmush, mux]
date_added: "2026-03-27"
tested: true
---

# Pattern: SoftFunctions Object

RhostMUSH allows registering softcode attributes as global callable functions via `@function`. The `softfunctions.minmax` file is the canonical example — it provides PennMUSH/MUX-compatible function aliases for functions that differ or are missing in RhostMUSH.

## Object structure

```mushcode
@create SoftFunctions
@set SoftFunctions=!no_command !halt inh safe indestructable

@create SFSideFX
@set SFSideFX=!no_command !halt inh safe indestructable sidefx

@fo SoftFunctions=&DB me=num(SoftFunctions)
@tel SFSideFX=softfunctions    @@ SFSideFX lives inside SoftFunctions
```

Two objects:
- **SoftFunctions** — holds function definitions (no SIDEFX needed for pure calculation)
- **SFSideFX** — child object with SIDEFX flag for functions that need side effects (like `set()`)

## Function definition naming conventions

| Prefix | Type | Registration command |
|--------|------|---------------------|
| `FUN_name` | Normal function | `@function name=obj/FUN_name` |
| `FUNPR_name` | Preserved (registers saved) | `@function/pres name=obj/FUNPR_name` |
| `FUNPV_name` | Privileged (requires power) | `@function/priv name=obj/FUNPV_name` |
| `FUNP_name` | Preserved + Privileged | `@function/priv/pres name=obj/FUNP_name` |
| `FUNPT_name` | Privileged + NoTrace | `@function/priv/notrace name=obj/FUNPT_name` |
| `MINMAX_name` | Arg count limits | `@function/min name=first; @function/max name=rest` |
| `FUNFLAG_name` | Access flags | `@admin function_access=name flag` |

## @startup — auto-register all functions

```mushcode
@startup SoftFunctions=
  @dolist lattr([v(db)]/fun_*)=  @function [after(##,_)]=[v(db)]/##;
  @dolist lattr([v(db)]/funp_*)= @function/priv/pres [after(##,_)]=[v(db)]/##;
  @dolist lattr([v(DB)]/funpr_*)=@function/pres [after(##,_)]=[v(DB)]/##;
  @dolist lattr([v(db)]/funpv_*)=@function/priv [after(##,_)]=[v(DB)]/##;
  @dolist lattr([v(db)]/funpt_*)=@function/priv/notrace [after(##,_)]=[v(db)]/##;
  @wait 10={
    @dolist lattr([v(db)]/funflag_*)=@admin function_access=[after(##,_)] [get([v(db)]/##)]
  };
  @wait 10=
    @dolist lattr([v(db)]/minmax_*)={
      @function/min [after(##,_)]=[first(get([v(db)]/##))];
      @function/max [after(##,_)]=[rest(get([v(db)]/##))]
    }
```

## Example function definitions

### Simple compat shim

```mushcode
@@ itemize() → elist() (PennMUSH name → RhostMUSH native)
&FUN_ITEMIZE SoftFunctions=[elist(%0,%2,%1,%4,%3)]
&MINMAX_ITEMIZE SoftFunctions=1 4

@@ poll() → doing()
&FUN_POLL SoftFunctions=[doing()]
&MINMAX_POLL SoftFunctions=1 1
```

### Privileged function (needs wizard context)

```mushcode
&FUNPV_ALIGN SoftFunctions=[u(align_handler[eq(add(words(%0),1),%+)],...)]
```

### Function with side effects (uses SFSideFX child)

```mushcode
&SET sfsidefx=[streval([set([before(%0,/)],[trim(after(%0,/))]:%1)],extract(cit guild arch coun roy imm god,bittype(%2)),%0,%1,%2)]
```

### LETQ — scoped register (like let-binding)

```mushcode
&FUN_LETQ SoftFunctions=[pushregs(+z)][setq(z,[ifelse(!$nameq(%0),%0,nameq(nameq(%0),,1))])][ifelse(match(%qz,z),,pushregs(+%qz))][setq([r(z)],%1)][eval(%2)][pushregs(-%qz -z)]
&MINMAX_LETQ SoftFunctions=3 3
&FUNFLAG_LETQ SoftFunctions=no_eval
```

`pushregs(+z)` / `pushregs(-z)` — save and restore registers. RhostMUSH-specific stack operation.

## Registering a single function manually

```mushcode
@function funcname=<dbref>/FUN_FUNCNAME          @@ normal
@function/pres funcname=<dbref>/FUNPR_FUNCNAME   @@ preserved (saves %q0-%q9)
@function/priv funcname=<dbref>/FUNPV_FUNCNAME   @@ wizard-only callers
@function/min funcname=2                          @@ minimum arg count
@function/max funcname=4                          @@ maximum arg count
@admin function_access=funcname no_eval           @@ flag: don't eval args
```

## Checking if a function exists before using it

```mushcode
@switch setr(0,1)=1,{
  @pemit %#=setr() works. Good.;
  &FN_SETR [v(dbref_pocket)];   @@ clear the stub
},
{
  @pemit %#=setr() missing — installing soft fallback.;
  @function/priv setr=<dbref>/fn_setr
}
```

## Key functions confirmed present in RhostMUSH

From `softfunctions.minmax` — these are NOT shimmed (i.e., they exist natively):

| Function | Notes |
|----------|-------|
| `elist()` | Native — shimmed as `itemize()` for PennMUSH compat |
| `setr()` | Native (shimmed only as fallback) |
| `ifelse()` | Native (shimmed only as fallback) |
| `timefmt()` | Native |
| `randextract()` | Native |
| `columns()` | Native (different from `column()`) |
| `ofparse()` | Native — backs `firstof()` / `allof()` |
| `spellnum()` | Native — backs `ordinal()` |
| `mask()` | Native — backs `band()`, `bor()` |
| `size()` | Native — backs `objmem()` |
| `creplace()` | Native — backs `strinsert()` |
| `sortlist()` | Native — backs `vmax()`, `vmin()` |
| `pack()` / `unpack()` | Native — backs `baseconv()` |

## pushregs() / nameq() — register stack

RhostMUSH-specific register management:

```mushcode
[pushregs(+z)]           @@ push register z onto stack (save it)
[pushregs(-z)]           @@ pop register z (restore it)
[pushregs(+z -a -b)]     @@ push z, pop a and b

[nameq(%0)]              @@ return name of register %0
[nameq(%0,,1)]           @@ return name, creating if needed
```

## strfunc() — build a function call dynamically

```mushcode
[strfunc(printf, format_string, arg1, arg2, ...)]
@@ equivalent to: printf(format_string, arg1, arg2, ...)
@@ useful when the function name or arg count is dynamic
```
