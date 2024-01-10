local log = require("utils.log")
local format = require("utils.format")

local project_state = require("utils.project_state")

local midi = require("library.midi")

-- TODO: rename this to just `midi_commands.lua`.

local midi_step_commands = {}

-- FIX: it is a bit stupid to pass chords here. i should make it possible to
-- pass single note / relative interval
--
-- TODO: move these to `custom_actions/midi_step_commands.lua`

midi_step_commands.midiStepRel_P1 = function(meta)
	-- 1. rename the `chord` param somehow
	midi.insertMidiNoteChunk(
		meta,
		{ move_cursor = true, chord = { "midi_step_rel_pitch_chord_name", { 1 }, playback = true } }
	)
end

midi_step_commands.midiStepRel_m2 = function(meta, opts)
	midi.insertMidiNoteChunk(meta, { move_cursor = true, chord = { "midi_step_rel_pitch_chord_name", { 2 } } })
end

midi_step_commands.midiStepRel_M2 = function(meta, opts)
	midi.insertMidiNoteChunk(meta, { move_cursor = true, chord = { "midi_step_rel_pitch_chord_name", { 3 } } })
end

midi_step_commands.midiStepRel_m3 = function(meta)
	midi.insertMidiNoteChunk(meta, { move_cursor = true, chord = { "midi_step_rel_pitch_chord_name", { 4 } } })
end

midi_step_commands.midiStepRel_M3 = function(meta, opts)
	midi.insertMidiNoteChunk(meta, { move_cursor = true, chord = { "midi_step_rel_pitch_chord_name", { 5 } } })
end

midi_step_commands.midiStepRel_P4 = function(meta, opts)
	midi.insertMidiNoteChunk(meta, { move_cursor = true, chord = { "midi_step_rel_pitch_chord_name", { 6 } } })
end

midi_step_commands.midiStepRel_b5 = function(meta, opts)
	midi.insertMidiNoteChunk(meta, { move_cursor = true, chord = { "midi_step_rel_pitch_chord_name", { 7 } } })
end

midi_step_commands.midiStepRel_P5 = function(meta, opts)
	midi.insertMidiNoteChunk(meta, { move_cursor = true, chord = { "midi_step_rel_pitch_chord_name", { 8 } } })
end

midi_step_commands.midiStepRel_m6 = function(meta, opts)
	midi.insertMidiNoteChunk(meta, { move_cursor = true, chord = { "midi_step_rel_pitch_chord_name", { 9 } } })
end

midi_step_commands.midiStepRel_M6 = function(meta, opts)
	midi.insertMidiNoteChunk(meta, { move_cursor = true, chord = { "midi_step_rel_pitch_chord_name", { 10 } } })
end

midi_step_commands.midiStepRel_m7 = function(meta, opts)
	midi.insertMidiNoteChunk(meta, { move_cursor = true, chord = { "midi_step_rel_pitch_chord_name", { 11 } } })
end

midi_step_commands.midiStepRel_M7 = function(meta, opts)
	midi.insertMidiNoteChunk(meta, { move_cursor = true, chord = { "midi_step_rel_pitch_chord_name", { 12 } } })
end

midi_step_commands.midiStepRel_P8 = function(meta, opts)
	midi.insertMidiNoteChunk(meta, { move_cursor = true, chord = { "midi_step_rel_pitch_chord_name", { 13 } } })
end
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
