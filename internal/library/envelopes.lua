local log = require("utils.log")
local format = require("utils.format")

local tbl = require("utils.table")

local TEMPLATE_SETTINGS = {
    envelopes = { start_delta = 0.01, end_delta = 0.01 },
    midi_cc = { start_delta = 0.01, end_delta = 0.01 },
}

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

local envelopes = {}

-- NOTE: CURVE SHAPE
-- Shapes ID is in same order than in the right click dropdown menu for Set
-- shape, 0 being Linear, 1 square etc...

-- NOTE: midi cc lanes:
-- Valid CC lanes: CC0-127=CC, 0x100|(0-31)=14-bit CC, 0x200=velocity,
-- 0x201=pitch, 0x202=program, 0x203=channel pressure, 0x204=bank/program
-- select, 0x205=text, 0x206=sysex, 0x207

envelopes.track_get_all_builtin_envs = function(tr)
    local t_envs = {}

    local const_builtin_envs = require("constants.constants").BUILTIN_ENVELOPES

    -- for _, v in ipairs(all_builtin_envs) do
    -- end

    for _, e in pairs(const_builtin_envs) do
        local env = reaper.GetTrackEnvelopeByChunkName(tr, e.search_string)

        if env then
            local _, buf = reaper.GetEnvelopeName(env)
            log.user(string.format("[[ %s ===> %s ]]", e.name, buf))
        end

        table.insert(t_envs, env)
    end

    return t_envs
end

-- TODO: filter type = track/take?
--
---Filters the envelopes of a track, eg. if you want all envelopes by this
---set of FX plugins, or params..
envelopes.fltr_track_envelopes = function(tr, opts)
    if not tr then
        log.user("[fltr_track_envelopes]: #1 expects Track")
        return
    end
    opts = opts or {}

    local count_envs = reaper.CountTrackEnvelopes(tr)
    if count_envs == 0 then
        log.user("[fltr_track_envelopes]: count_envs == 0")
        return
    end

    -- TODO: add filters for what type of fx or parameter to get envelopes
    -- for.

    local t_envelopes = {}

    for i = 0, count_envs do
        log.user("track envelope #", i)
        local track_env = reaper.GetTrackEnvelope(tr, i)
        table.insert(t_envelopes, track_env)
    end

    return t_envelopes
end

