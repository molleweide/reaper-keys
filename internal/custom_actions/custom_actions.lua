local log = require('utils.log')
local format = require('utils.format')

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

function custom_actions.sidechainToGhostKick()
  -- TODO
  --
  --  1. if track w/name containing 'ghostkick'
  --  2. check if 3/4 send exists (util)
  --  2. createSend (util)
  --  3. add reacomp to track
  --  4. rename the function to sidechain_to_ghostkick
  --    take all of my renaming functions etc and move them out to RK lib
  --    so that my syntax module is completely separated from the lib functions
  --  5. create generalized send function that works with send_str_input
end

-- util
function AddSends(src_t, dest_t)
  -- todo
  -- make this function work
  for i = 1, #src_t do
    local src_tr =  BR_GetMediaTrackByGUID( 0, src_t[i] )
    local src_tr_ch = GetMediaTrackInfo_Value( src_tr, 'I_NCHAN')
    for i = 1, #dest_t do
      local dest_tr =  BR_GetMediaTrackByGUID( 0, dest_t[i] )

      -- increase ch up to src track
      local dest_tr_ch = GetMediaTrackInfo_Value( dest_tr, 'I_NCHAN')
      if dest_tr_ch < src_tr_ch then SetMediaTrackInfo_Value( dest_tr, 'I_NCHAN', src_tr_ch ) end

      -- check for existing sends
      local is_exist = false
      for i =1,  GetTrackNumSends( src_tr, 0 ) do
        local dest_tr_check = BR_GetMediaTrackSendInfo_Track( src_tr, 0, i-1, 1 )
        if dest_tr_check == dest_tr then is_exist = true break end
      end

      if not is_exist then
        local new_id = CreateTrackSend( src_tr, dest_tr )
        SetTrackSendInfo_Value( src_tr, 0, new_id, 'D_VOL', defsendvol)
        SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_SENDMODE', defsendflag&255)

        if dest_tr_ch == 2 then
          SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_SRCCHAN',0)
        else
          SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_SRCCHAN',0|(1024*math.floor(src_tr_ch/2)))
        end
        --SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_DSTCHAN', 0)

      end
    end
  end
end

-- util
function GetDestTrGUID()
  local t = {}
  local _, sendidx = reaper.GetUserInputs("Send track dest idx:", 1, "send idx", "")
  local dest_track = reaper.GetTrack(0, sendidx-1)
  if dest_track  then t[1] = reaper.GetTrackGUID( dest_track  ) end
  return t
end

-- util
function GetSrcTrGUID()
  local t = {}
  for i = 1, reaper.CountSelectedTracks(0) do
    local tr = reaper.GetSelectedTrack(0,i-1)
    t[#t+1] = reaper.GetTrackGUID( tr )
  end
  return t
end


function custom_actions.addRouteForSelectedTracks()
  local num_sel = reaper.CountSelectedTracks(0)
  if num_sel == 0 then return end
  local src_GUID = GetSrcTrGUID() -- get table of src tracks

  -- todo
  --
  --  get src tracks ( selected tracks... )
  --    get user input
  --      regex > get send params
  --
  local route_help_str = "route params:\n" ..
  "\nk int  = category" ..
  "\ni int  = send idx" -- this is not displaying properly...


  local _, input_str = reaper.GetUserInputs("SPECIFY ROUTE:", 1, route_help_str, "")

  local send_params, err = getSendParamsFromUserInput(input_str)


  -- local dest_GUID = GetDestTrGUID()
  -- AddSends(src_GUID, dest_GUID)
end

function getSendParamsFromUserInput(str)
  -- defaults > move into def/configs?
  local send_params = {
    ["k"] = 0, -- k = category    : int,      is <0 for receives, 0=sends, >0 for hardware outputs
    ["i"] = 0, -- i = send_idx    : int
    ["m"] = 0, -- m = B_MUTE      : bool
    ["f"] = 0, -- f = B_PHASE     : bool,     true to flip phase
    ["M"] = 0, -- M = B_MONO      : bool
    ["v"] = 0, -- v = D_VOL       : double,   1.0 = +0dB etc
    ["p"] = 0, -- p = D_PAN       : double,   -1..+1
    ["P"] = 0, -- P = D_PANLAW    : double,   1.0=+0.0db, 0.5=-6dB, -1.0 = projdef etc
    ["s"] = 0, -- s = I_SENDMODE  : int,      0=post-fader, 1=pre-fx, 2=post-fx (deprecated), 3=post-fx
    ["a"] = 0, -- a = I_AUTOMODE  : int :     auto mode (-1=use track automode, 0=trim/off, 1=read, 2=touch, 3=write, 4=latch)
    ["c"] = 0, -- c = I_SRCCHAN   : int,      index,&1024=mono, -1 for none
    ["C"] = 0, -- C = I_DSTCHAN   : int,      index, &1024=mono, otherwise stereo pair, hwout:&512=rearoute
    ["I"] = 0, -- I = I_MIDIFLAGS : int,      low 5 bits=source channel 0=all, 1-16, next 5 bits=dest channel, 0=orig, 1-16=chanSee CreateTrackSend, RemoveTrackSend, GetTrackNumSends.
  }
  --  for i in char list,
  --    find if exists in `str` > return index of char AND index of next char???
  --      get all following chars int/double // charset = `d.` -- digits and periods???
  --      replace default

  log.user(format.block(str))
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
