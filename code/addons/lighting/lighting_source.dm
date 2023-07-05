// This is where the fun begins.
// These are the main datums that emit light.

/light_source/

	var/atom/top_atom        // The atom we're emitting light from (for example a mob if we're from a flashlight that's being held).
	var/atom/source_atom     // The atom that we belong to.

	var/turf/source_turf // The turf under the above.
	var/turf/pixel_turf  // The turf the top_atom _appears_ to be on
	var/light_power      // Intensity of the emitter light.
	var/light_range      // The range of the emitted light.
	var/light_color      // The colour of the light, string, decomposed by parse_light_color()
	var/light_angle      // The light's emission angle, in degrees.

	// Variables for keeping track of the colour.
	var/lum_r
	var/lum_g
	var/lum_b

	// The lumcount values used to apply the light.
	var/tmp/applied_lum_r
	var/tmp/applied_lum_g
	var/tmp/applied_lum_b

	// Variables used to keep track of the atom's angle.
	var/tmp/limit_a_x       // The first test point's X coord for the cone.
	var/tmp/limit_a_y       // The first test point's Y coord for the cone.
	var/tmp/limit_a_t       // The first test point's angle.
	var/tmp/limit_b_x       // The second test point's X coord for the cone.
	var/tmp/limit_b_y       // The second test point's Y coord for the cone.
	var/tmp/limit_b_t       // The second test point's angle.
	var/tmp/cached_origin_x // The last known X coord of the origin.
	var/tmp/cached_origin_y // The last known Y coord of the origin.
	var/tmp/old_direction   // The last known direction of the origin.
	var/tmp/test_x_offset   // How much the X coord should be offset due to direction.
	var/tmp/test_y_offset   // How much the Y coord should be offset due to direction.
	var/tmp/facing_opaque = FALSE

	var/list/lighting_corner/effect_str     // List used to store how much we're affecting corners.
	var/list/turf/affecting_turfs

	var/applied = FALSE // Whether we have applied our light yet or not.

	var/needs_update = LIGHTING_NO_UPDATE

/light_source/PreDestroy()
	remove_lum()
	SSlighting.light_queue -= src
	SSlighting.total_lighting_sources--

	if(source_atom)
		LAZYREMOVE(source_atom.light_sources, src)

	if(top_atom)
		LAZYREMOVE(top_atom.light_sources, src)
	. = ..()

/light_source/Destroy()

	top_atom = null
	source_atom = null
	source_turf = null
	pixel_turf = null

	if(effect_str)
		effect_str.Cut()
	if(affecting_turfs)
		affecting_turfs.Cut()

	return ..()

// This macro will only offset up to 1 tile, but anything with a greater offset is an outlier and probably should handle its own lighting offsets.
// Anything pixelshifted 16px or more will be considered on the next tile.
#define GET_APPROXIMATE_PIXEL_DIR(PX, PY) ((!(PX) ? 0 : ((PX >= 16 ? EAST : (PX <= -16 ? WEST : 0)))) | (!PY ? 0 : (PY >= 16 ? NORTH : (PY <= -16 ? SOUTH : 0))))
#define UPDATE_APPROXIMATE_PIXEL_TURF var/px = top_atom.light_offset_x; var/py = top_atom.light_offset_y; var/_mask = GET_APPROXIMATE_PIXEL_DIR(px, py); pixel_turf = _mask ? (get_step(source_turf, _mask) || source_turf) : source_turf

/light_source/New(atom/owner, atom/top)
	SSlighting.total_lighting_sources++
	source_atom = owner // Set our new owner.

	LAZYADD(source_atom.light_sources, src)

	if(!top)
		top = source_atom

	top_atom = top

	if (top_atom != source_atom)
		LAZYADD(top_atom.light_sources, src)

	source_turf = top_atom
	UPDATE_APPROXIMATE_PIXEL_TURF
	light_power = source_atom.light_power
	light_range = source_atom.light_range
	light_color = source_atom.light_color
	light_angle = source_atom.light_wedge

	parse_light_color()

	set_top_atom()

#define INTELLIGENT_UPDATE(level)           \
	if (needs_update == LIGHTING_NO_UPDATE) \
		SSlighting.light_queue += src;      \
	if (needs_update < level)               \
		needs_update = level;

