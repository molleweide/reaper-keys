local log = require("utils.log")
local format = require("utils.format")
local pickers = require("pickers.pickers")
local lib_tr = require("library.tracks")
local s = require("utils.string")
local tl = require("library.timeline")
local containers = require("library.items")
local segments = require("library.segments")

local fzf = require("library.fzf")

local fxu = require("library.fx")
local tbl = require("utils.table")

local project_state = require("utils.project_state")

local midi = require("library.midi")
local midi_editor = require("library.midi_editor")

local commands = {}

commands.MIDI_ChangeActiveSelection = function(meta, opts)
  pickers.all_tracks(_, {
    title = "jump to track midi",
    filter = "MCS",     -- filter track_obj.class = [MCS]
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

commands.open_route_ui = function(meta, opts)
  -- NOTE: what should this UI do?
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

local function check_if_item_exists_or_create(track, check_start_pos, check_end_pos)
  local items_found = containers.get_track_items_that_span_cursor_pos(track, check_start_pos, check_end_pos)
  local target_item
  if items_found then
    target_item = items_found[1].ref
  else
    target_item = containers.create_new_item(true, track, check_start_pos, check_end_pos)
  end
  return target_item
end

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
      filter = "M",       -- filter nodes
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

  local function tracks()
    local tag = "tracks"
    pickers.all_tracks(_, {
      title = "Select track(s) for prompt insertion.",
      width = 900,
      filter = "M",       -- filter nodes
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
  local route = require("library.routing")

  route.updateState()
end

local function get_focus_track_with_fx_chain_info()
  local focused_track_objects, _, context = lib_tr.get_focused_track_objects()
  local tr_node = focused_track_objects[1]
  local fx_results = fxu.get_track_fx_chain_info(tr_node.tr)
  return tr_node, fx_results
end

commands.track_fx_ui = function(meta, opts)
  local tr_node, fx_results = get_focus_track_with_fx_chain_info()

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

  local rk_main_menu = {
    { name = "preferences" },
    { name = "tracks" },
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

commands.sample_library_file_browser = function()
  -- TODO:
  -- 1. add sample library dir to def/config
  -- 2. on selection -> recursive call picker with the selected dir.
  -----
  -- On C-z, if previous dir is beyond base sample dir, don't do anything,
  -- else move back one step.
  -----
  -- C-f, preview sample,
  --      Hit C-f again to stop current preview, eg. if file is a loop.
  -----
  -- C-t, toggle play selected sample on change.

  fzf.init({
    title = "SAMPLE LIBRARY BROWSER",
    width = 1000,
    height = 800,
    x = 0,
    y = 1100,
    -- results = rk_main_menu,
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

      -- segments.insert_x_num_empty_measures_at_pos(region_opts.new_region_start, region_opts.new_region_end)
      -- marks.create({
      --   type = "region",
      --   register = region_opts.register,
      --   name = region_opts.name_string,
      --   left = region_opts.new_region_start,
      --   right = region_opts.new_region_end,
      -- })

      -- TODO:
      -- segments.inject_new_empty_region()

      return true
    end,
  })
end

-- commands.insert_new_region_before_current_region = function()
--   pickers.basic_prompt({
--     title = "Add region BEFORE current",
--     callback = function(prompt_string) end,
--   })
-- end
-- commands.insert_new_region_last = function()
--   pickers.basic_prompt({
--     title = "Add region to project end.",
--     callback = function(prompt_string) end,
--   })
-- end
-- commands.insert_new_region_beginning = function()
--   pickers.basic_prompt({
--     title = "Insert region at project start.",
--     callback = function(prompt_string) end,
--   })
-- end

return commands
