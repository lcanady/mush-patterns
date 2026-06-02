/*
################################################################################
## GMCCG → RHOST MIGRATION: 2d - User-Defined Functions
## Source:  https://github.com/thenomain/GMCCG (TinyMUX)
## Target:  RhostMUSH
## Migrated: 2026-03-27
##
## CHANGES (1 change):
##   @function/preserve/privileged → @function/preserve/privilege
##
##   TinyMUX uses the switch name '/privileged'; RhostMUSH uses '/privilege'.
##   The abbreviated form '/priv' also works in Rhost.
##   This change is applied in the @startup attribute below.
##
## Install after: 2c (all of 2a–2c must be installed first)
## Note: 2b and 2c (Statpath Functions, Support Functions) require no changes
##       and are installed directly from source.
################################################################################
*/

/*
================================================================================
== @startup ====================================================================

Re-registers all UDFs every time the server starts. Install on SFP object.
RhostMUSH @function definitions are not stored in DB — they must be
re-registered on startup.

CHANGE: /privileged → /privilege (RhostMUSH switch name)
*/

@startup [v( d.sfp )]=
	@dolist lattr( %!/ufunc.* )=
		@function/preserve [rest( ##, . )]=%!/##;
	@dolist lattr( %!/ufunc/privileged.* )=
		@function/preserve/privilege [rest( ##, . )]=%!/##


/*
================================================================================
== statpath([<player>/]<stat>) =================================================

USER-DEFINED FUNCTION: STATPATH()

Returns the canonical stat path for a stat name (with fuzzy matching).

%0: [player/]stat — broken apart internally
Output: full stat path, or error string (#-1 ...)
*/

@fo me=&ufunc/privileged.statpath [v( d.sfp )]=
	u\\( [v( d.sfp )]/f.statpath, \\%0 \\)

&f.statpath [v( d.sfp )]=

	[setq( s, )][setq( p,
		if( strmatch( %0, */* ),
			u( .pmatch, first( %0, / )),
			%#
		)
	)]
	[if( not( t( %qp )),
		#-1 Player not found,
		ulocal( f.statpath.workhorse, rest( %0, / ), %qp )
	)]


/*
================================================================================
== statname([<player>/]<stat>) =================================================

USER-DEFINED FUNCTION: STATNAME()

Like statpath() but returns the pretty display name rather than the path.
*/

@fo me=&ufunc/privileged.statname [v( d.sfp )]=
	u\\( [v( d.sfp )]/f.statname, \\%0 \\)

&f.statname [v( d.sfp )]=
	localize( strcat(
		setq( s, ulocal( f.statpath, %0 )),
		if( t( match( %qs, #-* )),
			%qs,
			ulocal( f.statname.workhorse, %qs )
		)
	))


/*
================================================================================
== getstat(<sheet>, <statpath>[, <mode>]) ======================================

USER-DEFINED FUNCTION: GETSTAT()

Returns the value of a stat on a character sheet.

%0: sheet dbref
%1: full stat path
%2: mode — blank (default/perm), 'offset', 'total', 'base', 'full'
*/

@fo me=&ufunc/privileged.getstat [v( d.sfp )]=
	u\\( [v( d.sfp )]/f.getstat, \\%0, \\%1, \\%2 \\)

&f.getstat [v( d.sfp )]=
	ulocal( f.getstat.workhorse, %0, _%1, %2 )


/*
================================================================================
== setstat(<sheet>, <statpath>, <value>[, <mode>]) =============================

USER-DEFINED FUNCTION: SETSTAT()

Sets a stat on a character sheet. Staff/privileged use only.

%0: sheet dbref
%1: full stat path
%2: value to set
%3: mode — blank (normal), 'offset', 'override'
*/

@fo me=&ufunc/privileged.setstat [v( d.sfp )]=
	u\\( [v( d.sfp )]/f.setstat, \\%0, \\%1, \\%2, \\%3 \\)

&f.setstat [v( d.sfp )]=
	ulocal( f.setstat.workhorse, %0, _%1, %2, %3 )


/*
================================================================================
== shiftstat(<sheet>, <statpath>, <delta>[, <mode>]) ===========================

USER-DEFINED FUNCTION: SHIFTSTAT()

Adjusts a numeric stat by a delta (positive or negative).

%0: sheet dbref
%1: full stat path
%2: delta (numeric, may be negative)
%3: mode — blank (normal), 'offset'
*/

@fo me=&ufunc/privileged.shiftstat [v( d.sfp )]=
	u\\( [v( d.sfp )]/f.shiftstat, \\%0, \\%1, \\%2, \\%3 \\)

&f.shiftstat [v( d.sfp )]=
	ulocal( f.shiftstat.workhorse, %0, _%1, %2, %3 )


/*
================================================================================
== statvalidate(<statpath>, <value>) ===========================================

USER-DEFINED FUNCTION: STATVALIDATE()

Returns 1 if <value> is valid for <statpath> per the data dictionary.
Returns error string otherwise.

%0: stat path
%1: value to validate
*/

@fo me=&ufunc/privileged.statvalidate [v( d.sfp )]=
	u\\( [v( d.sfp )]/f.statvalidate, \\%0, \\%1 \\)

&f.statvalidate [v( d.sfp )]=
	ulocal( f.statvalidate.workhorse, %0, %1 )


/*
================================================================================
== hastag?(<statpath>, <tag>) ==================================================

USER-DEFINED FUNCTION: HASTAG?()

Returns 1 if the stat at <statpath> has the specified tag.

%0: stat path
%1: tag to check
*/

@fo me=&ufunc.hastag? [v( d.sfp )]=
	u\\( [v( d.sfp )]/f.hastag?, \\%0, \\%1 \\)

&f.hastag? [v( d.sfp )]=
	ulocal( f.hastag?.workhorse, %0, %1 )


/*
================================================================================
== roll(<dice-expression>[, <n-again>[, <weakness?>]]) =========================

USER-DEFINED FUNCTION: ROLL()

Rolls a dice pool. Registered by the Roller subsystem (Phase 2).
Stub defined here for completeness — overwritten by 6e install.

%0: dice count or stat expression
%1: n-again threshold (default 10)
%2: weakness mode (1 = active)
*/

// (Registered by roller install — see phase2/6e-roller-commands.mu)
