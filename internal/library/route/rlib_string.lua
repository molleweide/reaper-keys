local ru = require("custom_actions.utils")
local log = require("utils.log")
local format = require("utils.format")
local str_util = require("utils.string")
local midi_util = require("utils.midi")
local r = require("utils.reaper")
local rc = require("definitions.routing")

local rlib_targets = require("library.route.rlib_targets")

-- FIX: rename `t_current_route_config` to `t_current_route_config`

local rlib_string = {}

-- TODO: this should go into the config file
local USER_INPUT_TARGETS_DIV = "|"

function extract_route_secondary_param(str, key)
	-- TODO: i have to document this pattern better
	--
	--
	-- NOTE: pattern looking for:
	-- 1. Either of these first `!?`
	-- 2. Target `character`, eg. "a"
	-- 3. num ?dot ?num ?num ?num ?num
	--
	local pattern = "!?" .. key .. "%d?%.?%d?%d?%d?%d?" -- very generic pattern

	local s, e = string.find(str, pattern)
	local mv_offset = 1
	local retval = false
	local matched_value
	local prefix

	if s ~= nil and e ~= nil then
		retval = true
		local sub_pattern = string.sub(str, s, e)
		prefix = string.sub(sub_pattern, 0, 1)
		if prefix == "!" then
			mv_offset = 2
		end
		matched_value = string.sub(str, s + mv_offset, e)
	end

	return retval, matched_value, prefix
end

--- Extract information about which data channels to target, ie. audio/midi
---@param str
---@param bracket_type
---@param sep
---@param allowed_range_low
---@param allowed_range_high
---@return
function extract_channel_info(str, bracket_type, sep, allowed_range_low, allowed_range_high)
	local dataBracket, str = str_util.extract_string_inside_brackets(str, bracket_type)
	local bSrc, bDst
	if dataBracket ~= nil then
		local dataBracketSplit = str_util.getStringSplitPattern(dataBracket, sep)
		for d = 1, #dataBracketSplit do
			local D = tonumber(dataBracketSplit[d])
			if D < allowed_range_low or D > allowed_range_high then
				D = 0
			end
			if d == 1 then
				if D ~= nil then
					bDst = D
				else
					bDst = 0
				end
			end
			if d == 2 then
				bSrc = bDst
				if D ~= nil then
					bDst = D
				else
					bDst = 0
				end
				break
			end
		end
	end
	return str, bSrc, bDst
end

--- Tries to extract a requested route config secondary param.
--- Defaults are assigned if pattern not found.
---@param t_current_route_config table
---@param str string
---@param key string
---@param primary string
---@return table, string
function extract_secondary_param_mappings(t_current_route_config, str, key, primary)
	local ret, val, pre = extract_route_secondary_param(str, key)
	-- log.user(key, ret, val, pre)

	--
	-- UPDATE ROUTE CONFIG
	--

	-- FIX: since t_current_route_config.default_params holds everything i just
	-- need to access the

	-- exists or PRIMARY
	if ret or primary ~= nil then
		if primary ~= nil then
			val = primary
		else
			val = tonumber(val)
		end

		if ret and val == nil then
			val = t_current_route_config.default_params[key].param_value
		end

		t_current_route_config.new_params[key] = {
			description = t_current_route_config.default_params[key].description,
			param_name = t_current_route_config.default_params[key].param_name,
			param_value = val,
		}

		-- exists and prefix
		if ret and pre == "!" then
			t_current_route_config.new_params[key].param_value =
				t_current_route_config.default_params[key].disable_value
		end
	end

	return t_current_route_config, str
end

-- NOTE: Order of operations:
-- 1. extract src/dest parenthesis
-- 2. extract channel info from {}/[]
-- 3. extract other (secondary) parameter mappings
--
--- Extracts route parameters from the config string
---@param t_current_route_config
---@param str
---@return
function rlib_string.extractParamsFromString(t_current_route_config, str)
	-- find first literal hyphen
	if str:find("%-") then
		t_current_route_config.remove_routes = true
		t_current_route_config.remove_both = true
	end

	-- find any # literal
	if str:find("%#") then
		t_current_route_config.category = 0
		t_current_route_config.remove_both = false
	end

	-- find any dollar literal
	if str:find("%$") then
		t_current_route_config.category = -1 -- ???
		t_current_route_config.remove_both = false
	end

	-- HANDLE PARENTHESIS
	--

	local ret, src_tr_data, dst_tr_data, str = str_util.extract_parenthesis(str) -- extractParenthesisTargets(str)

	-- log.user(ret, src_tr_data, dst_tr_data)

	-- NOTE: if the first parenthisis of two contains sub info about sources to pull
	-- from

	if src_tr_data ~= nil then -- SRC PROVIDED
		local src_tr_split = str_util.getStringSplitPattern(src_tr_data, USER_INPUT_TARGETS_DIV)
		local ret, t_current_route_config =
			rlib_targets.setRouteTargetGuids(t_current_route_config, "src_guids", src_tr_split)
	elseif r.isSel() then -- FALLBACK SRC SEL
		-- NOTE: if selection

		-- log.user('only one paren')
		-- t_current_route_config.src_from_selection = true
		-- if t_current_route_config.category == 0 then

		-- TODO: get this from utils/reaper
		t_current_route_config["src_guids"] = ru.getSelectedTracksGUIDs()
		-- end
	end

	-- NOTE: If only one () or second ()

	if dst_tr_data ~= nil then
		local dst_tr_split = str_util.getStringSplitPattern(dst_tr_data, USER_INPUT_TARGETS_DIV)

		-- log.user('dest: ' .. format.block(dst_tr_split))

		local ret, t_current_route_config =
			rlib_targets.setRouteTargetGuids(t_current_route_config, "dst_guids", dst_tr_split)
	end

	-- log.user('rstr', format.block(t_current_route_config.src_guids), format.block(t_current_route_config.dst_guids))

	-- t_current_route_config = assignGUIDsFromUserInput(t_current_route_config, src_tr_data, dst_tr_data)

	-- A. HANDLE PRIMARY COMMANDS

	-- what is b ??
	-- TODO: again move the separator into config file
	local str, bSrc, bDst = extract_channel_info(str, "[]", t_current_route_config.meta.channel_data_separator, 0, 6)
	local str, cSrc, cDst = extract_channel_info(str, "{}", t_current_route_config.meta.channel_data_separator, 0, 16)

	t_current_route_config, str = extract_secondary_param_mappings(t_current_route_config, str, "a", bSrc)
	t_current_route_config, str = extract_secondary_param_mappings(t_current_route_config, str, "d", bDst)

	-- apply midi default channs??!
	local midi_flags
	if cSrc ~= nil and cDst ~= nil then
		-- TODO: i need to learn this well
		midi_flags = midi_util.create_send_flags(cSrc, cDst)
	end
	-- log.user(cSrc, cDst, midi_flags)
	t_current_route_config, str = extract_secondary_param_mappings(t_current_route_config, str, "m", midi_flags)

	ret, val, pre = extract_route_secondary_param(str, "u")
	if ret then
		t_current_route_config.overwrite = true
	end

	return true, t_current_route_config
end

return rlib_string
