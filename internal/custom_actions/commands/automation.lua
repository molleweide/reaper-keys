local log = require("utils.log")
local format = require("utils.format")
local tl = require("library.timeline")
local envelopes = require("library.envelopes")
local lib_tr = require("library.tracks")
local constants = require("constants.constants")
local fzf = require("library.fzf")
local pickers = require("pickers.pickers")
local lib_items = require("library.items")
local effects = require("library.fx")

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

    local range_left, range_right

    -- TODO: check for selector also

    if state_interface.last_command_has("timeline_operator") then
        local tl_range = state_interface.getKey("last_set_timeline_range")
        range_left = tl_range[1]
        range_right = tl_range[2]

        if range_left > range_right then
            range_left, range_right = range_right, range_left
        end

        log.user("[ picker insert cc curve ]: operator; range:", tl_range[1], tl_range[2])
    else
        log.user("[ picker insert cc curve ]: NOT op")
    end

    if not range_left or not range_right then
        return
    end

    local focused_track_objects, _, context = lib_tr.get_focused_track_objects()

    log.user("state.context = ", format.block(context))

    local is_main, is_midi
    local target_midi_take
    local trobj = focused_track_objects[1]

    if not trobj then
        return
    end

    -- Check if there are possible midi take targets
    if context == "main" then
        is_main = true
        local enclosing_item = lib_items.get_item_enclosing_range(trobj.tr, range_left, range_right)

        log.user("items_in_range =", format.block(enclosing_item))

        if enclosing_item then
            local take = reaper.GetMediaItemTake(enclosing_item.ref, 0)
            target_midi_take = reaper.TakeIsMIDI(take) and take
        end
        log.user("items_in_range = ", format.block(enclosing_item))
    elseif context == "midi" then
        is_midi = true
        local ret, ctxm = require("library.midi_editor").getMidiValidContext()
        target_midi_take = ret and ctxm.take
    end

    --
    --

    local t_curve_results = {
        { name = "(env) Volume", code = "volume" },
        { name = "(env) Pan", code = "pan" },
    }

    -- Vol/Pan should always be visible here.

    if target_midi_take then
        table.insert(t_curve_results, {
            name = "(midi) Pitch",
            code = "pitch_bend",
            cc = true,
        })
        table.insert(t_curve_results, {
            name = "(midi) CC20",
            code = "cc_20",
            cc = true,
        })
    end

    --  If focused track has FX that allow for user envelopes -> add to list.

    local fltr_track_fx = effects.fltr_fx_track_single({
        target_track = trobj.tr,
        filter = function(fx)
            -- ensure we dont collect any syntax-fx pre/post fx
            return fx.name:match("_A_") == nil
        end,
    })

    log.user("fltr_track_fx ->", format.block(fltr_track_fx))
    local there_are_env_enabled_fx = false

    if #fltr_track_fx > 0 then
        there_are_env_enabled_fx = true
    end

    if there_are_env_enabled_fx then
        for _, x in ipairs(fltr_track_fx) do
            table.insert(t_curve_results, {
                name = string.format("(fx) [name = {%s} | pname = {%s}]", x.name, x.pname),
                custom_next_menu = function()
                    log.user("Call FX PARAMS ficker that in turn calls the env temp picker.")
                end,
            })
        end
    end

    -- TODO: Route envelopes
    --

    local function picker_curve_menu_start()
        fzf.init({
            title = "Picker: Curve menu start",
            results = t_curve_results,
            x = 200,
            width = 900,
            height = 600,
            on_select_func = function(gui)
                local sel = gui:get_on_enter_selection()
                log.user(format.block(sel))
                if sel.custom_next_menu and type(sel.custom_next_menu) == "function" then
                    sel.custom_next_menu()
                else
                    pickers.envelope_templates()
                end
                return false
            end,
            results_filter = "name",
            sort_comp = "name",
            entry_maker = "name",
        })
    end

    picker_curve_menu_start()
end

return automation_actions
