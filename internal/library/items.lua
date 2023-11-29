local log = require("utils.log")
local format = require("utils.format")

local lib_items = {}

-- NOTE: that I don't support using takes currently. only items as a singular
-- unit.

--
-- ITEMS / TAKES -> RENAMETO: containers?
--

local test_new_struct = {
	items = {},
	takes = {},
	-- functions take midi editor HWND as first arg and return something pertaining
	-- to items/takes within the passed midi editor.
	midi_editor = {},
}

-- TODO: needs nil checks and error handling
lib_items.get_all_media_items_for_track_obj = function(tobj)
	local t_tr_items = {}
	local num_items = reaper.GetTrackNumMediaItems(tobj.tr)
	if num_items > 0 then
		-- first_item = reaper.GetTrackMediaItem(track, 0)
		-- first_item_sel = reaper.IsMediaItemSelected(first_item)
		for i = 0, num_items - 1 do
			local item = reaper.GetTrackMediaItem(tobj.tr, i)
			local item_cur_take = reaper.GetTake(item, 0)
			local take_name = reaper.GetTakeName(item_cur_take)
			table.insert(t_tr_items, {
				parent_track_guid = tobj.guid,
				item_idx = reaper.GetMediaItemInfo_Value(item, "IP_ITEMNUMBER"),
				name = take_name,
				pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION"),
				length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH"),
			})
		end
	end
	return t_tr_items
end

lib_items.get_items_in_track_objects = function(t_track_objects)
	local t_all_items = {}
	for _, trk_obj in pairs(t_track_objects) do
		local num_items = reaper.GetTrackNumMediaItems(trk_obj.tr)
		if num_items > 0 then
			-- first_item = reaper.GetTrackMediaItem(track, 0)
			-- first_item_sel = reaper.IsMediaItemSelected(first_item)

			for i = 0, num_items - 1 do
				local item = reaper.GetTrackMediaItem(trk_obj.tr, i)
				local item_cur_take = reaper.GetTake(item, 0)
				local take_name = reaper.GetTakeName(item_cur_take)
				table.insert(t_all_items, {
					parent_track_id = guid,
					item_idx = reaper.GetMediaItemInfo_Value(item, "IP_ITEMNUMBER"),
					name = take_name,
				})
			end
		end
		return t_all_items
	end
end

-- REMOVE THIS!!!!!
--
-- -- : move all below to a lib function `get_single_item_data({
-- -- type = "midi|audio|both|???"
-- -- })`
-- lib_items.get_single_item_data = function(item, opts)
-- 	opts = opts or {}
-- 	if not item then
-- 		log.debug("No item was supplied to get_single_item_data")
-- 		return
-- 	end
-- 	local take = reaper.GetMediaItemTake(item, 0) -- active take?
-- 	local t_item_data = get_item_info(item)
--
-- 	if reaper.TakeIsMIDI(take) then
-- 		t_item_data.midi_events = require("library.midi").get_midi_data_from_take(take, {
-- 			filter = { notes = { pitch = { 24, 60 } } },
-- 		})
-- 	else
-- 		-- handle audio data
-- 	end
-- 	return t_item_data
-- end

-- TODO: supply filter params, eg
-- ~ note range
-- ~ channels
-- ~ cc evts
--
-- NOTE: begin by only storing/getting midi notes - cc later..
--
-- TODO: again implement filters similar to what I do with midi data.
-- so that I can easilly specify what I want from a track
--
lib_items.get_item_objs_from_single_track = function(tobj, opts)
	opts = opts or {}

	if not tobj then
		log.debug("no tobj passed to lib_items.get_all_items_data")
		return
	end

	local filter = opts.filter or {}

  -- TODO: get item ref??

	local info_filter = filter.info
	local data_filter = filter.data
	local no_filters = not info_filter and not data_filter
	local midi_and_audio
	if data_filter then
		midi_and_audio = data_filter.midi == nil and data_filter.audio == nil
	end
	-- log.user(string.format([[filter=%s, noflt=%s, m_and_a_=%s ]], filter, no_filters, midi_and_audio))

	local t_return_all_item_objs = {}

	local tr = require("custom_actions.utils").getTrackByGUID(tobj.guid)
	local item_count = reaper.CountTrackMediaItems(tr)
	for i = 0, item_count - 1 do -- does parent_item_cnt need to be stored????
		-- don't support takes - only get take 0
		local item = reaper.GetTrackMediaItem(tr, i)
		local take = reaper.GetMediaItemTake(item, 0) -- active take?
		local take_is_midi = reaper.TakeIsMIDI(take)

		local t_item_data_obj = {}

    if get_ref then
      -- TODO: ...
    end

		-- COLLECT ITEM INFO

		if no_filters or info_filter then
			log.user("GETTING: item info data")
			-- t_item_data_obj.midi_data = require("library.midi").get_midi_data_from_take(take, {
			-- 	filter = data_filter and data_filter.midi,
			-- })
			t_item_data_obj.item_info = lib_items.get_item_info(item)
			t_item_data_obj.take_info = lib_items.get_take_info(take)
		end

		-- COLLECT ITEM DATA

		if no_filters or midi_and_audio or data_filter.midi and take_is_midi then
			log.user("GETTING item midi data")
			-- get_midi_data_from_take should be moved into items since it is dealing
			-- with items/takes first hand, and not midi. >>> it is an item_util!!
			t_item_data_obj.midi_data = require("library.midi").get_midi_data_from_take(take, {
				filter = data_filter and data_filter.midi,
			})
		end

		if no_filters or midi_and_audio or data_filter.audio and not take_is_midi then
			log.user("GETTING item audio data")
			-- t_item_data_obj.audio_data = require("library.items").get_audio_data_from_take(take, {
			-- 	filter = data_filter and data_filter.audio,
			-- })
		end

		table.insert(t_return_all_item_objs, t_item_data_obj)
	end

	return t_return_all_item_objs
