local log = require("utils.log")
local format = require("utils.format")
local envelopes = require("library.envelopes")

local lib_tr = require("library.tracks")

local automation_actions = {}

-- number reaper.GetEnvelopeInfo_Value( env, parmname )
--     Gets an envelope numerical-value attribute:
--     I_TCPY : int : Y offset of envelope relative to parent track (may be separate lane or overlap with track contents)
--     I_TCPH : int : visible height of envelope
--     I_TCPY_USED : int : Y offset of envelope relative to parent track, exclusive of padding
--     I_TCPH_USED : int : visible height of envelope, exclusive of padding
--     P_TRACK : MediaTrack * : parent track pointer (if any)
--     P_DESTTRACK : MediaTrack * : destination track pointer, if on a send
--     P_ITEM : MediaItem * : parent item pointer (if any)
--     P_TAKE : MediaItem_Take * : parent take pointer (if any)
--     I_SEND_IDX : int : 1-based index of send in P_TRACK, or 0 if not a send
--     I_HWOUT_IDX : int : 1-based index of hardware output in P_TRACK or 0 if not a hardware output
--     I_RECV_IDX : int : 1-based index of receive in P_DESTTRACK or 0 if not a send/receive

-- env_points_count = reaper.CountEnvelopePoints(env)

-- br_env = reaper.BR_EnvAlloc(env, false)
--     [BR] Allocate envelope object from track or take envelope pointer. Always
--     call BR_EnvFree when done to release the object and commit changes if
--     needed.
--
--     takeEnvelopesUseProjectTime: take envelope points' positions are counted
--     from take position, not project start time. If you want to work with project
--     time instead, pass this as true.
--
--     For further manipulation see BR_EnvCountPoints, BR_EnvDeletePoint,
--     BR_EnvFind, BR_EnvFindNext, BR_EnvFindPrevious, BR_EnvGetParentTake,
--     BR_EnvGetParentTrack, BR_EnvGetPoint, BR_EnvGetProperties, BR_EnvSetPoint,
--     BR_EnvSetProperties, BR_EnvValueAtPos.

-- boolean reaper.BR_EnvFree(BR_Envelope envelope, boolean commit)
-- [BR] Free envelope object allocated with BR_EnvAlloc and commit changes if
-- needed. Returns true if changes were committed successfully. Note that when
-- envelope object wasn't modified nothing will get committed even if commit =
-- true - in that case function returns false.

--  integer reaper.GetEnvelopeScalingMode( env )
--      Returns the envelope scaling mode: 0=no scaling, 1=fader scaling. All
--      API functions deal with raw envelope point values, to convert raw
--      from/to scaled values see
--
-- number reaper.ScaleFromEnvelopeMode(integer scaling_mode, number val)

-- 	reaper.DeleteEnvelopePointRange(envelope, start_time-0.000000001, end_time+0.000000001)

-- boolean reaper.SetEnvelopePoint(env, k, timeInOptional, valueInOptional, shapeInOptional, tensionInOptional, false, true)
-- boolean reaper.SetEnvelopePoint( envelope, ptidx, timeIn, valueIn, shapeIn, tensionIn, selectedIn, noSortIn )

-- boolean reaper.InsertEnvelopePoint(
--     TrackEnvelope envelope,
--     number time,
--     number value,
--     integer shape,
--     number tension,
--     boolean selected,
--     optional boolean noSortIn
-- )
-- Insert an envelope point. If setting multiple points at once, set noSort=true, and call Envelope_SortPoints when done. See

-- retval, value, dVdS, ddVdS, dddVdS = reaper.Envelope_Evaluate( envelope, time, samplerate, samplesRequested )
--     Get the effective envelope value at a given time position.
--     samplesRequested is how long the caller expects until the next call to
--     Envelope_Evaluate (often, the buffer block size). The return value is
--     how many samples beyond that time position that the returned values are
--     valid. dVdS is the change in value per sample (first derivative), ddVdS
--     is the second derivative, dddVdS is the third derivative. See

