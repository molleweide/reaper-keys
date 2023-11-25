local log = require("utils.log")
local format = require("utils.format")
local containers = require("library.items")
local tl = require("library.timeline")

--
-- MIDI EDITOR UTILS
--
-- I.e. library functions that take a midi editor (HWND) as first argument.
-- Returns some data/info about given midi editor window/view.

-- TODO: there is a lot of redundancy in this file that can be refactored

-- TODO: which functions could be simplified with new reaper mide editor apis,
-- eg. enum_takes

local midi_editor = {}

midi_editor.setConfig = function(new_config)
  reaper.SNM_SetIntConfigVar("midieditor", new_config)
end

-- Get current MIDI editor settings
midi_editor.getConfigTable = function(config)
  config = config or reaper.SNM_GetIntConfigVar("midieditor", 0)
  return {
    raw = config,
    editor_type = config % 4,
    behavior_type = config & 20,
    active_item_follows_selection = config & 128,
    other_tracks_editable = config & 256,
    editability = config & 512,
    visibility = config & 1024,
  }
end

midi_editor.makeTempConfig = function() end

local function changeConfigForSelectionExploit(t_config, get_editable)
  local new_config = t_config.raw
  -- Set 'One MIDI Editor per project'
  new_config = new_config - t_config.editor_type + 1
  -- Set behavior for opening MIDI items to 'Open all selected MIDI items'
  new_config = new_config - t_config.behavior_type
  -- Diable 'Active MIDI item follows selection changes in arrange view'
  new_config = new_config - t_config.active_item_follows_selection + 128
  -- Disable 'Avoid automatically setting items from other tracks editable'
  new_config = new_config - t_config.other_tracks_editable + 256

  if get_editable then
    -- Enable 'Selection is linked to editability'
    new_config = new_config - t_config.editability
    -- Disable 'Selection is linked to visibility'
    new_config = new_config - t_config.visibility + 1024
  else
    -- Disable 'Selection is linked to editability'
    new_config = new_config - t_config.editability + 512
    -- Enable 'Selection is linked to visibility'
    new_config = new_config - t_config.visibility
  end
  return new_config
end

local function checkConfigForActiveLink(t_config, is_edit_state)
  -- local editor_type = config % 4
  local mask = is_edit_state and 512 or 1024
  -- Check if selection is already linked to visibility/editability
  return t_config.editor_type == 1 and t_config.raw & mask == 0
end

midi_editor.restoreHorizontalZoomState = function(hwnd, state)
  local sel_start_pos, sel_end_pos = tl.getTimeSelection()
  local zoom_start_pos = state.center - state.length / 2
  local zoom_end_pos = state.center + state.length / 2
  if zoom_start_pos < 0 then
    zoom_start_pos = 0
    zoom_end_pos = state.length
  end
  tl.setTimeSelection(zoom_start_pos, zoom_end_pos) -- tmp

  midi_editor.zoomToProjectLoopSelection(hwnd)

  tl.setTimeSelection(sel_start_pos, sel_end_pos) -- reset

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

--- Gets the midi context for HWND or current/active midi editor.
--
---@return boolean retval, table data
midi_editor.getMidiValidContext = function(hwnd)
  local ME = hwnd or reaper.MIDIEditor_GetActive()
  local take = reaper.MIDIEditor_GetTake(ME)
  local editor_item = take and reaper.GetMediaItemTake_Item(take) or nil

  local retval = true
  if not ME or (not take or not reaper.TakeIsMIDI(take)) or not reaper.ValidatePtr(take, "MediaItem_Take*") then
    retval = false
  end

  local mretval, notecnt, ccevtcnt, textsysevtcnt
  if take then
    mretval, notecnt, ccevtcnt, textsysevtcnt = reaper.MIDI_CountEvts(take)
  end

  return retval,
      {
        editor = ME,
        take = take,
        item = editor_item,
        events = take and { mretval, notecnt, ccevtcnt, textsysevtcnt } or nil,
        note_row = reaper.MIDIEditor_GetSetting_int(ME, "active_note_row"),
        cursor_pos = reaper.GetCursorPosition(),
      }
