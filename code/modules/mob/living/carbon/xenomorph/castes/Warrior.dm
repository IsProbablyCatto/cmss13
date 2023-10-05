/datum/caste_datum/warrior
	caste_type = XENO_CASTE_WARRIOR
	tier = 2

	melee_damage_lower = XENO_DAMAGE_TIER_3
	melee_damage_upper = XENO_DAMAGE_TIER_5
	melee_vehicle_damage = XENO_DAMAGE_TIER_5
	max_health = XENO_HEALTH_TIER_6
	plasma_gain = XENO_PLASMA_GAIN_TIER_9
	plasma_max = XENO_NO_PLASMA
	xeno_explosion_resistance = XENO_EXPLOSIVE_ARMOR_TIER_4
	armor_deflection = XENO_ARMOR_TIER_1
	evasion = XENO_EVASION_NONE
	speed = XENO_SPEED_TIER_7

	behavior_delegate_type = /datum/behavior_delegate/warrior_base

	evolves_to = list(XENO_CASTE_PRAETORIAN, XENO_CASTE_CRUSHER)
	deevolves_to = list(XENO_CASTE_DEFENDER)
	caste_desc = "A powerful front line combatant."
	can_vent_crawl = 0

	tackle_min = 2
	tackle_max = 4

	agility_speed_increase = -0.9

	heal_resting = 1.4

	minimum_evolve_time = 9 MINUTES

	minimap_icon = "warrior"

/mob/living/carbon/xenomorph/warrior
	caste_type = XENO_CASTE_WARRIOR
	name = XENO_CASTE_WARRIOR
	desc = "A beefy alien with an armored carapace."
	icon = 'icons/mob/xenos/warrior.dmi'
	icon_size = 64
	icon_state = "Warrior Walking"
	plasma_types = list(PLASMA_CATECHOLAMINE)
	pixel_x = -16
	old_x = -16
	tier = 2
	pull_speed = 2 // about what it was before, slightly faster

	base_actions = list(
		/datum/action/xeno_action/onclick/xeno_resting,
		/datum/action/xeno_action/onclick/regurgitate,
		/datum/action/xeno_action/watch_xeno,
		/datum/action/xeno_action/activable/tail_stab,
		/datum/action/xeno_action/activable/warrior_punch,
		/datum/action/xeno_action/activable/lunge,
		/datum/action/xeno_action/activable/fling,
		/datum/action/xeno_action/onclick/tacmap,
	)

	mutation_type = WARRIOR_NORMAL
	claw_type = CLAW_TYPE_SHARP
	icon_xeno = 'icons/mob/xenos/warrior.dmi'
	icon_xenonid = 'icons/mob/xenonids/warrior.dmi'

	var/lunging = FALSE // whether or not the warrior is currently lunging (holding) a target
/mob/living/carbon/xenomorph/warrior/throw_item(atom/target)
	toggle_throw_mode(THROW_MODE_OFF)

/mob/living/carbon/xenomorph/warrior/stop_pulling()
	if(isliving(pulling) && lunging)
		lunging = FALSE // To avoid extreme cases of stopping a lunge then quickly pulling and stopping to pull someone else
		var/mob/living/lunged = pulling
		lunged.set_effect(0, STUN)
		lunged.set_effect(0, WEAKEN)
	return ..()

/mob/living/carbon/xenomorph/warrior/start_pulling(atom/movable/AM, lunge)
	if (!check_state() || agility)
		return FALSE

	if(!isliving(AM))
		return FALSE
	var/mob/living/target = AM
	var/should_neckgrab = !(src.can_not_harm(target)) && lunge

	if(!QDELETED(target) && !QDELETED(target.pulledby) && target != src ) //override pull of other mobs
		visible_message(SPAN_WARNING("[src] has broken [target.pulledby]'s grip on [target]!"), null, null, 5)
		target.pulledby.stop_pulling()

	. = ..(target, lunge, should_neckgrab)

	if(.) //successful pull
		if(isxeno(target))
			var/mob/living/carbon/xenomorph/X = target
			if(X.tier >= 2) // Tier 2 castes or higher immune to warrior grab stuns
				return .

		if(should_neckgrab && target.mob_size < MOB_SIZE_BIG)
			target.drop_held_items()
			target.apply_effect(get_xeno_stun_duration(target, 2), WEAKEN)
			target.pulledby = src
			visible_message(SPAN_XENOWARNING("\The [src] grabs [target] by the throat!"), \
			SPAN_XENOWARNING("You grab [target] by the throat!"))
			lunging = TRUE
			addtimer(CALLBACK(src, PROC_REF(stop_lunging)), get_xeno_stun_duration(target, 2) SECONDS + 1 SECONDS)

/mob/living/carbon/xenomorph/warrior/proc/stop_lunging(world_time)
	lunging = FALSE

/mob/living/carbon/xenomorph/warrior/hitby(atom/movable/AM)
	if(ishuman(AM))
		return
	..()