automation_actions.test = function()
    local tl = require("library.timeline")
    local cursor_info = tl.get_cursor_info()
    local start_pos = cursor_info.msr.start
    local end_pos = cursor_info.msr._end

    local cursor_position = cursor_info.cursor_pos

    -- could this also be passed as an arg?
    local ret, ctxm = require("library.midi_editor").getMidiValidContext()
    -- if not ret then
    --   return
    -- end

    local t_foc_tr = lib_tr.get_focused_track_objects()

    local tr = t_foc_tr[1].tr

    local t_envs = envelopes.fltr_track_envelopes(tr)

    if t_envs == nil or #t_envs == 0 then
        log.user("No envelopes found")
        return
    end

    -- TEST: Test all types of calls to lib.envs.fltr funcs and ensure that all
    -- ways of accessing params work.
    -- TODO: AUTOMATION TESTING
    -- 1. delete all automation for track
    --   a. get all envelopes.
    --   b. delete all points for envelope.
    --   c. refactor into `lib/envs`
    envelopes.fltr_single_envelope({
        target = t_envs,
        remove = {},
    })
    --   --
    -- 2. insert single point
    --   a. insert point at cursor.
    envelopes.fltr_single_envelope({
        target = t_envs, -- FIX: only pass single env here
        insert = { { position = cursor_position, param_val = 0.5 } },
    })
    --   --
    -- 3. insert multiple points / range.
    --   a. pass range based on cursor to fltr func.
    envelopes.fltr_single_envelope({
        target = t_envs, -- FIX: only pass single env here
        insert = {
            { position = cursor_position - 0.5, param_val = 0.4 },
            { position = cursor_position + 0.5, param_val = 0.6 },
        },
    })
    --   --
    -- 4. transform notes
    envelopes.fltr_single_envelope({
        target = t_envs, -- FIX: only pass single env here
        filter = function(point)
            return point.position > cursor_position
        end,
        transform = { { right = 0.25, param_val = 0.4 } },
    })
    --  ..
    --   --
    -- 5. delete points in time selection
    envelopes.fltr_single_envelope({
        target = t_envs, -- FIX: only pass single env here
        remove = "timeline_selection", -- delete all notes within timeline selection.
    })
    --   --
    -- 6. TODO: picker select fx param insert env points
  --
    --

    -- FIX: API, create my own API for getting all events of type/lane

    -- get selected / active envelope lane

    -- local env = reaper.GetSelectedEnvelope(0)

    log.user("automation test -> t_envs:", format.block(t_envs))
end

automation_actions.insert_pattern_for_measure = function()
    -- TODO: insert quarter note random envelope pattern.
    -- 1. get measure info
    -- 2. compute mid quarter note points
    -- 3. randomize value for each mid point.
    -- 4. insert pattern
    --     ~ if pattern already exists for measure
    --         ~ prompt -> do you want to replace existing pattern?
    --
    --
    -- DO THIS FOR:
    --   both FX, midi CC, and other??
end

automation_actions.picker_list_envelope_nodes_for_track = function()
    -- ~~~ list in picker.
    --    ~~~~ for each track active envelope
    --    ~~~~ list every envelope node

    -- TODO: 1. get all active envelopes in track
    -- 2. for each envelope
    --     get envelope node table
    -- 3. list envelope nodes in picker
    -- 4. build the picker
end

automation_actions.example_insert_pitch_bend = function()
    --[[
 * ReaScript Name: Insert Pitch Bend
 * Instructions: Open a MIDI take in MIDI Editor. Position Edit Cursor, Run.
--]]

    local take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())
    local pos = reaper.GetCursorPositionEx()
    local ppq = reaper.MIDI_GetPPQPosFromProjTime(take, pos)
    local retval, userinput = reaper.GetUserInputs("Insert Pitch Bend", 1, "Value", "0")
    if not retval then
        return reaper.SN_FocusMIDIEditor()
    end

    local value = math.floor(userinput)
    if value < -8192 or value > 8191 then
        return reaper.MB("Please enter a value from -8192 through 8191", "Error", 0), reaper.SN_FocusMIDIEditor()
    end

    reaper.Undo_BeginBlock()
    value = value + 8192
    local LSB = value & 0x7f
    local MSB = value >> 7 & 0x7f
    reaper.MIDI_InsertCC(take, false, false, ppq, 224, 0, LSB, MSB)
    reaper.Undo_EndBlock("Insert Pitch Bend", 0)
    reaper.UpdateArrange()
    reaper.SN_FocusMIDIEditor()
