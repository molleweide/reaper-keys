local log = require("utils.log")
local format = require("utils.format")
local pickers = require("pickers.pickers")
local lib_tr = require("library.tracks")

local fxu = require("library.fx")

local project_state = require("utils.project_state")

local midi = require("library.midi")
local midi_editor = require("library.midi_editor")

local commands = {}

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
  pickers.marks_and_regions(_, {
    filter = "MCS",
    next_is_picker = true,
    next = function(meta, data)
      local log = require("utils.log")
      local format = require("utils.format")
      log.user("selection data", format.block(data))
      local mark_sel = data.selection

      -- # tResultButtons 10.0
      -- selection data {
      --   selection = {
      --     id = 1,
      --     index = 1,
      --     left = 8.0,
      --     name = "testing",
      --     position = 10.0,
      --     register = "r",
      --     right = 16.0,
      --     time = 1699895229,
      --     track_position = 169.0,
      --     track_selection = {
      --       169.0
      --     },
      --     type = "region"
      --   }
      -- }

      pickers.all_tracks(meta, {
        title = "Choose track for editing @ region = [" .. data.selection.name .. "]",
        filter = "MCS",
        next_is_picker = false,
        next = function(meta2, data2)
          log.user("selection data2", format.block(data2), "sel mark->", format.block(data))
          require("library.midi_editor").createEditMidiItemAtPositionForTrack(
            _,
            data2.selection,
            mark_sel.left,
            mark_sel.right
          )
          -- move edit cursor
          -- note: i dunno if this is the best place to put the move command.
          reaper.SetEditCurPos(mark_sel.left, false, false)
        end,
      })

      -- pickers.all_tracks
      --     >>> next = reuse next from above
      --        >>>> first - move it into library.
    end,
  })
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
    pickers.track_fx_params({ node = tr_node, fx_index = eq_instance.idx })
  end
end
commands.picker_first_comp_on_focused_track = function()
  local focused_track_objects, _, context = lib_tr.get_focused_track_objects()
  local tr_node = focused_track_objects[1]
  local comp_instance = fxu.get_fx_objs_by_name_string(tr_node.guid, "ReaComp")
  log.user("EQ INSTANCE:", format.block(comp_instance))
  if comp_instance then
    pickers.track_fx_params({ node = tr_node, fx_index = comp_instance.idx })
  end
end

commands.open_route_ui = function(meta, opts) end

commands.fuzzy_track_node_ui = function(meta, opts)

  -- ! string parse -> add nodes.

  -- ! should behavior be different in main/midi?

  -- This should allow me to easilly manage nodes.

  -- If this is used with the fuzzy UI, then i can use text for any inputs to
  -- reaper, and then see how good this window becomes for me.
  -- In the end this could almost become as like an AI text interface to the
  -- software, that then allows you to do some pretty fucking insane sounds.

  -- TODO: 1. parse string on each input.
  --       2. preview node(s) that will be affected.
  --       3. on keypress
  --              perform actions.
  --
  --      HACK: this can then be reused for the route_ui previewer above.

  -- TODO: refactor string funcs from route lib that extracts parenthesis
  -- into utils/strings, so that I can reuse the caturing mechanism here.


  -- TEST: ~ SYNTAX BASED HIDING -> picker all tracks > manage track_params
  --   eg. show/hide/solo/mute/volume/phase/


end

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

  -- TEST: delete region -> if region contains item data -> user will be prompted
  -- "Region contains item data - Are you sure you want to proceed? (Y/n)"

end

commands.show_hide_track_ui = function()
  -- TODO: create a picker of all track nodes.
  -- 1. keybind -> attach `hide` flag to each entry.
  -- 2. apply.
  --
  -- NOTE: hide tracks of class X, or if you say hide G, then all children
  -- will also be hidden.
  --
  --
  -- FIX: Need action/command to un-hide all tracks easy
  --
  -- NOTE: THIS SHOULD PROLLY GO INTO THE TRACK_NODE_UI ABOVE?!
end

-- TEST: Later, this should be modified to create a MIDI edit SCREENSET from
-- the group selection screenset.
commands.MIDI_picker_edit_tracks_CHAIN_region_and_group = function()

  -- 1. first select region.
  -- 2. then, select which Group,
  -- 3. then, select track.
end

commands.MIDI_picker_tracks_edit_existing_items_at_cursor = function()
end

commands.routing_user_string = function()

  local route = require("library.routing")

  route.updateState()
end

return commands
