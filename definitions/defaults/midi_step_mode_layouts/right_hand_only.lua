-- TODO: I need to move the step command layouts into their own files
-- since there will be about a handful of test layouts for various layouts.

-- RENAME: `midi-step-right-hand-insert`
return {
	-- TODO: easy actions
	-- ~ Toggle playback
	-- ~ Insert a pattern string.
	-- ~ Select rhyhtm pattern string AND use this as template for stepping forward.
	-- ~ Left hand -> repeat last right hand insert.
	--
	-- TODO: advanced / new modes
	-- ~ Set left and right handed mode for inserting pitches.
	--
	["Q"] = {
		"+SetStepSize",
		{
			-- TODO:
			["g"] = "StepSizeGrid",
			["t"] = "32th",
			["s"] = "16th",
			["e"] = "8th",
			["E"] = "8th_dot",
			["q"] = "QN",
			["w"] = "QN_dot",
			["c"] = "2xQN",
			["x"] = "3xQN",
			-- [""] = "4xQN",
			-- [""] = "Step_Measure",
		},
	},
	["T"] = {
		"+polyphonic",
		{
			["t"] = "TogglyMidiStepPolyhonic",
			-- Eg.
			-- ~ Use scale 3rds or sixths.
			-- ~ Use jazz chords.
			["s"] = "SetMidiStepPolyphonic_HarmonyType",
			-- Eg. only use perfect fifths
			["x"] = "MidiStepModePolyphonic_SetStaticChord",
		},
	},

	-- [""] = "", -- jump forward by predefined (*) length
	-- ["w"] = "", -- (*) set predefined length.
	-- ["e"] = "",
	-- ["r"] = "",
	-- ["t"] = "", --
	["a"] = "SetModeNormal", -- set pause/silent
	["s"] = "ToggleMidiStepSilent",
	["S"] = {
		"+silent step",
		{
			-- TODO:
			["t"] = "SilentNote32th",
			["f"] = "SilentNote24th",
			["s"] = "SilentNote16th",
			["d"] = "SilentNote16th_dot",
			["e"] = "SilentNote8th",
			["E"] = "SilentNote8th_dot",
			["i"] = "SilentNoteQN_div3",
			--
			["q"] = "SilentNoteQN",
			--
			["w"] = "SilentNoteQN_dot",
			["c"] = "SilentNoteQN_2x",
			["x"] = "SilentNoteQN_3x",
		},
	},
	["d"] = {
		"+setNextOctave",
		{
			["d"] = "ToggleMidiStepDirection",
			-- set dir up
			-- set dir down
		},
	},
	["f"] = {
		"+setNextOctave",
		{
			["u"] = "MidiStepSetNextOctaveUp",
			["d"] = "MidiStepSetNextOctaveDown",
		},
	},
	["g"] = {
		"+midi_step/go",
		{
			["o"] = "MidiStepGoBack", -- Why not just use `Undo`??
		},
	}, --
	-- TODO: reuse the motion function here and call it as a command, similar to insert note chunk fn.
	["G"] = "JumpToNote",
	-- ["z"] = "",
	-- ["x"] = "",
	-- ["c"] = "",
	-- ["v"] = "",
	-- ["b"] = "",

	-- NOTE: A. use toggle to switch direction

	["n"] = "InsertMidiStep_P1",
	["m"] = "InsertMidiStep_m2",
	[","] = "InsertMidiStep_M2",
	["."] = "InsertMidiStep_m3",
	["/"] = "InsertMidiStep_M3",
	["h"] = "",
	["j"] = "InsertMidiStep_P4",
	["k"] = "InsertMidiStep_b5",
	["l"] = "InsertMidiStep_P5",
	[";"] = "InsertMidiStep_m6",
	["y"] = "",
	["u"] = "InsertMidiStep_M6",
	["i"] = "InsertMidiStep_m7",
	["o"] = "InsertMidiStep_M7",
	["p"] = "InsertMidiStep_P8",

	-- NOTE: B. Use small/big letters to determine direction.

	-- small / ascending

	-- big / descending.
	-- InsertMidiStep_unison
	-- InsertMidiStep_asc_min_2
	-- InsertMidiStep_asc_maj_2
	-- InsertMidiStep_asc_min_3
	-- InsertMidiStep_asc_maj_3
	-- InsertMidiStep_asc_prf_4
	-- InsertMidiStep_asc_flt_5
	-- InsertMidiStep_asc_prf_5
	-- InsertMidiStep_asc_min_6
	-- InsertMidiStep_asc_maj_6
	-- InsertMidiStep_asc_min_7
	-- InsertMidiStep_asc_maj_7
	-- InsertMidiStep_asc_prf_8
	-- InsertMidiStep_desc_min_2
	-- InsertMidiStep_desc_maj_2
	-- InsertMidiStep_desc_min_3
	-- InsertMidiStep_desc_maj_3
	-- InsertMidiStep_desc_prf_4
	-- InsertMidiStep_desc_flt_5
	-- InsertMidiStep_desc_prf_5
	-- InsertMidiStep_desc_min_6
	-- InsertMidiStep_desc_maj_6
	-- InsertMidiStep_desc_min_7
	-- InsertMidiStep_desc_maj_7
	-- InsertMidiStep_desc_prf_8

	-- NOTE: C. Use only pitch to get to the closest pitch and then use octave
	-- jumps.

	-- NOTE: D. Use left hand for descending and right hand for acending.
	-- `tghy` are still left for navigation etc plus tab/enter AND space.

	--------------------
	-- thumb keys

	["<TAB>"] = "ToggleMidiStepDirection",
}
