/obj/item/clothing/overwear/coat/polymorphic
	name = "coat"
	desc = "A nice coat."
	icon = 'icons/obj/items/clothing/suit/jacket.dmi'

	rarity = RARITY_COMMON



	no_initial_blend = TRUE

	is_container = TRUE
	dynamic_inventory_count = 1

	container_max_size = SIZE_2

	size = SIZE_3
	weight = WEIGHT_3

	defense_rating = list(
		BLADE = 15,
		BLUNT = 10,
		PIERCE = 10,
		MAGIC = 15,
		COLD = 25
	)

	polymorphs = list(
		"base" = "#FFFFFF"
	)

	value = 30

/obj/item/clothing/overwear/coat/polymorphic/shaleez
	polymorphs = list(
		"base" = COLOR_SHALEEZ_RED,
		"sleeve" = COLOR_WHITE,
		"buttons" = COLOR_GOLD
	)