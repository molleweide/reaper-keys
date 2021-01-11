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

function custom_actions.insertSpaceAtEditCursorFromTimeSelection()
  local tstart, tend = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)

  reaper.PreventUIRefresh(1)

  local curPos = reaper.GetCursorPosition()
  reaper.GetSet_LoopTimeRange(true, false, curPos, curPos + (tend - tstart), false)
  reaper.Main_OnCommand(40200, 0) -- Time selection: Insert empty space at time selection (moving later items)
  reaper.GetSet_LoopTimeRange(true, false, tstart, tend, false)

  reaper.PreventUIRefresh(-1)
end

function custom_actions.repeatShiftAllItemsInTimeSelectionByTrackByTimeSel()
  -- 1. if item pos is before time sel start > skip
  -- 2. add time_sel_len
  local start_sel, end_sel = reaper.GetSet_LoopTimeRange(0, 0, 0, 0, 0)
  log.user(end_sel)

  local data = {}
  if reaper.CountSelectedMediaItems(0) < 1 then return end
  data = collectMediaItemData(data)
  local measure_shift, end_fullbeatsmax = CalcMeasureShift(data)
  local increment_measure = OverlapCheck(data, measure_shift, end_fullbeatsmax)
  -- DuplicateItems(data, end_sel - start_sel)
end

-- util
function collectMediaItemData(data)
  for i = 1, reaper.CountSelectedMediaItems(0) do
    local item = reaper.GetSelectedMediaItem( 0, i-1 )
    local pos = reaper.GetMediaItemInfo_Value( item, 'D_POSITION' )
    local len = reaper.GetMediaItemInfo_Value( item, 'D_LENGTH' )
    local GUID = reaper.BR_GetMediaItemGUID( item )
    local pos_beats_t = {reaper.TimeMap2_timeToBeats( 0,pos )}
    local end_beats_t = {reaper.TimeMap2_timeToBeats( 0,pos+len )}
    data[i] = {src_tr =  reaper.GetMediaItem_Track( item ),
      chunk = ({reaper.GetItemStateChunk( item, '', false )})[2],
      group_ID = reaper.GetMediaItemInfo_Value( item, 'I_GROUPID'),
      col = reaper.GetMediaItemInfo_Value( item, 'I_CUSTOMCOLOR' ),
      pos_conv = {   pos_conv_beats = pos_beats_t [1],
        pos_conv_measure = pos_beats_t [2],
        pos_conv_fullbeats = pos_beats_t [4],
      },
      end_conv = {   end_conv_beats = end_beats_t [1],
        end_conv_measure = end_beats_t [2],
        end_conv_fullbeats = end_beats_t [4],
      },
      GUID = reaper.BR_GetMediaItemGUID( item )
    }

  end
  return data
end

-- util
function CalcMeasureShift(data)
  local meas_min = math.huge
  local meas_max = 0
  local end_fullbeatsmax = 0
  for i = 1, #data do
    meas_min = math.min(meas_min, data[i].pos_conv.pos_conv_measure)
    meas_max = math.max(meas_max, data[i].end_conv.end_conv_measure)
    end_fullbeatsmax = math.max(end_fullbeatsmax, data[i].end_conv.end_conv_fullbeats)
  end
  local measure_shift = math.max(1,meas_max - meas_min)
  return measure_shift, end_fullbeatsmax
end

-- util
function OverlapCheck(data, measure_shift, end_fullbeatsmax)
  reaper.ClearConsole()
  for i = 1, #data do
    local shifted_pos = reaper.TimeMap2_beatsToTime( 0, data[i].pos_conv.pos_conv_beats, data[i].pos_conv.pos_conv_measure + measure_shift )
    if shifted_pos < reaper.TimeMap2_beatsToTime( 0, end_fullbeatsmax ) then  return 1 end
  end
  return 0
end

-- util
function DuplicateItems(data,measure_shift)
  for i = 1, #data do
    local new_it = reaper.AddMediaItemToTrack( data[i].src_tr )
    reaper.SetItemStateChunk( new_it, data[i].chunk, false )
    local new_pos = reaper.TimeMap2_beatsToTime( 0, data[i].pos_conv.pos_conv_beats, data[i].pos_conv.pos_conv_measure + measure_shift )
    local new_end = reaper.TimeMap2_beatsToTime( 0, data[i].pos_conv.pos_conv_beats, data[i].end_conv.end_conv_measure + measure_shift )
    reaper.SetMediaItemInfo_Value( new_it, 'D_POSITION', new_pos)
    reaper.SetMediaItemInfo_Value( new_it, 'D_LENGTH', new_end - new_pos)
    --SetMediaItemInfo_Value( new_it, 'I_CUSTOMCOLOR', data[i].col )
  end
end

return custom_actions
