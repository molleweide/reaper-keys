local log = require("utils.log")
local ru = require("custom_actions.utils")
local config = require("definitions.config")
local format = require("utils.format")
local fx = require("library.fx")
local io = require("definitions.io")

local utils = require("custom_actions.utils")

--  Motion start/end points can be retrieved with the (temporary selection)
--    local start_sel, end_sel = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
--  being made inside of the

local custom_actions = {
  move = require("custom_actions.movement"),
  select = require("custom_actions.selection"),
}

function custom_actions.clearTimeSelection()
  local current_position = reaper.GetCursorPosition()
  reaper.GetSet_LoopTimeRange(true, false, current_position, current_position, false)
end

function getUserGridDivisionInput()
  local _, num_string = reaper.GetUserInputs("Set Grid Division", 1, "Fraction/Number", "")
  local first_num = num_string:match("[0-9.]+")
  local divider = num_string:match("/([0-9.]+)")

  local division = nil
  if first_num and divider then
    division = first_num / divider
  elseif first_num then
    division = first_num
  else
    log.error("Could not parse specified grid division.")
    return nil
  end

  return division
end

function custom_actions.setMidiGridDivision()
  local division = getUserGridDivisionInput()
  if division then
    reaper.SetMIDIEditorGrid(0, division)
  end
end

function custom_actions.clearSelectedTimeline()
  local current_position = reaper.GetCursorPosition()
  reaper.GetSet_LoopTimeRange(true, false, current_position, current_position, false)
end

function custom_actions.setGridDivision()
  local division = getUserGridDivisionInput()
  if division then
    reaper.SetProjectGrid(0, division)
  end
end

-- this one avoids splitting all items across tracks in time selection, if no items are selected
function custom_actions.splitItemsAtTimeSelection()
  if reaper.CountSelectedMediaItems(0) == 0 then
    return
  end
  local SplitAtTimeSelection = 40061
  reaper.Main_OnCommand(SplitAtTimeSelection, 0)
end

function custom_actions.updatePrefixOfSelectedTracks()
  trackUpdateName(1)
end

function custom_actions.updateNameOfSelectedTracks()
  trackUpdateName(0)
end

-- mv to util/track.lua
function trackUpdateName(set_prefix)
  log.clear()
  local num_sel = reaper.CountSelectedTracks(0)
  local _, new_name_string = reaper.GetUserInputs("Change track name", 1, "Track name:", "")
  if num_sel == 0 then
    return
  end

  if num_sel > 0 then
    for i = 1, num_sel do
      local tr = reaper.GetSelectedTrack(0, i - 1)
      local ret, old_name_full = reaper.GetTrackName(tr)
      local s, e = string.find(old_name_full, config.name_prefix_match_str)
      if s == nil then
        s = 0
        e = 0
      end
      local old_prefix = string.sub(old_name_full, s, e)
      local old_name = string.sub(old_name_full, e + 1)

      local new_name_full
      if set_prefix == 1 then
        new_name_full = new_name_string .. old_name
      else
        new_name_full = old_prefix .. new_name_string
      end
      local _, str = reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", new_name_full, 1)
    end
    return
  end
end

function updateMidiPreProcessorByInputDevice(guid_tr)
  local tr, tr_idx = ru.getTrackByGUID(guid_tr)
  local tr_rec_in = reaper.GetMediaTrackInfo_Value(tr, "I_RECINPUT")
  local midi_device_offset = 4096
  local device_mask = 2016
  local dev_id = ((tr_rec_in - midi_device_offset) & device_mask) >> 5
  local retval, nameout = reaper.GetMIDIInputName(dev_id, "")

  local enabled_device
  for k, device_str in pairs(io.midi) do
    if nameout:lower():match(device_str:lower()) then
      enabled_device = device_str
    end
  end

  if enabled_device == nil then
    return
  end
  if enabled_device == io.midi.vkb then
    fx.setParamForFxAtIndex(guid_tr, 0, 1, 0, true) -- set device
    fx.setParamForFxAtIndex(guid_tr, 0, 2, 0, true) -- set mode
  end

  if enabled_device == io.midi.qmk then
    fx.setParamForFxAtIndex(guid_tr, 0, 1, 1, true) -- set device
    fx.setParamForFxAtIndex(guid_tr, 0, 2, 4, true) -- set mode
  end

  if enabled_device == io.midi.roland then
    fx.setParamForFxAtIndex(guid_tr, 0, 1, 2, true) -- set device
    fx.setParamForFxAtIndex(guid_tr, 0, 2, 8, true) -- set mode
  end
