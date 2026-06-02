/*
################################################################################
## GMCCG → RHOST MIGRATION: 2a - Stat Functions Prototype Setup
## Source:  https://github.com/thenomain/GMCCG (TinyMUX)
## Target:  RhostMUSH
## Migrated: 2026-03-27
## Changes:  NONE — fully compatible with RhostMUSH as-is.
##
## Install after: 1c
################################################################################
*/

/*
================================================================================
== SETUP =======================================================================
*/

@create Stat Functions Prototype <sfp>
@set Stat Functions Prototype <sfp>=inherit safe
@lock Stat Functions Prototype <sfp>=haspower(me,Wizard)
@lock/use Stat Functions Prototype <sfp>=haspower(me,Wizard)

@fo me=&d.sfp me=[search( name=Stat Functions Prototype <sfp> )]

@fo me=@parent Stat Functions Prototype <sfp>=search( name=Code Object Data Parent <codp> )


/*
================================================================================
== DATA ========================================================================
*/

@fo me=&d.data-dictionary [v( d.sfp )]=search( name=Data Dictionary <dd> )
@fo me=&d.data-tags [v( d.sfp )]=search( name=Data Tags <d:t> )

@fo me=&d.sfp [v( d.dd )]=search( name=Stat Functions Prototype <sfp> )


/*
================================================================================
== DOT-FUNCTIONS ===============================================================

--------------------------------------------------------------------------------
-- Dot-Function: Grab Exact ----------------------------------------------------
*/

&.grabexact [v( d.sfp )]=
	localize(
		if(
			t( setr( m, grab( %0, %1, %2, %2 ))),
			%qm,
			grab( sort( %0, ?, %2, %2 ), %1*, %2 )
		)
	)

/*
--------------------------------------------------------------------------------
-- Dot-Function: Crumple -------------------------------------------------------
*/

&.crumple [v( d.sfp )]=trim( squish( %0, %1 ), b, %1 )

/*
--------------------------------------------------------------------------------
-- Dot-Function: Pmatch --------------------------------------------------------
*/

&.pmatch [v( d.sfp )]=
	localize( strcat(
		setq( p,
			if( strmatch( %0, me ),
				%#,
				objeval( %#, pmatch( %0 ))
			)
		),
		if( cor( t( %qp ), not( t( %1 ))),
			%qp,
			first( search( eplayer=strmatch( name( ## ), %0* )))
		)
	))


/*
================================================================================
== SEARCH ORDER ================================================================
*/

&d.search-order [v( d.sfp )]=
	iter( sort( lattr( %!/d.search-order-* )), v( %i0 ))
&d.search-order-01 [v( d.sfp )]=attribute skill merit advantage
&d.search-order-09 [v( d.sfp )]=bio

&d.type.specials [v( d.sfp )]=special health

&filter.search-types [v( d.sfp )]=
	t( match( u( d.search-order ), first( %0, . )))

&sortby.types [v( d.sfp )]=
	[setq( o, u( d.search-order ))]
	[sub( match( %qo, first( %0, . )), match( %qo, first( %1, . )))]