end

-- NOTE: reaper.GetTakeName( take )
--
-- returns NULL if the take is not valid

-- NOTE: retval, stringNeedBig = reaper.GetSetMediaItemTakeInfo_String( tk, parmname, stringNeedBig, setNewValue )
--
-- Gets/sets a take attribute string:
-- P_NAME : char * : take name
-- P_EXT:xyz : char * : extension-specific persistent data
-- GUID : GUID * : 16-byte GUID, can query or update. If using a _String() function, GUID is a string {xyz-...}.

-- -- Get name of take
-- take_name = reaper.GetTakeName(reaper.GetActiveTake(reaper.GetSelectedMediaItem(0, i)))

-- new_take_name[i] = take_name .. "_" .. tostring(count)

-- -- Get active take
-- active_take = reaper.GetActiveTake(reaper.GetSelectedMediaItem(0, i))

-- -- Apply new name
-- reaper.GetSetMediaItemTakeInfo_String(active_take, 'P_NAME', new_take_name[i], true)

lib_items.get_item_info = function(item)
	if not item then
		log.debug("no item passed to get_item_info")
		return
	end

	local D_POSITION = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
	local D_LENGTH = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

	return {
		start = D_POSITION,
		_end = D_POSITION + D_LENGTH,
		-- B_MUTE : bool * : muted (item solo overrides). setting this value will clear C_MUTE_SOLO.
		-- B_MUTE_ACTUAL : bool * : muted (ignores solo). setting this value will not affect C_MUTE_SOLO.
		-- C_LANEPLAYS : char * : in fixed lane tracks, 0=this item lane does not play, 1=this item lane plays exclusively, 2=this item lane plays and other lanes also play (read-only)
		-- C_MUTE_SOLO : char * : solo override (-1=soloed, 0=no override, 1=unsoloed). note that this API does not automatically unsolo other items when soloing (nor clear the unsolos when clearing the last soloed item), it must be done by the caller via action or via this API.
		-- B_LOOPSRC : bool * : loop source
		-- B_ALLTAKESPLAY : bool * : all takes play
		-- B_UISEL : bool * : selected in arrange view
		-- C_BEATATTACHMODE : char * : item timebase, -1=track or project default, 1=beats (position, length, rate), 2=beats (position only). for auto-stretch timebase: C_BEATATTACHMODE=1, C_AUTOSTRETCH=1
		-- C_AUTOSTRETCH: : char * : auto-stretch at project tempo changes, 1=enabled, requires C_BEATATTACHMODE=1
		-- C_LOCK : char * : locked, &1=locked
		-- D_VOL : double * : item volume, 0=-inf, 0.5=-6dB, 1=+0dB, 2=+6dB, etc
		D_POSITION = D_POSITION, -- double * : item position in seconds
		D_LENGTH = D_LENGTH, -- double * : item length in seconds
		-- D_SNAPOFFSET : double * : item snap offset in seconds
		-- D_FADEINLEN : double * : item manual fadein length in seconds
		-- D_FADEOUTLEN : double * : item manual fadeout length in seconds
		-- D_FADEINDIR : double * : item fadein curvature, -1..1
		-- D_FADEOUTDIR : double * : item fadeout curvature, -1..1
		-- D_FADEINLEN_AUTO : double * : item auto-fadein length in seconds, -1=no auto-fadein
		-- D_FADEOUTLEN_AUTO : double * : item auto-fadeout length in seconds, -1=no auto-fadeout
		-- C_FADEINSHAPE : int * : fadein shape, 0..6, 0=linear
		-- C_FADEOUTSHAPE : int * : fadeout shape, 0..6, 0=linear
		-- I_GROUPID : int * : group ID, 0=no group
		-- I_LASTY : int * : Y-position (relative to top of track) in pixels (read-only)
		-- I_LASTH : int * : height in pixels (read-only)
		-- I_CUSTOMCOLOR : int * : custom color, OS dependent color|0x1000000 (i.e. ColorToNative(r,g,b)|0x1000000). If you do not |0x1000000, then it will not be used, but will store the color
		-- I_CURTAKE : int * : active take number
		-- IP_ITEMNUMBER : int : item number on this track (read-only, returns the item number directly)
		-- F_FREEMODE_Y : float * : free item positioning or fixed lane Y-position. 0=top of track, 1.0=bottom of track
		-- F_FREEMODE_H : float * : free item positioning or fixed lane height. 0.5=half the track height, 1.0=full track height
		-- I_FIXEDLANE : int * : fixed lane of item (fine to call with setNewValue, but returned value is read-only)
		-- B_FIXEDLANE_HIDDEN : bool * : true if displaying only one fixed lane and this item is in a different lane (read-only)
		-- P_TRACK : MediaTrack * : (read-only)
	}
end

