local log = require("utils.log")
local format = require("utils.format")

local project_state = require("utils.project_state")

local midi = require("library.midi")

-- TODO: rename this to just `midi_commands.lua`.

local midi_step_commands = {}

--
-- FIX: refactor both these. it should be possible to toggle things easier.
--      >>> project_state > toggle state value
--      >>> reaper_state > toggle state value
--
-- refactor all these functions into module so that I can configure these inside
-- actions instead

midi_step_commands.midiStepToggleDirection = function(meta, opts)
  local _, midi_step_state = midi.get_midi_step_state()
  midi_step_state.direction = not midi_step_state.direction
  project_state.overwrite("mode_state", "midi_step", midi_step_state)
end

midi_step_commands.midiStepToggleSilent = function(meta, opts)
  local _, midi_step_state = midi.get_midi_step_state()
  midi_step_state.silent = not midi_step_state.silent
  project_state.overwrite("mode_state", "midi_step", midi_step_state)
end

midi_step_commands.midiStepSetOctaveNextUp = function(meta, opts)
  local midi_step_state = midi.get_midi_step_state()
  midi_step_state.octave_next = 1
  project_state.overwrite("mode_state", "midi_step", midi_step_state)
end

midi_step_commands.midiStepSetOctaveNextDown = function(meta, opts)
  local midi_step_state = midi.get_midi_step_state()
  midi_step_state.octave_next = -1
  project_state.overwrite("mode_state", "midi_step", midi_step_state)
end

return midi_step_commands
