local log = require("utils.log")
local format = require("utils.format")

local tbl = require("utils.table")


local state_interface = require("state_machine.state_interface")
local project_state = require("utils.project_state")

local midi = require("library.midi")

-- TODO: rename this to just `midi_commands.lua`.

local midi_step_commands = {}

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

--
-- INSERT RELATIVE MIDI NOTES BASED ON DIRECTION TOGGLE STATE
--

local insert_note_from_state_opts = {
	move_cursor = true,
	playback = true,
}

-- `insert_note_from_state_direction_P1`
-- `...`
-- `...`

midi_step_commands.midiStepRel_P1 = function(meta)
	-- 1. rename the `chord` param somehow
	local opts = tbl.copy(insert_note_from_state_opts)
	opts.chord = { "midi_step_rel_pitch_chord_name", { 1 } }
	midi.insertMidiNoteChunk(
		meta,
		opts
		-- { move_cursor = true, playback = true, chord = { "midi_step_rel_pitch_chord_name", { 1 } } }
	)
end

midi_step_commands.midiStepRel_m2 = function(meta, opts)
	midi.insertMidiNoteChunk(
		meta,
		{ move_cursor = true, playback = true, chord = { "midi_step_rel_pitch_chord_name", { 2 } } }
	)
end

midi_step_commands.midiStepRel_M2 = function(meta, opts)
	midi.insertMidiNoteChunk(
		meta,
		{ move_cursor = true, playback = true, chord = { "midi_step_rel_pitch_chord_name", { 3 } } }
	)
end

midi_step_commands.midiStepRel_m3 = function(meta)
	midi.insertMidiNoteChunk(
		meta,
		{ move_cursor = true, playback = true, chord = { "midi_step_rel_pitch_chord_name", { 4 } } }
	)
end

midi_step_commands.midiStepRel_M3 = function(meta, opts)
	midi.insertMidiNoteChunk(
		meta,
		{ move_cursor = true, playback = true, chord = { "midi_step_rel_pitch_chord_name", { 5 } } }
	)
end

midi_step_commands.midiStepRel_P4 = function(meta, opts)
	midi.insertMidiNoteChunk(
		meta,
		{ move_cursor = true, playback = true, chord = { "midi_step_rel_pitch_chord_name", { 6 } } }
	)
end

midi_step_commands.midiStepRel_b5 = function(meta, opts)
	midi.insertMidiNoteChunk(
		meta,
		{ move_cursor = true, playback = true, chord = { "midi_step_rel_pitch_chord_name", { 7 } } }
	)
end

midi_step_commands.midiStepRel_P5 = function(meta, opts)
	midi.insertMidiNoteChunk(
		meta,
		{ move_cursor = true, playback = true, chord = { "midi_step_rel_pitch_chord_name", { 8 } } }
	)
end

midi_step_commands.midiStepRel_m6 = function(meta, opts)
	midi.insertMidiNoteChunk(
		meta,
		{ move_cursor = true, playback = true, chord = { "midi_step_rel_pitch_chord_name", { 9 } } }
	)
end

midi_step_commands.midiStepRel_M6 = function(meta, opts)
	midi.insertMidiNoteChunk(
		meta,
		{ move_cursor = true, playback = true, chord = { "midi_step_rel_pitch_chord_name", { 10 } } }
	)
end

midi_step_commands.midiStepRel_m7 = function(meta, opts)
	midi.insertMidiNoteChunk(
		meta,
		{ move_cursor = true, playback = true, chord = { "midi_step_rel_pitch_chord_name", { 11 } } }
	)
end

midi_step_commands.midiStepRel_M7 = function(meta, opts)
	midi.insertMidiNoteChunk(
		meta,
		{ move_cursor = true, playback = true, chord = { "midi_step_rel_pitch_chord_name", { 12 } } }
	)
end

midi_step_commands.midiStepRel_P8 = function(meta, opts)
	midi.insertMidiNoteChunk(
		meta,
		{ move_cursor = true, playback = true, chord = { "midi_step_rel_pitch_chord_name", { 13 } } }
	)
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

