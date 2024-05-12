local log = require("utils.log")
local format = require("utils.format")

local tbl = require("utils.table")

-- NOTE: Automation points can be UPDATED/SET directly, IE. I dont need to delete
-- points, and then re-insert the new values - I can just set the update the
-- points directly.
-- -> I should wrap this function in `update_env_point()` or `reset_` so that it
-- makes more sense.
-- >> reaper.SetEnvelopePoint( envelope, ptidx, timeIn, valueIn, shapeIn, tensionIn, selectedIn, noSortIn )

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

envelopes.loop_midi_buf_string = function()
    local gotAllOK, MIDIstring = reaper.MIDI_GetAllEvts(take, "") -- write MIDI events to MIDIstring, get all events okay
    if not gotAllOK then
        reaper.ShowMessageBox("Error while loading MIDI", "Error", 0)
        return false
    end -- if getting the MIDI data failed

    -- THESE CANT BE USED SINCE THEY ARE MOUSE DEPENDENT
    -- local cc_lane -- CC lane under mouse
    -- _, _, _ = reaper.BR_GetMouseCursorContext() -- initiate "get mouse cursor context"
    -- _, _, _, cc_lane, _, _ = reaper.BR_GetMouseCursorContext_MIDI() -- get CC lane
    -- local take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive()) -- get active take in MIDI editor
    -- local mouse_pos_ppq_int = math.floor(reaper.MIDI_GetPPQPosFromProjTime(take, reaper.BR_GetMouseCursorContext_Position())) -- get mouse position in project time, convert to PPQ and integer
    -- _, segment, _ = reaper.BR_GetMouseCursorContext() -- get mouse hovering area
    -- local selection_offset_found = false -- initalize

    local sum_offset = 0 -- initialize
    local MIDIlen = #MIDIstring -- get string length
    tableEvents = {} -- initialize table, MIDI events will temporarily be stored in this table until they are concatenated into a string again
    local stringPos = 1 -- position in MIDIstring while parsing through events

    while stringPos < MIDIlen - 12 do -- parse through all events in the MIDI string, one-by-one, excluding the final 12 bytes, which provides REAPER's All-notes-off end-of-take message
        offset, flags, msg, stringPos = string.unpack("i4Bs4", MIDIstring, stringPos) -- unpack MIDI-string on stringPos

        -- add offset until first selected event has been found
        if selection_offset_found == false then
            sum_offset = sum_offset + offset
        end

        if
            #msg == 3 -- if msg consists of 3 bytes (= channel message)
            and (msg:byte(1) >> 4) == 11
            and flags & 1 == 1 -- if status byte is a CC and event is selected
            and segment == "cc_lane" -- mouse cursor hovers the cc area
            and mouse_pos_ppq_int > 0 -- mouse cursor after take start (prevents unexpected event chaos)
        then
            if selection_offset_found == false then -- prevents writing "selection_offset_found = true" on each iteration
                selection_offset_found = true -- first selected event found
            end

            table.insert(tableEvents, string.pack("i4Bs4", offset, flags, msg)) -- keep original CC event
            msg_cc_lane = msg:sub(1, 1) .. string.char(cc_lane) .. msg:sub(3, 3) -- write msg chunk for cc_lane
            table.insert(tableEvents, string.pack("i4Bs4", mouse_pos_ppq_int - sum_offset, flags & ~1, msg_cc_lane)) -- copy CC event to mouse cursor, unselect and re-pack MIDI string
            table.insert(tableEvents, string.pack("i4Bs4", -mouse_pos_ppq_int + sum_offset, 0, "")) -- rectify distance and put an empty event after the new CC event
        else
            table.insert(tableEvents, string.pack("i4Bs4", offset, flags, msg)) -- write all other events back to table
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
        elseif targetLane == 0x203 then -- Channel pressure
            laneIsCHPRESS = true
        elseif 256 <= targetLane and targetLane <= 287 then -- CC, 14 bit (double lane)
            laneIsCC14BIT = true
        else -- not a lane type in which script can be used.
            reaper.ShowMessageBox(
                "This script only works in the following lanes:\n * 7-bit CC lanes,\n * 14-bit CC lanes,\n * Pitchwheel,\n * Channel pressure or \n * Program select.\n\n"
                    .. "(Note: The choice of method for removing redundancies from 14-bit CC lanes will depend on the user's intent: "
                    .. "For example, LSB information can be removed by simply deleting the CCs in the LSB lane.)",
                "ERROR",
                0
            )
            return false
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
        local default_note_chan = reaper.MIDIEditor_GetSetting_int(midieditor, "default_note_chan")
        local CC_lane_active = reaper.MIDIEditor_GetSetting_int(midieditor, "last_clicked_cc_lane")
        local cur_sec = reaper.GetCursorPosition()
        local cur_ppq = reaper.MIDI_GetPPQPosFromProjTime(take, cur_sec)

        local str = ""
        for ccidx = 1, ccevtcntOut do
            local _, selectedOut, _, ppqposOut, chanmsg, chanOut, CC_lane, CC_value = reaper.MIDI_GetCC(take, ccidx - 1)
            if selectedOut == true and CC_lane == CC_lane_active and chanOut == default_note_chan then
                if str == "" then
                    decrease_PPQ = ppqposOut
                end
                str = str .. "\n " .. math.floor(ppqposOut - decrease_PPQ) .. " " .. math.floor(CC_value)
            end
        end
        reaper.SetExtState("mpl CopyCC buffer", "buffer", str, false)
    end

    main()
