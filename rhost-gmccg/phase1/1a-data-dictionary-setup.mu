/*
################################################################################
## GMCCG → RHOST MIGRATION: 1a - Data Dictionary Setup
## Source:  https://github.com/thenomain/GMCCG (TinyMUX)
## Target:  RhostMUSH
## Migrated: 2026-03-27
## Changes:  NONE — fully compatible with RhostMUSH as-is.
##
## Install order: 1a → 1b → 1c → 2a → 2b → 2c → 2d
## Requires: d.codp (Code Object Data Parent dbref) already set on installer.
################################################################################
*/

/*
================================================================================
== SETUP =======================================================================
*/

@create Data Dictionary <dd>
@set  Data Dictionary <dd>=inherit safe
@lock Data Dictionary <dd>=haspower(me,Wizard)
@lock/use Data Dictionary <dd>=haspower(me,Wizard)

@fo me=&d.dd me=search( name=Data Dictionary <dd> )

@fo me=@parent Data Dictionary <dd>=[v( d.codp )]
&prefix.functions Data Dictionary <dd>=.
&prefix.attributes Data Dictionary <dd>=attribute.
&prefix.skills Data Dictionary <dd>=skill.
&prefix.merits Data Dictionary <dd>=merit.
&prefix.advantages Data Dictionary <dd>=advantage.
&prefix.bio Data Dictionary <dd>=bio.
&prefix.specials Data Dictionary <dd>=special.
&prefix.health Data Dictionary <dd>=health.
&prefix.conditions Data Dictionary <dd>=condition.
&prefix.specials Data Dictionary <dd>=special.


/*
--------------------------------------------------------------------------------
-- Data Tags -------------------------------------------------------------------
*/

@create Data Tags <d:t>
@set Data Tags <d:t>=inherit safe
@lock Data Tags <d:t>=haspower(me,Wizard)
@lock/use Data Tags <d:t>=haspower(me,Wizard)
@fo me=&d.dt me=search( name=Data Tags <d:t> )
@fo me=&d.dt [v( d.dd )]=search( name=Data Tags <d:t> )

@fo me=@parent [v( d.dt )]=[v( d.codp )]
&prefix.attributes [v( d.dt )]=tags.attribute.
&prefix.skills [v( d.dt )]=tags.skill.
&prefix.merits [v( d.dt )]=tags.merit.
&prefix.advantages [v( d.dt )]=tags.advantage.
&prefix.bio [v( d.dt )]=tags.bio.
&prefix.specials [v( d.dt )]=tags.special.
&prefix.health [v( d.dt )]=tags.health.
&prefix.conditions [v( d.dt )]=tags.condition.
&prefix.specials [v( d.dt )]=tags.special.


/*
================================================================================
== FUNCTIONS ===================================================================

Data Dictionary Prerequisite Shortcut Functions

--------------------------------------------------------------------------------
-- Class -----------------------------------------------------------------------
*/

&.Class [v( d.dd )]=u( [u( d.sfp )]/f.get-class, %0 )


/*
--------------------------------------------------------------------------------
-- Value -----------------------------------------------------------------------
*/

&.Value [v( d.dd )]=
	case( u( .class, %1 ),
		numeric, first( u( .value_full, %0, %1 ), . ),
		u( .value_full, %0, %1 )
	)

&.Value_Full [v( d.dd )]=
	udefault(
		[u( d.sfp )]/f.getstat.workhorse.[u( .class, %1 )],
		u( %0/_%1 ),
		%0, _%1
	)

&.Value_Stats [v( d.dd )]=
	ladd( iter( %1 , u( .value_full, %0, %i0 ), , . ), . )

&.Value_Stats_Template [v( d.dd )]=
	add(
		u( .value_stats, %0, %1 ),
		u( %2.[u( .value_full, %0, bio.template )], %0 )
	)


/*
--------------------------------------------------------------------------------
-- At Least --------------------------------------------------------------------
*/

&.At_Least [v( d.dd )]=
	gte( add( u( .value, %0, %1 ), %3 ), %2 )