end

automation_actions.increase_cc_values_for_measure = function()
    -- @description Increase events in CC lane under mouse cursor
    --    * This script increases all or selected CC events in the lane under the mouse cursor
    --    * This script works only in the MIDI Editor
    -- @link https://forums.cockos.com/showthread.php?p=1923923

    -- I wonder if this way of parsing midi events is faster?
    function CheckForSelectedEvents(cc_lane) -- check if cc_lane has selected events
        stringPos = 1 -- position in MIDIstring while parsing through events
        local selected_events = 0

        -- parse through all events in the MIDI string, one-by-one, excluding the final
        -- 12 bytes, which provides REAPER's All-notes-off end-of-take message
        while stringPos < MIDIlen - 12 do
            offset, flags, msg, stringPos = string.unpack("i4Bs4", MIDIstring, stringPos) -- unpack MIDI-string on stringPos

            -- if msg consists of 3 bytes (= channel message)
            if
                #msg == 3
                -- if status byte is a CC, CC# equals cc_lane
                and (msg:byte(1) >> 4) == 11
                and msg:byte(2) == cc_lane
                -- and event is selected
                and (flags & 1 == 1)
            then
                selected_events = 1
                return selected_events -- at least one selection was found
            end
        end
    end

    function IncreaseCC(take, cc_lane, selected_events, increase)
        -- position in MIDIstring while parsing through events
        stringPos = 1
        -- Initialize table, MIDI events will temporarily be stored in this table
        -- until they are concatenated into a string again
        tableEvents = {}

        -- parse through all events in the MIDI string, one-by-one, excluding the
        -- final 12 bytes, which provides REAPER's All-notes-off end-of-take
        -- message
        while stringPos < MIDIlen - 12 do
            -- unpack MIDI-string on stringPos
            offset, flags, msg, stringPos = string.unpack("i4Bs4", MIDIstring, stringPos)

            -- if msg consists of 3 bytes (= channel message)
            if
                #msg == 3
                -- if status byte is a CC, CC# equals cc_lane
                and (msg:byte(1) >> 4) == 11
                and msg:byte(2) == cc_lane
                -- and event or muted event is selected
                and (flags & 1 == 1 or not selected_events)
            then
                -- get CC value
                msg_b3 = msg:byte(3)
                msg = msg:sub(1, 1)
                    .. msg:sub(2, 2)
                    -- increase CC value, convert CC value to string, concatenate msg
                    .. string.char(math.min(127, (math.ceil(msg_b3 * increase))))
            end
            table.insert(tableEvents, string.pack("i4Bs4", offset, flags, msg)) -- re-pack MIDI string and write to table
        end

        reaper.MIDI_SetAllEvts(take, table.concat(tableEvents) .. MIDIstring:sub(-12))
        reaper.MIDI_Sort(take)
    end

    local cc_lane -- CC lane under mouse
    local increase = 1.1 -- value to increase the CC event
    _, _, _ = reaper.BR_GetMouseCursorContext() -- initiate "get mouse cursor context"
    _, _, _, cc_lane, _, _ = reaper.BR_GetMouseCursorContext_MIDI() -- get CC lane
    local take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive()) -- get active take in MIDI editor

    if reaper.TakeIsMIDI(take) then -- make sure, that take is MIDI
        gotAllOK, MIDIstring = reaper.MIDI_GetAllEvts(take, "") -- write MIDI events to MIDIstring, get all events okay
        if not gotAllOK then
            reaper.ShowMessageBox("Error while loading MIDI", "Error", 0)
            return false
        end -- if getting the MIDI data failed

        MIDIlen = #MIDIstring -- get string length
        local selected_events = CheckForSelectedEvents(cc_lane) -- check for selected events
        IncreaseCC(take, cc_lane, selected_events, increase) -- increase CC events
    end

    reaper.UpdateArrange()
    reaper.Undo_OnStateChange2(proj, "Increase events in CC" .. cc_lane .. " lane under mouse cursor")
