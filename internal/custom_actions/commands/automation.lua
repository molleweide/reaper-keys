local log = require("utils.log")
local format = require("utils.format")
local tl = require("library.timeline")
local envelopes = require("library.envelopes")
local lib_tr = require("library.tracks")
local constants = require("constants.constants")
local fzf = require("library.fzf")

local automation_actions = {}

-- TODO: these actions should be added to `<leader>ai<key>`
-- so that I can just play around and build up the library and see what
-- little tweaks have to be made over time. and then i will be able to
-- fucking push the mix and mastering up so fucking hard.
-- --
-- ~ Delete all points for env
-- ~ Insert template for current measure.
-- ~ Remove template at cursor.
-- ~ Add template for region.
-- ~ Add template for motion.
-- ~ Move cursor to next/prev template start.
-- ~
--

automation_actions.test = function()
    local cursor_info = tl.get_cursor_info()
    local msr_start_pos = cursor_info.msr.start
    local msr_end_pos = cursor_info.msr._end
    local cursor_position = cursor_info.cursor_pos

    local BUILTIN_ENVELOPE_NAMES = {
        volume_pre_fx = { name = "Volume (Pre-FX)", search_string = "<VOLENV" },
        pan = { name = "Pan", search_string = "<PANENV" },
    }

    local t_foc_tr = lib_tr.get_focused_track_objects()

    local tr = t_foc_tr[1].tr

    local t_envs = envelopes.fltr_track_envelopes(tr)

    -- get volume envelope
    local volenv = reaper.GetTrackEnvelopeByChunkName(tr, "<VOLENV2")

    local all_builtin_envs = envelopes.track_get_all_builtin_envs(tr)

    -- if t_envs == nil or #t_envs == 0 then
    --     log.user("No envelopes found")
    --     return
    -- end

    log.user("automation test -> t_envs:", format.block(t_envs))

    --
    -- Insert points to volume curve and see what happens.
    --
    log.user("# TEST INSERT")
    envelopes.fltr_single_envelope({
        target_env = volenv,
        insert = { { position = cursor_position, param_val = 0.5 } },
    })

    --
    -- Remove points
    --
    log.user("# TEST RM MSR")
    envelopes.fltr_single_envelope({
        target_env = volenv,
        remove = { { msr_start_pos, msr_end_pos } }, -- TODO: pass the range in which to remove
    })

    --
    -- Insert multiple points
    --
    log.user("# TEST insert mult points")
    envelopes.fltr_single_envelope({
        target_env = volenv,
        insert = {
            { position = cursor_position + 2.5, param_val = 0.4 },
            { position = cursor_position + 3, param_val = 0.6 },
        },
    })

    --
    -- Transform notes
    --
    log.user("# TEST transform points before cursor ")
    envelopes.fltr_single_envelope({
        target_env = volenv,
        filter = function(point)
            return point.position < cursor_position
        end,
        transform = { param_val = 300 },
        -- transform = { param_val = { 200, "force"} },
    })

    -- TEST: Transform in time
    log.user("# TEST transform points in time.")
    envelopes.fltr_single_envelope({
        target_env = volenv,
        filter = function(point)
            return point.position > cursor_position
        end,
        -- This should move events forward by one measure/ four QNs.
        transform = { position = 2 },
    })

    -- --   --
    -- -- 6. TODO: picker select fx param insert env points
    -- -- ------
    -- --    a. Get/select list of all possible parameters/envelopes
    -- --         -> Combine listing of [volume, pan, FX1, ..., FX2].
    -- --         -> If you select an FX, chain FX parameter selection.
    -- --      b. Prompt -> specify values to insert.
    -- --      c. Parse string.
    -- --      d. insert env points
    -- -- 7. Prompt env point substitute command.
    -- -- 8. Use motion as timeline edges
    -- --    a.
    -- -- 9. Use region as timeline edges.
    -- -- 10. Picker/prompt apply specific type of curve.
    --
    -- -- TODO: combine fltr track envs with fltr env points
    -- --
    -- envelopes.fltr_track_envelopes({
    --     target_track = "selected", -- default -> unnecessary...
    --     -- target both track volume and table -> fx name/param
    --     target_envs = { "volume", { name = "Reasamplo55000", param = 10 } },
    --     env_fltr = {
    --         filter = function(point)
    --             return point.position > cursor_position
    --         end,
    --         transform = { { right = 0.25, param_val = 0.4 } },
    --     },
    -- })