&.At_Least_All [v( d.dd )]=
	land( iter( %1, u( .at_least, %0, first( %i0, : ), rest( %i0, : ))))

&.At_Least_One [v( d.dd )]=
	lor( iter( %1, u( .at_least, %0, first( %i0, : ), rest( %i0, : ))))

&.At_Least_Stat [v( d.dd )]=
	localize(
		[setq( t, trim( first( edit( %2, -, +- ), + )))]
		[setq( a,
			iter( rest( edit( edit( %2, -%b, - ), -, %b+- ), + ), %i0, + 	)
		)]
		[u(
			.at_least,
			%0,
			%1,
			ladd(
				[u( .value, %0, %qt )]
				%qa
			),
			%3
		)]
	)


/*
--------------------------------------------------------------------------------
-- At Most ---------------------------------------------------------------------
*/

&.At_Most [v( d.dd )]=
	lte( add( u( .value, %0, %1 ), %3 ), %2 )

&.At_Most_All [v( d.dd )]=
	land( iter( %1, u( .at_most, %0, first( %i0, : ), rest( %i0, : ))))

&.At_Most_One [v( d.dd )]=
	lor( iter( %1, u( .at_most, %0, first( %i0, : ), rest( %i0, : ))))

&.At_Most_Stat [v( d.dd )]=
	localize(
		[setq( t, trim( first( edit( %2, -, +- ), + )))]
		[setq( a,
			iter( rest( edit( edit( %2, -%b, - ), -, %b+- ), + ), %i0, + )
		)]
		[u( .at_most,
			%0,
			%1,
			ladd(
				[u( .value, %0, %qt )]
				%qa
			),
			%3
		)]
	)


/*
--------------------------------------------------------------------------------
-- Between ---------------------------------------------------------------------
*/

&.Between [v( d.dd )]=
	cand(
		u( .at_least, %0, %1, %2, %4 ),
		u( .at_most, %0, %1, %3, %4 )
	)


/*
--------------------------------------------------------------------------------
-- Is --------------------------------------------------------------------------
*/

&.Is [v( d.dd )]=
	strmatch( %2, if( t( %3 ), %3, u( .value, %0, %1 )))

&.Is_Full [v( d.dd )]=
	strmatch( %2, if( t( %3 ), %3, u( .value_full, %0, %1 )))

&.Is_Not [v( d.dd )]=
	not( u( .is, %0, %1, %2, %3 ))

&.Is_One_Of [v( d.dd )]=
	t( match( %2, if( t( %3 ), %3, u( .value, %0, %1 )), . ))

&.Is_None_Of [v( d.dd )]=
	not( u( .is_one_of, %0, %1, %2, %3 ))

&.Is_Stat [v( d.dd )]=
	u( .is_one_of, %0,
		%1,
		u( .value, %0, %2 )
	)


/*
--------------------------------------------------------------------------------
-- Has -------------------------------------------------------------------------
*/

&.Has [v( d.dd )]=
	if( member( last( %1, _ ), %(*%) ),
		t( lattr( %0/_%1 )),
		t( u( .value, %0, %1 ))
	)

&.Has_Not [v( d.dd )]=
	not( u( .value, %0, %1 ))

&.Has_One_Of [v( d.dd )]=
	lor( iter( %1, u( .has, %0, %i0 )))

&.Has_All_Of [v( d.dd )]=
	land( iter( %1, u( .has, %0, %i0 )))

&.Has_None_Of [v( d.dd )]=
	not( u( .has_one_of, %0, %1 ))


/*
--------------------------------------------------------------------------------
-- Min Of / Max Of -------------------------------------------------------------
*/

&.Min_Of [v( d.dd )]=
	min(
		u( .value, %0, first( %1 )),
		if(
			dec( words( rest( %1 ))),
			u( .min_of, %0, rest( %1 )),
			u( .value, %0, rest( %1 ))
		)
	)

&.Max_Of [v( d.dd )]=
	max(
		u( .value, %0, first( %1 )),
		if(
			dec( words( rest( %1 ))),
			u( .max_of, %0, rest( %1 )),
			u( .value, %0, rest( %1 ))
		)
	)


