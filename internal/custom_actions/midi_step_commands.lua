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
			{ ascending = ascending, chord = { "midi_step_rel_pitch_chord_name", { interval } } }
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

midi_step_commands.midiStepToggleDirection = function(meta, opts)
	local state = state_interface.get()
	state.midi_step_state.direction = not state.midi_step_state.direction
	local ret = state_interface.set(state)
end

midi_step_commands.midiStepToggleSilent = function(meta, opts)
	local state = state_interface.get()
	state.midi_step_state.silent = not state.midi_step_state.silent
	local ret = state_interface.set(state)
end

midi_step_commands.midiStepSetOctaveNextUp = function(meta, opts)
	local state = state_interface.get()
	state.midi_step_state.octave_next = 1
	local ret = state_interface.set(state)
end

midi_step_commands.midiStepSetOctaveNextDown = function(meta, opts)
	local state = state_interface.get()
	state.midi_step_state.octave_next = -1
	local ret = state_interface.set(state)
end

-- TODO: i can impl this as a toggle first, and then layer on the picker..
-- then use leader key later for selection durations quickly.

midi_step_commands.midiStepSelectNoteDuration = function(meta, opts)
	local state = state_interface.get()
	-- make a picker that allows for selecting between a list of
	-- durations, eg:
	-- QN / 1/4
	-- 1/8
	-- 1/16
	-- 2QN / 2/4
	-- 1/24
	-- 1/32

	-- -- save selection to state.
	-- local exists, midi_step_state = project_state.get("mode_state", "midi_step")
	-- local new_midi_step_state
	-- if not exists then
	-- 	new_midi_step_state = {
	-- 		silent = false,
	-- 		direction = true,
	-- 	}
	-- else

	-- new_midi_step_state = midi_step_state
	-- new_midi_step_state.silent = not new_midi_step_state.silent

	state.midi_step_state.silent = not state.midi_step_state.silent

	-- end
	-- log.user(exists, midi_step_state, format.block(new_midi_step_state))
	-- project_state.overwrite("mode_state", "midi_step", new_midi_step_state)
	local ret = state_interface.set(state)
end

--
-- QUICK INSERT PAUSES
--

local helper_pause = function(meta, duration)
	midi.insertMidiNoteChunk(meta, { move_cursor = true, silent = true, note_duration = duration })
end

midi_step_commands.insert_silent_QN = function(meta)
	helper_pause(meta, 1)
end
-- under QN
midi_step_commands.insert_silent_8th = function(meta)
	helper_pause(meta, 1 / 2)
end
midi_step_commands.insert_silent_8th_dot = function(meta)
	helper_pause(meta, 1 / 4 * 3)
end
midi_step_commands.insert_silent_16th = function(meta)
	helper_pause(meta, 1 / 4)
end
midi_step_commands.insert_silent_24th = function(meta)
	helper_pause(meta, 1 / 6)
end
midi_step_commands.insert_silent_32th = function(meta)
	helper_pause(meta, 1 / 8)
end
midi_step_commands.insert_silent_QN_div3 = function(meta)
	helper_pause(meta, 1 / 3)
end
-- over QN
midi_step_commands.insert_silent_QN_dot = function(meta)
	helper_pause(meta, 1.5)
end
midi_step_commands.insert_silent_QN_2x = function(meta)
	helper_pause(meta, 2)
end
midi_step_commands.insert_silent_QN_3x = function(meta)
	helper_pause(meta, 3)
end

return midi_step_commands
