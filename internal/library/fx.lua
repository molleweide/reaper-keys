-- dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")
local ru = require("custom_actions.utils")
local log = require("utils.log")
local format = require("utils.format")

local r = require("utils.reaper")

local fx_util = {}

local REC_FX = 0x1000000

--[[-------------------------------

TODO

- make sure only GUIDS are used in this file as arguments

- bypass fx

-- rec/norec could be refactored into base fn

-----------------------------------


retval, minval, maxval = reaper.TrackFX_GetParam(track, fx_idx, param_idx)

retval, buf = reaper.TrackFX_GetParamName(track, fx_idx, param_idx, string buf)

----------------------------------

integer reaper.TrackFX_GetRecCount(track)

  To access record input FX, use a FX indices
  [0x1000000..0x1000000+n). On the master track, this accesses monitoring FX
  rather than record input FX.

---------------------------------

reaper.TrackFX_CopyToTrack(src_track, src_fx, dest_track, dest_fx, is_move)

  Copies (or moves) FX from src_track to dest_track.

  Can be used with src_track=dest_track to reorder, FX indices have 0x1000000 set
  to reference input FX.

-----------------------------------]]
--

function fx_util.insertFxToLastIndex(guid_tr, fx_str, is_rec_fx)
	local tr = ru.getTrackByGUID(guid_tr)
	return reaper.TrackFX_AddByName(tr, fx_str, is_rec_fx, -1) -- add to last index
end

-- check if named fx exists. this is much more specific than only looking for a
-- specific fx since two instances of same fx can different purposes...
function fx_util.trackHasFxChainString(guid_tr, fx_str, is_rec_fx)
	local found = false

	local tr = ru.getTrackByGUID(guid_tr)

	if is_rec_fx then
		local tc = reaper.TrackFX_GetRecCount(tr) - 1
		for i = 0, tc - 1 do
			local fxc_str = fx_util.getSetTrackFxNameByFxChainIndex(guid_tr, i, true) -- TODO rec fx
			if fx_str == fxc_str then
				found = true
			end
		end
	else
		local tc = reaper.TrackFX_GetCount(tr) - 1
		for i = 0, tc do
			local fxc_str = fx_util.getSetTrackFxNameByFxChainIndex(guid_tr, i, false) -- TODO rec fx
			-- log.user(fxc_str, fx_str)
			if fx_str == fxc_str then
				found = true
			end
		end
	end
	return found
end

-- add ability to add last fx index
function fx_util.insertFxAtIndex(guid_tr, fx_str, fx_insertTo_idx, is_rec_fx)
	local tr, tr_idx = ru.getTrackByGUID(guid_tr)
	local is_move_flag = true -- required on order to reorder tracks
	if is_rec_fx then
		log.user("pre add fx", tr)
		reaper.TrackFX_AddByName(tr, fx_str, true, -1) -- add to last index
		local fx_idx_last = reaper.TrackFX_GetRecCount(tr) - 1
		if fx_idx_last ~= fx_insertTo_idx then
			reaper.TrackFX_CopyToTrack(tr, REC_FX + fx_idx_last, tr, REC_FX + fx_insertTo_idx, is_move_flag)
		end
	else
		reaper.TrackFX_AddByName(tr, fx_str, false, -1) -- add to last index
		local fx_idx_last = reaper.TrackFX_GetCount(tr) - 1
		if fx_idx_last ~= fx_insertTo_idx then
			reaper.TrackFX_CopyToTrack(tr, fx_idx_last, tr, fx_insertTo_idx, is_move_flag)
		end
	end
end

function fx_util.replaceFxAtIndex(guid_tr, fx_str, fx_insertTo_idx, is_rec_fx)
	if is_rec_fx then
		fx_util.removeFxAtIndex(guid_tr, fx_insertTo_idx, true)
		fx_util.insertFxAtIndex(guid_tr, fx_str, fx_insertTo_idx, true)
	else
		fx_util.removeFxAtIndex(guid_tr, fx_insertTo_idx)
		fx_util.insertFxAtIndex(guid, fx_str, fx_insertTo_idx)
	end
end

function fx_util.removeFxAtIndex(guid_tr, fx_rm_idx, is_rec_fx)
	local tr, tr_idx = ru.getTrackByGUID(guid_tr)
	if is_rec_fx then
		reaper.TrackFX_Delete(tr, REC_FX + fx_rm_idx)
	else
		reaper.TrackFX_Delete(tr, fx_rm_idx)
	end
end