---This function operatos on a single Envelope object for a track.
--NOTE: requires you to pass a target envelope
envelopes.fltr_single_envelope = function(opts)
    opts = opts or {}

    -- log.user("[envelopes.fltr_single_envelope]: opts = ", format.block(opts))

    if not opts.target_env then
        log.user("[envelopes.fltr_single_envelope]: No target envelope provided")
        return
    end

    local target_env = opts.target_env

    -- local _, buf = reaper.GetEnvelopeName(opts.target_env)
    -- log.user("target env name = ", buf)

    local t_envp = {}

    -- NOTE: it seems i only need to do the collection of points in certain cases
    -- where i know that I want to filter them specifically or have do tasks by
    -- ptidx but this is not always.
    if not opts.insert then
        local count_env_pts = reaper.CountEnvelopePoints(target_env)
        for i = 0, count_env_pts, 1 do
            local retval, time, value, shape, tension, selected = reaper.GetEnvelopePoint(target_env, i)
            table.insert(t_envp, {
                ptidx = i,
                position = time,
                param_val = value,
                shape = shape,
                tension = tension,
                selected = selected,
            })
        end
    else
        -- log.user("[fltr_single_envelope] (first) if not opts.insert else condition")
        t_envp = opts.insert
    end

    if opts.filter then
        local filter = opts.filter
        if type(filter) == "boolean" then
            t_envp = tbl.filter(t_envp, function(pt)
                return pt[k] == filter
            end)
        elseif type(filter) == "number" then
            t_envp = tbl.filter(t_envp, function(pt)
                return pt[k] == filter
            end)
        elseif type(filter) == "table" then
            -- FIX: since there can be multiple ranges, i need to collect the filtered
            -- values and then assign them to t_envp at the end
            for _, subv in pairs(filter) do
                if type(subv) == "number" then
                    t_envp = tbl.filter(t_envp, function(pt)
                        return pt[k] == subv
                    end)
                elseif type(subv) == "table" then
                    t_envp = tbl.filter(t_envp, function(pt)
                        return subv[1] <= pt[k] and pt[k] <= subv[2]
                    end)
                end
            end
        elseif type(filter) == "function" then
            log.user("?????????")
            t_envp = tbl.filter(t_envp, filter) -- pass filter func
        end
    end

    local transform_in_time = false
    local env_pts_updated = 0
    if opts.transform then
        local transform = opts.transform

        for i, point in ipairs(t_envp) do
            local update = false
            for k, v in pairs(transform) do
                if k == "position" then
                    transform_in_time = true
                end

                if type(v) == "boolean" then
                    log.trace("midi take transform: set bool:", i, point[k], "->", v)
                    point[k] = v -- set bool value
                    update = true
                elseif type(v) == "number" then
                    log.user("fltr env transform: shift num:", i, point[k], "->", point[k] + v)
                    point[k] = point[k] + v -- shift by number
                    update = true
                elseif type(v) == "table" then
                    log.trace("midi take transform: force const:", i, point[k], "->", v[1])
                    point[k] = v[2] == "force" and v[1] -- { number, "force"} means force all notes to value
                    update = true
                elseif type(v) == "function" then
                    log.trace("midi take transform: func:", i, point[k], "->", v(point))
                    point[k] = v(point) -- apply function transform per point
                    update = true
                end
                if update then
                    -- i am not sure if this is useful to keep a counter
                    env_pts_updated = env_pts_updated + 1
                end
            end -- transform.notes -> k, v
        end
    end

    reaper.PreventUIRefresh(1)

    -- NOTE: if points are transformed in time, then I need to remove and then re-insert
    -- points

    if opts.remove then
        local rm = opts.remove
        if type(rm) == "table" then
            -- range tables are assumed to come in ascending order, so that I can reverse
            -- remove values
            for i = #rm, #rm, -1 do
                local range = rm[i]
                reaper.DeleteEnvelopePointRange(target_env, range[1], range[2])
            end
        end

    -- Envelopes can be "set" directly, so I dont need to remove and re-insert..
    elseif (env_pts_updated > 0 or opts.insert) and not opts.dry_run then
        -- TODO: if transform_in_time then...
        -- if not opts.insert and transform_in_time then
        -- 	envelopes.remove_points(take, t_cc)
        -- end

        log.user("[fltr_single_envelope] just before note insertion")
        -- midi.insert_notes({
        -- 	take = take,
        -- 	notes = t_cc,
        -- })
        -- log.user("env pts to insert ->", format.block(t_envp))

        -- -- local fx_env = reaper.GetFXEnvelope(track, fx_number, i - 1, true)
        -- if fx_env ~= nil then
        --     reaper.InsertEnvelopePoint(env, cursor_pos, param_val, 0, 0, false, true)
        -- end
        for _, point in ipairs(t_envp) do
            -- set shape etc to 0 now as default but this can be passed as param later.
            -- log.user("point:", format.block(point))
            if opts.insert then
                log.user("INSERT")
                reaper.InsertEnvelopePoint(target_env, point.position, point.param_val, 0, 0, false, true)
            else
                log.user("SET")
                log.user("point:", format.block(point))
                reaper.SetEnvelopePoint(
                    target_env,
                    point.ptidx,
                    point.position,
                    point.param_val,
                    point.shape,
                    point.tension,
                    point.selected,
                    true
                )
            end
        end
        -- else
        -- only transform params of point.

        -- for _, point in ipairs(t_envp) do

        -- reaper.SetEnvelopePoint(target_env, point.ptidx, timeIn, valueIn, shapeIn, tensionIn, selectedIn, noSortIn)
        -- end

        -- reaper.UpdateArrange()
    end

    reaper.Envelope_SortPoints(target_env)
    reaper.PreventUIRefresh(-1)