/*
--------------------------------------------------------------------------------
-- List Has --------------------------------------------------------------------
*/

&.List_Has [v( d.dd )]=
	t( match( u( .value_full, %0, %1 ), %2, . ))

&.List_Has_All [v( d.dd )]=
	eq(
		words( setinter( u( .value_full, %0, %1 ), %2, . ), . ),
		words( %2, . )
	)

&.List_Has_None [v( d.dd )]=
	eq(
		words( setinter( u( .value_full, %0, %1 ), %2, . ), . ),
		0
	)

&.List_At_Least [v( d.dd )]=gte( lmax( u( .value, %0, %1 ), . ), %2 )


/*
--------------------------------------------------------------------------------
-- Class: List -----------------------------------------------------------------
*/

&.class_translate_list [v( d.dd )]=
	case( 1,
		isnum( %1 ),
		elements( rest( v( %0 ), | ), %1, . ),
		t( match( first( v( %0 ), | ), %1, . )),
		elements( rest( v( %0 ), | ), match( first( v( %0 ), | ), %1, . ), . ),
		elements( first( v( %0 ), | ), match( rest( v( %0 ), | ), %1*, .), . )
	)


/*
--------------------------------------------------------------------------------
-- Max Trait / Trait Check -----------------------------------------------------
*/

&.max_trait [v( d.dd )]=
	add(
		max( 5,
			u( .value,
				%0,
				udefault(
					.max_trait.[u( .value_full, %0, bio.template )],
					0
				)
			)
		),
		ladd(
			iter(
				lattr( %!/.max_trait.[u( .value_full, %0, bio.template )].* ),
				u( %!/%i0, %0, %1 )
			)
		)
	)

&.max_trait.Changeling [v( d.dd )]=advantage.wyrd
&.max_trait.Werewolf [v( d.dd )]=advantage.primal_urge
&.max_trait.Promethean [v( d.dd )]=advantage.azoth
&.max_trait.Mage [v( d.dd )]=advantage.gnosis
&.max_trait.Geist [v( d.dd )]=advantage.psyche
&.max_trait.Skinthief [v( d.dd )]=advantage.supernatural_tolerance

&.max_trait.Werewolf.Embodiment [v( d.dd )]=
	u( .has, %0, merit.embodiment_of_the_firstborn_([rest( %1, . )]))

&.trait_check [v( d.dd )]=
	u( .at_most, %0, %1, u( .max_trait, %0, %1 ), %2 )


/*
--------------------------------------------------------------------------------
-- Sphere ----------------------------------------------------------------------
*/

&.sphere [v( d.dd )]=
	localize( strcat(
		setq( s,
			lcstr(
				last(
					grepi(
						%!,
						.sphere.*,
						edit( u( .value_full, %0, bio.template ), %b, _ )
					),
					.
				)
			)
		),
		if( t( %qs ), %qs )
	))

&.sphere.human [v( d.dd )]=Human
&.sphere.vampire [v( d.dd )]=Vampire Ghoul
&.sphere.demon [v( d.dd )]=Demon Stigmatic
&.sphere.werewolf [v( d.dd )]=Werewolf Wolf-Blooded


/*
--------------------------------------------------------------------------------
-- Specialties -----------------------------------------------------------------
*/

&.Specialty_For [v( d.dd )]=
	lcstr(
		rest(
			first(
				sort( iter( lattr( %0/_skill.*.%1 ), elements( %i0, 1 2, . )))
			),
			_
		)
	)

&.Specialty_Has [v( d.dd )]=
	gt( words( iter( %1, lattr( %0/_skill.%i0.%2 ))), 0 )


/*
--------------------------------------------------------------------------------
-- Instanced -------------------------------------------------------------------
*/

&.instanced_once [v( d.dd )]=
	localize( strcat(
		setq( p, first( %1 , _%(%) )),
		setq( i, before( rest( %1, _(, )), ) ),
		not(
			setdiff(
				lattr( %0/%qp_(*) ),
				_%qp_(%qi)
			)
		)
	))
