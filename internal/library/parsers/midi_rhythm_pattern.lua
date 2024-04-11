local midi_editor = require("library.midi_editor")
local midi_patterns = require("library.midi_patterns")

local mrp = {}

-- TODO: I believe that midi_pattern should go into this file. The name is
-- misleading because it only generates rhythm events but doesn't really
-- deal with MIDI per se - It might just as well be used as a basis for
-- creating patterns for injecting audio samples...

---Parses a pattern string and returns a single table with all information.
---@param input_pattern any
---@return table
mrp.parse_pattern = function(input_pattern)
  -- FIX: The context should be passed via opts from the initial caller,
  -- ie. `parse_and_render_midi_notes_block_from_string`

  local ok, t_midi_context = midi_editor.getMidiValidContext()

  local t_patterns_state, t_pattern_midi_notes = midi_patterns.parse(_, {
    pattern = input_pattern,
    midi_context = t_midi_context,

    start_at_zero = true,
  })
  return {
    meta_data = t_patterns_state,
    midi_events = t_pattern_midi_notes
  }
end

return mrp
