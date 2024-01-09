local log = require("utils.log")
local format = require("utils.format")

local midi = require("library.midi")

local midi_operators = {}

midi_operators.cut = function(meta, opts)
  midi.midi_take_filter_transform(meta.active_take, {
    remove = {
      notes = { sel = true }, -- this would select all notes in take
    },
  })
end

return midi_operators
