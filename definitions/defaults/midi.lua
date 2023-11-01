return {
	timeline_selector = {
		["s"] = "SelectedNotes", -- ??
	},
	timeline_operator = {
		["d"] = "CutNotes",
		["y"] = "CopyNotes",
		["c"] = "FitNotes",
		["a"] = "InsertNote",
		["A"] = "InsertNoteBlock", -- testing
		["Q"] = "InsertMidiBlockPickerOperator", -- NOTE: test connect picker to motion
		["g"] = "JoinNotes",
		["s"] = "SelectNotes",
		["z"] = "MidiZoomTimeSelection",
	},
	timeline_motion = {
		["l"] = "RightMidiGridDivision",
		["h"] = "LeftMidiGridDivision",
		["("] = "MidiTimeSelectionStart",
		[")"] = "MidiTimeSelectionEnd",
		["w"] = "NextNoteStart",
		["b"] = "PrevNoteStart",
		["W"] = "NextNoteSamePitchStart",
		["B"] = "PrevNoteSamePitchStart",
		["e"] = "EventSelectionEnd",
	},
	command = {
		["C"] = "InsertNoteBlockCommand", -- testing
		["G"] = "InsertMidiBlockPicker", -- testing
		["n"] = "AddNextNoteToSelection",
		["N"] = "AddPrevNoteToSelection",

		-- TODO: ZOOM BETTER SO THAT WE CAN
		-- make sure that we are in the world. oooh and also create more advanced
		-- zoom settings so that you can do zoom bar, zoom N bars, zoom region,
		-- zoom loop, etc.

		["+"] = "MidiZoomInHoriz",
		["-"] = "MidiZoomOutHoriz",
		-- ["gg"] = "TopNote",
		-- ["G"] = "BottomNote",
		["<C-+>"] = "MidiZoomInVert",
		["<C-->"] = "MidiZoomOutVert",
		["Z"] = "CloseWindow",
		["p"] = "MidiPaste",
		["P"] = "NoteRowPattern",
		["S"] = "UnselectAllEvents",
		["Y"] = "CopySelectedEvents",
		["D"] = "CutSelectedEvents",
		["k"] = "PitchUp",
		["j"] = "PitchDown",
		["K"] = "PitchUpOctave",
		["zp"] = "MidiZoomContent",
		-- [";"] = "MoveNotesToEditCursor", -- !!!!!!!!!!
		["J"] = "PitchDownOctave",
		["<C-b>"] = "PitchUpOctave",
		["<C-f>"] = "PitchDownOctave",
		["<C-u>"] = "PitchUp7",
		["<C-d>"] = "PitchDown7",
		["V"] = "SelectAllNotesAtPitch",
		["<M-k>"] = "MoveNoteUpSemitone",
		["<M-j>"] = "MoveNoteDownSemitone",
		["<M-K>"] = "MoveNoteUpOctave",
		["<M-J>"] = "MoveNoteDownOctave",
		["<M-l>"] = "MoveNoteRight", -- move edit cursos only | needs to be fixed!!
		["<M-h>"] = "MoveNoteLeft", -- move edit cursor only
		-- ["<M-L>"] = "MoveNoteRight", -- move note selection
		-- ["<M-H>"] = "MoveNoteLeft",  -- move note selection
		["<SPC>"] = {
			"+leader commands",
			{
				["m"] = { "+midi", {
					["w"] = "SetModeMidiStep",
				} },
			},
		},
	},
	midi_step_command = {

		-- okay so fixing the direction now is goig to be fuckNg mazing and then

		-- TODO: today
		-- ~ use [single|chord|pattern]
		-- ~ restrict pitches to closed set [0, 127]

		-- LEFT HAND
		["q"] = "", -- jump forward by predefined (*) length
		["w"] = "", -- (*) set predefined length.
		["e"] = "",
		["r"] = "",
		["t"] = "", --
		["a"] = "SetModeNormal", -- set pause/silent
		["s"] = "ToggleMidiStepSilent",
		["d"] = {
			"+setNextOctave",
			{
				["d"] = "ToggleMidiStepDirection",
				-- set dir up
				-- set dir down
			},
		},

		-- FIX: currently, octave and direction are set simultaneously
		-- which can cause wierd behavior if you set octave down but keep direction
		-- up. MAYBE the direction should be changed if octae direction is being set?
		["f"] = {
			"+setNextOctave",
			{
				["u"] = "MidiStepSetNextOctaveUp",
				["d"] = "MidiStepSetNextOctaveDown",
			},
		},

		["g"] = "", --
		["G"] = "JumpToNote", --
		["z"] = "",
		["x"] = "",
		["c"] = "",
		["v"] = "",
		["b"] = "",
		-- RIGHT HAND
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

		-- THUMBS
		["<TAB>"] = "ToggleMidiStepDirection", -- TODO: integrate, not used atm..
	},
}
