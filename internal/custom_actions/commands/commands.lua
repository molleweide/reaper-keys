local log = require("utils.log")
local format = require("utils.format")
local pickers = require("pickers.pickers")
local lib_tr = require("library.tracks")
local s = require("utils.string")
local tl = require("library.timeline")
local containers = require("library.items")
local segments = require("library.segments")
local marks = require("library.marks")
local route = require("library.routing")
local preferences = require("utils.preferences")

local midi_utils = require("utils.midi_toolkit_funcs")

local fzf = require("library.fzf")

local fxu = require("library.fx")
local tbl = require("utils.table")

local project_state = require("utils.project_state")

local midi = require("library.midi")
local midi_editor = require("library.midi_editor")

local commands = {}

--
-- NOTE: I need to revise everything here and see what I can refactor into
-- lib modules.
--

commands.MIDI_ChangeActiveSelection = function(meta, opts)
    pickers.all_tracks(_, {
        title = "jump to track midi",
        filter = "MCS", -- filter track_obj.class = [MCS]
        next = function(_, data)
            midi_editor.createEditMidiItemAtPositionForTrack(_, data.selection)
        end,
    })
end

commands.MIDI_EditMidiAtCurPosForTrack = function()
    local log = require("utils.log")
    local format = require("utils.format")

    -- this function could be renamed to `get_rk_context()` and return all possible
    -- useful information.
    local focused_track_objects, _, context = lib_tr.get_focused_track_objects()

    if context == "main" then
        local focus_track_obj = focused_track_objects[1]
        log.user(">>>", focus_track_obj)
        midi_editor.createEditMidiItemAtPositionForTrack(_, focus_track_obj)
    end
end

commands.Midi_EditMidiForRegionsMarksAndSelectTrack = function(meta, opts)
    local function me_select_reg_and_edit_track(not_first)
        pickers.marks_and_regions(_, {
            title = "ME: 1. select regions/marks; 2. select track edit",
            filter = "MCS",
            next = function(_, data)
                -- log.user("selection data", format.block(data))
                local mark_sel = data.selection
                pickers.all_tracks(meta, {
                    filter = "MCS",
                    -- FIX: use on_select_func instead here
                    next = function(_, data2)
                        -- log.user("selection data2", format.block(data2), "sel mark->", format.block(data))
                        require("library.midi_editor").createEditMidiItemAtPositionForTrack(
                            _,
                            data2.selection,
                            mark_sel.left,
                            mark_sel.right
                        )
                        reaper.SetEditCurPos(mark_sel.left, false, false)
                    end,
                    extended_mappings = {
                        ["C-z"] = function()
                            me_select_reg_and_edit_track(true)
                        end,
                    },
                })
            end,
        })
    end

    me_select_reg_and_edit_track()
end

commands.MidiEditor_go_insert = function(meta, opts)
    midi.jump_to_position_and_insert_by_string()
end

-- TODO: when running fx_picker on a CHANNESPLITTER, then I should first
-- be prompted to select which S subtrack, etc, etc. so that I can mix/modify
-- all subtracks, from within, eg, ME when editing a larger screenset of
-- MC tracks within a group.

commands.picker_first_eq_on_focused_track = function()
    local focused_track_objects, _, context = lib_tr.get_focused_track_objects()
    local tr_node = focused_track_objects[1]
    local eq_instance = fxu.get_fx_objs_by_name_string(tr_node.guid, "ReaEQ")

    log.user("EQ INSTANCE:", format.block(tr_node.tr), format.block(eq_instance))

    -- Add EQ if doesn't exist.
    if eq_instance then
        pickers.track_fx_params(_, { node = tr_node, fx_index = eq_instance.idx })
    end
end
commands.picker_first_comp_on_focused_track = function()
    local focused_track_objects, _, context = lib_tr.get_focused_track_objects()
    local tr_node = focused_track_objects[1]
    local comp_instance = fxu.get_fx_objs_by_name_string(tr_node.guid, "ReaComp")
    log.user("EQ INSTANCE:", format.block(comp_instance))
    if comp_instance then
        pickers.track_fx_params(_, { node = tr_node, fx_index = comp_instance.idx })
    end
end

commands.add_track_nodes_ui = function(_, opts)
    fzf.init({
        title = "Add track nodes",
        x = 200,
        width = 1100,
        height = 75,
        on_select_func = function(self)
            local _, main_input = tbl.findIndexOf(GUI.controls, "title", "main_input")
            if main_input then
                local ret, data = require("library.add_node_string").handle_add_nodes_string(main_input.value)
                return ret
            end
            return true
        end,
    })
end

-- local function check_if_item_exists_or_create(track, check_start_pos, check_end_pos)
--     local items_found = containers.get_track_items_that_span_cursor_pos(track, check_start_pos, check_end_pos)
--     local target_item
--     if items_found then
--         target_item = items_found[1].ref
--     else
--         target_item = containers.create_new_item(true, track, check_start_pos, check_end_pos)
--     end
--     return target_item
-- end

-- NOTE:
-- A. Initially, this should only work on the focused track selection.
--    >>> Later, add ability to target specific tracks.
--    --
-- B. Specify how long / repetitions for a given insertion.
--    --
-- C. Depending on which group is targetted, default octave change,
--    eg. bass = 1, comp = 3, lead = 4
--    >>> Create a file called definitions/rendering.lua/octave_map.lu where I
--    specify information on a zone/group basis for how things should be
--    handled when auto generating.
--
commands.main_insert_midi_block_from_string_UI = function()
    local focused_track_objects, _, context = lib_tr.get_focused_track_objects()
    if context ~= "main" then
        return
    end
    local cursor_info = tl.get_cursor_info()
    local focus_track_obj = focused_track_objects[1]
    local check_start_pos = cursor_info.msr.start
    local check_end_pos = cursor_info.msr._end

    local items_found =
        containers.get_track_items_that_span_cursor_pos(focus_track_obj.tr, check_start_pos, check_end_pos)

    -- log.user(">>>", focus_track_obj)
    -- midi_editor.createEditMidiItemAtPositionForTrack(_, focus_track_obj)

    local function handle_midi_string(insert_midi_str)
        log.user("MIDI BLOCK STRING:", insert_midi_str)
        local return_code = true
        local ok, t_final_rendered_notes = midi.parse_and_render_midi_notes_block_from_string(insert_midi_str)
        local target_item
        if items_found then
            target_item = items_found[1].ref
        else
            target_item = containers.create_new_item(true, focus_track_obj.tr, check_start_pos, check_end_pos)
        end
        -- FIX: use transform api
        midi.insert_notes({
            item = target_item,
            notes = t_final_rendered_notes,
        })
        -- log.user(format.block(t_patterns_state))
        -- log.user(format.block(t_pattern_midi_notes))
        return return_code
    end

    -- TODO: move this into pickers file as `pickers.basic_text_prompt`
    fzf.init({
        title = "Add MIDI blocks",
        x = 200,
        width = 1100,
        height = 75,
        on_select_func = function(gui)
            local _, main_input = gui:controlGetByName("main_input")
            if main_input then
                local ret, data = require("library.apply_music_transform").apply_patterns_to_sel_tracks({
                    prompt_str = main_input.value,
                })
                return ret
            end
            return true
        end,
    })
