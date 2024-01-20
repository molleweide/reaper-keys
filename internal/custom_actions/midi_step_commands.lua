local log = require("utils.log")
local format = require("utils.format")

local tbl = require("utils.table")

local state_interface = require("state_machine.state_interface")
local project_state = require("utils.project_state")

local midi = require("library.midi")

-- TODO: rename this to just `midi_commands.lua`.

local midi_step_commands = {}

local function render_next_step(meta, opts)
  -- TODO: check the NNN array and check whether or not use default or not.
  local state = state_interface.get()

  log.user("MIDI STEP STATE IN REDNER NEXT:", format.block(state.midi_step_state))

  if state.midi_step_state.next_note_rhythms == nil then
    log.debug("state.midi_step_state.next_note_rhythms == nil -> Adds to state.")
    state.midi_step_state.next_note_rhythms = {}
  end

  opts.staccatto = state.midi_step_state.staccatto

  -- prepare insert note chunk opts by state
  opts.silent = state.midi_step_state.silent
  opts.direction = state.midi_step_state.direction and 1 or -1
  --
  opts.octave_next = state.midi_step_state.octave_next
  state.midi_step_state.octave_next = nil

  if #state.midi_step_state.next_note_rhythms == 0 then
    opts.note_duration = state.midi_step_state.note_duration_default_QN_fraction
  else
    opts.note_duration = state.midi_step_state.next_note_rhythms[1]
    table.remove(state.midi_step_state.next_note_rhythms, 1)
  end

  midi.insertMidiNoteChunk(meta, opts)

  -- reset specific state
  state_interface.set(state)
end

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
  local opts = tbl.copy(insert_note_from_state_opts)
  opts.note_chunk = { "midi_step_rel_pitch_chord_name", relative_intervals = { 0 } }
  midi.insertMidiNoteChunk(meta, opts)
end

midi_step_commands.midiStepRel_m2 = function(meta, opts)
  midi.insertMidiNoteChunk(meta, {
    move_cursor = true,
    playback = true,
    note_chunk = { "midi_step_rel_pitch_chord_name", relative_intervals = { 1 } },
  })
end

midi_step_commands.midiStepRel_M2 = function(meta, opts)
  midi.insertMidiNoteChunk(meta, {
    move_cursor = true,
    playback = true,
    note_chunk = { "midi_step_rel_pitch_chord_name", relative_intervals = { 2 } },
  })
end

midi_step_commands.midiStepRel_m3 = function(meta)
  midi.insertMidiNoteChunk(meta, {
    move_cursor = true,
    playback = true,
    note_chunk = { "midi_step_rel_pitch_chord_name", relative_intervals = { 3 } },
  })
end

midi_step_commands.midiStepRel_M3 = function(meta, opts)
  midi.insertMidiNoteChunk(meta, {
    move_cursor = true,
    playback = true,
    note_chunk = { "midi_step_rel_pitch_chord_name", relative_intervals = { 4 } },
  })
end

midi_step_commands.midiStepRel_P4 = function(meta, opts)
  midi.insertMidiNoteChunk(meta, {
    move_cursor = true,
    playback = true,
    note_chunk = { "midi_step_rel_pitch_chord_name", relative_intervals = { 5 } },
  })
end

midi_step_commands.midiStepRel_b5 = function(meta, opts)
  midi.insertMidiNoteChunk(meta, {
    move_cursor = true,
    playback = true,
    note_chunk = { "midi_step_rel_pitch_chord_name", relative_intervals = { 6 } },
  })
end

midi_step_commands.midiStepRel_P5 = function(meta, opts)
  midi.insertMidiNoteChunk(meta, {
    move_cursor = true,
    playback = true,
    note_chunk = { "midi_step_rel_pitch_chord_name", relative_intervals = { 7 } },
  })
end

midi_step_commands.midiStepRel_m6 = function(meta, opts)
  midi.insertMidiNoteChunk(meta, {
    move_cursor = true,
    playback = true,
    note_chunk = { "midi_step_rel_pitch_chord_name", relative_intervals = { 8 } },
  })
end

midi_step_commands.midiStepRel_M6 = function(meta, opts)
  midi.insertMidiNoteChunk(meta, {
    move_cursor = true,
    playback = true,
    note_chunk = { "midi_step_rel_pitch_chord_name", relative_intervals = { 9 } },
  })