end

-- HACK: First, implement everything for basic CC curves, then
-- add -> pitch bend / channel pressure, etc..
automation_actions.midi_cc_test = function()
    local cursor_info = tl.get_cursor_info()
    local ms = cursor_info.msr.start
    local me = cursor_info.msr._end
    local cp = cursor_info.cursor_pos

    log.user("###### [midi_cc_test] ######")

    local ret, ctxm = require("library.midi_editor").getMidiValidContext()
    if not ret then
        log.user("[midi_cc_test]: NO midi context could be collected.")
        return
    end

    -- TEST: MIDI CC TEST BELOW
    -- Midi cc testing should initially be done within ME so that I can see
    -- what happens when creating events but later, I could also do it from
    -- the main area.

    -- -- TEST: Just test the loop and log messages.
    -- envelopes.midi_take_fltr_cc({
    --   take = ctxm.take,
    -- })

    --
    -- Insert array of CC values
    -- TODO Make it work with Start in source (Start offset) Originally this 0 did the trick --
    ms = reaper.MIDI_GetPPQPosFromProjTime(ctxm.take, ms)
    me = reaper.MIDI_GetPPQPosFromProjTime(ctxm.take, me)

    cp_ppq = reaper.MIDI_GetPPQPosFromProjTime(ctxm.take, cp)
    cp_ppq_and_qn = reaper.MIDI_GetPPQPosFromProjTime(ctxm.take, cp + 0.5)

    -- reaper.MIDI_InsertCC(
    --     ctxm.take,
    --     false, -- sel
    --     false, -- muted
    --     ms, -- ppq
    --     11, -- type
    --     1, -- chan
    --     0, -- which CC
    --     64 -- val
    -- )

    -- -- NOTE: insert cc events
    --
    --   envelopes.midi_take_fltr_cc({
    --       take = ctxm.take,
    --       -- This is where I specify which curve to target, what should be a
    --       -- good default here if no curve is supplied??
    --       target_curve = 5,
    --       insert = {
    --           cc = {
    --               { cc = 1, ppqpos = cp_ppq, val = 50 },
    --               { cc = 2, ppqpos = cp_ppq + 100, val = 80 },
    --               { cc = 3, ppqpos = cp_ppq + 201, val = 100 },
    --               { cc = 20, ppqpos = cp_ppq, val = 100 },
    --               { cc = 20, ppqpos = cp_ppq + 50, val = 105 },
    --               { cc = 20, ppqpos = cp_ppq + 59, val = 100 },
    --               { cc = 20, ppqpos = cp_ppq + 66, val = 109 },
    --           },
    --       },
    --   })

    --
    -- NOTE: INSERT PITCH BEND
    --
    local pb_step = 8192 / 16

    -- local pb_evts = {}
    -- for i = 0, 9, 1 do
    --   table.insert(pb_evts, {
    --     ppqpos = i * 100,
    --     val = i * 8192 / 16,
    --   })
    -- end
    -- envelopes.midi_take_fltr_cc({
    --   take = ctxm.take,
    --   insert = {
    --     pitch = pb_evts,
    --   },
    --   step_size = 128,
    -- })

    -- MIDI_SetCCShape

    --
    -- NOTE: INSERT PITCH BEND two notes w/shape
    --

    envelopes.midi_take_fltr_cc({
        take = ctxm.take,
        insert = {
            pitch = { { ppqpos = ms, val = 0, shape = "linear" }, { ppqpos = me - 1, val = pb_step * 8 } },
        },
    })

    --
    -- Remove CC events in cursor position QN
    --

    -- log.user("REMOVE PITCH BEND EVENTS at CP QN")

    -- envelopes.midi_take_fltr_cc({
    --     take = ctxm.take,
    --     -- remove = function(evt) return evt.type = "pitch", cp_ppq <= evt.ppqpos  and evt.ppqpos <= cp_ppq_and_qn end
    --     remove = {
    --         pitch = function(evt)
    --             return cp_ppq <= evt.ppqpos and evt.ppqpos <= cp_ppq_and_qn
    --         end,
    --     },
    -- })

    log.user("TRANSFORM EVENTS")

    envelopes.midi_take_fltr_cc({
        take = ctxm.take,
        filter = function(e)
            return e.chanmsg == constants.CC_CONSTANTS.type.pitch and e.ppqpos == cp_ppq
        end,
        transform = function(e)
            e.ppqpos = reaper.MIDI_GetPPQPosFromProjTime(ctxm.take, cp + 0.5)
        end,
    })

    -- -- 4. Insert values at motion
    -- envelopes.midi_take_fltr_cc({
    --     take = ctxm.take,
    --     insert = "motion", -- or ts / time_sel / tsel
    -- })
    -- -- 5. Insert values at region
    -- -- 6. Insert pitch bend
    -- -- 7. delete CC values in range
    -- envelopes.midi_take_fltr_cc({
    --     take = ctxm.take,
    --     remove = { { ms, me } }, -- or ts / time_sel / tsel
    -- })
    -- -- 8. transform CC values in range.
    -- envelopes.midi_take_fltr_cc({
    --     take = ctxm.take,
    --     filter = { { ms, me } }, -- or ts / time_sel / tsel
    --     transform = 5,
    -- })
