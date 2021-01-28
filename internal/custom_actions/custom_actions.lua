local log = require('utils.log')
local format = require('utils.format')
local fx = require('library.fx')
-- local routing = require('definitions.routing')

local custom_actions = {}

local movement = require('custom_actions.movement')
local selection = require('custom_actions.selection')
custom_actions.move = movement
custom_actions.select = selection

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

-- seems like these two functions could be refactored later into a `changeTracks()` super func
function custom_actions.changeNamesOfSelectedTracks()
  local num_sel = reaper.CountSelectedTracks(0)
  local _, new_name_string = reaper.GetUserInputs("Change track name", 1, "Track name:", "")

  if num_sel == 0 then return end
  if num_sel == 1 then
    local track = reaper.GetSelectedTrack(0,0)
    local _, str = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", new_name_string, 1);
    return
  end
  if num_sel > 1 then
    for i = 1, num_sel do
      local track = reaper.GetSelectedTrack(0, i - 1)
      local _, str = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", new_name_string, 1);
    end
    return
  end
end




function updateMidiPreProcessorByInputDevice(tr)
  local tr_rec_in = reaper.GetMediaTrackInfo_Value(tr, 'I_RECINPUT')
  local midi_device_offset = 4096
  local device_mask = 2016
  local dev_id = ((tr_rec_in - midi_device_offset) & device_mask) >> 5
  local retval, nameout = reaper.GetMIDIInputName( dev_id, '' )

  -- put into my configs ??
  local device_search_strings = {
    'Virtual Midi Keyboard',
    'Ergodox EZ',
    '- port 1' -- tmp roland RD grand
  }

  local enabled_device
  for k,device_str in pairs(device_search_strings) do
    if nameout:lower():match(device_str:lower()) then enabled_device = device_str end
  end

  if enabled_device == nil then return end


  -- // DEVICES ..............
  -- DEVICE_VIRTUAL = 0;
  -- DEVICE_QMK = 1;
  -- DEVICE_PIANO_FULL = 2;

  -- // DEVICE MODES..........
  -- MODE_VIRTUAL_KEYBOARD = 0;
  -- MODE_QMK_SINGLE       = 1;
  -- MODE_QMK_FULL         = 2;
  -- MODE_QMK_SPLIT        = 3;
  -- MODE_QMK_SPLIT_CH     = 4;
  -- MODE_QMK_KIT          = 5;
  -- MODE_PIANO_FULL       = 6;
  -- MODE_PIANO_FULL_SPLIT = 7;

  if enabled_device == 'Virtual Midi Keyboard' then
    log.user('using Virtual')
    fx.setParamForFxAtIndex(tr, 0, 1, 0, true) -- set device
    fx.setParamForFxAtIndex(tr, 0, 2, 0, true) -- set mode
  end

  if enabled_device == 'Ergodox EZ' then
    log.user('using EZ')
    fx.setParamForFxAtIndex(tr, 0, 1, 1, true) -- set device
    fx.setParamForFxAtIndex(tr, 0, 2, 1, true) -- set mode
  end

  if enabled_device == '- port 1' then
    log.user('using GRAND')
    fx.setParamForFxAtIndex(tr, 0, 1, 2, true) -- set device
    fx.setParamForFxAtIndex(tr, 0, 2, 6, true) -- set mode
  end
end


function custom_actions.setupMidiInputPreProcessorOnSelTrks()
  --log.clear()
  for i = 1, reaper.CountSelectedTracks(0) do
    local tr = reaper.GetSelectedTrack(0,i-1)
    local _, name = reaper.GetTrackName(tr, "")

    local zeroth_idx_name = fx.getSetTrackFxNameByFxChainIndex(tr, 0, true) -- TODO rec fx
    if zeroth_idx_name == 'RK_MIDI_PRE_PROCESSOR' then
      log.user('RK_MIDI')

      -- TODO
      --
      -- get recFX params > might require a new statechunk function `getFXParamValue`
      --    compare params > update if difference

      updateMidiPreProcessorByInputDevice(tr)
    else
      log.user('!RK_MIDI')

      -- INSERT MIDI PRE PROCESSOR JSFX
      local fx_str = 'mid_main.jsfx'
      fx.insertFxAtIndex(tr, fx_str, 0, true)
      fx.getSetTrackFxNameByFxChainIndex(tr,0, true, 'RK_MIDI_PRE_PROCESSOR')

      updateMidiPreProcessorByInputDevice(tr)
    end

  end


end

return custom_actions