end

midi_step_commands.midiStepRel_m7 = function(meta, opts)
  midi.insertMidiNoteChunk(meta, {
    move_cursor = true,
    playback = true,
    note_chunk = { "midi_step_rel_pitch_chord_name", relative_intervals = { 10 } },
  })
end

midi_step_commands.midiStepRel_M7 = function(meta, opts)
  midi.insertMidiNoteChunk(meta, {
    move_cursor = true,
    playback = true,
    note_chunk = { "midi_step_rel_pitch_chord_name", relative_intervals = { 11 } },
  })
end

midi_step_commands.midiStepRel_P8 = function(meta, opts)
  midi.insertMidiNoteChunk(meta, {
    move_cursor = true,
    playback = true,
    note_chunk = { "midi_step_rel_pitch_chord_name", relative_intervals = { 12 } },
  })
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
  -- midi.insertMidiNoteChunk(
  --   meta,
  --   tbl.copy_add(
  --     insert_note_from_state_opts,
  --     { ascending = ascending, note_chunk = { "midi_step_rel_pitch_chord_name", relative_intervals = { interval } } }
  --   )
  -- )
  render_next_step(
    meta,
    tbl.copy_add(insert_note_from_state_opts, {
      ascending = ascending,
      note_chunk = { "midi_step_rel_pitch_chord_name", relative_intervals = { interval } },
    })
  )
end

-- unison
midi_step_commands.insert_step_unison = function(meta)
  helper_insert_step(meta, _, 0) -- asc/desc does not matter here..
end

-- ascending
midi_step_commands.insert_step_asc_min_2 = function(meta)
  helper_insert_step(meta, true, 1)
end
midi_step_commands.insert_step_asc_maj_2 = function(meta)
  helper_insert_step(meta, true, 2)
end
midi_step_commands.insert_step_asc_min_3 = function(meta)
  helper_insert_step(meta, true, 3)
end
midi_step_commands.insert_step_asc_maj_3 = function(meta)
  helper_insert_step(meta, true, 4)
end
midi_step_commands.insert_step_asc_prf_4 = function(meta)
  helper_insert_step(meta, true, 5)
end
midi_step_commands.insert_step_asc_flt_5 = function(meta)
  helper_insert_step(meta, true, 6)
end
midi_step_commands.insert_step_asc_prf_5 = function(meta)
  helper_insert_step(meta, true, 7)
end
midi_step_commands.insert_step_asc_min_6 = function(meta)
  helper_insert_step(meta, true, 8)
end
midi_step_commands.insert_step_asc_maj_6 = function(meta)
  helper_insert_step(meta, true, 9)
end
midi_step_commands.insert_step_asc_min_7 = function(meta)
  helper_insert_step(meta, true, 10)
end
midi_step_commands.insert_step_asc_maj_7 = function(meta)
  helper_insert_step(meta, true, 11)
end
midi_step_commands.insert_step_asc_prf_8 = function(meta)
  helper_insert_step(meta, true, 12)
end

-- descending
midi_step_commands.insert_step_desc_min_2 = function(meta)
  helper_insert_step(meta, false, 1)
end
midi_step_commands.insert_step_desc_maj_2 = function(meta)
  helper_insert_step(meta, false, 2)
end
midi_step_commands.insert_step_desc_min_3 = function(meta)
  helper_insert_step(meta, false, 3)
end
midi_step_commands.insert_step_desc_maj_3 = function(meta)
  helper_insert_step(meta, false, 4)
end
midi_step_commands.insert_step_desc_prf_4 = function(meta)
  helper_insert_step(meta, false, 5)
end
midi_step_commands.insert_step_desc_flt_5 = function(meta)
  helper_insert_step(meta, false, 6)
end
midi_step_commands.insert_step_desc_prf_5 = function(meta)
  helper_insert_step(meta, false, 7)
end
midi_step_commands.insert_step_desc_min_6 = function(meta)
  helper_insert_step(meta, false, 8)
end
midi_step_commands.insert_step_desc_maj_6 = function(meta)
  helper_insert_step(meta, false, 9)
end
midi_step_commands.insert_step_desc_min_7 = function(meta)
  helper_insert_step(meta, false, 10)