end

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
        end -- ENDLOOP through selected tracks
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
        if not midi_cc[cc.msg2] then
            midi_cc[cc.msg2] = {}
        end
        table.insert(midi_cc[cc.msg2], cc)
    end
    return midi_cc
end

---This is the simple version that haves no filter besides the last event.
---Easy to understand and if you want to check the difference in performance
---with my IterateMIDI function. Or if you want to filter yourself.
---@param MIDIstring string string with all MIDI events (use reaper.MIDI_GetAllEvts)
---@param filter_midiend boolean Filter Last MIDI message (reaper automatically add a message when item ends 'CC123')
---@return function
local function IterateAllMIDI(MIDIstring, filter_midiend)
    -- Should it iterate the last midi 123 ? it just say when the item ends
    local MIDIlen = MIDIstring:len()
    if filter_midiend then
        MIDIlen = MIDIlen - 12
    end
    local iteration_stringPos = 1
    local offset_count = 0
    return function()
        if iteration_stringPos < MIDIlen then
            local offset, flags, msg, stringPos = string.unpack("i4Bs4", MIDIstring, iteration_stringPos)
            iteration_stringPos = stringPos
            offset_count = offset + offset_count
            return offset, offset_count, flags, msg, stringPos
        else -- Ends the iteration
            return nil
        end
    end
end

---Unpack a packed string MIDI message in different values
---@param msg string midi as packed string
---@return number msg_type midi message type: Note Off = 8; Note On = 9;
--Aftertouch = 10; CC = 11; Program Change = 12; Channel Pressure = 13; Pitch
--Vend = 14; text = 15.
---@return number msg_ch midi message channel 1 based (1-16)
---@return number data2 databyte1 -- like note pitch, cc num
---@return number data3 databyte2 -- like note velocity, cc val. Some midi messages dont have databyte2 and this will return nill. For getting the value of the pitchbend do databyte1 + databyte2
---@return string text if message is a text return the text
---@return table allbytes all bytes in a table in order, starting with statusbyte. usefull for longer midi messages like text
local function UnpackMIDIMessage(msg)
    -- 176 >> 4 = 11
    local msg_type = msg:byte(1) >> 4
    local msg_ch = (msg:byte(1) & 0x0F) + 1 --msg:byte(1)&0x0F -- 0x0F = 0000 1111 in binary. this is a bitmask. +1 to be 1 based
    local text
    if msg_type == 15 then
        text = msg:sub(3)
    end
    local val1 = msg:byte(2)
    local val2 = (msg_type ~= 15) and msg:byte(3) -- return nil if is text
    return msg_type, msg_ch, val1, val2, text, msg
end

---Unpack flags into selected, muted, curve_shape
---@param flag number
---@return boolean selected is selected
---@return boolean muted is muted
---@return integer curve_shape curve type 0square, 1linear, 2slow start/end, 3fast start, 4fast end, 5bezier
local function UnpackFlags(flag)
    local selected = flag & 1 == 1 -- AND operation with  1 (1 in binary) (return the first bit val)
    local muted = flag & 2 == 2 -- AND operation with 10 (2 in binary) (return the second bit val + 1 bit as 0 I could also move it to the void)
    -- cc_string
    local curve_shape = flag >> 4 -- Void the first 4 bits as they dont matter for cc curve and get the value. If is flags from something without curve shape like notes will just return 0, as square
    return selected, muted, curve_shape
end

local CC_CONSTANTS = {
    type = {
        ---       bits of the data byte ): Note Off = 8; Note On = 9; Aftertouch = 10; CC = 11;
        ---       Program Change = 12; Channel Pressure = 13; Pitch Vend = 14; text = 15.
        --     note_off = ,
        -- note_on = ,
        cc = 176, -- 176
        pitch = 224,
        -- pitch =
    },
}