end

-- this is the beginning of the midi cc transforming. this is going to be
-- TEST: I wonder if it will make sense to merge this into the main midi
-- fltr api. i will have to add a type parameter.
--
-- TODO: target focused track if no target is passed??
envelopes.midi_take_fltr_cc = function(opts)
    if not take or not reaper.TakeIsMIDI(take) then -- or midi take...
        log.debug("No take was supplied to midi.midi_take_filter_transform")
        return
    end

    if opts.insert and opts.remove then
        log.debug("midi transform filter: you cannot INSERT and REMOVE at same time")
        return
    end

    local t_cc = {}

    -- collect events
    if not opts.insert then
        local _, _, cc_count = reaper.MIDI_CountEvts(take)
        for i = 0, cc_count do
            local _, selected, muted, ppqpos, chanmsg, chan, msg2, msg3 = reaper.MIDI_GetCC(take, i)
            table.insert(t_cc, {
                index = i,
                selected = selected,
                muted = muted,
                ppqpos = ppqpos,
                chanmsg = chanmsg,
                chan = chan,
                msg2 = msg2,
                msg3 = msg3,
            })
            -- end
        end
    else
        -- NOTE: Pass notes for insertion.
        -- It is important here that I have a unified way for setting up midi data.
        --
        -- this means that an item hass been passed and I want to insert notes.
        -- This api is a bit unclear but i have to look at this later.
        log.user("did we get here?")
        t_cc = opts.insert.midi_data.notes
    end

    -- filter evts
    -- TODO: specify which type of cc events i want, then perform filter.
    if opts.filter then
        for k, v in pairs(opts.filter) do
            if type(v) == "boolean" then
                t_cc = tbl.filter(t_cc, function(cc_evt)
                    return cc_evt[k] == v
                end)
            elseif type(v) == "number" then
                t_cc = tbl.filter(t_cc, function(cc_evt)
                    return cc_evt[k] == v
                end)
            elseif type(v) == "table" then
                -- FIX: since there can be multiple ranges, i need to collect the filtered
                -- values and then assign them to t_cc at the end
                for _, subv in pairs(v) do
                    if type(subv) == "number" then
                        t_cc = tbl.filter(t_cc, function(cc_evt)
                            return cc_evt[k] == subv
                        end)
                    elseif type(subv) == "table" then
                        t_cc = tbl.filter(t_cc, function(cc_evt)
                            return subv[1] <= cc_evt[k] and cc_evt[k] <= subv[2]
                        end)
                    end
                end
            elseif type(v) == "function" then
                log.user("?????????")
                t_cc = tbl.filter(t_cc, v) -- pass filter func
            end
        end
    end

    -- -- remove
    -- if opts.remove then
    -- 	midi.delete_notes(take, t_cc)
    -- end

    -- if transform
    local cc_updated = 0
    if opts.transform then
        for i, ccevt in ipairs(t_cc) do
            local update = false
            for k, v in pairs(opts.transform) do
                if type(v) == "boolean" then
                    log.trace("midi take transform: set bool:", i, ccevt[k], "->", v)
                    ccevt[k] = v -- set bool value
                    update = true
                elseif type(v) == "number" then
                    log.trace("midi take transform: shift num:", i, ccevt[k], "->", ccevt[k] + v)
                    ccevt[k] = ccevt[k] + v -- shift by number
                    update = true
                elseif type(v) == "table" then
                    log.trace("midi take transform: force const:", i, ccevt[k], "->", v[1])
                    ccevt[k] = v[2] == "force" and v[1] -- { number, "force"} means force all notes to value
                    update = true
                elseif type(v) == "function" then
                    log.trace("midi take transform: func:", i, ccevt[k], "->", v(ccevt))
                    ccevt[k] = v(ccevt) -- apply function transform per ccevt
                    update = true
                end
                if update then
                    -- i am not sure if this is useful to keep a counter
                    cc_updated = cc_updated + 1
                end
            end
        end
    end

    if (cc_updated > 0 or opts.insert) and not opts.dry_run then
        reaper.PreventUIRefresh(1)
        -- if not opts.insert then
        -- 	midi.delete_notes(take, t_cc)
        -- end
        log.user("just before inserting notes")
        -- midi.insert_notes({
        -- 	take = take,
        -- 	notes = t_cc,
        -- })
        reaper.PreventUIRefresh(-1)
    end

    -- if insert and apply transform/removal.
end

envelopes.track_reset_all = function(tr)
    -- TODO: reset all curves to default and remove the envelope curves.
end

return envelopes
