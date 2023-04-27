/datum/action/cooldown/spell/summon_cult_dagger
	name = "Summon Ritual Dagger"
	desc = "Allows you to summon a ritual dagger, in case you've lost the dagger that was given to you."
	DEFINE_CULT_ACTION("equip", 'icons/mob/actions/actions_cult.dmi')

	sound = null
	invocation = "Wur d'dai leev'mai k'sagan!" //where did I leave my keys, again?
	spell_requirements = NONE
	school = SCHOOL_SANGUINE

	/// The item given to the cultist when the spell is invoked. Typepath.
	var/obj/item/summoned_type = /obj/item/melee/cultblade/dagger

/datum/action/cooldown/spell/summon_cult_dagger/New(Target, original)
	. = ..()
	AddComponent(/datum/component/charge_spell, charges = 1)

/datum/action/cooldown/spell/summon_cult_dagger/is_valid_target(atom/cast_on)
	return isliving(cast_on)

/datum/action/cooldown/spell/summon_cult_dagger/cast(mob/living/cast_on)
	. = ..()

	cast_on.visible_message(span_warning("[cast_on]'s hand glows red for a moment."),
		span_cultitalic("Your plea for aid is answered, and light begins to shimmer and take form within your hand!"),
	)
	var/obj/item/summoned_blade = new summoned_type(cast_on.loc)
	if(cast_on.put_in_hands(summoned_blade))
		cast_on.visible_message(
			span_warning("A [summoned_blade] appears in [owner]'s hand!"),
			span_cultitalic("A [summoned_blade] materializes in your hands."),
		)
	else
		cast_on.visible_message(
			span_warning("A [summoned_blade] appears at [owner]'s feet!"),
			span_cultitalic("A [summoned_blade] materializes at your feet."),
		)

	SEND_SOUND(cast_on, sound('sound/effects/magic.ogg', FALSE, 0, 25))