end

-- TODO: make this default bindings
--
-- FIX: only pass `gui` to bindings functions!!
local em = {
    ["C-s"] = function(t)
        local selection = t.gui_ref.t_search_results[t.sel_idx]
        selection.selected = true
        t.gui_ref:add_to_current_selection(selection)
        -- log.user("--- sel cur names ----")
        -- for _, cs in ipairs(t.gui_ref.selection_current) do
        --   log.user(cs.name)
        -- end
    end,
    ["C-a"] = function(t)
        t.gui_ref:reset_current_selection()
    end,
    -- [] = select all visible/filtered items
}

commands.apply_patterns_across_tracks = function()
    local function prompt()
        fzf.init({
            title = "Add MIDI blocks",
            x = 200,
            width = 1100,
            height = 75,
            on_select_func = function(gui)
                local _, main_input = gui:controlGetByName("main_input")
                if main_input then
                    local ret, data = require("library.apply_music_transform").apply_patterns_to_sel_tracks({
                        targets = gui:selection_history_find("tracks"),
                        prompt_str = main_input.value,
                    })
                    return ret
                end
                return true
            end,
        })
    end

    local function tracks()
        local tag = "tracks"
        pickers.all_tracks(_, {
            title = "Select track(s) for prompt insertion.",
            width = 900,
            filter = "M", -- filter nodes
            on_select_func = function(gui)
                if gui:has_mult_select() then
                    gui:selection_history_push(tag, gui:get_mult_select())
                else
                    gui:selection_history_push(tag, { gui:get_on_enter_selection() })
                end
                prompt()
            end,
            extended_mappings = em,
        })
    end

    tracks()
end

