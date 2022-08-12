/datum/component/exorcisable
	var/exorcise_time = 4 SECONDS
	var/datum/callback/pre_exorcism_callback
	var/datum/callback/on_exorcism_callback

/datum/component/exorcisable/Initialize(exorcise_time = 4 SECONDS, datum/callback/pre_exorcism_callback, datum/callback/on_exorcism_callback)
	if(!isatom(parent))
		return COMPONENT_INCOMPATIBLE

	if(!on_exorcism_callback)
		stack_trace("[type] was created without an on_exorcism_callback, so it will have no effects.")
		return COMPONENT_INCOMPATIBLE

	src.exorcise_time = exorcise_time
	src.pre_exorcism_callback = pre_exorcism_callback
	src.on_exorcism_callback = on_exorcism_callback

/datum/component/exorcisable/RegisterWithParent()
	RegisterSignal(parent, COMSIG_BIBLE_SMACKED, .proc/on_bible_smack)

/datum/component/exorcisable/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_BIBLE_SMACKED)

/datum/component/exorcisable/proc/on_bible_smack(datum/source, mob/living/user, obj/item/book/bible/bible)
	SIGNAL_HANDLER

	if(pre_exorcism_callback && pre_exorcism_callback.Invoke(user) == STOP_EXORCISM)
		return

	INVOKE_ASYNC(src, .proc/attempt_exorcism, user)
	return COMSIG_END_BIBLE_CHAIN

/datum/component/exorcisable/proc/attempt_exorcism(mob/living/exorcist)
	var/atom/exorcised_atom = parent

	exorcised_atom.balloon_alert(exorcist, span_notice("exorcising [exorcised_atom]..."))
	playsound(exorcised_atom, 'sound/hallucinations/veryfar_noise.ogg', 40, TRUE)

	if(!do_after(exorcist, exorcise_time, target = exorcised_atom) || !on_exorcism_callback.Invoke(exorcist))
		exorcised_atom.balloon_alert(exorcist, span_notice("exorcism failed!"))
		return

	playsound(exorcised_atom, 'sound/effects/pray_chaplain.ogg', 60, TRUE)
	exorcised_atom.balloon_alert(exorcist, span_notice("[exorcised_atom] exorcised"))
