/datum/action/xeno_action/activable/lunge/use_ability(atom/target_atom)
	var/mob/living/carbon/xenomorph/xeno = owner

	if (!action_cooldown_check())
		if(twitch_message_cooldown < world.time )
			xeno.visible_message(SPAN_XENOWARNING("\The [xeno]'s claws twitch."), SPAN_XENOWARNING("Your claws twitch as you try to lunge but lack the strength. Wait a moment to try again."))
			twitch_message_cooldown = world.time + 5 SECONDS
		return //this gives a little feedback on why your lunge didn't hit other than the lunge button going grey. Plus, it might spook marines that almost got lunged if they know why the message appeared, and extra spookiness is always good.

	if (!target_atom)
		return

	if (!isturf(xeno.loc))
		to_chat(xeno, SPAN_XENOWARNING("You can't lunge from here!"))
		return

	if (!xeno.check_state() || xeno.agility)
		return

	if(xeno.can_not_harm(target_atom) || !ismob(target_atom))
		apply_cooldown_override(click_miss_cooldown)
		return

	var/mob/living/carbon/target = target_atom
	if(target.stat == DEAD)
		return

	if (!check_and_use_plasma_owner())
		return

	apply_cooldown()
	..()

	xeno.visible_message(SPAN_XENOWARNING("\The [xeno] lunges towards [target]!"), SPAN_XENOWARNING("You lunge at [target]!"))

	xeno.throw_atom(get_step_towards(target_atom, xeno), grab_range, SPEED_FAST, xeno)

	if (xeno.Adjacent(target))
		xeno.start_pulling(target,1)
	else
		xeno.visible_message(SPAN_XENOWARNING("\The [xeno]'s claws twitch."), SPAN_XENOWARNING("Your claws twitch as you lunge but are unable to grab onto your target. Wait a moment to try again."))

	return TRUE

/datum/action/xeno_action/onclick/toggle_agility/use_ability(atom/target_atom)
	var/mob/living/carbon/xenomorph/xeno = owner

	if (!action_cooldown_check())
		return

	if (!xeno.check_state(1))
		return

	xeno.agility = !xeno.agility
	if (xeno.agility)
		to_chat(xeno, SPAN_XENOWARNING("You lower yourself to all fours."))
	else
		to_chat(xeno, SPAN_XENOWARNING("You raise yourself to stand on two feet."))
	xeno.update_icons()

	apply_cooldown()
	return ..()

/datum/action/xeno_action/activable/fling/use_ability(atom/target_atom)
	var/mob/living/carbon/xenomorph/xeno = owner

	if (!action_cooldown_check())
		return

	if (!isxeno_human(target_atom) || xeno.can_not_harm(target_atom))
		return

	if (!xeno.check_state() || xeno.agility)
		return

	if (!xeno.Adjacent(target_atom))
		return

	var/mob/living/carbon/target = target_atom
	if(target.stat == DEAD) return
	if(HAS_TRAIT(target, TRAIT_NESTED))
		return

	if(target == xeno.pulling)
		xeno.stop_pulling()

	if(target.mob_size >= MOB_SIZE_BIG)
		to_chat(xeno, SPAN_XENOWARNING("[target] is too big for you to fling!"))
		return

	if (!check_and_use_plasma_owner())
		return

	xeno.visible_message(SPAN_XENOWARNING("\The [xeno] effortlessly flings [target] to the side!"), SPAN_XENOWARNING("You effortlessly fling [target] to the side!"))
	playsound(target,'sound/weapons/alien_claw_block.ogg', 75, 1)
	if(stun_power)
		target.apply_effect(get_xeno_stun_duration(target, stun_power), STUN)
	if(weaken_power)
		target.apply_effect(weaken_power, WEAKEN)
	if(slowdown)
		if(target.slowed < slowdown)
			target.apply_effect(slowdown, SLOW)
	target.last_damage_data = create_cause_data(initial(xeno.caste_type), xeno)
	shake_camera(target, 2, 1)

	var/facing = get_dir(xeno, target)
	var/turf/throw_turf = xeno.loc
	var/turf/temp = xeno.loc

	for (var/x in 0 to fling_distance-1)
		temp = get_step(throw_turf, facing)
		if (!temp)
			break
		throw_turf = temp

	// Hmm today I will kill a marine while looking away from them
	xeno.face_atom(target)
	xeno.animation_attack_on(target)
	xeno.flick_attack_overlay(target, "disarm")
	target.throw_atom(throw_turf, fling_distance, SPEED_VERY_FAST, xeno, TRUE)

	apply_cooldown()
	return ..()