commands.apply_patterns_across_sel_REGIONS_and_TRACKS = function(meta, opts)
    local function prompt()
        fzf.init({
            title = "Add MIDI blocks",
            x = 200,
            width = 1100,
            height = 75,
            on_select_func = function(gui)
                local _, main_input = gui:controlGetByName("main_input")
                if main_input then
                    local ret, data = require("library.apply_music_transform").apply_patterns_to_sel_tracks({
                        targets = gui:selection_history_get_tags(),
                        prompt_str = main_input.value,
                    })
                    return ret
                end
                return true
            end,
        })
    end

    -- NOTE: maybe these types of "tags" name CONSTANTS should be kept in a dedicated
    -- file for security so I dont mess thigs up.

    local function tracks()
        local tag = "tracks"
        pickers.all_tracks(_, {
            title = "Select track(s) for prompt insertion.",
            width = 900,
            filter = "M", -- filter nodes
            on_select_func = function(gui)
                -- gui:log_current_selection()
                log.user("length current sel:", #gui.selection_current)

                if gui:has_mult_select() then
                    gui:selection_history_push(tag, gui:get_mult_select())
                else
                    gui:selection_history_push(tag, { gui:get_on_enter_selection() })
                end
                prompt()
            end,
            extended_mappings = em,
        })
    end

    local function regions()
        local tag = "regions"
        pickers.regions(_, {
            title = "REGIONS -> TRACKS -> PROMPT",
            x = 200,
            width = 800,
            height = 600,
            on_select_func = function(gui)
                if gui:has_mult_select() then
                    gui:selection_history_push(tag, gui:get_mult_select())
                else
                    gui:selection_history_push(tag, { gui:get_on_enter_selection() })
                end
                -- gui:log_selection_history_by_key(tag)
                tracks()
            end,
            extended_mappings = em,
        })
    end

    regions()
end

-- TODO:
-- ~ Connect this with the command/parser from above `main_insert_midi_block_from_string_UI`
-- ~ Chain pickers [ SelectRegion->Prompt ]
--
-- - Add ability to randomize some type of parameter change every N bars, so that
--   the listener always percieves that "stuff" is happening.
--
--
commands.MIDI_insert_fill_region = function()
    --
end

-- Create a UI that allows me to CRUD meta/macro info for a project so
-- that this will be used later when rendering, eg. regions from project
-- info.
commands.project_patterns_and_harmony_manager = function()
    -- ALL THEMES
    -- keybind -> add theme
    --     (a theme is a set of information that can be used as base input when
    --     rendering sections)
    --
    -- keybind -> add theme
    --         -> edit theme
    --         -> remove theme
    --         -> enter theme (SINGLE THEME)
    --
    -- SINGLE THEME
    -- keybind -> add entry
    --         -> edit entry
    --         -> delete entry
    --
    -- A theme should have
    -- rhythm patterns
    -- bass patterns
    -- comp patterns
    -- lead patterns
    -- fx/bkg
    -- key/center
    -- harmony / chord progression
end

-- ::: REGION UI :::
--
-- This one is going to be fun to build, since this allows me to sketch out
-- structure easilly and play around with copying songs.
--
commands.regions_manager_fuzzy_ui = function(meta, opts)
    -- TODO: CRUD ui that allows me to manage regions easilly.
    --
    -- >> on each key press -> reparse the commandline string,
    -- so that I can preview everything that I am typing.
    --
    -- NOTE: this will be very interesting because it gives me a convenient
    -- global way of managing the tracks.
    -- With this i could again create a simple DSL, that allows me to
    -- control what should happen with regions and structuring tracks.
    --
    -- this is a lot of fun and I just cant wait to understand what will
    -- happen in a couple of months now that this music engine is getting
    -- finalized, and that is pretty fucking cool. it is not something that
    -- i will be able to show him. this is going to be fucking amazing.
    --
    -- so i haven't really had time to get to use this very much
    --
    -- there is something about the undo works.
    --
    local _, ui_str = reaper.GetUserInputs("REGIONS UI:", 1, "regions string:", "")

    local input_units = s.split(ui_str, "/")

    -- TEST: delete region -> if region contains item data -> user will be prompted
    -- "Region contains item data - Are you sure you want to proceed? (Y/n)"
end

-- TEST: Later, this should be modified to create a MIDI edit SCREENSET from
-- the group selection screenset.
commands.MIDI_picker_edit_tracks_CHAIN_region_and_group = function()
    -- 1. first select region.
    -- 2. then, select which Group,
    -- 3. then, select track.
end

commands.MIDI_picker_tracks_edit_existing_items_at_cursor = function() end

commands.routing_user_string = function()
    log.clear()
    log.user("ROUTING USER STRING PROMPT")

    pickers.basic_prompt({
        title = "Do route string, eg. [todo example]",
        x = -177,
        height = 700,
        width = 700,
        callback = function(prompt_string)
            -- route.updateState(prompt_string)
            -- return true
            log.user("!!! working on routing prompt previewers -> dry running only..")
        end,
        -- 1. Config table -> passed to make_previewer function
        -- 2. Return the previewer_func that is run for each loop update.
        context_helpers = {
            {
                on_key_press = true,
                position = "left",
                width = "500",
                func = function(gui, prompt_str, elem)
                    local rc = route.updateState(prompt_str, false, false, true)
                    -- log.user("`L CXH: `" .. prompt_str .. "`-> `", format.block(rc.new_params))

                    local str = ""

                    str = str .. string.format("-- %s -----------------------\n", "SRC GUIDS")

                    if #rc.src_guids > 0 then
                        for i, s in ipairs(rc.src_guids) do
                            str = str .. "    " .. s.name .. "\n"
                        end
                    end

                    elem.label = str --format.block(rc)
                end,
            },
            {
                on_key_press = true,
                position = "right",
                width = "500",
                func = function(gui, prompt_str, elem)
                    local rc = route.updateState(prompt_str, false, false, true)

                    -- log.user(prompt_str, ">>", format.block(rc.dst_guids))
                    elem.label = format.block(rc.dst_guids)
                end,
            },
        },
    })
end

local function get_focus_track_with_fx_chain_info()
    local focused_track_objects, _, context = lib_tr.get_focused_track_objects()
    local tr_node = focused_track_objects[1]
    local fx_results = fxu.get_track_fx_chain_info(tr_node.tr)
    return tr_node, fx_results
end

commands.track_fx_ui = function(meta, opts)
    local tr_node, fx_results = get_focus_track_with_fx_chain_info()

    -- log.user("# # # # # # # # # # # ")
    -- log.user(format.block(fx_results))

    local function track_fx_ui(not_first)
        pickers.track_fx(_, {
            master_title = "TRACK FX UI",
            results = fx_results,
            next_is_picker = not_first and false or true,
            next = function(meta, data, self)
                local t_fx_params = fxu.get_track_fx_info(tr_node.tr, data.selection.idx)
                pickers.track_fx_params(_, {
                    node = tr_node,
                    fx_index = data.selection.idx,
                    results = t_fx_params.parameters,
                    sort_comp = require("pickers.sorters.default")("name"),
                    entry_maker = require("pickers.entry_makers.fx_parameters"),
                    extended_mappings = {
                        ["C-z"] = function()
                            track_fx_ui(true)
                        end,
                    },
                })
            end,
        })
    end

    track_fx_ui()
end

--
-- TODO: the purpose of this command is to make it easy to MIX the current
-- region during live playback.
--
commands.picker_all_tracks_THAT_have_active_items_in_CURRENT_region = function() end

--
-- TODO: the purpose of this command is to make it easy to MIX the next
-- region during live playback so that I can apply some crazy filters
-- to prepare an interesting section coming up.
--
commands.picker_all_tracks_THAT_have_active_items_in_NEXT_region = function() end

-- A. Base picker it `all tracks`
-- B. on_select -> open attributes for selected track
-- C. If `multiple selection`, then with key binds I can batch toggle.
--
-- D. Eg. `hiding` on a branch-node will also hide all contained nodes.
--
-- E. I can pretty much reuse the FX mixing keybinds for controlling
--      track attributes/parameters
--
-- F. combine!! channel_mix_params && track_attributes
--
commands.track_manager_ui = function()
    -- 1. put together all of the `result` properties.
    --     Compile nice sub-tables with all necessary info.
    -- 2.

    local function track_manager(not_first)
        pickers.track_fx(_, {
            master_title = "TRACK MANAGER: [ATTRS/PARAMS]",
            results = {},
            next = function(meta, data, self)
                -- local t_fx_params = fxu.get_track_fx_info(tr_node.tr, data.selection.idx)
                pickers.track_attributes_and_params(_, {
                    -- node = tr_node,
                    -- fx_index = data.selection.idx,
                    results = {},
                    -- sort_comp = require("pickers.sorters.default")("name"),
                    -- entry_maker = require("pickers.entry_makers.fx_parameters"),
                    extended_mappings = {
                        ["C-z"] = function()
                            track_manager(true)
                        end,
                    },
                })
            end,
        })
    end

    track_manager()
end

-- Move this to pickers main file later..
commands.rk_master_menu = function()
    local fzf = require("library.fzf")

    -- NOTE: Make this the most comprehensive actions menu ever,

    -- TODO: Navigate around this tree recursively for the menu.
    local rk_main_menu = {
        preferences = {
            audio_devices = {},
            midi_devices = {},
            buffering = {},
        },
        tracks = {
            add_new_tracks = {},
            remove_tracks = {},
        },
        { name = "regions" },
        { name = "automation" },
        { name = "tempo" },
        { name = "samples" },
        { name = "audio_file_loops" },
    }

    local rk_main_prefs = {
        "audio devices",
        "midi devices",
        "buffering",
    }
    local rk_main_tracks = {
        "add new tracks",
        "remove tracks",
        "hide tracks",
    }
    local rk_main_regions = {
        "add region",
        "extend regions",
        "rename regions",
    }
    local rk_main_automation = {
        "add auto",
        "extend auto",
        "rename auto",
    }
    local rk_main_tempo = {
        "add tempo",
        "extend tempo",
        "rename tempo",
    }
    local rk_main_samples = {
        "open sample library",
        "preview samples",
    }
    local rk_main_loops = {
        "open loops",
        "preview loops",
    }

    fzf.init({
        title = "RK MAIN MENU",
        width = 500,
        height = 700,
        x = 0,
        y = 1100,
        results = rk_main_menu,
        on_select_func = false,
        sort_comp = "name",
        entry_maker = "name",
        -- attach_mappings = require("pickers.attach_mappings.fx_parameters"),
        -- extended_mappings = opts.extended_mappings or nil,
    })
end

commands.automation_ui = function()
    local rk_main_menu = {
        { name = "ramp up" },
        { name = "ramp down" },
        { name = "flat bar" },
    }

    fzf.init({
        title = "AUTOMATION UI",
        width = 500,
        height = 700,
        x = 0,
        y = 1100,
        results = rk_main_menu,
        on_select_func = false,
        sort_comp = "name",
        entry_maker = "name",
        -- attach_mappings = require("pickers.attach_mappings.fx_parameters"),
        -- extended_mappings = opts.extended_mappings or nil,
    })
end

commands.master_prompt = function()
    -- text field that has basic vim bindings implemented.
    -- maybe i could just reuse the current state machine implementation
    -- and check if the context is main / midi / or jgui_norm
    --
    --
    -- ooh if i just add a new context, then i can always access modality
    -- from within the jgui
    --
    -- TODO: create a default switch command, that sets a flag inside
    -- jgui, that determines wether `insert_mode = true`.
    --
    -- If `insert_mode` -> that means that we just allow all keys to pass
    --    >>> if `esc switch` then we toggle the switch to false.
    --
    -- If FALSE, then we pass every key through the state_machine,
    -- and each ASF will then operate on the gui.text_field input, and
    -- apply all actions to the gui.text_field.
    --
    -- This would allow me to further refactor the core and allow the project
    -- to be even more modular.

    -- TODO: IMPORTANT
    --       There needs to be a `Proceed` prompt that clearly states what will
    --       be done to a project, so that you know for sure what will happen
    --       when executing the prompt.
end

commands.MIDI_AI_PROMPT = function()
    -- TODO: play around with a base promt that ensures we get data correctly
    -- formatted so that I can be confident that the AI always returns the
    -- correct type of info
    -- --
    -- I need to create a file-spec for how each type of data information should
    -- be formatted by the AI. This spec explanation will always be injected
    -- before the user-prompt so that an AI prompt always will give it all necessary
    -- details.
end

commands.midi_substitute = function()
    --
    -- Todo: Make a command that mirror's vim's substitute command,
    --
    -- {target|range} / {filter|match_pattern|midi_regex} / {transform|apply} / {flags}
    --
    -- Todo: Custom previewer that allows one to have very detailed knowledge
    -- of what tracks will be targeted.
end

commands.UI_add_new_regions = function()
    -- NOTE: There is already `regions_manager_fuzzy_ui` above.
    -- BUT I think the idea here was to select regions with picker to
    -- add multiple regions at once.
end

-- NOTE: I can reduce everything here into one command by checking for
-- the usual suspect chars.
-- -> Default: Insert after current region.
-- -> If find `-` then insert before.
-- -> If $, then insert region at project project end.
-- -> If ^, then insert region at beginning.

-- TODO: check for a char at the -> move cursor to new region?

-- fix: the timeline selection moves wierdly when

commands.insert_new_region_prompt = function()
    local marks = require("library.marks")
    pickers.basic_prompt({
        title = "Add region AFTER current",
        callback = function(prompt_string)
            local region_opts = require("library.parsers.create_new_region")(prompt_string)

            local regions_data = segments.compute_new_regions_data_for_insertion(region_opts)

            -- log.user("rd", format.block(regions_data))

            segments.inject_new_empty_region(regions_data[1])

            return true
        end,
    })
end

commands.add_song_structure_at_cursor = function()
    local st = require("definitions.project_region_templates")

    -- log.debug(format.block(all_chords))

    fzf.init({
        title = "Add song structure at cursor",
        results = st,
        on_select_func = function(self, i)
            local sel_st = self.t_search_results[i]

            for i, part in ipairs(sel_st.regions) do
                local region_opts = require("library.parsers.create_new_region")(part)

                local regions_data = segments.compute_new_regions_data_for_insertion(region_opts)

                -- log.user("rd", format.block(regions_data))

                marks.create(regions_data[1])
            end
            -- segments.inject_new_empty_region(regions_data[1])

            return true
        end,
        results_filter = "name",
        sort_comp = "name",
        -- chords picker should also display the step-array last in a nice manner.
        entry_maker = "name",
    })
end

commands.inject_song_structure_at_cursor = function() end

local function prompt_pattern_and_apply_region_manually(reg, reg_opts)
    log.user("REG:", format.block(reg))

    fzf.init({
        title = "Music apply pattern",
        x = 200,
        width = 1100,
        height = 75,
        on_select_func = function(gui)
            local _, main_input = gui:controlGetByName("main_input")
            if main_input then
                local picker_tags = gui:selection_history_get_tags()
                picker_tags["regions"] = { reg }
                local ret, data = require("library.apply_music_transform").apply_patterns_to_sel_tracks({
                    targets = picker_tags,
                    prompt_str = main_input.value,
                    add_new_region_opts = reg_opts or nil,
                })
                return ret
            end
            return true
        end,
    })
end

local function picker_select_tracks_for_insert_pattern_to_region(reg, pattern_prompt, reg_opts)
    local tag = "tracks"
    pickers.all_tracks(_, {
        title = "Select track(s) for prompt insertion.",
        width = 900,
        filter = "M", -- filter nodes
        on_select_func = function(gui)
            -- TODO: this if statement could be moved to inside jgui so that I only
            -- configure the current picker with the "tag", name and the rest is
            -- handled inside the picker.
            if gui:has_mult_select() then
                gui:selection_history_push(tag, gui:get_mult_select())
            else
                gui:selection_history_push(tag, { gui:get_on_enter_selection() })
            end
            pattern_prompt(reg, reg_opts)
        end,
        extended_mappings = em,
    })
end

commands.add_patterns_to_current_region = function()
    local current_region_ref = marks.get_nth_region_for_pos(false, 0)

    log.user("add_patterns_to_current_region:", format.block(current_region_ref))

    if not current_region_ref then
        log.user("no region!!!!")
        return
    end
    picker_select_tracks_for_insert_pattern_to_region(current_region_ref, prompt_pattern_and_apply_region_manually)
end

commands.add_patterns_next_region = function()
    local current_region_ref = marks.get_nth_region_for_pos(false, 1)
    log.user("add_patterns_next_region:", format.block(current_region_ref))
    if not current_region_ref then
        log.user("no region!!!!")
        return
    end
    picker_select_tracks_for_insert_pattern_to_region(current_region_ref, prompt_pattern_and_apply_region_manually)
end

commands.add_patterns_nth_region = function()
    -- Same as above but with nth region from current region
end

-- 00. add prefix count to actions
--        >>>> this will require adding a new action option called `prefixParam`, that
--        implements passing down the count param in `meta` so that it can
--        be used for selecting region N/-N
-- 0. get count number
-- log.user("meta", format.block(meta))
commands.Inject_Region_W_Pattern_After_Nth_Region = function(meta, opts)
    -- Get/prepare table with the the Nth regions
    local find_region = marks.get_nth_region_for_pos(false, 0)
    if not find_region then
        return
    end
    local regions_target_after = { find_region }

    local opts_region = {
        name_string = nil,
        after_current = true, -- inject new region after target region - `_current` is misleading..
        register = nil,
        num_measures = 2, -- should default to same length as previous??
    }

    -- Prepare/create new regions data from opts table.
    -- local new_regions_data = segments.compute_new_regions_data_for_insertion(opts_region, regions_target_after)

    -- log.user(">>>X", format.block(new_regions_data[1]))

    -- segments.inject_new_empty_region(new_regions_data[1])

    -- log.user(">>>", format.block(new_regions_data[1]))

    -- TODO: revise how this was done for multiple regions.
    -- 1. Document region string parsing.
    picker_select_tracks_for_insert_pattern_to_region(
        find_region,
        prompt_pattern_and_apply_region_manually,
        opts_region
    )

    -- 5. refactor into lib module
end

-- same as above BUT:
-- i. make the count variable negative.
-- ii. insert after or before region N?
--         >>>> add ability to re-specify before/after
commands.Inject_Region_W_Pattern_Before_Nth_Region_before = function() end

-- TODO: Picker select region(s) || input count or default -> double region
-- so that I can specify exactly which region to double from anywhere.
--
-- TODO: implement but using timeselection instead of looping over all project
-- items to filter out target items
commands.double_the_length_of_nth_region = function()
    -- should this be replaced with a fltr call later???
    local find_region = marks.get_nth_region_for_pos(false, 0)

    if not find_region then
        log.debug("No region found in [commands.double_the_length_of_nth_region()]")
        return
    end
    local reg_start, reg_end = find_region.pos, find_region.rgnend
    local length_time = reg_end - reg_start

    ---------------------------------------------------------------------------
    -- Method A: filter items within TL manually
    local items_in_region = require("library.items").all_project_items_filter_transform({
        get_type = "content",
        filter = {
            range = { reg_start, reg_end },
        },
    })
    -- Method B: get items in TL by leveraging get/set timeline
    -- TEST: see if this has better performance.
    ---------------------------------------------------------------------------
    -- note: if the region is the last one in proj -> we dont need to inject space...
    segments.inject_space_at_range(reg_end, reg_end + length_time)
    segments.duplicate_items(items_in_region, length_time)

    -- TEST: extend the length of region N

    -- Explanation: i know which region to target, so I only need to pass it along, and then
    -- specify which parameter to transform and to what by key value mapping of
    -- the parameter.
    marks.filter_transform_project_regions({
        target_region = { find_region },
        transform = {
            -- length_time is a number so it will be added to the orig number
            rgnend = length_time,
        },
    })

    -- ...
    -- future: take this function and allow for passing a "multiplier" float number, so
    --         that one can increase length by eg. 50% (ie. multiply length by 1.5)
    --         and make 16 bars -> 24...
    --
    --
    --         >>> make current region 0.25
    --
    --         >>> make current region 2.5
end

-- NOTE: This function repeats the selected region data once sequentially.
commands.picker_copy_sel_tracks_items_from_current_region_to_next_region = function()
    -- In current region
    --     picker tracks with items in current region
    --     >>>>> This just means implementing a new filter for the picker.
    --           Just search for `opts.filter` in pickers.pickers
    --         --
    --         selection -> duplicate item data to next region,
    --
    local find_region = marks.get_nth_region_for_pos(false, 0)
    if not find_region then
        log.debug("No region found in [commands.picker_copy_sel_tracks_items_from_current_region_to_next_region()]")
        return
    end
    local reg_start, reg_end = find_region.pos, find_region.rgnend
    local length_time = reg_end - reg_start
    pickers.all_tracks(_, {
        width = 900,
        filter = function(o)
            return s.strHasOneOfChars(o.class, "MCS")
                and lib_tr.has_items_within_timeline_range(o, find_region.pos, find_region.rgnend)
        end,
        on_select_func = function(gui, i)
            local selection = gui.t_search_results[i]
            if gui:has_mult_select() then
                selection = gui:get_mult_select()
            else
                selection = { gui:get_on_enter_selection() }
            end
            local ts = {}
            for _, to in ipairs(selection) do
                table.insert(ts, to.name)
            end
            log.user("sel tr:", format.block(ts))

            -- HACK: I would like to do:
            -- pickers.all_tracks(_, {
            --   width = 900,
            --   fltr = {
            --       class = { "M", "C", "S"}, -- or "MCS"
            --       items = {
            --           within = { range_start, range_end }
            --       }
            --   }
            local items_in_region_for_tracks = require("library.items").all_project_items_filter_transform({
                get_type = "content",
                filter = {
                    range = { reg_start, reg_end },
                    of_tracks = selection,
                },
            })

            segments.duplicate_items(items_in_region, length_time)

            return true
        end,
        extended_mappings = em,
    })
end

commands.picker_ui_select_region_to_insert_at_cursor = function()
    -- TODO: 1. select a region via picker
    -- 2. `/{N}` parse this from the prompt string.
    -- 3. Insert region data N times at cursor.
end

commands.picker_scale_regions_by_multiplyer = function()
    -- TODO: allow for scaling up or down a region by multiplyer,
    -- ie.  pars `/{N}.{M}` from the end of the prompt string,
    -- ->> use this number to scale the region.
end

--
-- ROUTING
--

commands.picker_list_routes_for_track = function()
    -- log.user("::: route list for track :::")
    -- local tr = reaper.GetSelectedTrack(0, 0)
    -- local tr_routes = route.get_route_object_for_track(tr)
    -- log.user(format.block(tr_routes))
    --
    -- fzf.init({
    --   title = "Track routes",
    --   results = tr_routes,
    --   on_select_func = function(gui)
    --     return true
    --   end,
    --   sort_comp = "other_tr_name",
    --   results_filter = "other_tr_name",
    --
    --   -- TODO: add zone/group name before each track name
    --   -- entry_maker = require("pickers.entry_makers.track_nodes"),
    --   entry_maker = { "index", "type", "other_tr_idx", "other_tr_name" },
    -- })
    pickers.single_track_routes()
end

commands.picker_list_all_sends_for_all_tracks = function()
    log.user("::: Routing: List all `sends` in project :::")
end

commands.open_route_ui = function(meta, opts)
    log.user("::: route ui :::")

    -- NOTE: brainstorm UI idea: what should this UI do?
    -- 1. open prompt -> input route opts
    -- 2. on <CR> switch to picker source selection
    -- 3. on <CR> switch to dest selection
    -- 4. on <tab> -> switch to route opts string to continue editing it.
    -- 5. create NEW gui window for sources ON LEFT side
    -- 6. create NEW gui window for dest ON RIGHT side
    -- 7. Add binding confirm and apply current route configuration
    -- 8. Run updateState()
end

commands.picker_select_anything = function()
    -- NOTE: Create a picker where I can select from a list anything possible
    -- in reaper to list, and then put me through a UI pipeline that allows me
    -- to filter and narrow down any type of selection.

    local categories = {
        "tracks",
        "items",
        "takes",
        "routes",
        "fx",
        "envelopes",
        "regions",
        "marks",
    }
end

commands.picker_select_position_midi_editor_UI = function()
    -- The final selection should be an item to jump to.
    --
    -- First filter down items in a specific sub section of a project,
    -- List items in this position,
    -- Jump to midi editor for editing the selection.
    -- if, it is an audio file jump to this audio file.
end

commands.picker_select_position_midi_editor_UI = function()
    -- The final selection should be an item to jump to.
    --
    -- First filter down items in a specific sub section of a project,
    -- List items in this position,
    -- Jump to midi editor for editing the selection.
    -- if, it is an audio file jump to this audio file.
end

commands.picker_midi_view_show_selected_group = function()
    -- TODO:
    --   - for target range in time line
    --   - check which group has midi items, and collect how many tracks/items
    --   - list group with numb tracks/items
    --   - on select -> make items within selected group visible in ME.
end

commands.rename_region_at_cursor = function()
    local find_region = marks.get_nth_region_for_pos(false, 0)

    if not find_region then
        return
    end

    -- TODO: marks.set_name_for_mark  mark/region
end

---Returns a table with the keys active, visible, and editable, which
---hosts the GUIDs for each category of tracks.
---@return table
local function get_midi_editor_item_and_track_state(hwnd)
    local t_tr_meta = {}
    local t_item_guids_meta = {}

    -- I need to do this with table keys instead

    local vis_guids = {}
    local t_all_vis_items = midi_editor.get_all_visible_items(hwnd)

    for i, item_v in ipairs(t_all_vis_items) do
        local item_v_guid = reaper.BR_GetMediaItemGUID(item_v)
        local tr = reaper.GetMediaItem_Track(item_v)
        local tr_guid = reaper.GetTrackGUID(tr)
        local _, tr_name = reaper.GetTrackName(tr)

        log.user(">>", tr_name, " #item =", i)

        if not vis_guids[tr_guid] then
            vis_guids[tr_guid] = true
        end

        local tr_guid_at_key = t_tr_meta[tr_guid]
        if not tr_guid_at_key then
            -- does not exist. creating...
            t_tr_meta[tr_guid] = {
                items = {
                    visible = { [item_v_guid] = item_v },
                    editable = {},
                },
            }
        else
            tr_guid_at_key.items.visible[item_v_guid] = item_v
        end

        t_item_guids_meta[item_v_guid] = {
            item = item_v,
            visible = true,
        }

        -- if not t_tr_meta[#t_tr_meta][tr_guid] then
        --     -- does not exist already
        --     table.insert(t_tr_meta, {
        --         guid = tr_guid,
        --         tr = tr,
        --         items = {
        --             visible = { item_v },
        --         },
        --     })
        -- else
        --     -- exists
        --     table.insert(t_tr_meta[#t_tr_meta].items.visible, item_v)
        -- end
    end

    local edit_guids = {}
    local t_all_editable_items = midi_editor.get_all_editable_items(hwnd)
    for _, item_e in ipairs(t_all_editable_items) do
        local item_e_guid = reaper.BR_GetMediaItemGUID(item_e)
        local tr = reaper.GetMediaItem_Track(item_e)
        local tr_guid = reaper.GetTrackGUID(tr)
        if not edit_guids[tr_guid] then
            edit_guids[tr_guid] = true
            vis_guids[tr_guid] = nil
        end

        local tr_guid_at_key = t_tr_meta[tr_guid]
        if not tr_guid_at_key then
            -- does not exist. creating with only editable...
            t_tr_meta[tr_guid] = {
                items = {
                    editable = { [item_e_guid] = item_e },
                },
            }
        else
            tr_guid_at_key.items.visible[item_e_guid] = nil
            tr_guid_at_key.items.editable[item_e_guid] = item_e
        end

        t_item_guids_meta[item_e_guid] = {
            item = item_e,
            visible = nil,
            editable = true,
        }
    end

    local axt = reaper.MIDIEditor_GetTake(hwnd)
    local axit = reaper.GetMediaItemTake_Item(axt)
    local active_take_track = reaper.GetMediaItem_Track(axit)
    local active_track_guid = reaper.GetTrackGUID(active_take_track)
    local item_a_guid = reaper.BR_GetMediaItemGUID(axit)
    edit_guids[active_track_guid] = nil

    local tr_guid_at_key = t_tr_meta[active_track_guid]
    if not tr_guid_at_key then
        -- does not exist. creating with only editable...
        t_tr_meta[active_track_guid] = {
            items = {
                active = axit, -- is it necessary to also assign item guid??
            },
        }
    else
        if tr_guid_at_key.items.visible then
            tr_guid_at_key.items.visible[active_track_guid] = nil
        end
        tr_guid_at_key.items.editable[active_track_guid] = nil
        tr_guid_at_key.items.active = axit
    end

    t_item_guids_meta[item_a_guid] = {
        item = axit,
        visible = nil,
        editable = nil,
        active = true,
    }

    return {
        active = active_track_guid,
        visible = vis_guids,
        editable = edit_guids,
        items = t_item_guids_meta,
        tracks = t_tr_meta,
    }
end

---Picker that allows you to manage what tracks are shown inside the current
---midi editor.
---It requires midi editor preference vars [editability linked] and [visibility
---linked] to be OFF/Disabled. Otherwise non active items will be auto removed
---upon next reaper GUI loop refresh.
commands.picker_midi_editor_add_track_to_view = function()
    local ME_EXISTS, ME = midi_editor.getMidiValidContext()
    if not ME_EXISTS then
        return
    end

    local sx = require("syntax.tracks")
    local sxu = require("syntax.utils")

    local vtt = sx.getVerifiedTree()

    log.clear()

    local state = get_midi_editor_item_and_track_state(ME.editor)

    local function assign_ME_states_to_picker_results()
        for _, tobj in ipairs(vtt.track_list) do
            if tobj.guid == state.active then
                tobj._midi_editor_active = true
            end
            for guid, _ in pairs(state.visible) do
                if tobj.guid == guid then
                    tobj._midi_editor_visible = true
                end
            end
            for guid, _ in pairs(state.editable) do
                if tobj.guid == guid then
                    tobj._midi_editor_editable = true
                end
            end
        end
    end
    assign_ME_states_to_picker_results()

    -- Helper to get selection in extended mappings.
    local function ext_map_get_sel(t)
        if t.gui_ref:has_mult_select() then
            return t.gui_ref:get_mult_select()
        else
            return { t.gui_ref.t_search_results[t.sel_idx] }
        end
    end

    local function make_target_items(ts, dont_create)
        local me_state = get_midi_editor_item_and_track_state(ME.editor)
        local t_items_at_pos = containers.ensure_tobjs_has_items_at_position(ts, dont_create)

        local target_items = {
            hidden = {},
            active = {},
            visible = {},
            editable = {},
        }
        for _, it in ipairs(t_items_at_pos) do
            local it_guid = reaper.BR_GetMediaItemGUID(it)
            -- t_map_item_guids_at_pos[it_guid] = it
            local it2 = me_state.items[it_guid]
            if it2 then
                if it2.active then
                    table.insert(target_items.active, it2.item)
                elseif it2.visible then
                    table.insert(target_items.visible, it2.item)
                elseif it2.editable then
                    table.insert(target_items.editable, it2.item)
                end
            else
                table.insert(target_items.hidden, it)
            end
        end
        return target_items
    end

    local function picker_me_tracks(show, opts)
        show = show or 0

        local use_column = false

        local function title_func()
            local str
            if show == 0 then
                str = "ALL"
                use_column = true
            elseif show == 1 then
                str = "VISIBLE"
            elseif show == 2 then
                str = "HIDDEN"
            end
            return string.format("MIDI EDITOR -> SOURCES: [%s]", str)
        end

        pickers.all_tracks(
            _,
            tbl.deep_extend({
                vtt = vtt,
                title = title_func(),
                width = 1100,
                height = 800,
                filter = function(tobj)
                    -- When "all/hidden", ensure that drum lane groups only list
                    -- the Group master track.
                    if show == 0 then
                        if (tobj.class == "M" or tobj.class == "C") and not sxu.trackObjHasOption(tobj.group, "m") then
                            return true
                        elseif tobj.class == "G" and sxu.trackObjHasOption(tobj, "m") then
                            return true
                        end
                    else
                        local has_visibility = tobj._midi_editor_active
                            or tobj._midi_editor_visible
                            or tobj._midi_editor_editable
                        if (show == 1 and has_visibility) or (show == 2 and not has_visibility) then
                            -- return true
                            if
                                (tobj.class == "M" or tobj.class == "C") and not sxu.trackObjHasOption(tobj.group, "m")
                            then
                                return true
                            elseif tobj.class == "G" and sxu.trackObjHasOption(tobj, "m") then
                                return true
                            end
                        end
                    end
                end,
                on_select_func = function(gui)
                    local t_items_to_add = containers.ensure_tobjs_has_items_at_position(gui:get_selection())
                    midi_editor.set_items_visible(ME.editor, t_items_to_add, true)
                    midi_editor.setActiveItem(ME.editor, t_items_to_add[1])
                    return true
                end,
                entry_maker = require("pickers.entry_makers.track_nodes_midi_editor_state"),
                extended_mappings = {
                    -- cycle listings filter
                    ["C-t"] = function()
                        picker_me_tracks((show + 1) % 3)
                    end,
                    -- set selection[0] active, unset previous
                    ["C-d"] = function(t)
                        local ts = ext_map_get_sel(t)
                        if ts[1]._midi_editor_active then
                            log.user("Cannot set already active, active again..")
                            return
                        end
                        for _, to in ipairs(vtt.track_list) do
                            -- reset prev ACTIVE
                            if to._midi_editor_active then
                                to._midi_editor_active = nil
                                to._midi_editor_visible = true
                            end
                            -- set new ACTIVE
                            if to.guid == ts[1].guid then
                                to._midi_editor_active = true
                            end
                        end
                        UPDATE_RESULTS = true
                        local t_items_to_add = containers.ensure_tobjs_has_items_at_position(ts)
                        midi_editor.setActiveItem(ME.editor, t_items_to_add[1])

                        t.gui_ref:setReaperFocus()
                    end,
                    -- make selection visible
                    ["C-a"] = function(t)
                        local ts = ext_map_get_sel(t)

                        -- This initial part is very similar for every mapping, it can
                        -- prolly be moved into a func.
                        for i = #ts, 1, -1 do
                            local tobj = ts[i]
                            if tobj._midi_editor_active then
                                log.user("Cannot change active item, you need to set a new active item instead.")
                                table.remove(ts, i)
                            elseif tobj._midi_editor_visible then
                                log.user("Already visible")
                                table.remove(ts, i)
                            -- Add more cases if necessary..
                            else
                                -- set tobj state of each affected track
                                tobj._midi_editor_visible = true
                                tobj._midi_editor_editable = nil
                            end
                        end

                        local target_items = make_target_items(ts)
                        midi_editor.set_items_visible_from_level(ME.editor, target_items.hidden, 0)
                        midi_editor.set_items_visible_from_level(ME.editor, target_items.editable, 2)
                        UPDATE_RESULTS = true
                        t.gui_ref:setReaperFocus()
                    end,
                    ["C-e"] = function(t)
                        local ts = ext_map_get_sel(t)
                        for i = #ts, 1, -1 do
                            local tobj = ts[i]
                            if tobj._midi_editor_active then
                                log.user("CANNOT CHANGE ACTIVE ITEM/TRACK")
                                table.remove(ts, i)
                            elseif tobj._midi_editor_editable then
                                log.user("ALREADY EDITABLE")
                                table.remove(ts, i)
                            -- Add more cases if necessary..
                            else
                                -- set tobj state of each affected track
                                tobj._midi_editor_editable = true
                                tobj._midi_editor_visible = nil
                            end
                        end

                        local target_items = make_target_items(ts)
                        UPDATE_RESULTS = true
                        midi_editor.set_items_editable_from_level(ME.editor, target_items.hidden, 0)
                        midi_editor.set_items_editable_from_level(ME.editor, target_items.visible, 1)
                        t.gui_ref:setReaperFocus()
                    end,
                    -- remove showing track.
                    -- TEST: Maybe `hiding` of items might be facilitaed by creating a custom
                    -- ME-temp-config for when wanting to batch hide many items, so that I
                    -- only need to run "one" midi editor function for each action, instead
                    -- of now chaining midi editor actions to hide eg "editable" items,
                    -- which might be what is causing the focus-shift or losing focus.
                    ["C-u"] = function(t)
                        local ts = ext_map_get_sel(t)
                        for i = #ts, 1, -1 do
                            local tobj = ts[i]
                            if tobj._midi_editor_active then
                                log.user("CANNOT CHANGE ACTIVE ITEM/TRACK")
                                table.remove(ts, i)
                            else
                                tobj._midi_editor_editable = nil
                                tobj._midi_editor_visible = nil
                            end
                        end

                        local target_items = make_target_items(ts, true)
                        midi_editor.set_items_hidden(ME.editor, target_items.visible, 1)
                        midi_editor.set_items_hidden(ME.editor, target_items.editable, 2)
                        t.gui_ref:setReaperFocus()
                        UPDATE_RESULTS = true
                    end,
                    ["C-s"] = function(t)
                        local selection = t.gui_ref.t_search_results[t.sel_idx]
                        selection.selected = true
                        t.gui_ref:add_to_current_selection(selection)
                    end,
                    -- reset selection | if every mapping was a table instead, then
                    -- I could also add a name, and a description for the mapping, so that
                    -- a legend can be shown
                    ["C-x"] = function(t)
                        t.gui_ref:reset_current_selection()
                    end,
                    ["C-g"] = function(t)
                        -- 1. get the group for single on enter selection
                        -- 2. hide all items || items outside of selected group
                        -- 3. get all MC track objects from selected group
                        -- 4. set items visible.
                    end,
                    -- [] = select all visible/filtered items
                },
                column_legend_enabled = use_column,
                columns_legend = {
                    { 9, "ZONE" },
                    { 10, "GROUP" },
                    { 8, "STATE" },
                    { 32, "NAME" },
                },
            }, opts)
        )
    end

    picker_me_tracks()
end

-- this is just for testing purposes
commands.sample_library_file_browser = function()
    local sample_dir_path = "/Users/hjalmarjakobsson/reaper/samples/1Shots Sampler Inst"
    log.clear()
    pickers.file_browser({
        cwd = sample_dir_path,
    })
end

commands.browse_reaper_preferences = function()
    log.clear()

    -- local mc = preferences.make("midieditor")
    --
    -- log.user("RAW =", mc:raw())
    --
    -- -- log.user("editor type =", mc["editor_type"])
    -- -- log.user("editor type =", mc["editor_type"])
    -- log.user("tostring", mc)
    --
    -- mc:set("editor_type", 2)
    -- mc:set("behavior_type", 3)
    -- mc:set("close_upon_item_deletion", 1)
    -- mc:set("active_item_follows_selection", 1)
    -- mc:set("other_tracks_editable", 1)
    -- mc:set("editability", 1)
    -- mc:set("visibility", 1)
    -- mc:set("all_items_are_editable_in_notation_view", 1)
    -- mc:set("secondary_items_editable_by_default", 1)
    --
    -- -- mc:set("editor_type", 0)
    -- -- mc:set("behavior_type", 0)
    -- -- mc:set("close_upon_item_deletion", 0)
    -- -- mc:set("active_item_follows_selection", 0)
    -- -- mc:set("other_tracks_editable", 0)
    -- -- mc:set("editability", 0)
    -- -- mc:set("visibility", 0)
    -- -- mc:set("all_items_are_editable_in_notation_view", 0)
    -- -- mc:set("secondary_items_editable_by_default", 0)
    --
    -- -- mc:set("editor_type", 1)
    -- -- mc:set("behavior_type", 1)
    -- -- mc:set("close_upon_item_deletion", 1)
    -- -- mc:set("active_item_follows_selection", 1)
    -- -- mc:set("other_tracks_editable", 1)
    -- -- mc:set("editability", 1)
    -- -- mc:set("visibility", 1)
    -- -- mc:set("all_items_are_editable_in_notation_view", 1)
    -- -- mc:set("secondary_items_editable_by_default", 1)
    --
    -- log.user("RAW =", mc:raw())
    --
    -- log.user("tostring", mc)
    --
    -- -- mc:toggle("visibility")
    -- -- mc:toggle("visibility")
    --
    -- mc:cycle("behavior_type")
    -- mc:cycle("behavior_type")
    -- mc:cycle("behavior_type")
    -- mc:cycle("behavior_type")
    -- mc:cycle("behavior_type", true)
    -- log.user("tostring", mc)

    fzf.init(tbl.deep_extend({
        title = "Reaper preferences",
        x = -100,
        width = 1300,
        height = 700,
        results = preferences.picker_friendly(),
        results_filter = function(t_results_data, sPattern, iMaxResults)
            local t_ret = {}
            local iCount = 0

            local function add(i, t)
                iCount = iCount + 1
                t.id = i -- keep track of position in main table
                t_ret[#t_ret + 1] = t
            end

            for i, t in ipairs(t_results_data) do
                if t.var_name and t.var_name ~= '""' and t.var_name:lower():find(sPattern) then
                    add(i, t)
                end
                if iMaxResults then
                    if #t_ret >= iMaxResults then -- check if we already have enough results
                        log.user(format.block(t_ret))
                        return t_ret
                    end
                end
            end -- for
            return t_ret
        end,
        entry_maker = require("pickers.entry_makers.preference_var"),
        sort_comp = function(a, b)
            a = a.var_name
            b = b.var_name
            if #a > #b then
                return true
            elseif #a == #b then
                return #a < #b
            else
                return false
            end
        end,
        columns_legend = {
            { 32, "cat/subcat" },
            { 16, "key" },
            { 40, "var name" },
            { 6, "val" },
            { 100, "value_string" },
        },
        context_helpers = {
            {
                on_focus_change = true,
                position = "right",
                width = "200",
                -- TODO: show alternatives
                func = function(gui, prompt_str, on_ente_sel)
                    log.user("previewer -> entry (type) =", type(on_ente_sel))
                end,
            },
        },
    }, opts))
end

-- TODO: list if a value can be/allowed to be changed.
---
commands.picker_track_info_params = function()
    log.clear()
    local focused_track_objects, _, context = lib_tr.get_focused_track_objects()
    local to = focused_track_objects[1]
    local _to = require("library.media_track_info_params").get_array(to)
    pickers.info_params({
        meta = { track = to.tr },
        title = string.format("[ TRACK ] Info Params for track = (%s) %s", to.trackIndex, to.name),
        results = _to,
    })
end

commands.picker_media_item_info_params = function()
    log.clear()
    local proj = require("project_classes.project"):new()
    local item = proj:getSelectedItem()
    if not item then
        return
    end
    local arr = require("library.media_item_info_params").get_array(item.pItem)
    pickers.info_params({
        meta = { item = item.pItem },
        title = string.format(
            "[ ACTIVE TAKE ] Info Params for track = (%s) %s",
            item._parent.tracknumber,
            item._parent.name
        ),
        results = arr,
    })
end

--- Picker for item's active take info params
commands.picker_media_item_take_info_params = function()
    log.clear()
    local proj = require("project_classes.project"):new()
    local item = proj:getSelectedItem()
    local take = item:getTake()
    if not take then
        return
    end
    local arr = require("library.media_item_take_info_params").get_array(take.pTake)
    pickers.info_params({
        meta = { take = take.pTake },
        title = string.format(
            "[ ACTIVE TAKE ] Info Params for track = (%s) %s",
            item._parent.tracknumber,
            item._parent.name
        ),
        results = arr,
    })
end

return commands
