/obj/item/proc/can_transfer_stacks_to(var/obj/item/I)
	return istype(src,I)

//Credit goes to Unknown Person

/proc/copy(var/atom/A)

	var/static/list/denyvar = make_associative(list("client","key","loc","x","y","z","type","locs","parent_type","verbs","vars"))

	var/atom/N = new A.type(A.loc)

	for(var/i in A.vars)
		if(denyvar[i])
			continue
		try
			N.vars[i] = A.vars[i]
		catch()
			log_error("Cannot write var [i]!")

	return N

/obj/item/proc/transfer_stacks_to(var/obj/item/I,var/amount = src.item_count_current)
	return I.add_item_count( -src.add_item_count(-amount) )

/obj/item/proc/split_stack()

	var/stacks_to_take = FLOOR(item_count_current/2, 1)
	if(!stacks_to_take)
		return FALSE


	var/obj/item/I = copy(src)
	transfer_stacks_to(I,stacks_to_take)

	return I

/obj/item/click_on_object(var/mob/caller,object,location,control,params)

	if(object == src || !is_item(object) || !src.loc || get_dist(src,object) > 1)
		return ..()

	var/obj/item/I = object
	if(I.can_transfer_stacks_to(src))
		var/stacks_transfered = I.transfer_stacks_to(src)
		if(stacks_transfered)
			caller.to_chat("You transfer [stacks_transfered] stacks.")
			return TRUE
		else
			caller.to_chat("\The [I.name] is full!")
			return TRUE


	return ..()

/obj/item/clicked_on_by_object(var/mob/caller,object,location,control,params)

	if(object == src || item_count_current <= 1 || !is_inventory(object) || !is_inventory(src.loc) || get_dist(src,object) > 1)
		return ..()

	var/obj/hud/inventory/I = object
	var/old_item_name = src.name
	var/obj/item/I2 = split_stack()
	caller.to_chat("You split \the stack of [old_item_name]. The new stack now has [I2.item_count_current].")
	I.add_object(I2)
	return TRUE