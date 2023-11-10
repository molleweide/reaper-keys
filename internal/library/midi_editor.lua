local log = require("utils.log")
local format = require("utils.format")

--
-- MIDI EDITOR UTILS
--
-- I.e. library functions that take a midi editor (HWND) as first argument.
-- Returns some data/info about given midi editor window/view.

local function ChangeConfigForSelectionExploit(config, get_editable)
	local editor_type = config % 4
	local behavior_type = config & 20
	local active_item_follows_selection = config & 128
	local other_tracks_editable = config & 256
	local editability = config & 512
	local visibility = config & 1024

	local new_config = config
	-- Set 'One MIDI Editor per project'
	new_config = new_config - editor_type + 1
	-- Set behavior for opening MIDI items to 'Open all selected MIDI items'
	new_config = new_config - behavior_type
	-- Diable 'Active MIDI item follows selection changes in arrange view'
	new_config = new_config - active_item_follows_selection + 128
	-- Disable 'Avoid automatically setting items from other tracks editable'
	new_config = new_config - other_tracks_editable + 256

	if get_editable then
		-- Enable 'Selection is linked to editability'
		new_config = new_config - editability
		-- Disable 'Selection is linked to visibility'
		new_config = new_config - visibility + 1024
	else
		-- Disable 'Selection is linked to editability'
		new_config = new_config - editability + 512
		-- Enable 'Selection is linked to visibility'
		new_config = new_config - visibility
	end
	return new_config
end

function CheckConfigForActiveLink(config, is_edit_state)
	local editor_type = config % 4
	local mask = is_edit_state and 512 or 1024
	-- Check if selection is already linked to visibility/editability
	return editor_type == 1 and config & mask == 0
end

function RestoreHorizontalZoomState(hwnd, state)
	local sel_start_pos, sel_end_pos = GetTimeSelection()
	local zoom_start_pos = state.center - state.length / 2
	local zoom_end_pos = state.center + state.length / 2
	if zoom_start_pos < 0 then
		zoom_start_pos = 0
		zoom_end_pos = state.length
	end
	SetTimeSelection(zoom_start_pos, zoom_end_pos)
	-- Cmd: Zoom to project loop selection
	reaper.MIDIEditor_OnCommand(hwnd, 40726)

	-- Reset previous time selection
	SetTimeSelection(sel_start_pos, sel_end_pos)

	if zoom_start_pos == 0 then
		-- Project selection can't be set below zero, therefore zoom in/out once
		local zoom_mode = reaper.SNM_GetIntConfigVar("zoommode", 0)
		local cursor_pos = reaper.GetCursorPosition()
		reaper.SetEditCurPos(state.center, false, false)
		-- Set horizontal zoom mode to 'Edit cursor or play cursor (default)'
		reaper.SNM_SetIntConfigVar("zoommode", 0)
		-- Cmd: Zoom in vertically
		reaper.MIDIEditor_OnCommand(hwnd, 1012)
		-- Cmd: Zoom out vertically
		reaper.MIDIEditor_OnCommand(hwnd, 1011)
		reaper.SNM_SetIntConfigVar("zoommode", zoom_mode)
		reaper.SetEditCurPos(cursor_pos, false, false)
	end
end

local midi_editor = {}

-- Get settings from a MIDI editor. setting_desc can be:
-- snap_enabled: returns 0 or 1
-- active_note_row: returns 0-127
-- last_clicked_cc_lane: returns 0-127=CC, 0x100|(0-31)=14-bit CC, 0x200=velocity, 0x201=pitch, 0x202=program, 0x203=channel pressure, 0x204=bank/program select, 0x205=text, 0x206=sysex, 0x207=off velocity, 0x208=notation events, 0x210=media item lane
-- default_note_vel: returns 0-127
-- default_note_chan: returns 0-15
-- default_note_len: returns default length in MIDI ticks
-- scale_enabled: returns 0-1
-- scale_root: returns 0-12 (0=C)
-- list_cnt: if viewing list view, returns event count
-- if setting_desc is unsupported, the function returns -1.

