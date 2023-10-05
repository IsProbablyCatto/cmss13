/datum/xeno_mutator/boxer
	name = "STRAIN: Warrior - Boxer"
	description = "In exchange for your ability to fling and shield yourself with slashes, you gain KO meter and the ability to resist stuns. Your punches will reset the cooldown of your Jab. Jab lets you close in and confuse your opponents while resetting Punch cooldown. Your slashes and abilities build up KO meter that later lets you deal damage, knockback, heal, and restore your stun resistance depending on how much KO meter you gained with a titanic Uppercut strike."
	cost = MUTATOR_COST_EXPENSIVE
	individual_only = TRUE
	caste_whitelist = list(XENO_CASTE_WARRIOR)
	mutator_actions_to_remove = list(
		/datum/action/xeno_action/activable/fling,
		/datum/action/xeno_action/activable/lunge,
	)
	mutator_actions_to_add = list(
		/datum/action/xeno_action/activable/jab,
		/datum/action/xeno_action/activable/uppercut,
	)
	behavior_delegate_type = /datum/behavior_delegate/boxer
	keystone = TRUE

/datum/xeno_mutator/boxer/apply_mutator(datum/mutator_set/individual_mutators/MS)
	. = ..()
	if (. == 0)
		return

	var/mob/living/carbon/Xenomorph/Warrior/xeno = MS.xeno
	xeno.health_modifier += XENO_HEALTH_MOD_MED
	xeno.armor_modifier += XENO_ARMOR_MOD_VERYSMALL
	xeno.agility = FALSE
	xeno.mutation_type = WARRIOR_BOXER
	apply_behavior_holder(xeno)
	mutator_update_actions(xeno)
	MS.recalculate_actions(description, flavor_description)