end

automation_actions.insert_cc_linear_ramp = function()
    --[[
 * ReaScript Name: Insert CC linear ramp events between selected ones if consecutive
 * Description: Interpolate multiple CC events by creating new ones. Works with multiple lanes (CC Channel).
 * Instructions: Open a MIDI take in MIDI Editor. Select Notes. Run.
 * Forum Thread URI: http://forum.cockos.com/showpost.php?p=1617117&postcount=1265
--]]

    -- USER CONFIG AREA ---------------------

    interval = "2"
    prompt = true -- User input dialog box
    selected = false -- new notes are selected

    ----------------- END OF USER CONFIG AREA

    -- Console Message
    function Msg(g)
        reaper.ShowConsoleMsg(tostring(g) .. "\n")
    end

    function GetCC(take, cc)
        return cc.selected, cc.muted, cc.ppqpos, cc.chanmsg, cc.chan, cc.msg2, cc.msg3
    end

    function main() -- local (i, j, item, take, track)
        take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())

        if take ~= nil then
            retval, notes, ccs, sysex = reaper.MIDI_CountEvts(take)

            if ccs == 0 then
                return
            end

            -- Store CC by types
            midi_cc = {}
            for j = 0, ccs - 1 do
                cc = {}
                retval, cc.selected, cc.muted, cc.ppqpos, cc.chanmsg, cc.chan, cc.msg2, cc.msg3 =
                    reaper.MIDI_GetCC(take, j)
                if not midi_cc[cc.msg2] then
                    midi_cc[cc.msg2] = {}
                end
                table.insert(midi_cc[cc.msg2], cc)
            end

            -- Look for consecutive CC
            cc_events = {}
            cc_events_len = 0

            for key, val in pairs(midi_cc) do
                -- GET SELECTED NOTES (from 0 index)
                for k = 1, #val - 1 do
                    a_selected, a_muted, a_ppqpos, a_chanmsg, a_chan, a_msg2, a_msg3 = GetCC(take, val[k])
                    b_selected, b_muted, b_ppqpos, b_chanmsg, b_chan, b_msg2, b_msg3 = GetCC(take, val[k + 1])

                    if a_selected == true and b_selected == true then
                        -- INSERT NEW CCs
                        time_interval = (b_ppqpos - a_ppqpos) / interval

                        for z = 1, interval - 1 do
                            cc_events_len = cc_events_len + 1
                            cc_events[cc_events_len] = {}

                            c_ppqpos = a_ppqpos + time_interval * z
                            c_msg3 = math.floor(((b_msg3 - a_msg3) / interval * z + a_msg3) + 0.5)

                            cc_events[cc_events_len].ppqpos = c_ppqpos
                            cc_events[cc_events_len].chanmsg = a_chanmsg
                            cc_events[cc_events_len].chan = a_chan
                            cc_events[cc_events_len].msg2 = a_msg2
                            cc_events[cc_events_len].msg3 = c_msg3
                        end
                    end
                end
            end

            -- Insert Events
            for i, cc in ipairs(cc_events) do
                reaper.MIDI_InsertCC(take, selected, false, cc.ppqpos, cc.chanmsg, cc.chan, cc.msg2, cc.msg3)
            end
        end -- ENFIF Take is MIDI
    end

    -- RUN ---------------------
    if prompt then
        retval, interval = reaper.GetUserInputs("Insert CC Events", 1, "Number of new events between CC?", interval)
    end

    if retval or prompt == false then -- if user complete the fields
        interval = tonumber(interval)

        if interval then
            reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

            interval = math.floor(interval) + 1

            main() -- Execute your main function

            reaper.UpdateArrange() -- Update the arrangement (often needed)

            reaper.Undo_EndBlock("Insert CC linear ramp events between selected ones if consecutive", -1) -- End of the undo block. Leave it at the bottom of your main function.
        end
    end
end

-- return automation_actions
--   end
-- end

return automation_actions
