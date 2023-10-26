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
		-- LEFT HAND
		["q"] = "InsertMidiStep_P1",
		["w"] = "InsertMidiStep_m2",
		["e"] = "InsertMidiStep_M2",
		["r"] = "InsertMidiStep_m3",
		["t"] = "InsertMidiStep_m3", --
		["a"] = "InsertMidiStep_P1",
		["s"] = "InsertMidiStep_m2",
		["d"] = "InsertMidiStep_M2",
		["f"] = "InsertMidiStep_m3",
		["g"] = "InsertMidiStep_m3", --
		["z"] = "InsertMidiStep_P1",
		["x"] = "InsertMidiStep_m2",
		["c"] = "InsertMidiStep_M2",
		["v"] = "InsertMidiStep_m3",
		["b"] = "ToggleMidiStepSilent", -- toggle mute/no-note
		-- RIGHT HAND
		["n"] = "ToggleMidiStepSilent", -- toggle mute/no-note
		["m"] = "InsertMidiStep_m6",
		[","] = "InsertMidiStep_M6",
		["."] = "InsertMidiStep_m7",
		["/"] = "InsertMidiStep_M7",
		["h"] = "InsertMidiStep_M3",
		["j"] = "InsertMidiStep_M3",
		["k"] = "InsertMidiStep_P4",
		["l"] = "InsertMidiStep_b5",
		[";"] = "InsertMidiStep_P5", --
		["y"] = "InsertMidiStep_M3",
		["u"] = "InsertMidiStep_M3",
		["i"] = "InsertMidiStep_P4",
		["o"] = "InsertMidiStep_b5",
		["p"] = "InsertMidiStep_P5", --

		-- THUMBS
		["<TAB>"] = "ToggleMidiStepDirection",
	},
}
