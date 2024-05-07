local envelopes = {}

-- NOTE: CURVE SHAPE
-- Shapes ID is in same order than in the right click dropdown menu for Set
-- shape, 0 being Linear, 1 square etc...


-- NOTE: midi cc lanes:
-- Valid CC lanes: CC0-127=CC, 0x100|(0-31)=14-bit CC, 0x200=velocity,
-- 0x201=pitch, 0x202=program, 0x203=channel pressure, 0x204=bank/program
-- select, 0x205=text, 0x206=sysex, 0x207



envelopes.track_fltr_env_points = function(opts) end

-- retval, time, value, shape, tension, selected = reaper.GetEnvelopePoint( envelope, ptidx )
--  retval, time, value, shape, tension, selected = reaper.GetEnvelopePointEx( envelope, autoitem_idx, ptidx )
--      autoitem_idx=-1 for the underlying envelope, 0 for the first automation
--      item on the envelope, etc. For automation items, pass
--      autoitem_idx|0x10000000 to base ptidx on the number of points in one full
--      loop iteration, even if the automation item is trimmed so that not all
--      points are visible. Otherwise, ptidx will be based on the number of visible
--      points in the automation item, including all loop iterations.

-- retval, buf = reaper.MIDI_GetAllEvts( take )
--     Get all MIDI data. MIDI buffer is returned as a list of { int offset, char
--     flag, int msglen, unsigned char msg[] }. offset: MIDI ticks from previous
--     event flag: &1=selected &2=muted flag high 4 bits for CC shape: &16=linear,
--     &32=slow start/end, &16|32=fast start, &64=fast end, &64|16=bezier msg: the
--     MIDI message. A meta-event of type 0xF followed by 'CCBZ ' and 5 more bytes
--     represents bezier curve data for the previous MIDI event: 1 byte for the
--     bezier type (usually 0) and 4 bytes for the bezier tension as a float. For
--     tick intervals longer than a 32 bit word can represent, zero-length meta
--     events may be placed between valid events.

-- NOTE: number reaper.GetEnvelopeInfo_Value( env, parmname )
--
-- -- Gets an envelope numerical-value attribute:
-- I_TCPY : int : Y offset of envelope relative to parent track (may be separate lane or overlap with track contents)
-- I_TCPH : int : visible height of envelope
-- I_TCPY_USED : int : Y offset of envelope relative to parent track, exclusive of padding
-- I_TCPH_USED : int : visible height of envelope, exclusive of padding
-- P_TRACK : MediaTrack * : parent track pointer (if any)
-- P_DESTTRACK : MediaTrack * : destination track pointer, if on a send
-- P_ITEM : MediaItem * : parent item pointer (if any)
-- P_TAKE : MediaItem_Take * : parent take pointer (if any)
-- I_SEND_IDX : int : 1-based index of send in P_TRACK, or 0 if not a send
-- I_HWOUT_IDX : int : 1-based index of hardware output in P_TRACK or 0 if not a hardware output
-- I_RECV_IDX : int : 1-based index of receive in P_DESTTRACK or 0 if not a send/receive

function enumEnvelopePoints()
  local pi = 0
  local count = reaper.CountEnvelopePoints(state.env)
  return function()
    local point = { reaper.GetEnvelopePoint(state.env, pi) }
    if point[1] then -- retval
      point[1] = pi
      pi = pi + 1
      return point
    end
  end
end

function getSelectedPoints()
  local points = {}
  for point in enumEnvelopePoints() do
    if point[6] then -- selected
      table.insert(points, point)
    end
  end
  return points
end

envelopes.loop_track_envelopes = function()
  -- LOOP TRHOUGH SELECTED TRACKS
  env = reaper.GetSelectedEnvelope(0)
  if env == nil then
    selected_tracks_count = reaper.CountSelectedTracks(0)
    for i = 0, selected_tracks_count - 1 do
      -- GET THE TRACK
      track = reaper.GetSelectedTrack(0, i) -- Get selected track i
      -- LOOP THROUGH ENVELOPES
      env_count = reaper.CountTrackEnvelopes(track)
      for j = 0, env_count - 1 do
        -- GET THE ENVELOPE
        env = reaper.GetTrackEnvelope(track, j)
        -- AddPoints(env)
      end -- ENDLOOP through envelopes
    end   -- ENDLOOP through selected tracks
  else
    -- AddPoints(env)
  end -- endif sel envelope
