/// Sent from /obj/item/soulstone/pre_attack(): (obj/item/soulstone/soulstone, mob/living/user)
#define COMSIG_SOULSTONE_HIT "soulstone_hit"
	/// Return to stop the rest of the soulstone hit from ocurring
	#define SOULSTONE_HIT_HANDLED (1<<0)

///From /obj/effect/rune/convert/do_sacrifice() : (list/invokers)
#define COMSIG_LIVING_CULT_SACRIFICED "living_cult_sacrificed"
	/// Return to stop the sac from occurring
	#define STOP_SACRIFICE (1<<0)
	/// Don't send a message for sacrificing this thing, we have our own
	#define SILENCE_SACRIFICE_MESSAGE (1<<1)
