local log = require("utils.log")
local reaper_utils = {}

-- KEEP GENERALIZED UTILS FOR REAPER
--
-- NOTE: this file is not allowed to import any modules except for logging
--
-- fix: some utils should move over to sxu!?

reaper_utils.GetProjIDByPath = function(projfn)
	for idx = 0, 1000 do
		local retval, projfn0 = reaper.EnumProjects(idx)
		if not retval then
			return
		end
		if projfn == projfn0 then
			return idx
		end
	end
end

function reaper_utils.isSel()
	return reaper.CountSelectedTracks(0) ~= 0
end

--- Get info for tracks matching search_name pattern
function reaper_utils.getMatchedTrackGUIDs(search_name)
	if not search_name then
		return nil
	end
	local found = false
	local t = {}
	for i = 0, reaper.CountTracks(0) - 1 do
		local tr = reaper.GetTrack(0, i)
		local _, current_name = reaper.GetTrackName(tr)
		-- log.info("["..current_name .." = " .. search_name .. "], ", current_name:match(search_name))
		if current_name:match(search_name) then
			t[#t + 1] = { name = current_name, guid = reaper.GetTrackGUID(tr) }

			found = true
		end
	end
	if found then
		return t
	else
		return false
	end
end

-- TODO
--
-- tr, tr_index // move this to RK main util???
--
-- or should there maybe be a `track` file under lib/ where we'd put
-- any kind of base track functions.
function reaper_utils.getGUIDByTrack(tr)
	for i = 0, reaper.CountTracks(0) - 1 do
		local GUID = reaper.GetTrackGUID(tr)
		if GUID ~= nil or GUID ~= "" then
			return GUID
		end
	end
	return false
end

-- add return track name also??
--
-- TODO: if table of guids passed return list of track references.
--
-- TODO: allow passing tobj, or list of tobjs
--
function reaper_utils.getTrackByGUID(search_guid)
	-- local tr = reaper.BR_GetMediaTrackByGUID( 0, search_guid )
	-- if type(tr) == 'userdata' then return tr else return false end
	-- or just nil >> but it is really nice to get idx together with guid sometimes..
	for i = 0, reaper.CountTracks(0) - 1 do
		local tr = reaper.GetTrack(0, i)
		local GUID = reaper.GetTrackGUID(tr)
		if GUID == search_guid then
			return tr, i
		end
	end
	return false
end

-- from MPL
-- function VF_GetTrackByGUID(giv_guid, reaproj)
-- 	if not (giv_guid and giv_guid:gsub("%p+", "")) then
-- 		return
-- 	end
-- 	for i = 1, CountTracks(reaproj or 0) do
-- 		local tr = GetTrack(reaproj or 0, i - 1)
-- 		--local GUID = reaper.GetTrackGUID( tr )
-- 		local retval, GUID = reaper.GetSetMediaTrackInfo_String(tr, "GUID", "", false)
-- 		if GUID:gsub("%p+", "") == giv_guid:gsub("%p+", "") then
-- 			return tr
-- 		end
-- 	end
-- end

reaper_utils.GetFXByGUID = function(GUID, tr, proj)
	if not GUID then
		return
	end
	local pat = "[%p]+"
	if not tr then
		for trid = 1, reaper.CountTracks(proj or 0) do
			local tr = reaper.GetTrack(0, trid - 1)
			local fxcnt_main = reaper.TrackFX_GetCount(tr)
			local fxcnt = fxcnt_main + reaper.TrackFX_GetRecCount(tr)
			for fx = 1, fxcnt do
				local fx_dest = fx
				if fx > fxcnt_main then
					fx_dest = 0x1000000 + fx - fxcnt_main
				end
				if reaper.TrackFX_GetFXGUID(tr, fx - 1):gsub(pat, "") == GUID:gsub(pat, "") then
					return true, tr, fx - 1
				end
			end
		end
	else
		if not (reaper.ValidatePtr2(proj or 0, tr, "MediaTrack*")) then
			return
		end
		local fxcnt_main = reaper.TrackFX_GetCount(tr)
		local fxcnt = fxcnt_main + reaper.TrackFX_GetRecCount(tr)
		for fx = 1, fxcnt do
			local fx_dest = fx
			if fx > fxcnt_main then
				fx_dest = 0x1000000 + fx - fxcnt_main
			end
			if reaper.TrackFX_GetFXGUID(tr, fx_dest - 1):gsub(pat, "") == GUID:gsub(pat, "") then
				return true, tr, fx_dest - 1
			end
		end
	end
end

reaper_utils.CalibrateFont = function(sz, rawsz) -- https://forum.cockos.com/showpost.php?p=2066576&postcount=17
	--  rawsz starting from 2.08 used for new script to allow use raw sz values rather than table hardcoded values
	local t = { [13] = 80, [15] = 90, [19] = 110, [21] = 150 } -- windows measured
	gfx.setfont(1, "Calibri", sz)
	local str_width, str_height = gfx.measurestr("MMMMMMMMMM")
	local font_factor
	if rawsz then
		font_factor = sz * 6.5 / str_width
	else
		font_factor = t[sz] / str_width
	end
	return math.floor(sz * font_factor)
end

-- tr nil checks

reaper_utils.get_single_track_state_chunk = function(tr)
	local ret, state = reaper.GetTrackStateChunk(tr, "", false)
	return state
end

reaper_utils.set_single_track_state_chunk = function(tr, state)
	if type(tr) == "number" then
		tr = reaper.GetTrack(0, tr)
	end
	return reaper.SetTrackStateChunk(tr, state, false)
end

-- error handling
reaper_utils.get_track_and_item_count_for_node = function(node)
	local tr = reaper_utils.getTrackByGUID(node.guid)
	local item_count = reaper.CountTrackMediaItems(tr)
	return tr, item_count
end

-- error handling
reaper_utils.get_item_and_first_take = function(tr, i)
	local item = reaper.GetTrackMediaItem(tr, i)
	local take = reaper.GetMediaItemTake(item, 0) -- active take
	return item, take
end

reaper_utils.check_item_belongs_to_track = function(tr, item)
	return tr == reaper.GetMediaItemTrack(item)
end

-- should this be moved into sxu?
--
-- This function is used when restoring items. if an item can be found by
-- GUID then we use it. Otherwise we create it
--
--- NOTE: a node is expected, but if you pass a regular track or index,
--- then that will be used for getting the track.
---
---@param in_track userdata | table | number
---@param item_node
reaper_utils.get_create_item_from_node = function(in_track, item_node)
	-- this means we were passed a node

	if type(in_track) == "number" then
		in_track = reaper.GetTrack(0, in_track)

		-- todo: handle errors
	end

	if type(in_track) ~= "userdata" then
		in_track = reaper_utils.getTrackByGUID(in_track.guid)
		-- todo: handle errors
	end

	-- todo: handle errors

	local item = reaper.BR_GetMediaItemByGUID(0, item_node.guid)
	local valid_item = type(item) == "userdata" and true or false
	local in_correct_track = valid_item and reaper_utils.check_item_belongs_to_track(in_track, item) or false

	if valid_item and in_correct_track then
		local take = reaper.GetMediaItemTake(item, 0) -- active take
		return item, take
	else
		local new_item = reaper.AddMediaItemToTrack(in_track)

		-- HACK: could i just set the item state chunk instead??
		for k, v in pairs(item_node.item_info) do
			local ret = reaper.SetMediaItemInfo_Value(new_item, k, v)
		end
		local new_take = reaper.GetMediaItemTake(new_item, 0) -- active take
		return new_item, new_take
	end
end

reaper_utils.node_takes_do = function(node, fn, ...)
	local tr, item_count = reaper_utils.get_track_and_item_count_for_node(node)
	for i = 0, item_count - 1 do -- does parent_item_cnt need to be stored????
		local item, take = reaper_utils.get_item_and_first_take(tr, i)
		fn(take, ...)
	end
end

-- first param is usually a track node, but you can also pass a media track
-- ref or pass the index of a track.
reaper_utils.node_insert_takes_do = function(node_or_tr, item_objs, fn, ...)
	for _, item_data in ipairs(item_objs) do
		local _, take = reaper_utils.get_create_item_from_node(node_or_tr, item_data)
		fn(take, item_data, ...)
	end
end

reaper_utils.node_iter_items_and_xtake = function(node, fn)
	local tr, item_count = reaper_utils.get_track_and_item_count_for_node(node)
	for i = 0, item_count - 1 do -- does parent_item_cnt need to be stored????
		local item, take = reaper_utils.get_item_and_first_take(tr, i)
		local take_is_midi = reaper.TakeIsMIDI(take)
		fn(item, take, take_is_midi)
	end
end

reaper_utils.delete_node = function(node)
	reaper.DeleteTrack(reaper_utils.getTrackByGUID(node.guid))
end

return reaper_utils