-- only data / no ref
lib_items.get_take_info = function(take)
	return {
		-- reaper.GetMediaItemTakeInfo_Value( take, parmname )
		--
		-- Get media item take numerical-value attributes.
		-- D_STARTOFFS : double * : start offset in source media, in seconds
		-- D_VOL : double * : take volume, 0=-inf, 0.5=-6dB, 1=+0dB, 2=+6dB, etc, negative if take polarity is flipped
		-- D_PAN : double * : take pan, -1..1
		-- D_PANLAW : double * : take pan law, -1=default, 0.5=-6dB, 1.0=+0dB, etc
		-- D_PLAYRATE : double * : take playback rate, 0.5=half speed, 1=normal, 2=double speed, etc
		-- D_PITCH : double * : take pitch adjustment in semitones, -12=one octave down, 0=normal, +12=one octave up, etc
		-- B_PPITCH : bool * : preserve pitch when changing playback rate
		-- I_LASTY : int * : Y-position (relative to top of track) in pixels (read-only)
		-- I_LASTH : int * : height in pixels (read-only)
		-- I_CHANMODE : int * : channel mode, 0=normal, 1=reverse stereo, 2=downmix, 3=left, 4=right
		-- I_PITCHMODE : int * : pitch shifter mode, -1=projext default, otherwise high 2 bytes=shifter, low 2 bytes=parameter
		-- I_CUSTOMCOLOR : int * : custom color, OS dependent color|0x1000000 (i.e. ColorToNative(r,g,b)|0x1000000). If you do not |0x1000000, then it will not be used, but will store the color
		-- IP_TAKENUMBER : int : take number (read-only, returns the take number directly)
		-- P_TRACK : pointer to MediaTrack (read-only)
		-- P_ITEM : pointer to MediaItem (read-only)
		-- P_SOURCE : PCM_source *. Note that if setting this, you should first retrieve the old source, set the new, THEN delete the old.
	}
end

-- get_track_items_in_range_time
lib_items.get_track_items_in_range_time_w_data = function(track, range_start, range_end)
	local item_cnt = reaper.GetTrackNumMediaItems(track)
	local items_found = {}
	for i = 0, item_cnt - 1 do
		local item_ref = reaper.GetTrackMediaItem(track, i)
		local item_info = lib_items.get_item_info(item)
		if item_info.start >= range_start and item_info._end <= range_end then
			table.insert(items_found, {
			  ref = item_ref,
			  info = item_info
			})
		end
	end
	return #items_found > 0 and items_found or false
end

lib_items.unselect_items = function(t_indices)
	if not t_indices then
		local csi = reaper.CountSelectedMediaItems(0)
		if csi > 0 then
			for i = 0, csi - 1 do
				local item = reaper.GetSelectedMediaItem(0, i)
				log.user(">>>>>>>>", type(item), item)
				reaper.SetMediaItemSelected(reaper.GetSelectedMediaItem(0, i), false)
			end
		end
	else
		-- TODO:...
		-- for k, v in pairs(t) do
		--
		-- end
	end
end

------------------------------------------------------------------------------

