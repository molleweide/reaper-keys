-- TODOS:
--
--  ~ fix: move active note row with w/b
--  ~ new: set active note row to current selection
--  ~


-- now these files are pretty much fucked.

-- TEST/IMPROVEMENTS:
-- preferences -> midi editor -> `selection is linked to editability` ??
-- preferences -> midi editor -> `close editor when all active items have been deleted` ??
-- preferences -> midi editor -> uncheck `avoid setting items from other track editable` ??
-- set opacity for secondary items
-- set custom color palette

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
		["Q"] = {
			"+pattern/pickers",
			{
				["Q"] = "InsertMidiBlockPickerOperator", -- NOTE: test connect picker to motion
			},
		},
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
		-- ["???"] = "Next",
		["b"] = "PrevNoteStart",
		["B"] = "PrevNoteSamePitchStart",
		["e"] = "EventSelectionEnd",
	},
	command = {
		["Q"] = {
			"+pattern/pickers",
			{
				["i"] = "InsertNoteBlockCommand", -- FIX: doesn't work...... bc the func is using meta or opts now..
				["I"] = "InsertMidiBlockPicker",
				["W"] = "NoteRowPattern",

				-- TODO: insert pattern from string
				-- 1. use fzf
				-- 2. results list should represent patterns from state history
				-- 3. so that I can easilly search and select already created patterns.
				-- 4. <CR> -> use selected pattern
				-- 5. <C-r> -> set text input element to selection for further editing.
				-- 6. allow for further editing
				-- 7. ...
				["E"] = "MidiPattern_InsertFromString_at_cursor",
				["e"] = "MidiPattern_InsertFromString_at_current_measure",

				["J"] = "PickerTracksWithMidiItemsAtSameTime", -- switch midi item to another track in the same time/region/position.
				["M"] = "PickerExistingMidiItemsAtSameTime",
				-- TODO: midi pattern string
				-- 1 and move
				-- 2 at beginning of measure
				-- 3 at beginning of midi take
				--
				-- TODO: merge pattern and chord.
				--
				-- TODO: randomize pitches over rhythm pattern from scale/chord in key.
				-- TODO: arpeggiate
				-- pass opts via fzf gui input. so that I can.
			},
		},
		["C"] = "InsertNoteBlockCommand",
		["G"] = "InsertMidiBlockPicker",
		--  [""] = "SelectChord",   -- test and see how midi note selections can be improved.
		--  [""] = "SelectNotesFromScale",
		--  [""] = "SelectNotes_NextVertical", -- use a threshold variabe to select evts that are close in time.
		--  [""] = "SelectNotes_PrevVertical",
		--  [""] = "CycleChords", -- if not notes then select nearest chord or vertical selection
		["n"] = "AddNextNoteToSelection",
		["N"] = "AddPrevNoteToSelection",
		["+"] = "MidiZoomInHoriz",
		["-"] = "MidiZoomOutHoriz",
		-- ["gg"] = "TopNote",
		-- ["G"] = "BottomNote",
		["<C-+>"] = "MidiZoomInVert",
		["<C-->"] = "MidiZoomOutVert",
		["Z"] = "CloseWindow", -- TODO: rename to something more descriptive.
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
