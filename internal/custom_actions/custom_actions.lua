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

function GetDestTrGUID()
  local t = {}
  local _, sendidx = reaper.GetUserInputs("Send track dest idx:", 1, "send idx", "")
  local dest_track = reaper.GetTrack(0, sendidx-1)
  if dest_track  then t[1] = reaper.GetTrackGUID( dest_track  ) end
  return t
end

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
  local src_GUID = GetSrcTrGUID()
  local dest_GUID = GetDestTrGUID()
  AddSends(src_GUID, dest_GUID)
end

return custom_actions

--  `s15mf`
--
--  rsh = CATEGORY is <0 for receives, 0=sends, >0 for hardware outputs
--    SEND_IDX
--        m = B_MUTE : returns bool *
--        f = B_PHASE : returns bool *, true to flip phase
--        M = B_MONO : returns bool *
--        v = D_VOL : returns double *, 1.0 = +0dB etc
--        p = D_PAN : returns double *, -1..+1
--        P = D_PANLAW : returns double *,1.0=+0.0db, 0.5=-6dB, -1.0 = projdef etc
--        s = I_SENDMODE : returns int *, 0=post-fader, 1=pre-fx, 2=post-fx (deprecated), 3=post-fx
--        a = I_AUTOMODE : returns int * : automation mode (-1=use track automode, 0=trim/off, 1=read, 2=touch, 3=write, 4=latch)
--        c = I_SRCCHAN : returns int *, index,&1024=mono, -1 for none
--        C = I_DSTCHAN : returns int *, index, &1024=mono, otherwise stereo pair, hwout:&512=rearoute
--        I = I_MIDIFLAGS : returns int *, low 5 bits=source channel 0=all, 1-16, next 5 bits=dest channel, 0=orig, 1-16=chanSee CreateTrackSend, RemoveTrackSend, GetTrackNumSends.
--

-- boolean reaper.SetTrackSendInfo_Value(tr, int categ, int sidx, str pname, num newval)