/datum/behavior_delegate/warrior_base
	name = "Base Warrior Behavior Delegate"

	var/lifesteal_percent = 7
	var/max_lifesteal = 9
	var/lifesteal_range =  3 // Marines within 3 tiles of range will give the warrior extra health
	var/lifesteal_lock_duration = 20 // This will remove the glow effect on warrior after 2 seconds
	var/color = "#6c6f24"
	var/emote_cooldown = 0

/datum/behavior_delegate/warrior_base/melee_attack_additional_effects_target(mob/living/carbon/A)
	..()

	if(SEND_SIGNAL(bound_xeno, COMSIG_XENO_PRE_HEAL) & COMPONENT_CANCEL_XENO_HEAL)
		return

	var/final_lifesteal = lifesteal_percent
	var/list/mobs_in_range = oviewers(lifesteal_range, bound_xeno)

	for(var/mob/mob as anything in mobs_in_range)
		if(final_lifesteal >= max_lifesteal)
			break

		if(mob.stat == DEAD || HAS_TRAIT(mob, TRAIT_NESTED))
			continue

		if(bound_xeno.can_not_harm(mob))
			continue

		final_lifesteal++

// This part is then outside the for loop
		if(final_lifesteal >= max_lifesteal)
			bound_xeno.add_filter("empower_rage", 1, list("type" = "outline", "color" = color, "size" = 1, "alpha" = 90))
			bound_xeno.visible_message(SPAN_DANGER("[bound_xeno.name] glows as it heals even more from its injuries!."), SPAN_XENODANGER("You glow as you heal even more from your injuries!"))
			bound_xeno.flick_heal_overlay(2 SECONDS, "#00B800")
		if(istype(bound_xeno) && world.time > emote_cooldown && bound_xeno)
			bound_xeno.emote("roar")
			bound_xeno.xeno_jitter(1 SECONDS)
			emote_cooldown = world.time + 5 SECONDS
		addtimer(CALLBACK(src, PROC_REF(lifesteal_lock)), lifesteal_lock_duration/2)

	bound_xeno.gain_health(Clamp(final_lifesteal / 100 * (bound_xeno.maxHealth - bound_xeno.health), 20, 40))

/datum/behavior_delegate/warrior_base/proc/lifesteal_lock()
	bound_xeno.remove_filter("empower_rage")

/datum/behavior_delegate/boxer
	name = "Boxer Warrior Behavior Delegate"

	var/ko_delay = 5 SECONDS
	var/max_clear_head = 3
	var/clear_head_delay = 15 SECONDS
	var/clear_head = 3
	var/next_clear_head_regen
	var/clear_head_tickcancel

	var/mob/punching_bag
	var/ko_counter = 0
	var/ko_reset_timer
	var/max_ko_counter = 15

	var/image/ko_icon
	var/image/big_ko_icon

/datum/behavior_delegate/boxer/New()
	. = ..()
	if(SSticker.mode && (SSticker.mode.flags_round_type & MODE_XVX))
		clear_head = 0
		max_clear_head = 0

/datum/behavior_delegate/boxer/append_to_stat()
	. = list()
	if(punching_bag)
		. += "Beating [punching_bag] - [ko_counter] hits"
	. += "Clarity [clear_head] hits"

/datum/behavior_delegate/boxer/on_life()
	var/wt = world.time
	if(wt > next_clear_head_regen && clear_head<max_clear_head)
		clear_head++
		next_clear_head_regen = wt + clear_head_delay

/datum/behavior_delegate/boxer/melee_attack_additional_effects_target(mob/living/carbon/A, ko_boost = 0.5)
	if(!ismob(A))
		return
	if(punching_bag != A)
		remove_ko()
		punching_bag = A
		ko_icon = image(null, A)
		ko_icon.alpha = 196
		ko_icon.maptext_width = 16
		ko_icon.maptext_x = 16
		ko_icon.maptext_y = 16
		ko_icon.layer = 20
		if(bound_xeno.client && bound_xeno.client.prefs && !bound_xeno.client.prefs.lang_chat_disabled)
			bound_xeno.client.images += ko_icon

	ko_counter += ko_boost
	if(ko_counter > max_ko_counter)
		ko_counter = max_ko_counter
	var/to_display = round(ko_counter)
	ko_icon.maptext = "<span class='center langchat'>[to_display]</span>"

	ko_reset_timer = addtimer(CALLBACK(src, .proc/remove_ko), ko_delay, TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_NO_HASH_WAIT|TIMER_STOPPABLE)

/datum/behavior_delegate/boxer/proc/remove_ko()
	punching_bag = null
	ko_counter = 0
	if(bound_xeno.client && ko_icon)
		bound_xeno.client.images -= ko_icon
	ko_icon = null

/datum/behavior_delegate/boxer/proc/display_ko_message(var/mob/H)
	if(!bound_xeno.client)
		return
	if(!bound_xeno.client.prefs || bound_xeno.client.prefs.lang_chat_disabled)
		return
	big_ko_icon = image(null, H)
	big_ko_icon.alpha = 196
	big_ko_icon.maptext_y = H.langchat_height
	big_ko_icon.maptext_width = LANGCHAT_WIDTH
	big_ko_icon.maptext_height = 64
	big_ko_icon.color = "#FF0000"
	big_ko_icon.maptext_x = LANGCHAT_X_OFFSET
	big_ko_icon.maptext = "<span class='center langchat langchat_bolditalicbig'>KO!</span>"
	bound_xeno.client.images += big_ko_icon
	addtimer(CALLBACK(src, .proc/remove_big_ko), 2 SECONDS)

