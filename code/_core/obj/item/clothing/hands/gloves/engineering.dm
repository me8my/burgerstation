/obj/item/clothing/hands/gloves/engineering
	name = "right engineering glove"
	icon = 'icons/obj/items/clothing/gloves/engineering_rig_gloves.dmi'

	icon_state = "inventory_right"
	icon_state_worn = "worn_right"

	item_slot = SLOT_HAND_RIGHT
	protected_limbs = list(BODY_HAND_RIGHT)

	rarity = RARITY_RARE

	defense_rating = list(
		BLADE = 20,
		BLUNT = 30,
		PIERCE = 15,
		LASER = 10,
		MAGIC = -25,
		HEAT = 75,
		COLD = 75,
		BIO = 25,
		RAD = 75
	)

	protection_cold = list(
		BODY_HAND_LEFT = 2
	)

	size = SIZE_1
	weight = WEIGHT_1

	value = 100

/obj/item/clothing/hands/gloves/engineering/left
	name = "left engineering glove"
	color = "#FFFF00"

	icon_state = "inventory_left"
	icon_state_worn = "worn_left"

	item_slot = SLOT_HAND_LEFT
	protected_limbs = list(BODY_HAND_LEFT)

	protection_cold = list(
		BODY_HAND_RIGHT = 2
	)