function toBits(num) -- returns a table of bits, least significant first.
	local t = {}
	while num > 0 do
		rest = math.fmod(num, 2)
		t[#t + 1] = math.floor(rest)
		num = (num - rest) / 2
	end
	return t
end

function IsSelectionLinkEdit() -- return bol
	link = toBits(reaper.SNM_GetIntConfigVar("midieditor", 5))[10] -- Is Selection is linked to editability On? 0 Yes 1 No.
	if link == 0 then
		link = true
	elseif link == 1 then
		link = false
	end
	return link
end

-- https://forum.cockos.com/showthread.php?p=2431991#post2431991
function GetEditableMIDITakes(link) --  bool link - Is Selection linked to editability? //Return a take_table with the takes editable in piano roll
	take_table = {}
	if link == true then -- Selection is linked to editability
		local item_count = reaper.CountSelectedMediaItems(0)
		if item_count > 0 then -- If at least one item is MIDI
			for i = 0, item_count - 1 do
				local loop_item = reaper.GetSelectedMediaItem(0, i)
				local loop_take = reaper.GetMediaItemTake(loop_item, 0)
				local bol = reaper.TakeIsMIDI(loop_take)
				if bol == true then
					table.insert(take_table, loop_take)
				end
			end
		end
		if item_count == 0 or #take_table == 0 then -- No selected Item or None was added to a table(none is MIDI)
			local midieditor = reaper.MIDIEditor_GetActive()
			local take = reaper.MIDIEditor_GetTake(midieditor)
			table.insert(take_table, take)
		end
		print(#take_table)
	elseif link == false then -- Selection is NOT linked to editability
		local midieditor = reaper.MIDIEditor_GetActive()
		local take = reaper.MIDIEditor_GetTake(midieditor)
		table.insert(take_table, take)
	end
	return take_table
end

------------------------------------------------------------------------------

-- https://forum.cockos.com/showthread.php?p=2731870#post2731870

-- function MIDIEditor_GetVisibleTakes(hwnd)
-- 	local editor_take = reaper.MIDIEditor_GetTake(hwnd)
-- 	if not reaper.ValidatePtr(editor_take, "MediaItem_Take*") then
-- 		return
-- 	end
-- 	-- Cycle through visible MIDI items until the first one is reached
-- 	local vis_takes = { editor_take }
-- 	-- Activate next visible MIDI item
-- 	reaper.MIDIEditor_OnCommand(hwnd, 40500)
-- 	local active_take = reaper.MIDIEditor_GetTake(hwnd)
-- 	while active_take ~= editor_take do
-- 		vis_takes[#vis_takes + 1] = active_take
-- 		-- Activate next visible MIDI item
-- 		reaper.MIDIEditor_OnCommand(hwnd, 40500)
-- 		active_take = reaper.MIDIEditor_GetTake(hwnd)
-- 	end
-- 	return vis_takes
-- end

-- -- https://forum.cockos.com/showpost.php?p=2449694&postcount=51
-- function MIDIEditor_GetVisibleItems(hwnd)
-- 	local editor_take = reaper.MIDIEditor_GetTake(hwnd)
-- 	if not reaper.ValidatePtr(editor_take, "MediaItem_Take*") then
-- 		return
-- 	end
--
-- 	reaper.PreventUIRefresh(1)
-- 	-- Save current item selection
-- 	local sel_items = {}
-- 	for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
-- 		sel_items[#sel_items + 1] = reaper.GetSelectedMediaItem(0, i)
-- 	end
--
-- 	-- Get current MIDI editor settings
-- 	local config = reaper.SNM_GetIntConfigVar("midieditor", 0)
--
-- 	local editor_type = config % 4
-- 	local behavior_type = config & 20
-- 	local editability = config & 512
-- 	local visibility = config & 1024
--
-- 	local new_config = config
-- 	-- Set 'One MIDI Editor per project'
-- 	new_config = new_config - editor_type + 1
-- 	-- Set behavior for opening MIDI items to 'Open all selected MIDI items'
-- 	new_config = new_config - behavior_type
-- 	-- Disable 'Selection is linked to visibility'
-- 	new_config = new_config - editability
-- 	-- Enable 'Selection is linked to visibility'
-- 	new_config = new_config - visibility
-- 	reaper.SNM_SetIntConfigVar("midieditor", new_config)
--
-- 	-- Set current editor item to be the only selected item
-- 	reaper.SelectAllMediaItems(0, false)
-- 	local editor_item = reaper.GetMediaItemTake_Item(editor_take)
-- 	reaper.SetMediaItemSelected(editor_item, true)
--
-- 	-- Cmd: Open in built-in MIDI editor
-- 	reaper.Main_OnCommand(40153, 0)
--
-- 	-- Save current item selection
-- 	local vis_items = {}
-- 	for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
-- 		vis_items[#vis_items + 1] = reaper.GetSelectedMediaItem(0, i)
-- 	end
--
-- 	reaper.SNM_SetIntConfigVar("midieditor", config)
--
-- 	-- Restore previous item selection
-- 	reaper.SelectAllMediaItems(0, false)
-- 	for _, item in ipairs(sel_items) do
-- 		reaper.SetMediaItemSelected(item, true)
-- 	end
--
-- 	reaper.PreventUIRefresh(-1)
-- 	return vis_items
-- end
--

-- function MIDIEditor_GetEditableItems(hwnd)
-- 	local editor_take = reaper.MIDIEditor_GetTake(hwnd)
-- 	if not reaper.ValidatePtr(editor_take, "MediaItem_Take*") then
-- 		return
-- 	end
--
-- 	reaper.PreventUIRefresh(1)
-- 	-- Save current item selection
-- 	local sel_items = {}
-- 	for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
-- 		sel_items[#sel_items + 1] = reaper.GetSelectedMediaItem(0, i)
-- 	end
--
-- 	-- Get MIDI editor settings
-- 	local config = reaper.SNM_GetIntConfigVar("midieditor", 0)
--
-- 	local editor_type = config % 4
-- 	local behavior_type = config & 20
-- 	local editability = config & 512
-- 	local visibility = config & 1024
--
-- 	-- Change MIDI editor settings
-- 	local new_config = config
-- 	-- Set 'One MIDI Editor per project'
-- 	new_config = new_config - editor_type + 1
-- 	-- Set behavior for opening MIDI items to 'Open all selected MIDI items'
-- 	new_config = new_config - behavior_type
-- 	-- Enable 'Selection is linked to editability'
-- 	new_config = new_config - editability
-- 	-- Disable 'Selection is linked to visibility'
-- 	new_config = new_config - visibility + 1024
-- 	reaper.SNM_SetIntConfigVar("midieditor", new_config)
--
-- 	-- Set current editor item to be the only selected item
-- 	reaper.SelectAllMediaItems(0, false)
-- 	local editor_item = reaper.GetMediaItemTake_Item(editor_take)
-- 	reaper.SetMediaItemSelected(editor_item, true)
--
-- 	-- Cmd: Open in built-in MIDI editor
-- 	reaper.Main_OnCommand(40153, 0)
--
-- 	-- Save current item selection
-- 	local vis_items = {}
-- 	for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
-- 		vis_items[#vis_items + 1] = reaper.GetSelectedMediaItem(0, i)
-- 	end
--
-- 	reaper.SNM_SetIntConfigVar("midieditor", config)
--
-- 	-- Restore previous item selection
-- 	reaper.SelectAllMediaItems(0, false)
-- 	for _, item in ipairs(sel_items) do
-- 		reaper.SetMediaItemSelected(item, true)
-- 	end
--
-- 	reaper.PreventUIRefresh(-1)
-- 	return vis_items
-- end
--
--- FTC item/midi helpers

lib_items.create_new_item = function(is_midi, tr, start, _end, new_name)
	local new_item
	if is_midi then
		new_item = reaper.CreateNewMIDIItemInProj(tr, start, _end, false)
	else
		new_item = reaper.AddMediaItemToTrack(tr)
		local length = _end - start
		reaper.SetMediaItemInfo_Value(new_item, "D_POSITION", start)
		reaper.SetMediaItemInfo_Value(new_item, "D_LENGTH", length)
	end
	lib_items.rename_item(new_item, new_name)
	return new_item
end

lib_items.rename_item = function(new_item, new_name)
	new_name = new_name or "[no name]"
	local take = reaper.GetActiveTake(new_item)
	reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", new_name, true)
end

lib_items.getItemSelection = function()
	local items = {}
	for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
		items[#items + 1] = reaper.GetSelectedMediaItem(0, i)
	end
	return items
end

-- unselect_items() is better because it allows you to also pass a list if
-- indices which can be used to fine tune affected items.
lib_items.unselectAllMediaItems = function()
	-- reaper.SelectAllMediaItems(0, false) -- NOTE: why not just use this?!
	for i = reaper.CountSelectedMediaItems(0) - 1, 0, -1 do
		local item = reaper.GetSelectedMediaItem(0, i)
		reaper.SetMediaItemSelected(item, false)
	end
end

lib_items.setItemSelection = function(items)
	lib_items.unselectAllMediaItems()
	if type(items) == "userdata" then
		reaper.SetMediaItemSelected(items, true)
	elseif type(items) == "table" then
		for _, item in ipairs(items) do
			reaper.SetMediaItemSelected(item, true)
		end
	end
end

lib_items.setSelectionStateOfItems = function(items, state)
	for _, item in ipairs(items) do
		reaper.SetMediaItemSelected(item, state)
	end
end

lib_items.addItemsToSelection = function(items) end

lib_items.getTakeChunk = function(take)
	local item = reaper.GetMediaItemTake_Item(take)
	local _, chunk = reaper.GetItemStateChunk(item, "", false)
	local tk = reaper.GetMediaItemTakeInfo_Value(take, "IP_TAKENUMBER")

	local take_start_ptr = 0
	local take_end_ptr = 0

	for _ = 0, tk do
		take_start_ptr = take_end_ptr
		take_end_ptr = chunk:find("\nTAKE[%s\n]", take_start_ptr + 1)
	end
	return chunk:sub(take_start_ptr, take_end_ptr)
end

lib_items.getTakeChunkHZoom = function(chunk)
	local pattern = "CFGEDITVIEW (.-) (.-) "
	return chunk:match(pattern)
end

lib_items.getTakeChunkTimeBase = function(chunk)
	local pattern = "CFGEDIT " .. (".- "):rep(18) .. "(.-) "
	return tonumber(chunk:match(pattern))
end

lib_items.isValidMIDIItem = function(item)
	if reaper.ValidatePtr(item, "MediaItem*") then
		local active_take = reaper.GetActiveTake(item)
		return reaper.TakeIsMIDI(active_take)
	end
end

lib_items.get_dimensions = function(itm)
	local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
	local item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
	local item_end = item_start + item_length

	return {
		start = item_start,
		_end = item_end,
		length = item_length,
	}
end

-- function GetMIDIEditorView(hwnd)
-- 	local take = reaper.MIDIEditor_GetTake(hwnd)
-- 	if not reaper.ValidatePtr(take, "MediaItem_Take*") then
-- 		return
-- 	end
--
-- 	local GetProjTimeFromPPQ = reaper.MIDI_GetProjTimeFromPPQPos
--
-- 	local chunk = GetTakeChunk(take)
-- 	local start_ppq, hzoom_lvl = GetTakeChunkHZoom(chunk)
-- 	if not start_ppq then
-- 		return
-- 	end
--
-- 	local timebase = GetTakeChunkTimeBase(chunk) or 0
-- 	-- 0 = Beats (proj) 1 = Project synced 2 = Time (proj) 4 = Beats (source)
--
-- 	local end_ppq
-- 	local start_pos, end_pos
--
-- 	if reaper.JS_Window_FindChildByID then
-- 		local midiview = reaper.JS_Window_FindChildByID(hwnd, 0x3E9)
-- 		local _, width_in_pixels = reaper.JS_Window_GetClientSize(midiview)
--
-- 		if timebase == 0 or timebase == 4 then
-- 			-- For timebase 0 and 4, hzoom_lvl is in pixel/ppq
-- 			end_ppq = start_ppq + width_in_pixels / hzoom_lvl
-- 		else
-- 			-- For timebase 1 and 2, hzoom_lvl is in pixel/time
-- 			start_pos = GetProjTimeFromPPQ(take, start_ppq)
-- 			end_pos = start_pos + width_in_pixels / hzoom_lvl
-- 		end
-- 	else
-- 		if timebase == 1 then
-- 			-- Timebase: Toggle sync to arrange view
-- 			reaper.MIDIEditor_OnCommand(hwnd, 40640)
-- 		end
--
-- 		-- Cmd: Scroll view right
-- 		reaper.MIDIEditor_OnCommand(hwnd, 40141)
--
-- 		-- To determine the length of the editor we scroll right once.
-- 		-- The updated ppq position in the take chunk gives us the ppq position
-- 		-- at the right edge (end) of the MIDI editor window.
-- 		chunk = GetTakeChunk(take)
-- 		end_ppq = GetTakeChunkHZoom(chunk)
--
-- 		-- Cmd: Scroll view left
-- 		reaper.MIDIEditor_OnCommand(hwnd, 40140)
--
-- 		if timebase == 1 then
-- 			-- Timebase: Toggle sync to arrange view
-- 			reaper.MIDIEditor_OnCommand(hwnd, 40640)
-- 		end
-- 	end
--
-- 	-- Convert ppq to time based units
-- 	start_pos = start_pos or GetProjTimeFromPPQ(take, start_ppq)
-- 	end_pos = end_pos or GetProjTimeFromPPQ(take, end_ppq)
--
-- 	if timebase == 0 or timebase == 4 then
-- 		-- Convert hzoom_lvl from pixel/ppq to pixel/time
-- 		local width_in_pixels = (end_ppq - start_ppq) * hzoom_lvl
-- 		hzoom_lvl = width_in_pixels / (end_pos - start_pos)
-- 	end
--
-- 	return start_pos, end_pos, hzoom_lvl
-- end

-- function GetEditorHorizontalZoomState(hwnd)
-- 	local start_pos, end_pos = GetMIDIEditorView(hwnd)
-- 	-- A factor is necessary to convert to the size of the selection used for the action
-- 	-- "Zoom to project loop selection" which is smaller than the actual visible length
-- 	local factor = 0.943396226415
-- 	local length = end_pos - start_pos
-- 	local center = start_pos + length / 2
-- 	return { length = length * factor, center = center }
-- end

-- function RestoreHorizontalZoomState(hwnd, state)
-- 	local sel_start_pos, sel_end_pos = GetTimeSelection()
-- 	local zoom_start_pos = state.center - state.length / 2
-- 	local zoom_end_pos = state.center + state.length / 2
-- 	if zoom_start_pos < 0 then
-- 		zoom_start_pos = 0
-- 		zoom_end_pos = state.length
-- 	end
-- 	SetTimeSelection(zoom_start_pos, zoom_end_pos)
-- 	-- Cmd: Zoom to project loop selection
-- 	reaper.MIDIEditor_OnCommand(hwnd, 40726)
--
-- 	-- Reset previous time selection
-- 	SetTimeSelection(sel_start_pos, sel_end_pos)
--
-- 	if zoom_start_pos == 0 then
-- 		-- Project selection can't be set below zero, therefore zoom in/out once
-- 		local zoom_mode = reaper.SNM_GetIntConfigVar("zoommode", 0)
-- 		local cursor_pos = reaper.GetCursorPosition()
-- 		reaper.SetEditCurPos(state.center, false, false)
-- 		-- Set horizontal zoom mode to 'Edit cursor or play cursor (default)'
-- 		reaper.SNM_SetIntConfigVar("zoommode", 0)
-- 		-- Cmd: Zoom in vertically
-- 		reaper.MIDIEditor_OnCommand(hwnd, 1012)
-- 		-- Cmd: Zoom out vertically
-- 		reaper.MIDIEditor_OnCommand(hwnd, 1011)
-- 		reaper.SNM_SetIntConfigVar("zoommode", zoom_mode)
-- 		reaper.SetEditCurPos(cursor_pos, false, false)
-- 	end
-- end

-- function ChangeConfigForSelectionExploit(config, get_editable)
-- 	local editor_type = config % 4
-- 	local behavior_type = config & 20
-- 	local active_item_follows_selection = config & 128
-- 	local other_tracks_editable = config & 256
-- 	local editability = config & 512
-- 	local visibility = config & 1024
--
-- 	local new_config = config
-- 	-- Set 'One MIDI Editor per project'
-- 	new_config = new_config - editor_type + 1
-- 	-- Set behavior for opening MIDI items to 'Open all selected MIDI items'
-- 	new_config = new_config - behavior_type
-- 	-- Diable 'Active MIDI item follows selection changes in arrange view'
-- 	new_config = new_config - active_item_follows_selection + 128
-- 	-- Disable 'Avoid automatically setting items from other tracks editable'
-- 	new_config = new_config - other_tracks_editable + 256
--
-- 	if get_editable then
-- 		-- Enable 'Selection is linked to editability'
-- 		new_config = new_config - editability
-- 		-- Disable 'Selection is linked to visibility'
-- 		new_config = new_config - visibility + 1024
-- 	else
-- 		-- Disable 'Selection is linked to editability'
-- 		new_config = new_config - editability + 512
-- 		-- Enable 'Selection is linked to visibility'
-- 		new_config = new_config - visibility
-- 	end
-- 	return new_config
-- end

-- function CheckConfigForActiveLink(config, is_edit_state)
-- 	local editor_type = config % 4
-- 	local mask = is_edit_state and 512 or 1024
-- 	-- Check if selection is already linked to visibility/editability
-- 	return editor_type == 1 and config & mask == 0
-- end

-- function MIDIEditor_GetItemsByState(hwnd, is_edit_state)
-- 	-- get the take that is currently being edited in this MIDI editor. see MIDIEditor_EnumTakes
-- 	local editor_take = reaper.MIDIEditor_GetTake(hwnd)
--
-- 	-- Return true if the pointer is a valid object of the right type in proj
-- 	-- (proj is ignored if pointer is itself a project). Supported types are:
-- 	-- ReaProject*, MediaTrack*, MediaItem*, MediaItem_Take*, TrackEnvelope* and
-- 	-- PCM_source*.
-- 	if not reaper.ValidatePtr(editor_take, "MediaItem_Take*") then
-- 		return
-- 	end
--
-- 	-- Save current item selection
-- 	local sel_items = GetItemSelection()
--
-- 	-- Get current MIDI editor settings
-- 	local config = reaper.SNM_GetIntConfigVar("midieditor", 0)
-- 	if CheckConfigForActiveLink(config, is_edit_state) then
-- 		-- Return selected MIDI items when selection is already linked
-- 		local midi_items = {}
-- 		for _, item in ipairs(sel_items) do
-- 			if IsValidMIDIItem(item) then
-- 				midi_items[#midi_items + 1] = item
-- 			end
-- 		end
-- 		return midi_items
-- 	end
--
-- 	reaper.PreventUIRefresh(1)
-- 	local editor_item = reaper.GetMediaItemTake_Item(editor_take)
--
-- 	-- Save current horizontal zoom state
-- 	local hzoom_state = GetEditorHorizontalZoomState(hwnd)
-- 	local new_config = ChangeConfigForSelectionExploit(config, is_edit_state)
-- 	reaper.SNM_SetIntConfigVar("midieditor", new_config)
--
-- 	-- Set current editor item to be the only selected item
-- 	UnselectAllMediaItems()
-- 	reaper.SetMediaItemSelected(editor_item, true)
--
-- 	-- Cmd: Open in built-in MIDI editor
-- 	reaper.Main_OnCommand(40153, 0)
--
-- 	-- Selected items are visible/editable items
-- 	local ret_items = GetItemSelection()
--
-- 	-- Restore original ini configuration
-- 	reaper.SNM_SetIntConfigVar("midieditor", config)
--
-- 	SetItemSelection(sel_items)
-- 	RestoreHorizontalZoomState(hwnd, hzoom_state)
--
-- 	reaper.PreventUIRefresh(-1)
-- 	return ret_items
-- end

-- -- TODO pass table instead.
-- function MIDIEditor_SetItemsState(hwnd, is_edit_state, items, state)
-- 	local editor_take = reaper.MIDIEditor_GetTake(hwnd)
-- 	if not reaper.ValidatePtr(editor_take, "MediaItem_Take*") then
-- 		return
-- 	end
--
-- 	-- Get current MIDI editor settings
-- 	local config = reaper.SNM_GetIntConfigVar("midieditor", 0)
-- 	if CheckConfigForActiveLink(config, is_edit_state) then
-- 		-- Select / Unselect items to change their state
-- 		for _, item in ipairs(items) do
-- 			reaper.SetMediaItemSelected(item, state)
-- 		end
-- 		reaper.UpdateArrange()
-- 		return
-- 	end
--
-- 	-- Save current item selection
-- 	local sel_items = GetItemSelection()
--
-- 	reaper.PreventUIRefresh(1)
--
-- 	-- Save current horizontal zoom state
-- 	local hzoom_state = GetEditorHorizontalZoomState(hwnd)
-- 	local new_config = ChangeConfigForSelectionExploit(config, is_edit_state)
-- 	reaper.SNM_SetIntConfigVar("midieditor", new_config)
--
-- 	-- Set current editor item to be the only selected item
-- 	UnselectAllMediaItems()
-- 	local editor_item = reaper.GetMediaItemTake_Item(editor_take)
-- 	reaper.SetMediaItemSelected(editor_item, true)
--
-- 	-- Cmd: Open in built-in MIDI editor
-- 	reaper.Main_OnCommand(40153, 0)
--
-- 	-- Select / Unselect items to change their state
-- 	for _, item in ipairs(items) do
-- 		reaper.SetMediaItemSelected(item, state)
-- 	end
--
-- 	-- Options: Track list/media item lane follows selection changes in arrange view
-- 	reaper.MIDIEditor_OnCommand(hwnd, 40826)
-- 	-- We toggle this setting so that arrange selection is mirrored in MIDI editor
-- 	reaper.MIDIEditor_OnCommand(hwnd, 40826)
--
-- 	-- Restore original ini configuration
-- 	reaper.SNM_SetIntConfigVar("midieditor", config)
--
-- 	SetItemSelection(sel_items)
-- 	RestoreHorizontalZoomState(hwnd, hzoom_state)
--
-- 	reaper.PreventUIRefresh(-1)
-- end

-- local MIDIEditor_GetAllVisibleItems = function(hwnd)
-- 	local visible_items = MIDIEditor_GetItemsByState(hwnd, false)
-- 	return visible_items
-- end

-- -- move to lib/midi_editor
-- items.MIDIEditor_GetAllEditableItems = function(hwnd)
-- 	local editable_items = MIDIEditor_GetItemsByState(hwnd, true)
-- 	return editable_items
-- end

-- items.MIDIEditor_IsItemVisible = function(hwnd, item)
-- 	local visible_items = MIDIEditor_GetAllVisibleItems(hwnd)
-- 	if visible_items then
-- 		for _, visible_item in ipairs(visible_items) do
-- 			if item == visible_item then
-- 				return true
-- 			end
-- 		end
-- 	end
-- 	return false
-- end

-- items.MIDIEditor_IsItemEditable = function(hwnd, item)
-- 	local editable_items = MIDIEditor_GetAllEditableItems(hwnd)
-- 	if editable_items then
-- 		for _, editable_item in ipairs(editable_items) do
-- 			if item == editable_item then
-- 				return true
-- 			end
-- 		end
-- 	end
-- 	return false
-- end

-- items.MIDIEditor_SetItemsVisible = function(hwnd, items, is_visible)
-- 	if items then
-- 		for _, item in ipairs(items) do
-- 			if not IsValidMIDIItem(item) then
-- 				return
-- 			end
-- 		end
-- 		MIDIEditor_SetItemsState(hwnd, false, items, is_visible)
-- 	end
-- end
--
-- items.MIDIEditor_SetItemsEditable = function(hwnd, items, is_editable)
-- 	if items then
-- 		for _, item in ipairs(items) do
-- 			if not IsValidMIDIItem(item) then
-- 				return
-- 			end
-- 		end
-- 		MIDIEditor_SetItemsState(hwnd, true, items, is_editable)
-- 	end
-- end
--
-- items.MIDIEditor_SetItemVisible = function(hwnd, item, is_visible)
-- 	if IsValidMIDIItem(item) then
-- 		MIDIEditor_SetItemsState(hwnd, false, { item }, is_visible)
-- 	end
-- end
--
-- items.MIDIEditor_SetItemEditable = function(hwnd, item, is_editable)
-- 	if IsValidMIDIItem(item) then
-- 		MIDIEditor_SetItemsState(hwnd, true, { item }, is_editable)
-- 	end
-- end
--
--
-- items.MIDIEditor_SetActiveItem = function(hwnd, active_item)
-- 	-- Check if item is already active (prevent zoom)
-- 	local editor_take = reaper.MIDIEditor_GetTake(hwnd)
-- 	if reaper.ValidatePtr(editor_take, "MediaItem_Take*") then
-- 		local editor_item = reaper.GetMediaItemTake_Item(editor_take)
-- 		if editor_item == active_item then
-- 			return
-- 		end
-- 	end
--
-- 	if not IsValidMIDIItem(active_item) then
-- 		return
-- 	end
--
-- 	reaper.PreventUIRefresh(1)
--
-- 	-- Save current visibility/editability state
-- 	local visible_items = MIDIEditor_GetAllVisibleItems(hwnd)
-- 	local editable_items = MIDIEditor_GetAllEditableItems(hwnd)
--
-- 	-- Save current item selection
-- 	local sel_items = GetItemSelection()
--
-- 	-- Save current horizontal zoom state
-- 	local hzoom_state = GetEditorHorizontalZoomState(hwnd)
--
-- 	local config = reaper.SNM_GetIntConfigVar("midieditor", 0)
-- 	local new_config = ChangeConfigForSelectionExploit(config, is_edit_state)
-- 	reaper.SNM_SetIntConfigVar("midieditor", new_config)
--
-- 	-- Set current editor item to be the only selected item
-- 	UnselectAllMediaItems()
-- 	reaper.SetMediaItemSelected(active_item, true)
--
-- 	-- Cmd: Open in built-in MIDI editor
-- 	reaper.Main_OnCommand(40153, 0)
--
-- 	-- Restore original ini configuration
-- 	reaper.SNM_SetIntConfigVar("midieditor", config)
--
-- 	SetItemSelection(sel_items)
-- 	RestoreHorizontalZoomState(hwnd, hzoom_state)
--
-- 	-- Restore previous visibility/editability state
-- 	MIDIEditor_SetItemsVisible(hwnd, visible_items, true)
-- 	MIDIEditor_SetItemsEditable(hwnd, editable_items, true)
--
-- 	reaper.PreventUIRefresh(-1)
-- end

-- function RestoreHorizontalZoomState(hwnd, state)
-- 	local sel_start_pos, sel_end_pos = GetTimeSelection()
-- 	local zoom_start_pos = state.center - state.length / 2
-- 	local zoom_end_pos = state.center + state.length / 2
-- 	if zoom_start_pos < 0 then
-- 		zoom_start_pos = 0
-- 		zoom_end_pos = state.length
-- 	end
-- 	SetTimeSelection(zoom_start_pos, zoom_end_pos)
-- 	-- Cmd: Zoom to project loop selection
-- 	reaper.MIDIEditor_OnCommand(hwnd, 40726)
--
-- 	-- Reset previous time selection
-- 	SetTimeSelection(sel_start_pos, sel_end_pos)
--
-- 	if zoom_start_pos == 0 then
-- 		-- Project selection can't be set below zero, therefore zoom in/out once
-- 		local zoom_mode = reaper.SNM_GetIntConfigVar("zoommode", 0)
-- 		local cursor_pos = reaper.GetCursorPosition()
-- 		reaper.SetEditCurPos(state.center, false, false)
-- 		-- Set horizontal zoom mode to 'Edit cursor or play cursor (default)'
-- 		reaper.SNM_SetIntConfigVar("zoommode", 0)
-- 		-- Cmd: Zoom in vertically
-- 		reaper.MIDIEditor_OnCommand(hwnd, 1012)
-- 		-- Cmd: Zoom out vertically
-- 		reaper.MIDIEditor_OnCommand(hwnd, 1011)
-- 		reaper.SNM_SetIntConfigVar("zoommode", zoom_mode)
-- 		reaper.SetEditCurPos(cursor_pos, false, false)
-- 	end
-- end

-- TODO: repeat/loop items
--  1. repeat items COUNT times
--  2. repeat items COUNT times and glue
--  3. loop item count times
--  4. add N count item aliases after target item
--  #
--  default should be:
--  2x if no count is provided, ie. repeat/loop once.

lib_items.repeat_items = function()

	-- TODO: options
	--    - active in ME
	--    - selected items in arrange
	--    - glue items together
	--    - use [duplicating|looping|aliasing]

	-- NOTE: I will need to look into `lib/segments` to see how things are
	-- duplicated easilly
end

return lib_items