function fx_util.removeAllFXAfterIndex(guid_tr, index)
	local tr, tr_idx = ru.getTrackByGUID(guid_tr)
	local tc = reaper.TrackFX_GetCount(tr)
	local num_fx_after_i = tc - index
	while num_fx_after_i > 0 do
		for i = index, tc - 1 do
			reaper.TrackFX_Delete(tr, i)
		end
		tc = reaper.TrackFX_GetCount(tr)
		num_fx_after_i = tc - index
	end
end

--
--
--
--
-- TODO: merge set fx param funcs into one - accepting single param or
-- table.
--
--
-- NOTE: is_rec_fx is optional right??

--- Given track guid, update FX param for FX index..
---@param guid_tr string
---@param fx_idx integer
---@param param integer
---@param value number|string
---@param is_rec_fx boolean
function fx_util.setParamForFxAtIndex(guid_tr, fx_idx, param, value, is_rec_fx)
	local tr, tr_idx = ru.getTrackByGUID(guid_tr)
	if is_rec_fx then
		reaper.TrackFX_SetParam(tr, REC_FX + fx_idx, param, value)
	else
		reaper.TrackFX_SetParam(tr, fx_idx, param, value)
	end
end

---
---@param guid_tr string
---@param fx_idx int
---@param t_params table
function fx_util.setFxParamsFromTable(guid_tr, fx_idx, t_params)
	local tr = ru.getTrackByGUID(guid_tr)
	for i, parm in pairs(t_params) do
		retval, parname = reaper.TrackFX_GetParamName(tr, fx_idx, i, "")
		-- log.user(i, parname, parm)
		local ret = reaper.TrackFX_SetParam(tr, fx_idx, i, parm)
	end
end

-- function insertFxToLastIdxAndGuiRename(guid_tr, fx_search_str, fx_gui_name)
--     local fx_idx = fx_util.insertFxToLastIndex(guid_tr, fx_search_str, false)
--     fx_util.getSetTrackFxNameByFxChainIndex(guid_tr, fx_idx, true, fx_gui_name)
-- end

