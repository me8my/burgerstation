/obj/item/clothing/feet/shoes/tutorial
	name = "right tutorial boot"
	rarity = RARITY_MYTHICAL
	icon_state = "inventory_right"
	icon_state_worn = "worn_right"
	worn_layer = LAYER_MOB_CLOTHING_BELT

	icon = 'icons/obj/items/clothing/shoes/tutorial_shoes.dmi'

	item_slot = SLOT_FOOT_RIGHT
	protected_limbs = list(BODY_FOOT_RIGHT)

	defense_rating = list(
		BLADE = 20,
		BLUNT = 20,
		PIERCE = 10,
		LASER = -25,
		MAGIC = 25,
		HEAT = 10,
		COLD = 10
	)

	size = SIZE_2
	weight = WEIGHT_3

	value = 100

	slowdown_mul_worn = 1.05

/obj/item/clothing/feet/shoes/tutorial/left
	name = "left tutorial boot"
	icon_state = "inventory_left"
	icon_state_worn = "worn_left"

	item_slot = SLOT_FOOT_LEFT
	protected_limbs = list(BODY_FOOT_LEFT)

