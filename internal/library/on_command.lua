-- TODO: Redo this module so that each command id is in a table and one
-- entry per line
--

local new_test = {
  main = {
    go_to_loop_end = 40633,
    stop_playback = 1016,
    open_in_builtin_midi_editor = 40153,
  },
}

local onCommand = {
  main = {
    go_to_loop_end = function()
      reaper.Main_OnCommand(40633, 0)
    end,
    stop_playback = function()
      reaper.Main_OnCommand(1016, 0)
    end,
    open_in_builtin_midi_editor = function()
      reaper.Main_OnCommand(40153, 0)
    end,
    select_all_items_in_time_sel = function()
      reaper.Main_OnCommand(40717, 0)
    end,
    split_items_at_time_selection = function()
      reaper.Main_OnCommand(40061, 0)
    end,
  },
  midi = {

    activate_next_visible_item = function(hwnd)
      reaper.MIDIEditor_OnCommand(hwnd, 40500)
    end,

    -- Cmd: Zoom to project loop selection
    zoom_to_project_loop_selection = function(hwnd)
      reaper.MIDIEditor_OnCommand(hwnd, 40726)
    end,

    -- Options: Track list/media item lane follows selection changes in arrange view
    toggle_TrackListAndMediaItemLane_FollowsSelectionChangesInArrangeView = function(hwnd)
      reaper.MIDIEditor_OnCommand(hwnd, 40826)
    end,
  },
}

return onCommand
