local midi_editor = require("library.midi_editor")
local midi_patterns = require("library.midi_patterns")

local mrp = {}

mrp.parse_pattern = function(input_pattern)
  -- FIX: The context should be passed via opts from the initial caller,
  -- ie. `parse_and_render_midi_notes_block_from_string`

  local ok, t_midi_context = midi_editor.getMidiValidContext()

  local t_patterns_state, t_pattern_midi_notes = midi_patterns.parse(_, {
    pattern = input_pattern,
    midi_context = t_midi_context,

    start_at_zero = true,
  })
  return t_pattern_midi_notes
end

return mrp
