/macros/
	var/client/owner
	var/list/macros = list(
		"W" = NORTH,
		"D" = EAST,
		"S" = SOUTH,
		"A" = WEST,
		"T" = "say",
		"E" = "grab",
		"Shift" = "sprint",
		"Alt" = "walk",
		"Ctrl" = "crouch",
		"R" = "throw",
		"Q" = "drop",
		"Space" = "kick",
		"C" = "quick_self",
		"Tab" = "change_focus",
		"1" = "bind_1",
		"2" = "bind_2",
		"3" = "bind_3",
		"4" = "bind_4",
		"5" = "bind_5",
		"6" = "bind_6",
		"7" = "bind_7",
		"8" = "bind_8",
		"9" = "bind_9",
		"0" = "bind_0"
	)

/macros/New(var/client/spawning_owner)
	owner = spawning_owner

/macros/proc/on_pressed(button)
	var/command = macros[button]
	if(isnum(command))
		owner.mob.move_dir |= command
		if(owner.mob)
			owner.mob.move_delay = max(owner.mob.move_delay,2)

	else if(copytext(command,1,5) == "bind")
		var/text_num = copytext(command,6,7)
		if(is_advanced(owner.mob))
			var/mob/living/advanced/A = owner.mob
			if(text_num == A.quick_mode)
				A.quick_mode = null
			else
				A.quick_mode = text_num
			for(var/obj/hud/button/slot/B in A.buttons)
				var/was_active = B.active
				B.active = A.quick_mode == B.id
				if(was_active != B.active)
					B.update_icon() //Only update if changed. Prevents lag.

	else
		switch(command)
			if("sprint")
				owner.mob.movement_flags |= MOVEMENT_RUNNING
			if("walk")
				owner.mob.movement_flags |= MOVEMENT_WALKING
			if("crouch")
				owner.mob.movement_flags |= MOVEMENT_CROUCHING
			if("throw")
				owner.mob.attack_flags |= ATTACK_THROW
			if("drop")
				owner.mob.attack_flags |= ATTACK_DROP
			if("kick")
				owner.mob.attack_flags |= ATTACK_KICK
			if("grab")
				owner.mob.attack_flags |= ATTACK_GRAB
			if("quick_self")
				owner.mob.attack_flags |= ATTACK_SELF

	return TRUE

/macros/proc/on_released(button)
	var/command = macros[button]

	if(isnum(command))
		owner.mob.move_dir &= ~command
	else
		switch(command)
			if("say")
				owner.mob.say()
			if("sprint")
				owner.mob.movement_flags &= ~MOVEMENT_RUNNING
			if("walk")
				owner.mob.movement_flags &= ~MOVEMENT_WALKING
			if("crouch")
				owner.mob.movement_flags &= ~MOVEMENT_CROUCHING
			if("throw")
				owner.mob.attack_flags &= ~ATTACK_THROW
			if("drop")
				owner.mob.attack_flags &= ~ATTACK_DROP
			if("kick")
				owner.mob.attack_flags &= ~ATTACK_KICK
			if("grab")
				owner.mob.attack_flags &= ~ATTACK_GRAB
			if("quick_self")
				owner.mob.attack_flags &= ~ATTACK_SELF


	return TRUE