// This proc will cause the light source to update the top atom, and add itself to the update queue.
/light_source/proc/set_top_atom(atom/new_top_atom)
	// This top atom is different.
	if (new_top_atom && new_top_atom != top_atom)
		if(top_atom != source_atom) // Remove ourselves from the light sources of that top atom.
			LAZYREMOVE(top_atom.light_sources, src)

		top_atom = new_top_atom

		if (top_atom != source_atom)
			LAZYADD(top_atom.light_sources, src)	// Add ourselves to the light sources of our new top atom.

	INTELLIGENT_UPDATE(LIGHTING_CHECK_UPDATE)

// Will force an update without checking if it's actually needed.
/light_source/proc/force_update()
	INTELLIGENT_UPDATE(LIGHTING_FORCE_UPDATE)

// Will cause the light source to recalculate turfs that were removed or added to visibility only.
/light_source/proc/vis_update()
	INTELLIGENT_UPDATE(LIGHTING_VIS_UPDATE)

// Decompile the hexadecimal colour into lumcounts of each perspective.
/light_source/proc/parse_light_color()
	if (light_color)


		lum_r = GetRedPart   (light_color) / 255
		lum_g = GetGreenPart (light_color) / 255
		lum_b = GetBluePart  (light_color) / 255
	else
		lum_r = 1
		lum_g = 1
		lum_b = 1

#define POLAR_TO_CART_X(R,T) ((R) * cos(T))
#define POLAR_TO_CART_Y(R,T) ((R) * sin(T))
#define DISCRIMINANT(A_X,A_Y,B_X,B_Y) ((A_X)*(B_Y) - (A_Y)*(B_X))
#define MINMAX(NUM) ((NUM) < 0 ? -round(-(NUM)) : round(NUM))
#define ARBITRARY_NUMBER 10

/light_source/proc/regenerate_angle(ndir)
	old_direction = ndir

	var/turf/front = get_step(source_turf, old_direction)
	facing_opaque = (front && front.has_opaque_atom)

	cached_origin_x = test_x_offset = source_turf.x
	cached_origin_y = test_y_offset = source_turf.y

	if (facing_opaque)
		return

	var/angle = light_angle * 0.5


	limit_a_t = angle
	limit_b_t = -angle

	switch(old_direction)
		if(NORTH)
			limit_a_t += 90
			limit_b_t += 90
			test_y_offset += 1
		if(NORTHEAST)
			limit_a_t += 45
			limit_b_t += 45
			test_y_offset += 0.5
			test_x_offset += 0.5
		if(EAST)
			limit_a_t += 0
			limit_b_t += 0
			test_x_offset += 1
		if(SOUTHEAST)
			limit_a_t -= 45
			limit_b_t -= 45
			test_x_offset += 0.5
			test_y_offset -= 0.5
		if(SOUTH)
			limit_a_t -= 90
			limit_b_t -= 90
			test_y_offset -= 1
		if(SOUTHWEST)
			limit_a_t += 225
			limit_b_t -= 135
			test_x_offset -= 0.5
			test_y_offset -= 0.5
		if(WEST)
			limit_a_t += 180
			limit_b_t -= 180
			test_x_offset -= 1
		if(NORTHWEST)
			limit_a_t += 135
			limit_b_t -= 225
			test_x_offset -= 0.5
			test_y_offset += 0.5


	/*
	switch (old_direction)
		if (NORTH)
			limit_a_t = angle + 90
			limit_b_t = -(angle) + 90
			++test_y_offset

		if (SOUTH)
			limit_a_t = (angle) - 90
			limit_b_t = -(angle) - 90
			--test_y_offset

		if (EAST)
			limit_a_t = angle
			limit_b_t = -(angle)
			++test_x_offset

		if (WEST)
			limit_a_t = angle + 180
			limit_b_t = -(angle) - 180
			--test_x_offset
	*/

	// Convert our angle + range into a vector.
	limit_a_x = POLAR_TO_CART_X(light_range + ARBITRARY_NUMBER, limit_a_t)
	limit_a_x = MINMAX(limit_a_x)
	limit_a_y = POLAR_TO_CART_Y(light_range + ARBITRARY_NUMBER, limit_a_t)
	limit_a_y = MINMAX(limit_a_y)
	limit_b_x = POLAR_TO_CART_X(light_range + ARBITRARY_NUMBER, limit_b_t)
	limit_b_x = MINMAX(limit_b_x)
	limit_b_y = POLAR_TO_CART_Y(light_range + ARBITRARY_NUMBER, limit_b_t)
	limit_b_y = MINMAX(limit_b_y)

