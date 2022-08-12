/// Sent from /obj/item/soulstone/pre_attack(): (obj/item/soulstone/soulstone, mob/living/user)
#define COMSIG_SOULSTONE_HIT "soulstone_hit"
	/// Return to stop the rest of the soulstone hit from ocurring
	#define SOULSTONE_HIT_HANDLED (1<<0)