/datum/action/xeno_action/activable/warrior_punch/use_ability(atom/target_atom)
	var/mob/living/carbon/xenomorph/xeno = owner

	if (!action_cooldown_check())
		return

	if (!isxeno_human(target_atom) || xeno.can_not_harm(target_atom))
		return

	if (!xeno.check_state() || xeno.agility)
		return

	var/distance = get_dist(xeno, target_atom)

	if (distance > 2)
		return

	var/mob/living/carbon/target = target_atom

	if (distance > 1 && xeno.mutation_type == WARRIOR_BOXER)
		step_towards(xeno, target, 1)

	if (!xeno.Adjacent(target))
		return

	if(target.stat == DEAD) return
	if(HAS_TRAIT(target, TRAIT_NESTED)) return

	var/obj/limb/target_limb = target.get_limb(check_zone(xeno.zone_selected))

	if (ishuman(target) && (!target_limb || (target_limb.status & LIMB_DESTROYED)))
		target_limb = target.get_limb("chest")


	if (!check_and_use_plasma_owner())
		return

	target.last_damage_data = create_cause_data(initial(xeno.caste_type), xeno)

	xeno.visible_message(SPAN_XENOWARNING("\The [xeno] hits [target] in the [target_limb? target_limb.display_name : "chest"] with a devastatingly powerful punch!"), \
	SPAN_XENOWARNING("You hit [target] in the [target_limb? target_limb.display_name : "chest"] with a devastatingly powerful punch!"))
	var/sound = pick('sound/weapons/punch1.ogg','sound/weapons/punch2.ogg','sound/weapons/punch3.ogg','sound/weapons/punch4.ogg')
	playsound(target,sound, 50, 1)

	if (xeno.mutation_type != WARRIOR_BOXER)
		do_base_warrior_punch(target, target_limb)
	else
		do_boxer_punch(target,target_limb)
	apply_cooldown()
	return ..()

/datum/action/xeno_action/activable/warrior_punch/proc/do_base_warrior_punch(mob/living/carbon/target, obj/limb/target_limb)
	var/mob/living/carbon/xenomorph/xeno = owner
	var/damage = rand(base_damage, base_damage + damage_variance)

	if(ishuman(target))
		if((target_limb.status & LIMB_SPLINTED) && !(target_limb.status & LIMB_SPLINTED_INDESTRUCTIBLE)) //If they have it splinted, the splint won't hold.
			target_limb.status &= ~LIMB_SPLINTED
			playsound(get_turf(target), 'sound/items/splintbreaks.ogg', 20)
			to_chat(target, SPAN_DANGER("The splint on your [target_limb.display_name] comes apart!"))
			target.pain.apply_pain(PAIN_BONE_BREAK_SPLINTED)

		if(ishuman_strict(target))
			target.apply_effect(3, SLOW)
		if(isyautja(target))
			damage = rand(base_punch_damage_pred, base_punch_damage_pred + damage_variance)
		else if(target_limb.status & (LIMB_ROBOT|LIMB_SYNTHSKIN))
			damage = rand(base_punch_damage_synth, base_punch_damage_synth + damage_variance)


	target.apply_armoured_damage(get_xeno_damage_slash(target, damage), ARMOR_MELEE, BRUTE, target_limb? target_limb.name : "chest")

	// Hmm today I will kill a marine while looking away from them
	xeno.face_atom(target)
	xeno.animation_attack_on(target)
	xeno.flick_attack_overlay(target, "punch")
	shake_camera(target, 2, 1)
	step_away(target, xeno, 2)

/datum/action/xeno_action/activable/warrior_punch/proc/do_boxer_punch(mob/living/carbon/target, obj/limb/target_limb)
	var/mob/living/carbon/Xenomorph/xeno = owner

	var/damage = rand(boxer_punch_damage, boxer_punch_damage + damage_variance)

	if(ishuman(target))
		if(isYautja(target))
			damage = rand(boxer_punch_damage_pred, boxer_punch_damage_pred + damage_variance)
		else if(target_limb.status & (LIMB_ROBOT|LIMB_SYNTHSKIN))
			damage = rand(boxer_punch_damage_synth, boxer_punch_damage_synth + damage_variance)

	target.apply_armoured_damage(get_xeno_damage_slash(target, damage), ARMOR_MELEE, BRUTE, target_limb? target_limb.name : "chest")

	step_away(target, xeno)
	if(prob(25)) // 25% chance to fly 2 tiles
		step_away(target, xeno)
	var/datum/behavior_delegate/boxer/BD = xeno.behavior_delegate
	if(istype(BD))
		BD.melee_attack_additional_effects_target(target, 1)

	var/datum/action/xeno_action/activable/jab/JA = get_xeno_action_by_type(xeno, /datum/action/xeno_action/activable/jab)
	if (istype(JA) && !JA.action_cooldown_check())
		if(isXeno(target))
			JA.reduce_cooldown(JA.xeno_cooldown / 2)
		else
			JA.end_cooldown()

