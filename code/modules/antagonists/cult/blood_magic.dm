/datum/action/innate/cult/blood_spell/manipulation
	name = "Blood Rites"
	desc = "Empowers your hand to absorb blood to be used for advanced rites, or heal a cultist on contact. Use the spell in-hand to cast advanced rites."
	invocation = "Fel'th Dol Ab'orod!"
	button_icon_state = "manip"
	charges = 5
	magic_path = "/obj/item/melee/blood_magic/manipulator"

/obj/item/melee/blood_magic/manipulator
	name = "Blood Rite Aura"
	desc = "Absorbs blood from anything you touch. Touching cultists and constructs can heal them. Use in-hand to cast an advanced rite."
	color = "#7D1717"

/obj/item/melee/blood_magic/manipulator/examine(mob/user)
	. = ..()
	. += "Bloody halberd, blood bolt barrage, and blood beam cost [BLOOD_HALBERD_COST], [BLOOD_BARRAGE_COST], and [BLOOD_BEAM_COST] charges respectively."

/obj/item/melee/blood_magic/manipulator/afterattack(atom/target, mob/living/carbon/human/user, proximity)
	if(proximity)
		if(ishuman(target))
			var/mob/living/carbon/human/H = target
			if(HAS_TRAIT(H, TRAIT_NOBLOOD))
				to_chat(user,span_warning("Blood rites do not work on people with no blood!"))
				return
			if(IS_CULTIST(H))
				if(H.stat == DEAD)
					to_chat(user,span_warning("Only a revive rune can bring back the dead!"))
					return
				if(H.blood_volume < BLOOD_VOLUME_SAFE)
					var/restore_blood = BLOOD_VOLUME_SAFE - H.blood_volume
					if(uses*2 < restore_blood)
						H.blood_volume += uses*2
						to_chat(user,span_danger("You use the last of your blood rites to restore what blood you could!"))
						uses = 0
						return ..()
					else
						H.blood_volume = BLOOD_VOLUME_SAFE
						uses -= round(restore_blood/2)
						to_chat(user,span_warning("Your blood rites have restored [H == user ? "your" : "[H.p_their()]"] blood to safe levels!"))
				var/overall_damage = H.getBruteLoss() + H.getFireLoss() + H.getToxLoss() + H.getOxyLoss()
				if(overall_damage == 0)
					to_chat(user,span_cult("That cultist doesn't require healing!"))
				else
					var/ratio = uses/overall_damage
					if(H == user)
						to_chat(user,span_cult("<b>Your blood healing is far less efficient when used on yourself!</b>"))
						ratio *= 0.35 // Healing is half as effective if you can't perform a full heal
						uses -= round(overall_damage) // Healing is 65% more "expensive" even if you can still perform the full heal
					if(ratio>1)
						ratio = 1
						uses -= round(overall_damage)
						H.visible_message(span_warning("[H] is fully healed by [H == user ? "[H.p_their()]":"[H]'s"] blood magic!"))
					else
						H.visible_message(span_warning("[H] is partially healed by [H == user ? "[H.p_their()]":"[H]'s"] blood magic."))
						uses = 0
					ratio *= -1
					H.adjustOxyLoss((overall_damage*ratio) * (H.getOxyLoss() / overall_damage), 0)
					H.adjustToxLoss((overall_damage*ratio) * (H.getToxLoss() / overall_damage), 0)
					H.adjustFireLoss((overall_damage*ratio) * (H.getFireLoss() / overall_damage), 0)
					H.adjustBruteLoss((overall_damage*ratio) * (H.getBruteLoss() / overall_damage), 0)
					H.updatehealth()
					playsound(get_turf(H), 'sound/magic/staff_healing.ogg', 25)
					new /obj/effect/temp_visual/cult/sparks(get_turf(H))
					user.Beam(H, icon_state="sendbeam", time = 15)
			else
				if(H.stat == DEAD)
					to_chat(user,span_warning("[H.p_their(TRUE)] blood has stopped flowing, you'll have to find another way to extract it."))
					return
				if(H.has_status_effect(/datum/status_effect/speech/slurring/cult))
					to_chat(user,span_danger("[H.p_their(TRUE)] blood has been tainted by an even stronger form of blood magic, it's no use to us like this!"))
					return
				if(H.blood_volume > BLOOD_VOLUME_SAFE)
					H.blood_volume -= 100
					uses += 50
					user.Beam(H, icon_state="drainbeam", time = 1 SECONDS)
					playsound(get_turf(H), 'sound/magic/enter_blood.ogg', 50)
					H.visible_message(span_danger("[user] drains some of [H]'s blood!"))
					to_chat(user,span_cultitalic("Your blood rite gains 50 charges from draining [H]'s blood."))
					new /obj/effect/temp_visual/cult/sparks(get_turf(H))
				else
					to_chat(user,span_warning("[H.p_theyre(TRUE)] missing too much blood - you cannot drain [H.p_them()] further!"))
					return
		if(isconstruct(target))
			var/mob/living/simple_animal/M = target
			var/missing = M.maxHealth - M.health
			if(missing)
				if(uses > missing)
					M.adjustHealth(-missing)
					M.visible_message(span_warning("[M] is fully healed by [user]'s blood magic!"))
					uses -= missing
				else
					M.adjustHealth(-uses)
					M.visible_message(span_warning("[M] is partially healed by [user]'s blood magic!"))
					uses = 0
				playsound(get_turf(M), 'sound/magic/staff_healing.ogg', 25)
				user.Beam(M, icon_state="sendbeam", time = 1 SECONDS)
		if(istype(target, /obj/effect/decal/cleanable/blood))
			blood_draw(target, user)
		..()

/obj/item/melee/blood_magic/manipulator/proc/blood_draw(atom/target, mob/living/carbon/human/user)
	var/temp = 0
	var/turf/T = get_turf(target)
	if(T)
		for(var/obj/effect/decal/cleanable/blood/B in view(T, 2))
			if(B.blood_state == BLOOD_STATE_HUMAN)
				if(B.bloodiness == 100) //Bonus for "pristine" bloodpools, also to prevent cheese with footprint spam
					temp += 30
				else
					temp += max((B.bloodiness**2)/800,1)
				new /obj/effect/temp_visual/cult/turf/floor(get_turf(B))
				qdel(B)
		for(var/obj/effect/decal/cleanable/trail_holder/TH in view(T, 2))
			qdel(TH)
		if(temp)
			user.Beam(T,icon_state="drainbeam", time = 15)
			new /obj/effect/temp_visual/cult/sparks(get_turf(user))
			playsound(T, 'sound/magic/enter_blood.ogg', 50)
			to_chat(user, span_cultitalic("Your blood rite has gained [round(temp)] charge\s from blood sources around you!"))
			uses += max(1, round(temp))

/obj/item/melee/blood_magic/manipulator/attack_self(mob/living/user)
	if(IS_CULTIST(user))
		var/static/list/spells = list(
			"Bloody Halberd (150)" = image(icon = 'icons/obj/cult/items_and_weapons.dmi', icon_state = "occultpoleaxe0"),
			"Blood Bolt Barrage (300)" = image(icon = 'icons/obj/weapons/guns/ballistic.dmi', icon_state = "arcane_barrage"),
			"Blood Beam (500)" = image(icon = 'icons/obj/weapons/items_and_weapons.dmi', icon_state = "disintegrate")
			)
		var/choice = show_radial_menu(user, src, spells, custom_check = CALLBACK(src, PROC_REF(check_menu), user), require_near = TRUE)
		if(!check_menu(user))
			to_chat(user, span_cultitalic("You decide against conducting a greater blood rite."))
			return
		switch(choice)
			if("Bloody Halberd (150)")
				if(uses < BLOOD_HALBERD_COST)
					to_chat(user, span_cultitalic("You need [BLOOD_HALBERD_COST] charges to perform this rite."))
				else
					uses -= BLOOD_HALBERD_COST
					var/turf/current_position = get_turf(user)
					qdel(src)
					var/datum/action/innate/cult/halberd/halberd_act_granted = new(user)
					var/obj/item/melee/cultblade/halberd/rite = new(current_position)
					halberd_act_granted.Grant(user, rite)
					rite.halberd_act = halberd_act_granted
					if(user.put_in_hands(rite))
						to_chat(user, span_cultitalic("A [rite.name] appears in your hand!"))
					else
						user.visible_message(span_warning("A [rite.name] appears at [user]'s feet!"), \
							span_cultitalic("A [rite.name] materializes at your feet."))
			if("Blood Bolt Barrage (300)")
				if(uses < BLOOD_BARRAGE_COST)
					to_chat(user, span_cultitalic("You need [BLOOD_BARRAGE_COST] charges to perform this rite."))
				else
					var/obj/rite = new /obj/item/gun/ballistic/rifle/enchanted/arcane_barrage/blood()
					uses -= BLOOD_BARRAGE_COST
					qdel(src)
					if(user.put_in_hands(rite))
						to_chat(user, span_cult("<b>Your hands glow with power!</b>"))
					else
						to_chat(user, span_cultitalic("You need a free hand for this rite!"))
						qdel(rite)
			if("Blood Beam (500)")
				if(uses < BLOOD_BEAM_COST)
					to_chat(user, span_cultitalic("You need [BLOOD_BEAM_COST] charges to perform this rite."))
				else
					var/obj/rite = new /obj/item/blood_beam()
					uses -= BLOOD_BEAM_COST
					qdel(src)
					if(user.put_in_hands(rite))
						to_chat(user, span_cultlarge("<b>Your hands glow with POWER OVERWHELMING!!!</b>"))
					else
						to_chat(user, span_cultitalic("You need a free hand for this rite!"))
						qdel(rite)

/obj/item/melee/blood_magic/manipulator/proc/check_menu(mob/living/user)
	if(!istype(user))
		CRASH("The Blood Rites manipulator radial menu was accessed by something other than a valid user.")
	if(user.incapacitated() || !user.Adjacent(src))
		return FALSE
	return TRUE
