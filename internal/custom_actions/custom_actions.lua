local log = require('utils.log')
local format = require('utils.format')
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

-- how can I make this action work with movement in reaper??
function custom_actions.hookUpMidiRouter()
  -- connect router to selected track I want to record to.
  -- if name of selected is midi_router DONT connect.
  --
  local tr = reaper.GetSelectedTrack(0, 0)
  local _, name = reaper.GetTrackName(tr, "")
  log.user(name)
end

return custom_actions