/datum/behavior_delegate/boxer/proc/remove_big_ko()
	if(bound_xeno.client && big_ko_icon)
		bound_xeno.client.images -= big_ko_icon
	big_ko_icon = null


/mob/living/carbon/Xenomorph/Warrior/Daze(amount)
	var/datum/behavior_delegate/boxer/behavior = behavior_delegate
	if(mutation_type != WARRIOR_BOXER || !istype(behavior) || behavior.clear_head <= 0)
		..(amount)
		return
	if(behavior.clear_head_tickcancel == world.time)
		return
	behavior.clear_head_tickcancel = world.time
	behavior.clear_head--
	if(behavior.clear_head<=0)
		behavior.clear_head = 0

/mob/living/carbon/Xenomorph/Warrior/SetDazed(amount)
	var/datum/behavior_delegate/boxer/behavior = behavior_delegate
	if(mutation_type != WARRIOR_BOXER || !istype(behavior) || behavior.clear_head <= 0)
		..(amount)
		return
	if(behavior.clear_head_tickcancel == world.time)
		return
	behavior.clear_head_tickcancel = world.time
	behavior.clear_head--
	if(behavior.clear_head<=0)
		behavior.clear_head = 0

/mob/living/carbon/Xenomorph/Warrior/AdjustDazed(amount)
	var/datum/behavior_delegate/boxer/behavior = behavior_delegate
	if(mutation_type != WARRIOR_BOXER || !istype(behavior) || behavior.clear_head <= 0)
		..(amount)
		return
	if(behavior.clear_head_tickcancel == world.time)
		return
	behavior.clear_head_tickcancel = world.time
	behavior.clear_head--
	if(behavior.clear_head<=0)
		behavior.clear_head = 0

/mob/living/carbon/Xenomorph/Warrior/KnockDown(amount, forced)
	var/datum/behavior_delegate/boxer/behavior = behavior_delegate
	if(forced || mutation_type != WARRIOR_BOXER || !istype(behavior) || behavior.clear_head <= 0)
		..(amount, forced)
		return
	if(behavior.clear_head_tickcancel == world.time)
		return
	behavior.clear_head_tickcancel = world.time
	behavior.clear_head--
	if(behavior.clear_head<=0)
		behavior.clear_head = 0

/mob/living/carbon/Xenomorph/Warrior/SetKnockeddown(amount)
	var/datum/behavior_delegate/boxer/behavior = behavior_delegate
	if(mutation_type != WARRIOR_BOXER || !istype(behavior) || behavior.clear_head <= 0)
		..(amount)
		return
	if(behavior.clear_head_tickcancel == world.time)
		return
	behavior.clear_head_tickcancel = world.time
	behavior.clear_head--
	if(behavior.clear_head<=0)
		behavior.clear_head = 0

/mob/living/carbon/Xenomorph/Warrior/AdjustKnockeddown(amount)
	var/datum/behavior_delegate/boxer/behavior = behavior_delegate
	if(mutation_type != WARRIOR_BOXER || !istype(behavior) || behavior.clear_head <= 0)
		..(amount)
		return
	if(behavior.clear_head_tickcancel == world.time)
		return
	behavior.clear_head_tickcancel = world.time
	behavior.clear_head--
	if(behavior.clear_head<=0)
		behavior.clear_head = 0

/mob/living/carbon/Xenomorph/Warrior/Stun(amount)
	var/datum/behavior_delegate/boxer/behavior = behavior_delegate
	if(mutation_type != WARRIOR_BOXER || !istype(behavior) || behavior.clear_head <= 0)
		..(amount)
		return
	if(behavior.clear_head_tickcancel == world.time)
		return
	behavior.clear_head_tickcancel = world.time
	behavior.clear_head--
	if(behavior.clear_head<=0)
		behavior.clear_head = 0

/mob/living/carbon/Xenomorph/Warrior/SetStunned(amount)
	var/datum/behavior_delegate/boxer/behavior = behavior_delegate
	if(mutation_type != WARRIOR_BOXER || !istype(behavior) || behavior.clear_head <= 0)
		..(amount)
		return
	if(behavior.clear_head_tickcancel == world.time)
		return
	behavior.clear_head_tickcancel = world.time
	behavior.clear_head--
	if(behavior.clear_head<=0)
		behavior.clear_head = 0

/mob/living/carbon/Xenomorph/Warrior/AdjustStunned(amount)
	var/datum/behavior_delegate/boxer/behavior = behavior_delegate
	if(mutation_type != WARRIOR_BOXER || !istype(behavior) || behavior.clear_head <= 0)
		..(amount)
		return
	if(behavior.clear_head_tickcancel == world.time)
		return
	behavior.clear_head_tickcancel = world.time
	behavior.clear_head--
	if(behavior.clear_head<=0)
		behavior.clear_head = 0
