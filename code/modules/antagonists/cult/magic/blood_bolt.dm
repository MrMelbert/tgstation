/// Not a default cult spell.
/// This is the blood barrage invoked by using blood rites.
/datum/action/cooldown/spell/conjure_item/infinite_guns/blood_bolt
	name = "Blood Bold Barrage"
	desc = ""
	DEFINE_CULT_ACTION("arcane_barrage", 'icons/mob/actions/actions_spells.dmi')

	// default_button_position = DEFAULT_UNIQUE_BLOODSPELLS
	default_button_position = "5:67,4:30"

	sound = null
	invocation_type = INVOCATION_NONE
	cooldown_time = 20 SECONDS
	spell_requirements = NONE
	school = SCHOOL_SANGUINE

	item_type = /obj/item/gun/ballistic/rifle/enchanted/arcane_barrage/blood

	/// If TRUE, the spell deletes itself after casting it.
	/// Doesn't delete the barrage item though.
	var/delete_after_cast = TRUE

/datum/action/cooldown/spell/conjure_item/infinite_guns/blood_bolt/after_cast(atom/cast_on)
	. = ..()
	if(delete_after_cast)
		qdel(src)

/obj/item/gun/ballistic/rifle/enchanted/arcane_barrage/blood
	name = "blood bolt barrage"
	desc = "Blood for blood."
	color = "#ff0000"
	guns_left = 24
	mag_type = /obj/item/ammo_box/magazine/internal/blood
	fire_sound = 'sound/magic/wand_teleport.ogg'

/obj/item/gun/ballistic/rifle/enchanted/arcane_barrage/blood/can_trigger_gun(mob/living/user, akimbo_usage)
	if(akimbo_usage)
		return FALSE //no akimbo wielding magic lol.
	. = ..()
	if(!.)
		return FALSE
	if(IS_CULTIST(user))
		return TRUE

	to_chat(user, span_cultlarge("\"Did you truly think that you could channel MY blood without my approval? Amusing, but futile.\""))
	var/lefthand_cast = (user.active_hand_index % 2 == 0)
	user.apply_damage(20, BRUTE, lefthand_cast ? BODY_ZONE_L_ARM : BODY_ZONE_R_ARM, sharpness = SHARP_EDGED)
	qdel(src)
	return FALSE

/obj/item/ammo_box/magazine/internal/blood
	caliber = CALIBER_A762
	ammo_type = /obj/item/ammo_casing/magic/arcane_barrage/blood

/obj/item/ammo_casing/magic/arcane_barrage/blood
	projectile_type = /obj/projectile/magic/arcane_barrage/blood
	firing_effect_type = /obj/effect/temp_visual/cult/sparks

/obj/projectile/magic/arcane_barrage/blood
	name = "blood bolt"
	icon_state = "mini_leaper"
	nondirectional_sprite = TRUE
	damage_type = BRUTE
	impact_effect_type = /obj/effect/temp_visual/dir_setting/bloodsplatter

/obj/projectile/magic/arcane_barrage/blood/on_hit(atom/target, blocked, pierce_hit)
	if(!ismob(target))
		return ..()

	var/mob/mob_target = target
	var/turf/splat_turf = get_turf(target)
	playsound(splat_turf, 'sound/effects/splat.ogg', 50, TRUE)

	if(!IS_CULTIST(mob_target))
		return ..()

	if(ishuman(target) && mob_target.reagents && mob_target.stat != DEAD)
		mob_target.reagents.add_reagent(/datum/reagent/fuel/unholywater, 4)

	if(isshade(target) || isconstruct(target))
		var/mob/living/simple_animal/cult_creature = target
		cult_creature.adjustHealth(-5)

	new /obj/effect/temp_visual/cult/sparks(splat_turf)
	return BULLET_ACT_BLOCK