end

midi_editor.activateNextVisibleItem = function(hwnd)
  reaper.MIDIEditor_OnCommand(hwnd, 40500)
end

-- Cmd: Open in built-in MIDI editor
midi_editor.openFromMain = function()
  reaper.Main_OnCommand(40153, 0)
end

-- Cmd: Zoom to project loop selection
midi_editor.zoomToProjectLoopSelection = function(hwnd)
  reaper.MIDIEditor_OnCommand(hwnd, 40726)
end

-- Options: Track list/media item lane follows selection changes in arrange view
midi_editor.toggle_TrackListAndMediaItemLane_FollowsSelectionChangesInArrangeView = function(hwnd)
  reaper.MIDIEditor_OnCommand(hwnd, 40826)
end

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

midi_editor.getVisibleTakes = function(hwnd)
  local ME_EXISTS, ME = midi_editor.getMidiValidContext(hwnd)
  if not ME_EXISTS then
    return
  end
  -- Cycle through visible MIDI items until the first one is reached
  local vis_takes = { ME.take }
  midi_editor.activateNextVisibleItem(hwnd)
  local active_take = reaper.MIDIEditor_GetTake(hwnd)
  while active_take ~= ME.take do
    vis_takes[#vis_takes + 1] = active_take
    midi_editor.activateNextVisibleItem(hwnd)
    active_take = reaper.MIDIEditor_GetTake(hwnd)
  end
  return vis_takes
end

-- https://forum.cockos.com/showpost.php?p=2449694&postcount=51
--
-- FIX: getVisibleItems AND getEditableItems funcs only differ by
-- one line. refactor...
--
midi_editor.getVisibleItems = function(hwnd)
  local ME_EXISTS, ME = midi_editor.getMidiValidContext(hwnd)
  if not ME_EXISTS then
    return
  end

  reaper.PreventUIRefresh(1)

  local saved_item_selection = containers.getItemSelection()

  local t_config = midi_editor.getConfigTable()

  -- TODO: refactor these into `midi_editor.makeTempConfig`
  -- 	-- >>> use `changeConfigForSelectionExploit`
  local new_config = t_config.raw
  new_config = new_config - t_config.editor_type + 1 -- Set 'One MIDI Editor per project'
  new_config = new_config - t_config.behavior_type -- Set behavior for opening MIDI items to 'Open all selected MIDI items'
  new_config = new_config - t_config.editability -- Disable 'Selection is linked to visibility'
  new_config = new_config - t_config.visibility -- Enable 'Selection is linked to visibility'
  midi_editor.setConfig(new_config)

  -- Set current editor item to be the only selected item
  containers.setItemSelection(ME.item)
  midi_editor.openFromMain()

  -- Save current item selection
  local vis_items = containers.getItemSelection()

  midi_editor.setConfig(t_config.raw)

  -- Restore previous item selection
  containers.setItemSelection(saved_item_selection)

  reaper.PreventUIRefresh(-1)
  return vis_items
end

midi_editor.getEditableItems = function(hwnd)
  local ME_EXISTS, ME = midi_editor.getMidiValidContext(hwnd)
  if not ME_EXISTS then
    return
  end

  reaper.PreventUIRefresh(1)

  local saved_item_selection = containers.getItemSelection()

  local t_config = midi_editor.getConfigTable()

  -- TODO: refactor these into `midi_editor.makeTempConfig`
  -- >>> use `changeConfigForSelectionExploit`
  local new_config = t_config.raw
  new_config = new_config - t_config.editor_type + 1 -- Set 'One MIDI Editor per project'
  new_config = new_config - t_config.behavior_type -- Set behavior for opening MIDI items to 'Open all selected MIDI items'
  new_config = new_config - t_config.editability -- Disable 'Selection is linked to visibility'
  new_config = new_config - t_config.visibility + 1024 -- Disable 'Selection is linked to visibility'
  midi_editor.setConfig(new_config)

  -- Set current editor item to be the only selected item
  containers.setItemSelection(ME.item)
  midi_editor.openFromMain()

  -- Save current item selection
  local editable_items = containers.getItemSelection()

  midi_editor.setConfig(t_config.raw)

  -- Restore previous item selection
  containers.setItemSelection(saved_item_selection)

  reaper.PreventUIRefresh(-1)
  return editable_items
end

-- FIX: rename to `GetUIViewState` -> return table.
---
---@param hwnd userdata
---@return number start_pos, number end_pos, number hzoom_lvl
midi_editor.getMIDIEditorView = function(hwnd)
  local ME_EXISTS, ME = midi_editor.getMidiValidContext(hwnd)
  if not ME_EXISTS then
    return
  end

  local GetProjTimeFromPPQ = reaper.MIDI_GetProjTimeFromPPQPos

  local chunk = containers.getTakeChunk(ME.take)
  local start_ppq, hzoom_lvl = containers.getTakeChunkHZoom(chunk)
  if not start_ppq then
    return
  end

  local timebase = containers.getTakeChunkTimeBase(chunk) or 0
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
      start_pos = GetProjTimeFromPPQ(ME.take, start_ppq)
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
    chunk = containers.getTakeChunk(ME.take)
    end_ppq = containers.getTakeChunkHZoom(chunk)

    -- Cmd: Scroll view left
    reaper.MIDIEditor_OnCommand(hwnd, 40140)

    if timebase == 1 then
      -- Timebase: Toggle sync to arrange view
      reaper.MIDIEditor_OnCommand(hwnd, 40640)
    end
  end

  -- Convert ppq to time based units
  start_pos = start_pos or GetProjTimeFromPPQ(ME.take, start_ppq)
  end_pos = end_pos or GetProjTimeFromPPQ(ME.take, end_ppq)

  if timebase == 0 or timebase == 4 then
    -- Convert hzoom_lvl from pixel/ppq to pixel/time
    local width_in_pixels = (end_ppq - start_ppq) * hzoom_lvl
    hzoom_lvl = width_in_pixels / (end_pos - start_pos)
  end

  return start_pos, end_pos, hzoom_lvl
end

midi_editor.getEditorHorizontalZoomState = function(hwnd)
  local start_pos, end_pos = midi_editor.getMIDIEditorView(hwnd)
  -- A factor is necessary to convert to the size of the selection used for the action
  -- "Zoom to project loop selection" which is smaller than the actual visible length
  -- This might need to be tweaked and put in the user config table.
  local factor = 0.943396226415
  local length = end_pos - start_pos
  local center = start_pos + length / 2
  return { length = length * factor, center = center }
end

midi_editor.getItemsByState = function(hwnd, is_edit_state)
  local ME_EXISTS, ME = midi_editor.getMidiValidContext(hwnd)
  if not ME_EXISTS then
    return
  end

  local saved_item_selection = containers.getItemSelection()
  local t_old_config = midi_editor.getConfigTable()

  if checkConfigForActiveLink(t_old_config, is_edit_state) then
    -- Return selected MIDI items when selection is already linked
    local midi_items = {}
    for _, item in ipairs(saved_item_selection) do
      if containers.isValidMIDIItem(item) then
        midi_items[#midi_items + 1] = item
      end
    end
    return midi_items
  end

  reaper.PreventUIRefresh(1)

  -- Save current horizontal zoom state
  local hzoom_state = midi_editor.getEditorHorizontalZoomState(hwnd)
  local new_config = changeConfigForSelectionExploit(t_old_config) -- second arg was set to `is_edit_state` which was undefined..
  midi_editor.setConfig(new_config)

  -- Set current editor item to be the only selected item
  containers.setItemSelection(ME.item)
  midi_editor.openFromMain()

  -- Selected items are visible/editable items
  local ret_items = containers.getItemSelection()

  midi_editor.setConfig(t_old_config.raw)

  containers.setItemSelection(saved_item_selection)
  midi_editor.restoreHorizontalZoomState(ME.editor, hzoom_state)

  reaper.PreventUIRefresh(-1)
  return ret_items
end

-- TODO: pass table instead with opts instead
midi_editor.setItemsState = function(hwnd, is_edit_state, items, state)
  local ME_EXISTS, ME = midi_editor.getMidiValidContext(hwnd)
  if not ME_EXISTS then
    return
  end

  local t_old_config = midi_editor.getConfigTable()

  if checkConfigForActiveLink(t_old_config, is_edit_state) then
    -- Select / Unselect items to change their state
    for _, item in ipairs(items) do
      reaper.SetMediaItemSelected(item, state)
    end
    reaper.UpdateArrange()
    return
  end

  local saved_item_selection = containers.getItemSelection()

  reaper.PreventUIRefresh(1)

  -- Save current horizontal zoom state
  local hzoom_state = midi_editor.getEditorHorizontalZoomState(hwnd)
  local new_config = changeConfigForSelectionExploit(t_old_config, is_edit_state)
  midi_editor.setConfig(new_config)

  -- Set current editor item to be the only selected item
  containers.setItemSelection(ME.item)
  midi_editor.openFromMain()

  containers.setSelectionStateOfItems(items, state)
  -- We toggle this setting so that arrange selection is mirrored in MIDI editor
  midi_editor.toggle_TrackListAndMediaItemLane_FollowsSelectionChangesInArrangeView(hwnd)
  midi_editor.toggle_TrackListAndMediaItemLane_FollowsSelectionChangesInArrangeView(hwnd)

  -- Restore
  midi_editor.setConfig(t_old_config.raw)
  containers.setItemSelection(saved_item_selection)
  midi_editor.restoreHorizontalZoomState(ME.editor, hzoom_state)

  reaper.PreventUIRefresh(-1)
end

midi_editor.getAllVisibleItems = function(hwnd)
  return midi_editor.getItemsByState(hwnd, false)
end

midi_editor.getAllEditableItems = function(hwnd)
  return midi_editor.getItemsByState(hwnd, true)
end

midi_editor.isItemVisible = function(hwnd, item)
  local visible_items = midi_editor.getAllVisibleItems(hwnd)
  if visible_items then
    for _, visible_item in ipairs(visible_items) do
      if item == visible_item then
        return true
      end
    end
  end
  return false
end

midi_editor.isItemEditable = function(hwnd, item)
  local editable_items = midi_editor.getAllEditableItems(hwnd)
  if editable_items then
    for _, editable_item in ipairs(editable_items) do
      if item == editable_item then
        return true
      end
    end
  end
  return false
end

midi_editor.setItemsVisible = function(hwnd, items, is_visible)
  if items then
    for _, item in ipairs(items) do
      if not containers.isValidMIDIItem(item) then
        return
      end
    end
    midi_editor.setItemsState(hwnd, false, items, is_visible)
  end
end

midi_editor.setItemsEditable = function(hwnd, items, is_editable)
  if items then
    for _, item in ipairs(items) do
      if not containers.isValidMIDIItem(item) then
        return
      end
    end
    midi_editor.setItemsState(hwnd, true, items, is_editable)
  end
end

midi_editor.setItemVisible = function(hwnd, item, is_visible)
  if containers.isValidMIDIItem(item) then
    midi_editor.setItemsState(hwnd, false, { item }, is_visible)
  end
end

midi_editor.setItemEditable = function(hwnd, item, is_editable)
  if containers.isValidMIDIItem(item) then
    midi_editor.setItemsState(hwnd, true, { item }, is_editable)
  end
end

--- Makes select item the active item in HWND midi editor. This means that you
--- can eg. insert notes into the item.
---@param hwnd userdata | nil
--
--- I believe that the `item_make_active` should be `item_make_active`
---@param item_make_active userdata
midi_editor.setActiveItem = function(hwnd, item_make_active, note_row)
  local ME_EXISTS, ME = midi_editor.getMidiValidContext(hwnd)
  if not containers.isValidMIDIItem(item_make_active) then
    return false
  end

  if not ME_EXISTS then
    reaper.PreventUIRefresh(1)
    containers.setItemSelection(item_make_active) -- make the only selected item
    midi_editor.openFromMain() -- trigger midi editor refresh
    if note_row then
      local ME_EXISTS_2, ME_2 = midi_editor.getMidiValidContext(hwnd)
      if ME_EXISTS_2 then
        reaper.MIDIEditor_SetSetting_int(ME_2.editor, "active_note_row", note_row)
      end
    end
    reaper.PreventUIRefresh(-1)
    return true
  else
    if ME.item == item_make_active then
      if note_row then
        reaper.MIDIEditor_SetSetting_int(ME.editor, "active_note_row", note_row)
      else
        return
      end
    end

    reaper.PreventUIRefresh(1)

    -- Save current state (visibility, editability, itemsel, hzoom, config)
    local visible_items = midi_editor.getAllVisibleItems(ME.editor)
    local editable_items = midi_editor.getAllEditableItems(ME.editor)
    local sel_items = containers.getItemSelection()
    local hzoom_state = midi_editor.getEditorHorizontalZoomState(ME.editor)

    local t_old_config = midi_editor.getConfigTable()

    local new_config = changeConfigForSelectionExploit(t_old_config) -- second arg was set to `is_edit_state` which was undefined..g
    midi_editor.setConfig(new_config)

    containers.setItemSelection(item_make_active) -- make the only selected item
    midi_editor.openFromMain() -- trigger midi editor refresh

    if note_row then
      reaper.MIDIEditor_SetSetting_int(ME.editor, "active_note_row", note_row)
    end

    -- Restore saved state
    midi_editor.setConfig(t_old_config.raw)
    containers.setItemSelection(sel_items)
    midi_editor.restoreHorizontalZoomState(ME.editor, hzoom_state)
    midi_editor.setItemsVisible(ME.editor, visible_items, true)
    midi_editor.setItemsEditable(ME.editor, editable_items, true)

    reaper.PreventUIRefresh(-1)
  end
end

-- TODO: create new item for selected mark/region
--
--
midi_editor.createEditMidiItemAtPositionForTrack = function(meta, track_obj, new_item_start, new_item_end)
  local sx = require("SYNTAX.tracks")
  local sx_utils = require("SYNTAX.utils")
  local cursor_info = tl.get_cursor_info()
  local g_obj, _, _ = sx_utils.get_track_object_group(sx.getVerifiedTree(), track_obj)

  -- TODO: if track is midi split child -> then enter parent track
  -- and set midi channel for insertion

  local target_tr, items_found, note_row

  local check_start_pos = new_item_start or cursor_info.msr.start
  local check_end_pos =  new_item_end or cursor_info.msr._end

  -- FIX: if there is an item that spans wider than both start/end, then
  -- this item also needs to be found, ie. DONT create a new item if there
  -- already exists one if it is very large

  if sx_utils.trackObjHasOption(g_obj, "m") then -- drum lanes
    target_tr = g_obj.tr
    items_found = containers.get_track_items_in_range_time(g_obj.tr, check_start_pos, check_end_pos)
    note_row = sx_utils.get_drum_lane_start_idx_from_child_track(g_obj, track_obj)

    -- TODO: midi channelsplitters -> set channel splitter master and set active midi channel in ME
    --
    -- elseif track_obj.level == 4 then -- channelsplit child
    --   target_tr = "track obj channel split parrent"
    --   items_found = containers.get_track_items_in_range_time(
    --     "track obj channel split parrent",
    --     check_start_pos,
    --     check_end_pos
    --   )
  else -- regular
    target_tr = track_obj.tr
    items_found =
    containers.get_track_items_in_range_time(track_obj.tr, check_start_pos, check_end_pos)
  end

  containers.unselect_items()

  if items_found then
    midi_editor.setActiveItem(nil, items_found[1].ref, note_row)
  else
    local new_item = containers.create_new_item(true, target_tr, check_start_pos, check_end_pos)
    midi_editor.setActiveItem(nil, new_item, note_row)
  end

end

return midi_editor
