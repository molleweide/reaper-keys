local onCommand = {
    main = {
        stop_playback = function()
            reaper.Main_OnCommand(1016, 0)
        end,
        open_in_builtin_midi_editor = function()
            reaper.Main_OnCommand(40153, 0)
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
