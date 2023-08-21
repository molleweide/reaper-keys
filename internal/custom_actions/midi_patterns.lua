local log = require("utils.log")
local format = require("utils.format")

local reaper_state = require("utils.reaper_state")

local s = require("utils.string")

local midi_patterns = {}

local function getMidiValidContext()
	local ME = reaper.MIDIEditor_GetActive()
	local take = reaper.MIDIEditor_GetTake(ME)

	local retval = true
	if not ME or (not take or not reaper.TakeIsMIDI(take)) then
		retval = false
	end
	return retval, ME, take
end

local function randomBool()
	return math.floor(math.random() + 0.5) == 1
end

midi_patterns.insertPatternForCurrentBarAndNoteRow = function()
	local ret, ME, take = getMidiValidContext()
	if not ret then
		return
	end

	local cursor_pos = reaper.GetCursorPosition()
	local t_midi_events = { reaper.MIDI_CountEvts(take) }
	local active_note_row = reaper.MIDIEditor_GetSetting_int(ME, "active_note_row")
	local t_pattern = {}
	local sixteen_note_len = 0.125
	local note_end_gap = 0.005
	local note_duration = sixteen_note_len - note_end_gap
	local retval, measures, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats(0, cursor_pos)

	local insertion_data = {
		selected = false,
		muted = false,
		chan = 0,
		noSortIn = true,
	}

	for i = 1, t_midi_events[2] do
		local note_idx = i - 1
		local _, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, note_idx)

		-- local note_time = reaper.MIDI_GetProjTimeFromPPQPos(take, startppqpos)
		-- local retval, measures, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats(0, reaper.GetCursorPosition())
		-- log.user("note ppq time:", note_time)
		-- log.user("chan", chan)

		if pitch == active_note_row then
			-- reaper.MIDI_SetNote(take, note_idx, true, muted, startppqpos, endppqpos, chan, pitch, vel, true)
			reaper.MIDI_DeleteNote(take, note_idx)
			-- else
			-- 	-- reaper.MIDI_SetNote(take, note_idx, false, muted, startppqpos, endppqpos, chan, pitch, vel, true)
		end
	end

	-- log.user(">>>", cursor_pos, retval, measures, cml, fullbeats, cdenom)

	for i = 0, 15 do
		local note_start = i * sixteen_note_len
		table.insert(t_pattern, {
			flag = randomBool(),
			time_pos_start = note_start,
			time_pos_end = note_start + note_duration,
		})
	end

	log.user(format.block(t_pattern))

	for _, t_note in ipairs(t_pattern) do
		if t_note.flag then
			local ret = reaper.MIDI_InsertNote(
				take,
				insertion_data.selected,
				insertion_data.muted,
				reaper.MIDI_GetPPQPosFromProjTime(take, t_note.time_pos_start),
				reaper.MIDI_GetPPQPosFromProjTime(take, t_note.time_pos_end),
				insertion_data.chan,
				active_note_row,
				80,
				insertion_data.noSortIn
			)
		end
	end

	reaper.MIDI_Sort(take)
end

-- NOTE: PATTERN SPEC
--
--  -> `134C` first, third, and fourth beats should have randomized sixteenth notes
--
--  -> `13B` first and third beat should have random eighth notes
--
--        (default is to specify QN with digits)
--
--        (use delimiter to separate digits if above 10, eg. 9,10,11,60)
--
--        this could actually be quite powerful for inserting rhythms.
--
--        -> `.15,65,98,00(15)` use (.) to specify that digits symbolize which
--            eight note i am refering to and the chars coming after the digits
--            specify how the notes should be inserted/randomized. eg use 16th, 8th,
--            triplets or whatever notes for the beats.
--
--

local state_table_name = "midipatterns"

-- FIX: rename to `createNewPatternAndInsert`
midi_patterns.insertPatternFromString = function()
	local midi_patterns_state = reaper_state.get(state_table_name)

	log.user("PREV PATTERN:", format.block(midi_patterns_state))

	local user_input_opts = {
		-- todo:...
	}
	local input_placeholder = "a b c d x4"
	local input_field_width = "extrawidth=350"
	local caption_csv = string.format("%s,%s", input_placeholder, input_field_width)
	local retvals_csv = ""

	-- pattern options
	local pattern_opts = {
		-- todo...
	}
	local pattern_sep = " "

	local _, str_pat_input = reaper.GetUserInputs("pattern:", 1, input_placeholder, caption_csv, retvals_csv)
	local t_pattern_strings = s.split(str_pat_input, pattern_sep)

	log.user("PATTERN STRING:", format.block(t_pattern_strings))

	-- NOTE: EXAMPLES
	--
	-- -> SHORTHANDS:
	--
	--  a = 1/4
	--  b = 1/8
	--  c = 1/16 notes
	--
	--  eg. a $4 -> insert 4 QNs of quarter notes
	--      b $2 -> insert 2 QN of consecutive 16th notes
	--      c $8 -> insert 8 QNs of 1/8 notes
	--
	--  . (period) -> empty QN
	--
	--  ..       -> two empty quarter notes
	--
	--  .3     -> three empty QNs
	--
	--  ^     -> fill rest of measure with empty QNs
	--             eg. if you have very large meter eg 11/4 then [ . a ^ x5 ]
	--             would create a pattern of length 11 QNs
	--
	--
	--  -> SPECIFY EXPLICIT PATTERNS:
	--
	--    xoxx oxoo xkxo xkoo
	--
	--    x,k  = hit
	--    o    = no hit
	--
	--    () use () to indicate triples
	--
	--
	--  xx(xxx)    -> (xxx) indicates a triplet 24th note
	--
	--  [xx]    -> [] indicates 32th notes
	--
	--  {}#
	--
	--
	--  +(N)/-N    -> use to alternate note rows up or down, eg if you want
	--                 get the feel of alternating hands
	--                 x x x...
	--                  x x
	--
	--  LAST CHUNK
	--
	--  xN or $N    -> to indicate number of repetitons of pattern
	--
	--  !      -> don't extend midi item if pattern overflows take end point.

	-- TODO: parse each QN instance
	--
	-- ~ each delimited segment could describe something that is longer than
	--   a QN - truncate info so that only QNs length blocks are used.

	-- TODO: last repeat $5
	--   handle repetition of pattern.
	--   eg. ooxx 4$ -> repeat ooxx four times

	reaper_state.set(state_table_name, { prev_pattern_string = str_pat_input })
end

midi_patterns.editPrevPatternAndInsert = function() end

midi_patterns.repeatPrevPatternFromCurrentMeasure = function() end

midi_patterns.repeatPrevPatternFromCursor = function() end

return midi_patterns