/datum/action/xeno_action/activable/jab/use_ability(atom/target_atom)
	var/mob/living/carbon/Xenomorph/xeno = owner
	if (!isXenoOrHuman(target_atom) || xeno.can_not_harm(target_atom))
		return

	if (!action_cooldown_check())
		return

	if (!xeno.check_state())
		return

	var/distance = get_dist(xeno, target_atom)

	if (distance > 3)
		return

	var/mob/living/carbon/target = target_atom
	if(target.stat == DEAD) return
	if(HAS_TRAIT(target, TRAIT_NESTED)) return

	if (!check_and_use_plasma_owner())
		return

	if (distance > 2)
		step_towards(xeno, target, 1)

	if (distance > 1)
		step_towards(xeno, target, 1)

	if (!xeno.Adjacent(target))
		return

	target.last_damage_data = create_cause_data(initial(xeno.caste_type), xeno)
	xeno.visible_message(SPAN_XENOWARNING("\The [xeno] hits [target] with a powerful jab!"), \
	SPAN_XENOWARNING("You hit [target] with a powerful jab!"))
	var/sound = pick('sound/weapons/punch1.ogg','sound/weapons/punch2.ogg','sound/weapons/punch3.ogg','sound/weapons/punch4.ogg')
	playsound(target,sound, 50, 1)

	// Check actions list for a warrior punch and reset it's cooldown if it's there
	var/datum/action/xeno_action/activable/warrior_punch/punch_action = null
	for (var/datum/action/xeno_action/activable/warrior_punch/P in xeno.actions)
		punch_action = P
		break

	if (punch_action && !punch_action.action_cooldown_check())
		if(isxenoeno(target))
			punch_action.reduce_cooldown(punch_action.xeno_cooldown / 2)
		else
			punch_action.end_cooldown()

	target.Daze(3)
	target.Slow(5)
	var/datum/behavior_delegate/boxer/BD = xeno.behavior_delegate
	if(istype(BD))
		BD.melee_attack_additional_effects_target(target, 1)
	apply_cooldown()
	..()


/datum/action/xeno_action/activable/uppercut/use_ability(atom/target_atom)
	var/mob/living/carbon/Xenomorph/xeno = owner
	if (!isXenoOrHuman(target_atom) || xeno.can_not_harm(target_atom))
		return

	if (!action_cooldown_check())
		return

	if (!xeno.check_state())
		return

	var/datum/behavior_delegate/boxer/BD = xeno.behavior_delegate
	if(!istype(BD))
		return

	if(!BD.punching_bag)
		return

	if(BD.punching_bag != target_atom)
		return

	var/mob/living/carbon/target = BD.punching_bag
	if(target.stat == DEAD)
		return
	if(HAS_TRAIT(target, TRAIT_NESTED))
		return

	if (!check_and_use_plasma_owner())
		return

	if (!xeno.Adjacent(target))
		return

	if(target.mob_size >= MOB_SIZE_BIG)
		to_chat(xeno, SPAN_XENOWARNING("[target] is too big for you to uppercut!"))
		return

	var/datum/action/xeno_action/activable/jab/JA = get_xeno_action_by_type(xeno, /datum/action/xeno_action/activable/jab)
	if (istype(JA))
		JA.apply_cooldown_override(JA.xeno_cooldown)

	var/datum/action/xeno_action/activable/warrior_punch/WP = get_xeno_action_by_type(xeno, /datum/action/xeno_action/activable/warrior_punch)
	if (istype(WP))
		WP.apply_cooldown_override(WP.xeno_cooldown)

	target.last_damage_data = create_cause_data(initial(xeno.caste_type), xeno)

	var/ko_counter = BD.ko_counter

	var/damage = ko_counter >= 1
	var/knockback = ko_counter >= 3
	var/knockdown = ko_counter >= 6
	var/knockout = ko_counter >= 9

	var/message = (!damage) ? "weak" : (!knockback) ? "good" : (!knockdown) ? "powerful" : (!knockout) ? "gigantic" : "titanic"

	xeno.visible_message(SPAN_XENOWARNING("\The [xeno] hits [target] with a [message] uppercut!"), \
	SPAN_XENOWARNING("You hit [target] with a [message] uppercut!"))
	var/sound = pick('sound/weapons/punch1.ogg','sound/weapons/punch2.ogg','sound/weapons/punch3.ogg','sound/weapons/punch4.ogg')
	playsound(target,sound, 50, 1)

	if(BD.ko_reset_timer != TIMER_ID_NULL)
		deltimer(BD.ko_reset_timer)
	BD.remove_ko()

	var/obj/limb/target_limb = target.get_limb(check_zone(xeno.zone_selected))

	if(damage)
		target.apply_armoured_damage(get_xeno_damage_slash(target, base_damage * ko_counter), ARMOR_MELEE, BRUTE, target_limb? target_limb.name : "chest")

	if(knockout)
		target.KnockOut(knockout_power)
		BD.display_ko_message(target)
		playsound(target,'sound/effects/dingding.ogg', 75, 1)

	if(knockback)
		target.explosion_throw(base_knockback * ko_counter, get_dir(xeno, target))

	if(knockdown)
		target.KnockDown(base_knockdown * ko_counter)

	var/mob_multiplier = 1
	if(isXeno(target))
		mob_multiplier = XVX_WARRIOR_HEALMULT

	if(ko_counter > 0)
		xeno.gain_health(mob_multiplier * ko_counter * base_healthgain * xeno.maxHealth / 100)

	apply_cooldown()
	..()
