local log = require("utils.log")
local format = require("utils.format")

-- TODO: Add custom bindings here for handling fx_parameters when mixing.
-- This will start the era of having custom FZF bindings for modifying
-- FX and other data inside of the program.

return function(gui, key, i)
  log.user("attack mappings refactored")

	local selection = gui.t_search_results[i]
	if not selection then
		return
	end
	log.user("#################################", key)

	local _, step, smallstep, largestep, istoggle =
		reaper.TrackFX_GetParameterStepSizes(gui.meta.node.tr, gui.meta.fx_index, selection.index)
	local _, minval, maxval = reaper.TrackFX_GetParam(gui.meta.node.tr, gui.meta.fx_index, selection.index)
	local full_range = maxval - minval

	-- move to utils.math
	local function round(number, decimalPlaces)
		local multiplier = 10 ^ (decimalPlaces or 0)
		return math.floor(number * multiplier + 0.5) / multiplier
	end

	local function update_fx_parameter(amount)
		local amount_new
		if istoggle then
			amount_new = amount > 0 and 1 or 0
		else
			log.user(type(selection.val))
			log.user("???:", selection.val, amount, selection.val + amount)
			amount_new = selection.val + amount
			if amount_new <= minval then
				amount_new = minval
			elseif amount_new >= maxval then
				amount_new = maxval
			end
		end

		-- amount_new = round(amount_new, 3)

		-- set plugin value
		local ret = reaper.TrackFX_SetParamNormalized(gui.meta.node.tr, gui.meta.fx_index, selection.index, amount_new)

		-- get values so that we can update the table entry in the picker
		local num = reaper.TrackFX_GetParamNormalized(gui.meta.node.tr, gui.meta.fx_index, selection.index)

		local _, numf = reaper.TrackFX_GetFormattedParamValue(gui.meta.node.tr, gui.meta.fx_index, selection.index)
		selection.val = num
		selection.valf = numf
		UPDATE_RESULTS = true

		-- log.user(string.format(
		--   [[
		-- ---
		-- amount in:     %s
		-- prev val:      %s
		-- new val:       %s (amount new)
		-- after getting: %s
		-- ---
		-- ]] ,
		--   amount,
		--   selection.val,
		--   amount_new,
		--   num
		-- ))
	end

	log.user(type(selection.val), type(selection.valf))

	local function make_incr_decr_mapping_pair(mod, down, up, divider)
		local val = full_range / divider
		if key == gui.kb[mod .. "_" .. down] then
			update_fx_parameter(-val)
		end
		if key == gui.kb[mod .. "_" .. up] then
			update_fx_parameter(val)
		end
	end

	make_incr_decr_mapping_pair("control", "w", "b", 350)
	make_incr_decr_mapping_pair("control", "d", "f", 100)
	make_incr_decr_mapping_pair("control", "s", "g", 50)
	make_incr_decr_mapping_pair("control", "j", "k", 10)
	make_incr_decr_mapping_pair("control", "n", "p", 5)
end