-- this is the beginning of the midi cc transforming. this is going to be
-- TEST: I wonder if it will make sense to merge this into the main midi
-- fltr api. i will have to add a type parameter.
--
-- TODO: target focused track if no target is passed??
envelopes.midi_take_fltr_cc = function(opts)
    opts = opts or {}
    if not opts.take or not reaper.TakeIsMIDI(opts.take) then -- or midi take...
        log.debug("No take was supplied to midi.midi_take_filter_transform")
        return
    end

    log.user("midi_take_fltr_cc ENTERED, opts =", format.block(opts))

    if opts.insert and opts.remove then
        log.debug("midi transform filter: you cannot INSERT and REMOVE at same time")
        return
    end

    local filter = opts.filter

    if opts.remove then
        filter = opts.remove
    end

    local t_cc = {}

    -- NOTE: local retval, buf = reaper.MIDI_GetAllEvts( take )
    -- Get all MIDI data. MIDI buffer is returned as a list of { int offset,
    --       char flag, int msglen, unsigned char msg[] }.
    -- ~ offset: MIDI ticks from previous event
    -- ~ flag: &1=selected &2=muted
    --       flag high 4 bits for CC shape: &16=linear, &32=slow start/end,
    --       &16|32=fast start, &64=fast end, &64|16=bezier
    -- ~ msg: the MIDI message.
    -- ------
    -- A meta-event of type 0xF followed by 'CCBZ ' and 5 more bytes represents
    -- bezier curve data for the previous MIDI event: 1 byte for the bezier type
    -- (usually 0) and 4 bytes for the bezier tension as a float.
    -- ------
    -- For tick intervals longer than a 32 bit word can represent, zero-length
    -- meta events may be placed between valid events.
    --
    --
    -- HACK: Searching for `i4Bs4` gives a set of good results in the forum.
    -- https://forums.cockos.com/search.php?searchid=17398038
    --
    --
    -- TEST: ->>>> `_set_start_of_sel_notes_to_cursor.lua` shows how you can
    -- modularize the packing/unpacking of midi events.
    --
    -- TODO: Read daniel lumertz midi_toolkit/functions.lua
    -- https://github.com/daniellumertz/DanielLumertz-Scripts/blob/master/MIDI/MIDI%20Toolkit/Functions/MIDI%20Functions.lua
    -- Because he does everything in a very nice manner.

    -- NOTE: Valid CC lanes: CC0-127=CC, 0x100|(0-31)=14-bit CC, 0x200=velocity,
    -- 0x201=pitch, 0x202=program, 0x203=channel pressure, 0x204=bank/program
    -- select, 0x205=text, 0x206=sysex, 0x207

    -- NOTE: Forum post on how to delete CC for specific channel:
    -- https://forums.cockos.com/showthread.php?t=252925
    function SoloChannel(ch)
        local _, MIDIstring = reaper.MIDI_GetAllEvts(take, "")
        local MIDIlen = MIDIstring:len()
        local tableEvents = {}
        local stringPos = 1
        --local pos=0
        while stringPos < MIDIlen - 12 do
            -- Unpack the MIDI[stringPos] event
            local offset, flags, msg, stringPos = string.unpack("i4Bs4", MIDIstring, stringPos)
            --pos=pos+offset -- For keeping track of the Postion of the notes
            --in Ticks
            -- if msg:len == 3 means it have 3 messages(Notes, CC,Poly Aftertouch,
            -- Pitchbend )  (msg:byte(1)>>4 == 9 or msg:byte(1)>>4 == 8) note on or
            -- off
            if msg:len() == 3 and (msg:byte(1) >> 4 == 9 or msg:byte(1) >> 4 == 8) then
                -- 0x0F = 0000 1111 in binary . msg is decimal. & is an and bitwise
                -- operation "have to have 1 in both to be 1". Will return channel as a
                -- decimal number
                local channel = msg:byte(1) & 0x0F
                if channel ~= ch - 1 then
                    msg = ""
                end
            end
            table.insert(tableEvents, string.pack("i4Bs4", offset, flags, msg))
        end
        reaper.MIDI_SetAllEvts(take, table.concat(tableEvents))
        -- reaper.MIDI_SetAllEvts(cur_take, table.concat(tableEvents) .. MIDIstring:sub(-12))
    end

    -- NOTE: https://github.com/jeremybernstein/ReaScripts/blob/main/MIDI/MIDIUtils.lua
    -- >>>> This project describes a very advanced midi utils library for reaper.

    -- collect events
    if not opts.insert then
        -- NOTE: w/MIDI_GetAllEvts
        --
        -- local _, midi_str = reaper.MIDI_GetAllEvts(opts.take)
        --
        -- -- Whatever I do with the `midiend` I have to do the same when I write the buf
        -- -- again.
        --
        -- for offset, offset_count, flags, msg, stringPos in IterateAllMIDI(midi_str, true) do
        --   -- log.user("#:", offset, offset_count, flags, msg, stringPos)
        --   local msg_type, msg_ch, val1, val2, text = UnpackMIDIMessage(msg)
        --   local selected, muted, curve_shape = UnpackFlags(flags)
        --
        --   -- local msg_ch = msg:byte(1)&0x0F -- 0x0F = 0000 1111 in binary . msg is string. & is an and bitwise operation "have to have 1 in both to be 1". Will return channel as a decimal number. 0 based
        --
        --   log.user(string.format(
        --     [[> offs: %s, offsc: %s, flags: %s, msg: <off>, strPos: %s | mtype: %s, mch: %s, val1: %s, val2: %s, text: %s, sel: %s, muted: %s, shape: %s]],
        --     offset,
        --     offset_count,
        --     flags,
        --     -- msg,
        --     stringPos,
        --     msg_type,
        --     msg_ch,
        --     val1,
        --     val2,
        --     text,
        --     selected,
        --     muted,
        --     curve_shape
        --   ))
        --
        --   -- -- TODO: i should put all events in a table that makes it easier for me
        --   -- -- to manage them programmatically.
        --   -- table.insert(t_cc, {
        --   --   -- ...
        --   -- })
        -- end

        local _, _, cc_count = reaper.MIDI_CountEvts(opts.take)

    -- NOTE: I could rewrite this as a special iterator so that I only
    -- need to perform one single loop for all cc/insert -> filter -> transform.
        for i = 0, cc_count do
            local _, selected, muted, ppqpos, chanmsg, chan, msg2, msg3 = reaper.MIDI_GetCC(opts.take, i)

            -- Move the filter to here actually.
            local t_cc_evt = {
                index = i,
                selected = selected,
                muted = muted,
                ppqpos = ppqpos,
                chanmsg = chanmsg,
                chan = chan,
                msg2 = msg2,
                msg3 = msg3,
            }
            -- if not filter or filter(t_cc_evt) then
            table.insert(t_cc, t_cc_evt)
            -- end
            -- end
        end
    else
        t_cc = opts.insert
    end

    log.user("t_cc ->", format.block(t_cc))

    -- filter evts
    if filter then
        log.user("enter filter...")
        if type(filter) == "function" then
            log.user("[midi_take_fltr_cc] filter = function()")
            t_cc = tbl.filter(t_cc, filter) -- pass filter func
        end
    end

    -- -- remove
    -- if opts.remove then
    -- 	midi.delete_notes(take, t_cc)
    -- end

    -- NOTE: Can `retval, shape, beztension = reaper.MIDI_GetCCShape( take, ccidx )` be used for
    -- CC transform?

    -- -- if transform
    local cc_updated = 0
    if opts.transform then
        for i, ccevt in ipairs(t_cc) do
            local update = false
            if type(opts.transform) == "function" then
                opts.transform(ccevt)
                update = true
            end
            if update then
                -- i am not sure if this is useful to keep a counter
                cc_updated = cc_updated + 1
            end
        end
    end

    --
    -- GET NEXT SEL CC EVENT -> local int = reaper.MIDI_EnumSelCC( take, ccidx )
    --      Returns the index of the next selected MIDI CC event after ccidx (-1
    --      if there are no more selected events).

    log.user("Len t_cc =", #t_cc)

    if opts.remove and not opts.insert then
        reaper.PreventUIRefresh(1)
        for i, evt in ipairs(t_cc) do
            local ret = reaper.MIDI_DeleteCC(opts.take, evt.index)
        end
        reaper.PreventUIRefresh(-1)
        reaper.MIDI_Sort(opts.take)
    elseif cc_updated > 0 then
        reaper.PreventUIRefresh(1)
        for i, evt in ipairs(t_cc) do
            log.user("Set evt:", format.block(evt))
            reaper.MIDI_SetCC(
                opts.take,
                evt.index,
                evt.selected,
                evt.muted,
                evt.ppqpos,
                evt.chanmsg,
                evt.chan,
                evt.msg2,
                evt.msg3,
                true
            )
        end
        reaper.PreventUIRefresh(-1)
        reaper.MIDI_Sort(opts.take)
    elseif opts.insert and not opts.dry_run then
        reaper.PreventUIRefresh(1)

        -- if not opts.insert then
        -- 	midi.delete_notes(take, t_cc)
        -- end
        log.user("[midi_take_fltr_cc]: Just before inserting CC")
        -- midi.insert_notes({
        -- 	take = take,
        -- 	notes = t_cc,
        -- })
        local CC_SHAPES = {
            [0] = "square",
            [1] = "linear",
        }

        for k, list_cc in pairs(opts.insert) do
            if k == "cc" then
                for i, evt in ipairs(list_cc) do
                    log.user("evt =", format.block(evt))
                    reaper.MIDI_InsertCC(
                        opts.take,
                        evt.selected and evt.selected or false,
                        evt.muted and evt.muted or false,
                        evt.ppqpos >= 0 and evt.ppqpos or 400,
                        CC_CONSTANTS.type[k], -- CC = 11
                        evt.chan and evt.chan or 0,
                        evt.cc and evt.cc or 1, -- which cc curve to target.
                        evt.val and evt.val or 64
                    )
                end
            elseif k == "pitch" then
                -- NOTE: "Please enter a value from -8192 through 8191"
                -- >>> The range for pitch bend is quite large.
                local step
                local interval
                for i, evt in ipairs(list_cc) do
                    -- It seems that I need to first upshift values by 8192 and
                    -- then use AND combined with RIGHT SHIFT to generate the real pitch
                    -- bend values.
                    local value = evt.val + 8192
                    local LSB = value & 0x7f
                    local MSB = value >> 7 & 0x7f
                    reaper.MIDI_InsertCC(
                        opts.take,
                        false,
                        false,
                        evt.ppqpos,
                        CC_CONSTANTS.type.pitch,
                        0, -- chan
                        LSB,
                        MSB
                    )
                    if evt.shape then
                        -- local retval, selected, muted, ppqpos, msg = reaper.MIDI_GetEvt( take, evtidx )
                        local get_cc_count = function()
                            local _, _, ccevtcnt, _ = reaper.MIDI_CountEvts(opts.take)
                            return ccevtcnt
                        end
                        local cc_count = get_cc_count()

                        reaper.MIDI_SetCCShape(opts.take, cc_count - 1, 1, 0, true)
                        log.user("setting shape of idx =", cc_count - 1)
                    end
                end
            end
        end

        reaper.MIDI_Sort(opts.take)
        reaper.PreventUIRefresh(-1)
    end

    -- if insert and apply transform/removal.
end


envelopes.track_delete_single_envelope = function()
    -- TODO: reset all curves to default and remove the envelope curves.
end


envelopes.track_reset_all = function(tr)
    -- TODO: reset all curves to default and remove the envelope curves.
end

envelopes.list_all_curve_objects = function()
end

return envelopes