end

envelopes.single_get_properties = function(br_env)
  local active, visible, armed, inLane, laneHeight, defaultShape, minValue, maxValue, centerValue, type_, faderScaling =
      reaper.BR_EnvGetProperties(br_env, true, true, true, true, 0, 0, 0, 0, 0, 0, true)
  return {
    active = active,
    visible = visible,
    armed = armed,
    in_lane = inLane,
    lane_height = laneHeight,
    default_shape = defaultShape,
    min_val = minValue,
    max_val = maxValue,
    center_val = centerValue,
    type = type_,
    fader_scaling = faderScaling,
  }
end

-- this function uses the slower method where I have to know which ccidx before hand.
envelopes.get_midi_ccs_by_type = function(take)
  local retval, notes, ccs, sysex = reaper.MIDI_CountEvts(take)

  -- Store CC by types
  local midi_cc = {}
  for j = 0, ccs - 1 do
    local cc = {}
    _, cc.selected, cc.muted, cc.ppqpos, cc.chanmsg, cc.chan, cc.msg2, cc.msg3 = reaper.MIDI_GetCC(take, j)
    if not midi_cc[cc.msg2] then midi_cc[cc.msg2] = {} end
    table.insert(midi_cc[cc.msg2], cc)
  end
  return midi_cc
end

envelopes.loop_midi_buf_string = function()
  local gotAllOK, MIDIstring = reaper.MIDI_GetAllEvts(take, "") -- write MIDI events to MIDIstring, get all events okay
  if not gotAllOK then
    reaper.ShowMessageBox("Error while loading MIDI", "Error", 0)
    return (false)
  end -- if getting the MIDI data failed


  -- THESE CANT BE USED SINCE THEY ARE MOUSE DEPENDENT
  -- local cc_lane -- CC lane under mouse
  -- _, _, _ = reaper.BR_GetMouseCursorContext() -- initiate "get mouse cursor context"
  -- _, _, _, cc_lane, _, _ = reaper.BR_GetMouseCursorContext_MIDI() -- get CC lane
  -- local take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive()) -- get active take in MIDI editor
  -- local mouse_pos_ppq_int = math.floor(reaper.MIDI_GetPPQPosFromProjTime(take, reaper.BR_GetMouseCursorContext_Position())) -- get mouse position in project time, convert to PPQ and integer
  -- _, segment, _ = reaper.BR_GetMouseCursorContext() -- get mouse hovering area
  -- local selection_offset_found = false -- initalize



  local sum_offset = 0                                                                -- initialize
  local MIDIlen = #MIDIstring                                                         -- get string length
  tableEvents = {}                                                                    -- initialize table, MIDI events will temporarily be stored in this table until they are concatenated into a string again
  local stringPos = 1                                                                 -- position in MIDIstring while parsing through events

  while stringPos < MIDIlen - 12 do                                                   -- parse through all events in the MIDI string, one-by-one, excluding the final 12 bytes, which provides REAPER's All-notes-off end-of-take message
    offset, flags, msg, stringPos = string.unpack("i4Bs4", MIDIstring, stringPos)     -- unpack MIDI-string on stringPos

    -- add offset until first selected event has been found
    if selection_offset_found == false then
      sum_offset = sum_offset + offset
    end

    if #msg == 3                                    -- if msg consists of 3 bytes (= channel message)
        and (msg:byte(1) >> 4) == 11 and flags & 1 == 1 -- if status byte is a CC and event is selected
        and segment == "cc_lane"                    -- mouse cursor hovers the cc area
        and mouse_pos_ppq_int > 0                   -- mouse cursor after take start (prevents unexpected event chaos)
    then
      if selection_offset_found == false then       -- prevents writing "selection_offset_found = true" on each iteration
        selection_offset_found = true               -- first selected event found
      end

      table.insert(tableEvents, string.pack("i4Bs4", offset, flags, msg))                                        -- keep original CC event
      msg_cc_lane = msg:sub(1, 1) .. string.char(cc_lane) .. msg:sub(3, 3)                                       -- write msg chunk for cc_lane
      table.insert(tableEvents, string.pack("i4Bs4", mouse_pos_ppq_int - sum_offset, flags & ~1, msg_cc_lane))   -- copy CC event to mouse cursor, unselect and re-pack MIDI string
      table.insert(tableEvents, string.pack("i4Bs4", -mouse_pos_ppq_int + sum_offset, 0, ""))                    -- rectify distance and put an empty event after the new CC event
    else
      table.insert(tableEvents, string.pack("i4Bs4", offset, flags, msg))                                        -- write all other events back to table
    end
  end

  -- Note that if lanes_from_which_to_remove == "all", each 7-bit part of 14-bit CCs will be analyzed separately,
  if lanes_from_which_to_remove == "all" then
    laneIsALLCC, laneIsPITCH, laneIsPROGRAM, laneIsCHPRESS = true, true, true, true
  else
    if 0 <= targetLane and targetLane <= 127 then -- CC, 7 bit (single lane)
      laneIsCC7BIT = true
    elseif targetLane == 0x201 then
      laneIsPITCH = true
    elseif targetLane == 0x202 then
      laneIsPROGRAM = true
    elseif targetLane == 0x203 then                     -- Channel pressure
      laneIsCHPRESS = true
    elseif 256 <= targetLane and targetLane <= 287 then -- CC, 14 bit (double lane)
      laneIsCC14BIT = true
    else                                                -- not a lane type in which script can be used.
      reaper.ShowMessageBox(
        "This script only works in the following lanes:\n * 7-bit CC lanes,\n * 14-bit CC lanes,\n * Pitchwheel,\n * Channel pressure or \n * Program select.\n\n"
        .. "(Note: The choice of method for removing redundancies from 14-bit CC lanes will depend on the user's intent: "
        .. "For example, LSB information can be removed by simply deleting the CCs in the LSB lane.)"
        , "ERROR", 0)
      return (false)
    end
  end

