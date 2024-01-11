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

-- TODO: INSERT PATTERN FROM STRING
-- 1. use fzf
-- 2. results list should represent patterns from state history
-- 3. so that I can easilly search and select already created patterns.
-- 4. <CR> -> use selected pattern
-- 5. <C-r> -> set text input element to selection for further editing.
-- 6. allow for further editing
-- 7. ...

-- TODO: MIDI STEP MODE NOTES
--
-- ~ use [single|chord|pattern]
-- ~ restrict pitches to closed set [0, 127]
-- ~ use eg. shift keys for ascending/descending notes, so that I don't have
--     to hit a char to toggle direction everytime. this might be slow over time.
-- ~ keys to incr/decr step size.
-- ~ fuzzy finder -> select current step_size.
-- ~ put the most regularly used step_sizes/note lengths as single key switches.
-- ~ Maybe -> use left hand for notes, and right hand for changing step_size,
--     and shift modifier keys to switch direction.
-- ~ use ALT key for: ???
--     move previous inserted note(s) up down chromatically, so that I can error correct.
--       >>> Always make the last inserted note "selected" so that it becomes easy
--           to just shift selection up/down.
-- ~ ALT-(interval key/pitch key) >> throw up chord picker for each note.
--        Eg. `alt-(minor3rd)` -> opens a picker and inserts chord at minor
--        third up/down from prev position
-- ~ use modifier keys + key to select specific length for "pause and move"
-- ~ octave-operator: key preceding intreval/pitch hits that makes next insertion
--        insert at ( interval + octave )
--
-- FIX: set octave -> currently, octave and direction are set simultaneously
-- which can cause wierd behavior if you set octave down but keep direction
-- up. MAYBE the direction should be changed if octae direction is being set?

