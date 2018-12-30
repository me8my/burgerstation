var/global/list/all_mobs = list()

/mob/
	name = "MOB ERROR"
	icon = 'icons/debug/mobs.dmi'
	icon_state = ""
	layer = LAYER_MOB
	var/enable_AI = FALSE

	var/tmp/movement_flags = 0x0

	var/tmp/attack_flags = 0x0

	var/list/obj/inventory/inventory //List of inventory items

/mob/New()
	all_mobs += src
	inventory = list()
	. = ..()

/mob/proc/on_life_client()
	handle_movement(TRUE)
	return TRUE

/mob/proc/on_life()
	return TRUE

/mob/get_movement_delay()
	var/delay = movement_delay

	if(movement_flags & MOVEMENT_CROUCHING)
		delay *= 2

	/*
	if(movement_flags & MOVEMENT_WALKING)
		delay *= 2
	*/

	if(movement_flags & MOVEMENT_RUNNING)
		delay *= 0.5

	return delay

/*
/mob/Destroy() //TODO: Destroy system
	all_mobs -= src
*/