-- DON'T USE  `TRACKS`
--    ONLY GUID
--    REFACTOR: take options table as input instead. more readable
--    {
--      tr_guid = string, (track guid)
--      fx_idx = number
--      is_rec = bool,
--      new_name = string
--    }
function fx_util.getSetTrackFxNameByFxChainIndex(guid_tr_or_opts, idx_fx, is_rec_fx, newName)
	local guid_tr = guid_tr_or_opts

	-- handle opts table
	if guid_tr_or_opts == nil then
		return
	elseif type(guid_tr_or_opts) == "table" then
		local t = guid_tr_or_opts
		guid_tr = t.guid_tr
		idx_fx = t.idx_fx
		is_rec_fx = t.is_rec_fx
		newName = t.newName
	end

	-- log.user(guid_tr, idx_fx, is_rec_fx, newName)

	local tr, tr_idx = ru.getTrackByGUID(guid_tr)
	local strT, found, slot = {}
	local Pcall
	local FXGUID

	if is_rec_fx then
		Pcall, FXGUID = pcall(reaper.TrackFX_GetFXGUID, tr, REC_FX + idx_fx)
	else
		Pcall, FXGUID = pcall(reaper.TrackFX_GetFXGUID, tr, idx_fx)
	end

	if not Pcall or not FXGUID then
		return false
	end
	local retval, str = reaper.GetTrackStateChunk(tr, "", false)
	local trFxNameStr

	-- https://lua.programmingpedia.net/en/tutorial/5829/pattern-matching
	for l in (str .. "\n"):gmatch(".-\n") do
		table.insert(strT, l) -- add each line to table
	end

	for i = #strT, 1, -1 do
		if strT[i]:match(FXGUID:gsub("%p", "%%%0")) then
			found = true
		end
		if strT[i]:match("^<") and found and not strT[i]:match("JS_SER") then
			found = nil
			local nStr = {}
			for S in strT[i]:gmatch("%S+") do
				if not X then
					nStr[#nStr + 1] = S
				else
					nStr[#nStr] = nStr[#nStr] .. " " .. S
				end
				if S:match('"') and not S:match('""') and not S:match('".-"') then
					if not X then
						X = true
					else
						X = nil
					end
				end
			end
			if strT[i]:match("^<%s-JS") then
				slot = 3
			elseif strT[i]:match("^<%s-AU") then
				slot = 4
			elseif strT[i]:match("^<%s-VST") then
				slot = 5
			end
			if not slot then
				error("Failed to rename/access name", 2)
			end
			trFxNameStr = nStr[slot]
			if newName ~= nil and type(newName) == "string" then
				nStr[slot] = newName:gsub(newName:gsub("%p", "%%%0"), '"%0"')
			end
			nStr[#nStr + 1] = "\n"
			strT[i] = table.concat(nStr, " ")
			break
		end
	end

	if newName ~= nil and type(newName) == "string" then
		return reaper.SetTrackStateChunk(tr, table.concat(strT), false)
	end
	return trFxNameStr
end

function fx_util.insertFxToLastIdxAndGuiRename(guid_tr, fx_search_str, fx_gui_name)
	local fx_idx = fx_util.insertFxToLastIndex(guid_tr, fx_search_str, false)
	fx_util.getSetTrackFxNameByFxChainIndex(guid_tr, fx_idx, false, fx_gui_name)
	return fx_idx
end

-- TODO:...
function fx_util.fxSetBypass(guid_tr, fx_idx, bypass)
	-- 0 = off
	-- 1 = one
	-- 2 = toggle
end

-- TODO:...
function fx_util.fxBypassToggle(guid_tr, fx_idx)
	fx_util.fxSetBypass(guid_tr, fx_idx, 2)
end

--- Get the index of an FX with name == "search_name"
---
---@param guid_tr
---@param search_name
---@param found_idx number | nil
fx_util.get_fx_objs_by_name_string = function(guid_tr, search_name, found_idx)
	-- TODO: handle regular expressions in search_name pattern string

	-- TODO: handle is_rec_fx
	local is_rec_fx = false

	if not search_name then
		return nil
	end

	local tr, tr_idx = ru.getTrackByGUID(guid_tr)

	local tc = reaper.TrackFX_GetCount(tr)
	-- local internal_fxc = reaper.TrackFX_AddByName(tr, search_name, is_rec_fx, 0) -- add to last index
	-- log.info("internal_fxc:", internal_fxc)

	local found = false
	local t = {}
	for i = 0, tc - 1 do
		local current_name = fx_util.getSetTrackFxNameByFxChainIndex(guid_tr, i, is_rec_fx)
		local ok, plugin_name = reaper.TrackFX_GetFXName(tr, i)
		local fx_has_custom_name = true
		if current_name == '""' then
			fx_has_custom_name = false
		end
		if fx_has_custom_name then
			if current_name:match(search_name) then
				t[#t + 1] = { name = current_name, idx = i, guid = reaper.TrackFX_GetFXGUID(tr, i) }
				log.info("entered current for", current_name)

				found = true
			end
		end
		if not fx_has_custom_name then
			if ok then
				if plugin_name:match(search_name) then
					t[#t + 1] = { name = plugin_name, idx = i, guid = reaper.TrackFX_GetFXGUID(tr, i) }
					found = true
				end
			end
		end
	end

	if found then
		if not found_idx then
			return t[1]
		else
			return found_idx == 0 and t or t[found_idx]
		end
	else
		return false
	end
end

fx_util.get_single_tracks_fx_state_chunk = function(tr)
	-- https://mespotin.uber.space/Ultraschall/US_Api_Functions.html#SaveFXStateChunkAsRFXChainfile
	--
	-- TODO: test ultra shall `GetFX`
	--
	--
	-- todo: install -> https://mespotin.uber.space/Ultraschall/US_Api_Introduction_and_Concepts.html#Introduction_001_Api

	local s_track_state_chunk = reaper.GetTrackStateChunk(tr, "", false)
	dofile(reaper.GetResourcePath() .. "/UserPlugins/ultraschall_api.lua")
	local s_FXStateChunk, i_line_num = ultraschall.GetFXStateChunk(s_track_state_chunk)
	-- log.user(s_FXStateChunk)
	return s_FXStateChunk
end

---
---@param tr userdata
---@param fx_state string
fx_util.set_single_tracks_fx_state_chunk = function(tobj, fx_state)
	local tr, tr_i = r.getTrackByGUID(tobj.guid)
	local retval, s_track_state_chunk = r.get_single_track_state_chunk(tr)
	dofile(reaper.GetResourcePath() .. "/UserPlugins/ultraschall_api.lua")
	local retval, s_altered_track_state_chunk = ultraschall.SetFXStateChunk(s_track_state_chunk, fx_state)

	r.set_single_track_state_chunk(tr, state)
end
--
--
--
--
--
--
--
--
--
-- TODO: improve this function with filters similar to `get_item_info`
-- and `get_midi_data_from_item`
--
--
-- NOTE: currently only works on selected track single
--
--
-- fix: pass tobj or tr?
--
fx_util.get_track_fx_chain_info = function(tr)
	tr = tr or reaper.GetSelectedTrack(0, 0)

	local t_track_fx_chain = {}
	local tc = reaper.TrackFX_GetCount(tr)

	local GUID = reaper.GetTrackGUID(tr)

	for i = 0, tc - 1 do
		local current_name = fx_util.getSetTrackFxNameByFxChainIndex(GUID, i, false)

		local ok, plugin_name = reaper.TrackFX_GetFXName(tr, i)

		local fx_obj = {
			idx = i,
			name = current_name,
			pname = plugin_name,
		}
		table.insert(t_track_fx_chain, fx_obj)
	end
	return t_track_fx_chain
end

fx_util.get_track_fx_info = function(tr, fx_idx)
	local parm_cnt = reaper.TrackFX_GetNumParams(tr, fx_idx)
	local _, name = reaper.TrackFX_GetFXName(tr, fx_idx, "")

	-- local special_name =
	local _, special_name = reaper.TrackFX_GetFXName(tr, fx_idx)

	local t_track_fx_info = {
		name = name,
		name_special = special_name,
		parameters = {},
	}

	for i = 0, parm_cnt - 1 do
		local _, parm_name = reaper.TrackFX_GetParamName(tr, fx_idx, i, "")
		local val = reaper.TrackFX_GetParamNormalized(tr, fx_idx, i)
		local _, valf = reaper.TrackFX_GetFormattedParamValue(tr, fx_idx, i, "")
		table.insert(t_track_fx_info.parameters, {
			index = i,
			name = parm_name,
			val = val,
			valf = valf
		})
	end
	return t_track_fx_info
end

-- --
-- --
-- --
-- --
-- --
-- --
-- --
-- --
-- -- FIX: rename -> the current name is a bit misleading
-- --
-- --
-- -- TEST: does this function work from all aspects, as standalone passed with tobj,
-- -- from main selection, or from ME?
-- --
-- --
-- -- NOTE: only targets first instance of effect_name found
-- --
-- -- TODO: add rec_fx
-- --
-- --
-- --
-- fx_util.focus_tracks_fx_do = function(meta, opts)
-- 	-- log.user("plugname", format.block(plugin_name))
--
-- 	local plugin_name = opts[1]
-- 	local callback = opts[2]
--
-- 	-- FIX: this has to be passed to the fx lib
-- 	local target_trk_objects, track_objects_list = lib_tr.get_focused_track_objects()
--
-- 	for _, tobj in pairs(target_trk_objects) do
-- 		-- local gobj = sxlu.get_track_object_group(sx.getVerifiedTree(track_objects_list), tobj)
-- 		local fx_obj = fx_util.get_fx_objs_by_name_string(tobj.guid, plugin_name)
--
-- 		if not fx_obj then
-- 			log.debug(
-- 				string.format([[ [plugins.randomize_rs5k_...]: %s has no RS5K to load with samples..]], tobj.name)
-- 			)
-- 		else
-- 			local ok, fx_mod = pcall(require, "plugins." .. plugin_name)
-- 			if not ok then
-- 				log.debug("fx has no module or doesn't exist")
-- 			end
--
-- 			-- if is_rec_fx then
-- 			--   Pcall, FXGUID = pcall(reaper.TrackFX_GetFXGUID, tr, REC_FX + idx_fx)
-- 			-- else
-- 			--   Pcall, FXGUID = pcall(reaper.TrackFX_GetFXGUID, tr, idx_fx)
-- 			-- end
--
-- 			if type(callback) == "string" then
-- 				fx_mod[callback](tobj, fx_obj.idx)
-- 			elseif type(callback) == "function" then
-- 				callback(fx_mod)
-- 			end
-- 		end
--
-- 		-- -- check that we are working with a midi drum track
-- 		-- if sxlu.trackObjHasOption(gobj, "m") then
-- 		--   rs5k.updateSample(tobj, fx_idx)
-- 		-- else
-- 		--   log.debug(
-- 		--     string.format([[ [plugins.randomize_rs5k_...]: %s has no RS5K to load with samples..]], tobj.name)
-- 		--   )
-- 		-- end
-- 	end
-- end

---Filter/transform API for working with all projects track fx.
---This could be useful in order to eg. mute all effects based on a certain
---criterion.
---@param opts table | nil
fx_util.fltr_all = function (opts)
end

return fx_util