end

function custom_actions.setupMidiInputPreProcessorOnSelTrks()
  local t_sel = ru.getSelectedTracksGUIDs()
  for i = 1, #t_sel do
    local guid_tr = t_sel[i].guid

    -- log.user('insid setup io', guid_tr)

    local zeroth_idx_name = fx.getSetTrackFxNameByFxChainIndex(guid_tr, 0, true) -- TODO rec fx
    if zeroth_idx_name == "RK_MIDI_PRE_PROCESSOR" then
      updateMidiPreProcessorByInputDevice(guid_tr)
    else
      local fx_str = "midi-rec-pre.jsfx" -- INSERT MIDI PRE PROCESSOR JSFX
      fx.insertFxAtIndex(guid_tr, fx_str, 0, true)
      fx.getSetTrackFxNameByFxChainIndex(guid_tr, 0, true, "RK_MIDI_PRE_PROCESSOR")
      updateMidiPreProcessorByInputDevice(guid_tr)
    end
  end
end

function custom_actions.sidechainCompTracks(key_track_name)

  -- check if not `FX_SC_GKICK` exists
  -- add last fx
  -- create recieve for sel track
  -- from ghost 1/2 into 3/4
end

-- 1. this is a custom action
--
-- 2. it should be usable both as an operator, or as a motion.
--
-- 3. this requires differentiating whether we're executing as CMD or OP
--
-- 4. why? well, this action will both be used as an operator for inserting
--    notes based on a motion, AND it will be used standalone using state
--    to determine its parameters
--
--  FIX: rename to:
--                    insert_midi_note_chunk
--      why? well because this function can insert midi in many forms and
--      therefore needs a bit more flexible.

function custom_actions.insertMidiNotes(state)
  local start_sel, end_sel = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)

  local midi_insertion_data_default = {
    selected = false,
    muted = false,
    chan = 0,
    noSortIn = true,
  }

  local ret, ME, take = utils.getMidiValidContext()
  if not ret then
    return
  end

  local cursor_pos = reaper.GetCursorPosition()
  local t_midi_events = { reaper.MIDI_CountEvts(take) }
  local active_note_row = reaper.MIDIEditor_GetSetting_int(ME, "active_note_row")
  local t_pattern = {}
  local sixteen_note_len = 0.125
  local note_end_gap = 0.005
  local note_duration = sixteen_note_len - note_end_gap
  local retval, measures, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats(0, cursor_pos)

  remove_note_row(take, t_midi_events, active_note_row)

  -- log.user(">>>", cursor_pos, retval, measures, cml, fullbeats, cdenom)

  for i = 0, 15 do
    local note_start = i * sixteen_note_len
    table.insert(t_pattern, {
      flag = randomBool(),
      time_pos_start = note_start,
      time_pos_end = note_start + note_duration,
    })
  end

  log.user(format.block(t_pattern))

  for _, t_note in ipairs(t_pattern) do
    if t_note.flag then
      local ret = reaper.MIDI_InsertNote(
        take,
        midi_insertion_data_default.selected,
        midi_insertion_data_default.muted,
        reaper.MIDI_GetPPQPosFromProjTime(take, t_note.time_pos_start),
        reaper.MIDI_GetPPQPosFromProjTime(take, t_note.time_pos_end),
        midi_insertion_data_default.chan,
        active_note_row,
        80,
        midi_insertion_data_default.noSortIn
      )
    end
  end

  reaper.MIDI_Sort(take)
end

return custom_actions
