/// Exorcisbale component
/// For things which can be exorciszed by a holy person with their bible.
/datum/component/exorcisable
	/// How long does the exorcism take?
	var/exorcise_time = 4 SECONDS
	/// Optional. Callback invoked before the exorcism is done, when the item is hit with the bible.
	/// Return STOP_EXORCISM from the callback to stop the exorcism from occurring.
	var/datum/callback/pre_exorcism_callback
	/// Required. Callback invoked when the exorcism is done.
	var/datum/callback/on_exorcism_callback

/datum/component/exorcisable/Initialize(exorcise_time = 4 SECONDS, datum/callback/pre_exorcism_callback, datum/callback/on_exorcism_callback)
	if(!isatom(parent))
		return COMPONENT_INCOMPATIBLE

	if(!on_exorcism_callback)
		stack_trace("[type] was created without an on_exorcism_callback, so it will have no effects.")

	src.exorcise_time = exorcise_time
	src.pre_exorcism_callback = pre_exorcism_callback
	src.on_exorcism_callback = on_exorcism_callback

/datum/component/exorcisable/RegisterWithParent()
	RegisterSignal(parent, COMSIG_BIBLE_SMACKED, .proc/on_bible_smack)

/datum/component/exorcisable/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_BIBLE_SMACKED)

/// Signal prc for [COMSIG_BIBLE_SMACKED], when our parent gets smacked with a bible it's time to try to exorcise it.
/datum/component/exorcisable/proc/on_bible_smack(datum/source, mob/living/user, obj/item/book/bible/bible)
	SIGNAL_HANDLER

	// We have a pre_exorcism callback and it returns STOP_EXORCISM? Well, stop the exorcism
	if(pre_exorcism_callback?.Invoke(user) == STOP_EXORCISM)
		return

	INVOKE_ASYNC(src, .proc/attempt_exorcism, user)
	return COMSIG_END_BIBLE_CHAIN

/// Actually do the exorcism, starting a do_after and invoking the success callback when complete
/datum/component/exorcisable/proc/attempt_exorcism(mob/living/exorcist)
	var/atom/exorcised_atom = parent

	exorcised_atom.balloon_alert(exorcist, span_notice("exorcising..."))
	playsound(exorcised_atom, 'sound/hallucinations/veryfar_noise.ogg', 40, TRUE)

	if(!do_after(exorcist, exorcise_time, target = exorcised_atom) || !on_exorcism_callback.Invoke(exorcist))
		exorcised_atom.balloon_alert(exorcist, span_notice("exorcism failed!"))
		return

	playsound(exorcised_atom, 'sound/effects/pray_chaplain.ogg', 60, TRUE)
	exorcised_atom.balloon_alert(exorcist, span_notice("exorcised"))