end
midi_step_commands.insert_step_desc_maj_7 = function(meta)
  helper_insert_step(meta, false, 11)
end
midi_step_commands.insert_step_desc_prf_8 = function(meta)
  helper_insert_step(meta, false, 12)
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

--
-- SET MAIN RHYTHM
--

local helper_set_main_rhythm = function(meta, frac)
  local state = state_interface.get()
  state.midi_step_state.note_duration_default_QN_fraction = frac
  state_interface.set(state)
end

midi_step_commands.set_main_rhythm_to_QN = function(meta)
  helper_set_main_rhythm(meta, 1)
end
-- under QN
midi_step_commands.set_main_rhythm_to_8th = function(meta)
  helper_set_main_rhythm(meta, 1 / 2)
end
midi_step_commands.set_main_rhythm_to_8th_dot = function(meta)
  helper_set_main_rhythm(meta, 1 / 4 * 3)
end
midi_step_commands.set_main_rhythm_to_16th = function(meta)
  helper_set_main_rhythm(meta, 1 / 4)
end
midi_step_commands.set_main_rhythm_to_24th = function(meta)
  helper_set_main_rhythm(meta, 1 / 6)
end
midi_step_commands.set_main_rhythm_to_32th = function(meta)
  helper_set_main_rhythm(meta, 1 / 8)
end
midi_step_commands.set_main_rhythm_to_QN_div3 = function(meta)
  helper_set_main_rhythm(meta, 1 / 3)
end
-- over QN
midi_step_commands.set_main_rhythm_to_QN_dot = function(meta)
  helper_set_main_rhythm(meta, 1.5)
end
midi_step_commands.set_main_rhythm_to_QN_2x = function(meta)
  helper_set_main_rhythm(meta, 2)
end
midi_step_commands.set_main_rhythm_to_QN_3x = function(meta)
  helper_set_main_rhythm(meta, 3)
end

--
-- ADD NEXT NOTE RHYTHMS
--

local helper_add_next_note_rhythm = function(meta, frac)
  local state = state_interface.get()
  -- log.user(format.block(state.midi_step_state))
  table.insert(state.midi_step_state.next_note_rhythms, frac)
  state_interface.set(state)
end

midi_step_commands.add_next_note_rhythm_QN = function(meta)
  helper_add_next_note_rhythm(meta, 1)
end
-- under QN
midi_step_commands.add_next_note_rhythm_8th = function(meta)
  helper_add_next_note_rhythm(meta, 1 / 2)
end
midi_step_commands.add_next_note_rhythm_8th_dot = function(meta)
  helper_add_next_note_rhythm(meta, 1 / 4 * 3)
end
midi_step_commands.add_next_note_rhythm_16th = function(meta)
  helper_add_next_note_rhythm(meta, 1 / 4)
end
midi_step_commands.add_next_note_rhythm_24th = function(meta)
  helper_add_next_note_rhythm(meta, 1 / 6)
end
midi_step_commands.add_next_note_rhythm_32th = function(meta)
  helper_add_next_note_rhythm(meta, 1 / 8)
end
midi_step_commands.add_next_note_rhythm_QN_div3 = function(meta)
  helper_add_next_note_rhythm(meta, 1 / 3)
end
-- over QN
midi_step_commands.add_next_note_rhythm_QN_dot = function(meta)
  helper_add_next_note_rhythm(meta, 1.5)
end
midi_step_commands.add_next_note_rhythm_QN_2x = function(meta)
  helper_add_next_note_rhythm(meta, 2)
end
midi_step_commands.add_next_note_rhythm_QN_3x = function(meta)
  helper_add_next_note_rhythm(meta, 3)
end

--
-- VARIOUS
--

midi_step_commands.toggle_staccatto = function()
  local state = state_interface.get()
  -- log.user(format.block(state.midi_step_state))
  -- table.insert(state.midi_step_state.next_note_rhythms, frac)

  if state.midi_step_state.staccatto ~= nil then
    if state.midi_step_state.staccatto then
      state.midi_step_state.staccatto = false
    else
      state.midi_step_state.staccatto = true
    end
  else
    state.midi_step_state.staccatto = false
  end

  state_interface.set(state)
end

midi_step_commands.user_input_next_note_rhythms = function() end

midi_step_commands.reset_next_note_rhytms = function() end

return midi_step_commands
