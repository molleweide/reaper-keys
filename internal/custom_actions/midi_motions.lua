local log = require("utils.log")
local format = require("utils.format")

local midi = require("library.midi")

local midi_motions = {}

-- NextPitch = {
--   midi.get_or_jump_current_note_row,
--   opts = { amount = 1 },
--   midiCommand = true,
--   prefixRepetitionCount = true,
-- },
-- PrevPitch = {
--   midi.get_or_jump_current_note_row,
--   opts = { amount = -1 },
--   midiCommand = true,
--   prefixRepetitionCount = true,
-- },

midi_motions.nextPitch = function(meta, opts)
  midi.get_or_jump_current_note_row(1, true)
end

midi_motions.prevPitch = function(meta, opts)
  midi.get_or_jump_current_note_row(-1, true)
end

return midi_motions