-- midi_editor.get_note_row = function()
-- 	local me = reaper.MIDIEditor_GetActive()
-- 	local active_row = reaper.MIDIEditor_GetSetting_int(me, "active_note_row")
-- 	return active_row
-- end

midi_editor.GetVisibleTakes = function(hwnd)
	local editor_take = reaper.MIDIEditor_GetTake(hwnd)
	if not reaper.ValidatePtr(editor_take, "MediaItem_Take*") then
		return
	end
	-- Cycle through visible MIDI items until the first one is reached
	local vis_takes = { editor_take }
	-- Activate next visible MIDI item
	reaper.MIDIEditor_OnCommand(hwnd, 40500)
	local active_take = reaper.MIDIEditor_GetTake(hwnd)
	while active_take ~= editor_take do
		vis_takes[#vis_takes + 1] = active_take
		-- Activate next visible MIDI item
		reaper.MIDIEditor_OnCommand(hwnd, 40500)
		active_take = reaper.MIDIEditor_GetTake(hwnd)
	end
	return vis_takes
end

-- https://forum.cockos.com/showpost.php?p=2449694&postcount=51
midi_editor.GetVisibleItems = function(hwnd)
	local editor_take = reaper.MIDIEditor_GetTake(hwnd)
	if not reaper.ValidatePtr(editor_take, "MediaItem_Take*") then
		return
	end

	reaper.PreventUIRefresh(1)
	-- Save current item selection
	local sel_items = {}
	for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
		sel_items[#sel_items + 1] = reaper.GetSelectedMediaItem(0, i)
	end

	-- Get current MIDI editor settings
	local config = reaper.SNM_GetIntConfigVar("midieditor", 0)

	local editor_type = config % 4
	local behavior_type = config & 20
	local editability = config & 512
	local visibility = config & 1024

	local new_config = config
	-- Set 'One MIDI Editor per project'
	new_config = new_config - editor_type + 1
	-- Set behavior for opening MIDI items to 'Open all selected MIDI items'
	new_config = new_config - behavior_type
	-- Disable 'Selection is linked to visibility'
	new_config = new_config - editability
	-- Enable 'Selection is linked to visibility'
	new_config = new_config - visibility
	reaper.SNM_SetIntConfigVar("midieditor", new_config)

	-- Set current editor item to be the only selected item
	reaper.SelectAllMediaItems(0, false)
	local editor_item = reaper.GetMediaItemTake_Item(editor_take)
	reaper.SetMediaItemSelected(editor_item, true)

	-- Cmd: Open in built-in MIDI editor
	reaper.Main_OnCommand(40153, 0)

	-- Save current item selection
	local vis_items = {}
	for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
		vis_items[#vis_items + 1] = reaper.GetSelectedMediaItem(0, i)
	end

	reaper.SNM_SetIntConfigVar("midieditor", config)

	-- Restore previous item selection
	reaper.SelectAllMediaItems(0, false)
	for _, item in ipairs(sel_items) do
		reaper.SetMediaItemSelected(item, true)
	end

	reaper.PreventUIRefresh(-1)
	return vis_items
end

midi_editor.GetEditableItems = function(hwnd)
	local editor_take = reaper.MIDIEditor_GetTake(hwnd)
	if not reaper.ValidatePtr(editor_take, "MediaItem_Take*") then
		return
	end

	reaper.PreventUIRefresh(1)
	-- Save current item selection
	local sel_items = {}
	for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
		sel_items[#sel_items + 1] = reaper.GetSelectedMediaItem(0, i)
	end

	-- Get MIDI editor settings
	local config = reaper.SNM_GetIntConfigVar("midieditor", 0)

	local editor_type = config % 4
	local behavior_type = config & 20
	local editability = config & 512
	local visibility = config & 1024

	-- Change MIDI editor settings
	local new_config = config
	-- Set 'One MIDI Editor per project'
	new_config = new_config - editor_type + 1
	-- Set behavior for opening MIDI items to 'Open all selected MIDI items'
	new_config = new_config - behavior_type
	-- Enable 'Selection is linked to editability'
	new_config = new_config - editability
	-- Disable 'Selection is linked to visibility'
	new_config = new_config - visibility + 1024
	reaper.SNM_SetIntConfigVar("midieditor", new_config)

	-- Set current editor item to be the only selected item
	reaper.SelectAllMediaItems(0, false)
	local editor_item = reaper.GetMediaItemTake_Item(editor_take)
	reaper.SetMediaItemSelected(editor_item, true)

	-- Cmd: Open in built-in MIDI editor
	reaper.Main_OnCommand(40153, 0)

	-- Save current item selection
	local vis_items = {}
	for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
		vis_items[#vis_items + 1] = reaper.GetSelectedMediaItem(0, i)
	end

	reaper.SNM_SetIntConfigVar("midieditor", config)

	-- Restore previous item selection
	reaper.SelectAllMediaItems(0, false)
	for _, item in ipairs(sel_items) do
		reaper.SetMediaItemSelected(item, true)
	end

	reaper.PreventUIRefresh(-1)
	return vis_items
end

-- FIX: rename to `GetUIViewState` -> return table.
---
---@param hwnd userdata
---@return start_pos int, end_pos int, hzoom_lvl int
midi_editor.GetMIDIEditorView = function(hwnd)
	local take = reaper.MIDIEditor_GetTake(hwnd)
	if not reaper.ValidatePtr(take, "MediaItem_Take*") then
		return
	end

	local GetProjTimeFromPPQ = reaper.MIDI_GetProjTimeFromPPQPos

	local chunk = GetTakeChunk(take)
	local start_ppq, hzoom_lvl = GetTakeChunkHZoom(chunk)
	if not start_ppq then
		return
	end

	local timebase = GetTakeChunkTimeBase(chunk) or 0
	-- 0 = Beats (proj) 1 = Project synced 2 = Time (proj) 4 = Beats (source)

	local end_ppq
	local start_pos, end_pos

	if reaper.JS_Window_FindChildByID then
		local midiview = reaper.JS_Window_FindChildByID(hwnd, 0x3E9)
		local _, width_in_pixels = reaper.JS_Window_GetClientSize(midiview)

		if timebase == 0 or timebase == 4 then
			-- For timebase 0 and 4, hzoom_lvl is in pixel/ppq
			end_ppq = start_ppq + width_in_pixels / hzoom_lvl
		else
			-- For timebase 1 and 2, hzoom_lvl is in pixel/time
			start_pos = GetProjTimeFromPPQ(take, start_ppq)
			end_pos = start_pos + width_in_pixels / hzoom_lvl
		end
	else
		if timebase == 1 then
			-- Timebase: Toggle sync to arrange view
			reaper.MIDIEditor_OnCommand(hwnd, 40640)
		end

		-- Cmd: Scroll view right
		reaper.MIDIEditor_OnCommand(hwnd, 40141)

		-- To determine the length of the editor we scroll right once.
		-- The updated ppq position in the take chunk gives us the ppq position
		-- at the right edge (end) of the MIDI editor window.
		chunk = GetTakeChunk(take)
		end_ppq = GetTakeChunkHZoom(chunk)

		-- Cmd: Scroll view left
		reaper.MIDIEditor_OnCommand(hwnd, 40140)

		if timebase == 1 then
			-- Timebase: Toggle sync to arrange view
			reaper.MIDIEditor_OnCommand(hwnd, 40640)
		end
	end

	-- Convert ppq to time based units
	start_pos = start_pos or GetProjTimeFromPPQ(take, start_ppq)
	end_pos = end_pos or GetProjTimeFromPPQ(take, end_ppq)

	if timebase == 0 or timebase == 4 then
		-- Convert hzoom_lvl from pixel/ppq to pixel/time
		local width_in_pixels = (end_ppq - start_ppq) * hzoom_lvl
		hzoom_lvl = width_in_pixels / (end_pos - start_pos)
	end

	return start_pos, end_pos, hzoom_lvl
end

midi_editor.GetEditorHorizontalZoomState = function(hwnd)
	local start_pos, end_pos = GetMIDIEditorView(hwnd)
	-- A factor is necessary to convert to the size of the selection used for the action
	-- "Zoom to project loop selection" which is smaller than the actual visible length
	local factor = 0.943396226415
	local length = end_pos - start_pos
	local center = start_pos + length / 2
	return { length = length * factor, center = center }
end

midi_editor.MIDIEditor_GetItemsByState = function(hwnd, is_edit_state)
	-- get the take that is currently being edited in this MIDI editor. see MIDIEditor_EnumTakes
	local editor_take = reaper.MIDIEditor_GetTake(hwnd)

	-- Return true if the pointer is a valid object of the right type in proj
	-- (proj is ignored if pointer is itself a project). Supported types are:
	-- ReaProject*, MediaTrack*, MediaItem*, MediaItem_Take*, TrackEnvelope* and
	-- PCM_source*.
	if not reaper.ValidatePtr(editor_take, "MediaItem_Take*") then
		return
	end

	-- Save current item selection
	local sel_items = GetItemSelection()

	-- Get current MIDI editor settings
	local config = reaper.SNM_GetIntConfigVar("midieditor", 0)
	if CheckConfigForActiveLink(config, is_edit_state) then
		-- Return selected MIDI items when selection is already linked
		local midi_items = {}
		for _, item in ipairs(sel_items) do
			if IsValidMIDIItem(item) then
				midi_items[#midi_items + 1] = item
			end
		end
		return midi_items
	end

	reaper.PreventUIRefresh(1)
	local editor_item = reaper.GetMediaItemTake_Item(editor_take)

	-- Save current horizontal zoom state
	local hzoom_state = GetEditorHorizontalZoomState(hwnd)
	local new_config = ChangeConfigForSelectionExploit(config, is_edit_state)
	reaper.SNM_SetIntConfigVar("midieditor", new_config)

	-- Set current editor item to be the only selected item
	UnselectAllMediaItems()
	reaper.SetMediaItemSelected(editor_item, true)

	-- Cmd: Open in built-in MIDI editor
	reaper.Main_OnCommand(40153, 0)

	-- Selected items are visible/editable items
	local ret_items = GetItemSelection()

	-- Restore original ini configuration
	reaper.SNM_SetIntConfigVar("midieditor", config)

	SetItemSelection(sel_items)
	RestoreHorizontalZoomState(hwnd, hzoom_state)

	reaper.PreventUIRefresh(-1)
	return ret_items
end

-- TODO pass table instead.
midi_editor.MIDIEditor_SetItemsState = function(hwnd, is_edit_state, items, state)
	local editor_take = reaper.MIDIEditor_GetTake(hwnd)
	if not reaper.ValidatePtr(editor_take, "MediaItem_Take*") then
		return
	end

	-- Get current MIDI editor settings
	local config = reaper.SNM_GetIntConfigVar("midieditor", 0)
	if CheckConfigForActiveLink(config, is_edit_state) then
		-- Select / Unselect items to change their state
		for _, item in ipairs(items) do
			reaper.SetMediaItemSelected(item, state)
		end
		reaper.UpdateArrange()
		return
	end

	-- Save current item selection
	local sel_items = GetItemSelection()

	reaper.PreventUIRefresh(1)

	-- Save current horizontal zoom state
	local hzoom_state = GetEditorHorizontalZoomState(hwnd)
	local new_config = ChangeConfigForSelectionExploit(config, is_edit_state)
	reaper.SNM_SetIntConfigVar("midieditor", new_config)

	-- Set current editor item to be the only selected item
	UnselectAllMediaItems()
	local editor_item = reaper.GetMediaItemTake_Item(editor_take)
	reaper.SetMediaItemSelected(editor_item, true)

	-- Cmd: Open in built-in MIDI editor
	reaper.Main_OnCommand(40153, 0)

	-- Select / Unselect items to change their state
	for _, item in ipairs(items) do
		reaper.SetMediaItemSelected(item, state)
	end

	-- Options: Track list/media item lane follows selection changes in arrange view
	reaper.MIDIEditor_OnCommand(hwnd, 40826)
	-- We toggle this setting so that arrange selection is mirrored in MIDI editor
	reaper.MIDIEditor_OnCommand(hwnd, 40826)

	-- Restore original ini configuration
	reaper.SNM_SetIntConfigVar("midieditor", config)

	SetItemSelection(sel_items)
	RestoreHorizontalZoomState(hwnd, hzoom_state)

	reaper.PreventUIRefresh(-1)
end

midi_editor.MIDIEditor_GetAllVisibleItems = function(hwnd)
	local visible_items = MIDIEditor_GetItemsByState(hwnd, false)
	return visible_items
end

midi_editor.MIDIEditor_GetAllEditableItems = function(hwnd)
	local editable_items = MIDIEditor_GetItemsByState(hwnd, true)
	return editable_items
end

midi_editor.MIDIEditor_IsItemVisible = function(hwnd, item)
	local visible_items = MIDIEditor_GetAllVisibleItems(hwnd)
	if visible_items then
		for _, visible_item in ipairs(visible_items) do
			if item == visible_item then
				return true
			end
		end
	end
	return false
end

midi_editor.MIDIEditor_IsItemEditable = function(hwnd, item)
	local editable_items = MIDIEditor_GetAllEditableItems(hwnd)
	if editable_items then
		for _, editable_item in ipairs(editable_items) do
			if item == editable_item then
				return true
			end
		end
	end
	return false
end

midi_editor.MIDIEditor_SetItemsVisible = function(hwnd, items, is_visible)
	if items then
		for _, item in ipairs(items) do
			if not IsValidMIDIItem(item) then
				return
			end
		end
		MIDIEditor_SetItemsState(hwnd, false, items, is_visible)
	end
end

midi_editor.MIDIEditor_SetItemsEditable = function(hwnd, items, is_editable)
	if items then
		for _, item in ipairs(items) do
			if not IsValidMIDIItem(item) then
				return
			end
		end
		MIDIEditor_SetItemsState(hwnd, true, items, is_editable)
	end
end

midi_editor.MIDIEditor_SetItemVisible = function(hwnd, item, is_visible)
	if IsValidMIDIItem(item) then
		MIDIEditor_SetItemsState(hwnd, false, { item }, is_visible)
	end
end

midi_editor.MIDIEditor_SetItemEditable = function(hwnd, item, is_editable)
	if IsValidMIDIItem(item) then
		MIDIEditor_SetItemsState(hwnd, true, { item }, is_editable)
	end
end

midi_editor.MIDIEditor_SetActiveItem = function(hwnd, active_item)
	-- Check if item is already active (prevent zoom)
	local editor_take = reaper.MIDIEditor_GetTake(hwnd)
	if reaper.ValidatePtr(editor_take, "MediaItem_Take*") then
		local editor_item = reaper.GetMediaItemTake_Item(editor_take)
		if editor_item == active_item then
			return
		end
	end

	if not IsValidMIDIItem(active_item) then
		return
	end

	reaper.PreventUIRefresh(1)

	-- Save current visibility/editability state
	local visible_items = MIDIEditor_GetAllVisibleItems(hwnd)
	local editable_items = MIDIEditor_GetAllEditableItems(hwnd)

	-- Save current item selection
	local sel_items = GetItemSelection()

	-- Save current horizontal zoom state
	local hzoom_state = GetEditorHorizontalZoomState(hwnd)

	local config = reaper.SNM_GetIntConfigVar("midieditor", 0)
	local new_config = ChangeConfigForSelectionExploit(config, is_edit_state)
	reaper.SNM_SetIntConfigVar("midieditor", new_config)

	-- Set current editor item to be the only selected item
	UnselectAllMediaItems()
	reaper.SetMediaItemSelected(active_item, true)

	-- Cmd: Open in built-in MIDI editor
	reaper.Main_OnCommand(40153, 0)

	-- Restore original ini configuration
	reaper.SNM_SetIntConfigVar("midieditor", config)

	SetItemSelection(sel_items)
	RestoreHorizontalZoomState(hwnd, hzoom_state)

	-- Restore previous visibility/editability state
	MIDIEditor_SetItemsVisible(hwnd, visible_items, true)
	MIDIEditor_SetItemsEditable(hwnd, editable_items, true)

	reaper.PreventUIRefresh(-1)
end

return midi_editor