--
-- INSERT RELATIVE MIDI NOTES WITH ASCENDING/DECENDING ATTRIBUTES
-- This serves to make it easier to use shifted keys or left/right hand
-- in step midi mode.
--

local helper_insert_step = function(meta, ascending, interval)
	midi.insertMidiNoteChunk(
		meta,
		tbl.copy_add(
			insert_note_from_state_opts,
			{ ascending = true, chord = { "midi_step_rel_pitch_chord_name", { 1 } } }
		)
	)
end

-- unison
midi_step_commands.insert_step_unison = function(meta)
  helper_insert_step(meta, _, 1) -- asc/desc does not matter here..
end

-- ascending
midi_step_commands.insert_step_asc_min_2 = function(meta)
  helper_insert_step(meta, true, 2)
end
midi_step_commands.insert_step_asc_maj_2 = function(meta)
  helper_insert_step(meta, true, 3)
end
midi_step_commands.insert_step_asc_min_3 = function(meta)
  helper_insert_step(meta, true, 4)
end
midi_step_commands.insert_step_asc_maj_3 = function(meta)
  helper_insert_step(meta, true, 5)
end
midi_step_commands.insert_step_asc_prf_4 = function(meta)
  helper_insert_step(meta, true, 6)
end
midi_step_commands.insert_step_asc_flt_5 = function(meta)
  helper_insert_step(meta, true, 7)
end
midi_step_commands.insert_step_asc_prf_5 = function(meta)
  helper_insert_step(meta, true, 8)
end
midi_step_commands.insert_step_asc_min_6 = function(meta)
  helper_insert_step(meta, true, 9)
end
midi_step_commands.insert_step_asc_maj_6 = function(meta)
  helper_insert_step(meta, true, 10)
end
midi_step_commands.insert_step_asc_min_7 = function(meta)
  helper_insert_step(meta, true, 11)
end
midi_step_commands.insert_step_asc_maj_7 = function(meta)
  helper_insert_step(meta, true, 12)
end
midi_step_commands.insert_step_asc_prf_8 = function(meta)
  helper_insert_step(meta, true, 13)
end

-- descending
midi_step_commands.insert_step_desc_min_2 = function(meta)
  helper_insert_step(meta, false, 2)
end
midi_step_commands.insert_step_desc_maj_2 = function(meta)
  helper_insert_step(meta, false, 3)
end
midi_step_commands.insert_step_desc_min_3 = function(meta)
  helper_insert_step(meta, false, 4)
end
midi_step_commands.insert_step_desc_maj_3 = function(meta)
  helper_insert_step(meta, false, 5)
end
midi_step_commands.insert_step_desc_prf_4 = function(meta)
  helper_insert_step(meta, false, 6)
end
midi_step_commands.insert_step_desc_flt_5 = function(meta)
  helper_insert_step(meta, false, 7)
end
midi_step_commands.insert_step_desc_prf_5 = function(meta)
  helper_insert_step(meta, false, 8)
end
midi_step_commands.insert_step_desc_min_6 = function(meta)
  helper_insert_step(meta, false, 9)
end
midi_step_commands.insert_step_desc_maj_6 = function(meta)
  helper_insert_step(meta, false, 10)
end
midi_step_commands.insert_step_desc_min_7 = function(meta)
  helper_insert_step(meta, false, 11)
end
midi_step_commands.insert_step_desc_maj_7 = function(meta)
  helper_insert_step(meta, false, 12)
end
midi_step_commands.insert_step_desc_prf_8 = function(meta)
  helper_insert_step(meta, false, 13)
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

--
-- FIX: refactor both these. it should be possible to toggle things easier.
--      >>> project_state > toggle state value
--      >>> reaper_state > toggle state value
--
-- refactor all these functions into module so that I can configure these inside
-- actions instead
--
--
-- FIX: use state_interface here instead.

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