end

-- TODO: Select
-- 1. tracks
-- 2. select which types of params to randomize.
-- 3. apply fltr calls on each track.
automation_actions.picker_add_random_curves_to_selection = function() end

automation_actions.picker_builtins_add_curve = function()
    -- TODO: from the picker select which one (<CR>) extend with a
    -- new random curve
end

automation_actions.picker_add_env_curve_for_fx_param = function()
    -- TODO: Reuse my current FX -> FX param picker.
    -- 1. Insert point at cursor for selection. <CR>
end

-- IDEA: should i first prompt for both envelops and midi cc in the same command?
-- And then just list:
--  ~ (env) vol
--  ~ (env) pan
--  ~ +fx
--  ~ (cc) pitch bend
--  ~ (cc) cc1
--  ~ (cc) cc2
automation_actions.picker_insert_cc_curve = function()
    local state_interface = require("state_machine.state_interface")

    -- TODO: check for selector

    if state_interface.last_command_has("timeline_operator") then
        local tl_range = state_interface.getKey("last_set_timeline_range")

        -- table.insert(target_ranges, {
        --     left = tl_range[1],
        --     right = tl_range[2],
        -- })
        log.user("[ picker insert cc curve ]: operator; range:", tl_range[1], tl_range[2])
    else
        log.user("[ picker insert cc curve ]: NOT op")
    end

    local t_curve_results = {
        { "Volume" },
        { "Pan" },
        { "+FX" },
        { "Pitch" },
        { "CC1" },
        { "CC2" },
    }

    local function picker_curve_menu_start()
        fzf.init({
            title = "Picker: Curve menu start",
            results = t_curve_results,
            x = 200,
            width = 600,
            height = 600,
            on_select_func = true,
            results_filter = 1,
            sort_comp = 1,
            entry_maker = 1,
        })
    end

    picker_curve_menu_start()

    -- local target_ranges = {}
    -- -- 1. selected regions
    -- if custom_targets.regions then
    --     -- for _, cs in ipairs(custom_targets.regions) do
    --     -- 	log.user("regions:", cs.name)
    --     -- end
    --     for _, reg in ipairs(custom_targets.regions) do
    --         table.insert(target_ranges, { left = reg.pos, right = reg.rgnend })
    --     end
    -- else
    --     -- 2. operator & motion
    --     if state_interface.last_command_has("timeline_operator") then
    --         local tl_range = state_interface.getKey("last_set_timeline_range")
    --         table.insert(target_ranges, {
    --             left = tl_range[1],
    --             right = tl_range[2],
    --         })
    --     else
    --         -- 3. cursor position
    --         local cursor_info = tl.get_cursor_info()
    --         table.insert(target_ranges, {
    --             left = cursor_info.msr.start,
    --             right = cursor_info.msr._end,
    --         })
    --     end
    -- end
    -- return target_ranges
end

return automation_actions