end

  -- integer reaper.MIDIEditor_GetSetting_int( midieditor, setting_desc )
  --   Get settings from a MIDI editor. setting_desc can be:
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

  envelopes.MPL_copy_selected_cc = function()
    -- @description Copy selected CC
    -- @version 1.0
    -- @author MPL
    -- @website http://forum.cockos.com/member.php?u=70694
    -- @changelog
    --    + init release



    function main()
      -- local midieditor =  reaper.MIDIEditor_GetActive()
      -- if not midieditor then return end
      -- local take =  reaper.MIDIEditor_GetTake( midieditor )
      -- if not take or not reaper.TakeIsMIDI(take) then return end
      local _, _, ccevtcntOut = reaper.MIDI_CountEvts(take)
      local default_note_chan = reaper.MIDIEditor_GetSetting_int(midieditor, 'default_note_chan')
      local CC_lane_active = reaper.MIDIEditor_GetSetting_int(midieditor, 'last_clicked_cc_lane')
      local cur_sec = reaper.GetCursorPosition()
      local cur_ppq = reaper.MIDI_GetPPQPosFromProjTime(take, cur_sec)

      local str = ''
      for ccidx = 1, ccevtcntOut do
        local _, selectedOut, _, ppqposOut, chanmsg, chanOut, CC_lane, CC_value = reaper.MIDI_GetCC(take, ccidx - 1)
        if selectedOut == true and CC_lane == CC_lane_active and chanOut == default_note_chan then
          if str == '' then decrease_PPQ = ppqposOut end
          str = str .. '\n ' .. math.floor(ppqposOut - decrease_PPQ) .. ' ' .. math.floor(CC_value)
        end
      end
      reaper.SetExtState('mpl CopyCC buffer', 'buffer', str, false)
    end

    main()
  end

  envelopes.take_fltr_midi_cc = function(opts)
    -- retval, selected, muted, ppqpos, chanmsg, chan, msg2, msg3 = reaper.MIDI_GetCC( take, ccidx )
  end

return envelopes
