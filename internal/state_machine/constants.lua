-- TODO rename this file to reset and just return reset state
local constants = {
  reset_state = {
    key_sequence = "",
    context = "main",
    mode = "normal",
    macro_recording = false,
    macro_register = "+",
    timeline_selection_side = "left",
    last_searched_track_name = "^$",
    last_track_name_search_direction_was_forward = true,
    visual_track_pivot_i = 0,
    last_command = {
      context = "main",
      mode = "normal",
      action_keys = {
        "NoOp",
      },
      action_sequence = {
        "command",
      },
    },
    ME_follow_motions = false,
    midi_step_state = {
      silent = false,
      direction = true,
      octave_next = nil,
      -- can be either `nil` or a list of GUIDs
      guids_track_active = nil,
      note_duration_default_QN_fraction = 1 / 4,
      staccatto = false,
      next_note_rhythms = {},
    },
  },
}

return constants