#undef ARBITRARY_NUMBER
#undef POLAR_TO_CART_X
#undef POLAR_TO_CART_Y
#undef MINMAX

/light_source/proc/remove_lum(now = FALSE)
	applied = FALSE

	var/thing
	for (thing in affecting_turfs)
		var/turf/T = thing
		LAZYREMOVE(T.affecting_lights, src)

	affecting_turfs = null

	for (thing in effect_str)
		var/lighting_corner/C = thing
		REMOVE_CORNER(C,now)

		LAZYREMOVE(C.affecting, src)

	effect_str = null

/light_source/proc/recalc_corner(var/lighting_corner/C, now = FALSE)
	LAZYINITLIST(effect_str)
	if (effect_str[C]) // Already have one.
		REMOVE_CORNER(C,now)
		effect_str[C] = 0

	var/actual_range = light_range

	var/Sx = pixel_turf.x
	var/Sy = pixel_turf.y
	var/Sz = pixel_turf.z

	var/height = C.z == Sz ? LIGHTING_HEIGHT : CALCULATE_CORNER_HEIGHT(C.z, Sz)
	APPLY_CORNER(C, now, Sx, Sy, height)

	UNSETEMPTY(effect_str)

/light_source/proc/update_corners(var/now = FALSE)

	var/update = FALSE
	var/atom/source_atom = src.source_atom //From /tg/. Prevents it from being cleared mid update.

	if(!source_atom || source_atom.qdeleting)
		qdel(src)
		return

	if(source_atom.light_power != light_power)
		light_power = source_atom.light_power
		update = TRUE

	if(source_atom.light_range != light_range)
		light_range = source_atom.light_range
		update = TRUE

	if(!top_atom)
		top_atom = source_atom
		update = TRUE

	if(top_atom.loc != source_turf)
		source_turf = top_atom.loc
		UPDATE_APPROXIMATE_PIXEL_TURF
		update = TRUE

	if(!light_range || !light_power)
		update = TRUE

	if(is_turf(top_atom))
		if(source_turf != top_atom)
			source_turf = top_atom
			UPDATE_APPROXIMATE_PIXEL_TURF
			update = TRUE
	else if (top_atom.loc != source_turf)
		source_turf = top_atom.loc
		UPDATE_APPROXIMATE_PIXEL_TURF
		update = TRUE

	if (!source_turf)
		log_error("LIGHTING: No source_turf existed for update_corners()!")
		return	// Somehow we've got a light in nullspace, no-op.

	if (light_range && light_power && !applied)
		update = TRUE

	if (source_atom.light_color != light_color)
		light_color = source_atom.light_color
		parse_light_color()
		update = TRUE

	else if (applied_lum_r != lum_r || applied_lum_g != lum_g || applied_lum_b != lum_b)
		update = TRUE

	if (source_atom.light_wedge != light_angle)
		light_angle = source_atom.light_wedge
		update = TRUE

	if (light_angle)
		var/ndir = top_atom.dir

		if (old_direction != ndir)	// If our direction has changed, we need to regenerate all the angle info.
			regenerate_angle(ndir)
			update = TRUE
		else // Check if it was just a x/y translation, and update our vars without an regenerate_angle() call if it is.
			var/co_updated = FALSE
			if (source_turf.x != cached_origin_x)
				test_x_offset += source_turf.x - cached_origin_x
				cached_origin_x = source_turf.x

				co_updated = TRUE

			if (source_turf.y != cached_origin_y)
				test_y_offset += source_turf.y - cached_origin_y
				cached_origin_y = source_turf.y

				co_updated = TRUE

			if (co_updated)
				// We might be facing a wall now.
				var/turf/front = get_step(source_turf, old_direction)
				var/new_fo = (front && front.has_opaque_atom)
				if (new_fo != facing_opaque)
					facing_opaque = new_fo
					regenerate_angle(ndir)

				update = TRUE

	if (update)
		needs_update = LIGHTING_CHECK_UPDATE
	else if (needs_update == LIGHTING_CHECK_UPDATE)
		return	// No change.

	var/list/lighting_corner/corners = list()
	var/list/turf/turfs = list()
	var/thing
	var/lighting_corner/C
	var/turf/T
	var/list/Tcorners
	var/Sx = pixel_turf.x	// these are used by APPLY_CORNER_BY_HEIGHT
	var/Sy = pixel_turf.y
	var/Sz = pixel_turf.z
	var/corner_height = LIGHTING_HEIGHT
	var/actual_range = 0
	if(source_atom == source_turf)
		actual_range = (light_angle && facing_opaque) ? light_range * LIGHTING_BLOCKED_FACTOR_TURF : light_range
	else
		actual_range = (light_angle && facing_opaque) ? light_range * LIGHTING_BLOCKED_FACTOR : light_range
	var/test_x
	var/test_y

	actual_range = CEILING(actual_range,1)

	FOR_DVIEW(T, actual_range, source_turf, 0)

		if (light_angle && !facing_opaque)	// Directional lighting coordinate filter.
			test_x = T.x - test_x_offset
			test_y = T.y - test_y_offset

			// if the signs of both of these are NOT the same, the point is NOT within the cone.
			if ((DISCRIMINANT(limit_a_x, limit_a_y, test_x, test_y) > 0) || (DISCRIMINANT(test_x, test_y, limit_b_x, limit_b_y) > 0))
				continue

		if (T.light_sources || TURF_IS_DYNAMICALLY_LIT_UNSAFE(T))
			Tcorners = T.corners
			if(!T.lighting_corners_initialised)
				T.lighting_corners_initialised = TRUE

				if (!Tcorners)
					T.corners = list(null, null, null, null)
					Tcorners = T.corners

				for (var/i = 1 to 4)
					if (Tcorners[i])
						continue

					Tcorners[i] = new /lighting_corner(T, LIGHTING_CORNER_DIAGONAL[i], i)

			if(!T.has_opaque_atom)
				for (var/v in 1 to 4)
					var/val = Tcorners[v]
					if (val)
						corners[val] = 0

		turfs += T

		CHECK_TICK(75,FPS_SERVER*10)

	END_FOR_DVIEW

	LAZYINITLIST(affecting_turfs)

	var/list/L = turfs - affecting_turfs // New turfs, add us to the affecting lights of them.
	affecting_turfs += L
	for(thing in L)
		T = thing
		LAZYADD(T.affecting_lights, src)
		CHECK_TICK(75,FPS_SERVER*10)

	L = affecting_turfs - turfs // Now-gone turfs, remove us from the affecting lights.
	affecting_turfs -= L
	for (thing in L)
		T = thing
		LAZYREMOVE(T.affecting_lights, src)
		CHECK_TICK(75,FPS_SERVER*10)

	LAZYINITLIST(effect_str)
	if (needs_update == LIGHTING_VIS_UPDATE)
		for (thing in corners - effect_str)
			C = thing
			LAZYADD(C.affecting, src)
			if (!C.active)
				effect_str[C] = 0
				continue
			APPLY_CORNER_BY_HEIGHT(now)
			CHECK_TICK(75,FPS_SERVER*10)
	else
		L = corners - effect_str
		for (thing in L)
			C = thing
			LAZYADD(C.affecting, src)
			if (!C.active)
				effect_str[C] = 0
				continue
			APPLY_CORNER_BY_HEIGHT(now)
			CHECK_TICK(75,FPS_SERVER*10)

		for (thing in corners - L)
			C = thing
			if (!C.active)
				effect_str[C] = 0
				continue
			APPLY_CORNER_BY_HEIGHT(now)
			CHECK_TICK(75,FPS_SERVER*10)

	L = effect_str - corners
	for (thing in L)
		C = thing
		REMOVE_CORNER(C, now)
		LAZYREMOVE(C.affecting, src)
		CHECK_TICK(75,FPS_SERVER*10)

	effect_str -= L

	applied_lum_r = lum_r
	applied_lum_g = lum_g
	applied_lum_b = lum_b

	UNSETEMPTY(effect_str)
	UNSETEMPTY(affecting_turfs)

#undef INTELLIGENT_UPDATE
#undef DISCRIMINANT
#undef GET_APPROXIMATE_PIXEL_DIR
#undef UPDATE_APPROXIMATE_PIXEL_TURF