return {
  midi_selector = {
    -- [""] = "ME_UpperLeft",
    -- [""] = "ME_UpperRight",
    -- [""] = "ME_LowerLeft",
    -- [""] = "ME_LowerRight",
    ["i"] = {
      "+inner",
      {
        ["a"] = "MidiInnerActiveTake",
        ["U"] = "MidiInnerActiveTakeAbove",
        ["D"] = "MidiInnerActiveTakeBelow",

        ["h"] = "NoteChunkHorz", -- select all notes at cursor that are X distance apart in time
        -- [""] = "Measure",
        -- [""] = "xxx", -- 16th notes apart.
        -- [""] = "xxx" -- eight notes
        -- [""] = "xxx" -- beat
        -- [""] = "xxx"
        -- [""] = "xxx"
        ["n"] = "UserInput_FilterNotesByString", --
        -- ["p"]
        -- select notes in
        -- octave
        -- two octaves up
        -- N notes up / down
        -- N notes up AND down.
        -- Eg. select 16th notes within current octave.
        --
        -- Select notes above pitch
      },
    },
  },
  midi_operator = {
    ["U"] = "MidiCut", -- MidiCutNotes
    ["M"] = "SelectNoteRows",
  },
  -- RENAME: to note_row_motion
  pitch_motion = {
    ["k"] = "NextPitch", -- move pitch row up
    ["j"] = "PrevPitch", -- move pitch row down
    [""] = "NextNotesBig",
    [""] = "PrevNotesBig",
  },
  -- these motions both work on note row and timeline together, so that
  -- you can eg target rectangular areas of midi data.
  midi_motion = {},
  timeline_selector = {
    ["s"] = "SelectedNotes",
  },
  timeline_operator = {
    ["d"] = "CutNotes", -- TODO: make custom
    ["y"] = "CopyNotes", -- TODO: make custom
    ["c"] = "FitNotes",
    ["a"] = "InsertNote",
    ["A"] = "InsertNoteBlock", -- Use this instead of build in
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
  -- NOTE: midi time line motions only move the edit cursor.
  -- >> This makes it impossible to discern which note is moved to
  -- in thick clusters of notes. Therefore I need custom next/prev note
  -- commands that move BOTH edit cursor AND note row.
  timeline_motion = {
    ["l"] = "RightMidiGridDivision",
    ["h"] = "LeftMidiGridDivision",
    ["("] = "MidiTimeSelectionStart",
    [")"] = "MidiTimeSelectionEnd",
    ["w"] = "NextNoteStart", -- horizontal, ie. iterates pitch indices.
    ["W"] = "NextNoteStartHorizontal", -- TODO:
    ["b"] = "PrevNoteStart",
    ["B"] = "PrevNoteSamePitchStart", -- TODO: replace this with prev note horizontal
    ["e"] = "EventSelectionEnd",
    -- [""] = "PrevItemStart", -- TODO:
    -- [""] = "NextItemStart", -- TODO:
    -- [""] = "Prev/Next Vertical", -- chord...
  },
  command = {
    ["Q"] = {
      "+pattern/pickers",
      {
        ["i"] = "InsertNoteBlockCommand", -- FIX: doesn't work...... bc the func is using meta or opts now..
        ["I"] = "InsertMidiBlockPicker",
        ["W"] = "NoteRowPattern",

        ["E"] = "MidiPattern_InsertFromString_at_cursor",
        ["e"] = "MidiPattern_InsertFromString_at_current_measure",

        ["R"] = "MidiPattern_InsertRandom16thNotes_fill_bar",
        ["F"] = "Midi_ChangeActiveSelection",

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
    ["C"] = "InsertNoteBlockCommand", -- TODO: move this to a leader
    ["G"] = "InsertMidiBlockPicker", -- TODO: move to leader
    --  [""] = "SelectChord",   -- test and see how midi note selections can be improved.
    --  [""] = "SelectNotesFromScale",
    --  [""] = "SelectNotes_NextVertical", -- use a threshold variabe to select evts that are close in time.
    --  [""] = "SelectNotes_PrevVertical",
    --  [""] = "CycleChords", -- if not notes then select nearest chord or vertical selection
    ["n"] = "AddNextNoteToSelection",
    ["N"] = "AddPrevNoteToSelection",

    -- TODO: Zoom mode, that senses if you're in ME/main.

    ["zp"] = "MidiZoomContent",
    ["+"] = "MidiZoomInHoriz",
    ["-"] = "MidiZoomOutHoriz",
    ["<C-+>"] = "MidiZoomInVert", -- FIX: bigger increment steps.
    ["<C-->"] = "MidiZoomOutVert", -- FIX: bigger increment steps.

    -- NOTE: migrate these to motions.
    ["g"] = {
      "+midi_go",
      {
        ["g"] = "TopNote",
        ["s"] = "MoveCurrentNoteRowToClosestSeleced",
        -- if you come from the right, then it should jump to the end of the
        -- last selected note, and to the start of first selected if coming
        -- from the left.
        ["S"] = "MoveCursorToSelection",
        -- ["h"] = "LeftMostNote",
        -- ["j"] = "TopNote",
        -- ["k"] = "BottomNote",
        -- ["l"] = "RightMostNote",
        -- ["u"] = "TopLeftMostNote",
        -- ["i"] = "TopRightMostNote",
        -- ["m"] = "BottomLeftMostNote",
        -- [","] = "BottomRightMostNote",
      },
    },
    -- TODO: move to motion
    -- ~ add prefix count to specify which pitch row to jump to.
    ["G"] = "BottomNote",
    ["Z"] = {
      "+me_window",
      {
        ["Z"] = "CloseWindow",
        ["E"] = "JumpToMain",
      },
    },

    ["p"] = "MidiPaste", -- TODO: make custom
    ["P"] = "NoteRowPattern",
    ["S"] = "UnselectAllEvents",
    ["Y"] = "CopySelectedEvents",

    ["D"] = {
      "+cut",
      {
        ["D"] = "CutSelectedEvents",
        -- NOTE: these should maybe become `midi_selector`
        ["A"] = "NotesAfter",
        -- [""] = "NotesBefore",
        -- [""] = "TopLeftNotes",
        -- [""] = "BottomLeftNotes",
        -- [""] = "TopRightNotes",
        -- [""] = "BottomRightNotes",
      },
    },

    -- [""] = "CutNotesAfterCursorOfSamePitch", -- TODO:
    -- [""] = "CutNotesBeforeCursorOfSamePitch", -- TODO:

    ["k"] = "PitchUp",
    ["j"] = "PitchDown",

    ["K"] = "PitchUpOctave", -- rewrite this as repeat running pitch_motions.

    -- [";"] = "MoveNotesToEditCursor", -- !!!!!!!!!!
    ["J"] = "PitchDownOctave",

    -- NOTE: Need commands AND oper/motion - maybe `fit` does it.
    --
    -- [""] = "ExtendNotesToNextClosestGrid",
    -- [""] = "ExtendNotesToNextClosestBeat",
    -- [""] = "ExtendNotesToNextClosestMeasure",
    -- [""] = "MakeNotesLegato",
    -- [""] = "ForceNotesToLength_UI", -- use fzf window -> specify custom length or select predefined.

    -- NOTE: Say that I select a note, then i want to be able to extend my selection
    -- in various directions, up down, left and right.
    -- Maybe, there should be a dedicated mode for visually selecting notes?
    --
    -- [""] = "ExtendNoteSelectionToNoteRowAbove",
    -- [""] = "...NoteRowAbove"

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
        ["m"] = {
          "+midi",
          {
            ["w"] = "SetModeMidiStep",
            -- todo: ext state -> do this and see where it goes...
            -- [""] = "Toggle_MoveCursorWith_Motions",
          },
        },
      },
    },
  },

  -- RENAME: `midi-step-right-hand-insert`
  midi_step_command = {
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

    -- NOTE: C. Use only pitch to get to the closest pitch and then use octave
    -- jumps.

    -- NOTE: D. Use left hand for descending and right hand for acending.
    -- `tghy` are still left for navigation etc plus tab/enter AND space.

    --------------------
    -- thumb keys

    ["<TAB>"] = "ToggleMidiStepDirection",
  },
  midi_step_both_hands = {},
}
