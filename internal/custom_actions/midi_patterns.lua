local log = require("utils.log")
local format = require("utils.format")

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
--  -> specify explicit patterns:
--    xoxx oxoo xkxo xkoo
--
--    x,k  = hit
--    o    = no hit
--
--    () use () to indicate triples



midi_patterns.insertPatternFromString = function()
	-- ~ DRUM PATTERNS -> take input string -> store to project extstate/state ->
	-- same way as `last search` is stored

	-- 2. store to project ext state.
	-- 3. reuse logic from above to insert midi

	local input_placeholder = "a b c d x4"

	local input_field_width = "350"

	-- use string.format
	local caption_csv = input_placeholder .. ",extrawidth=" .. input_field_width
	local retvals_csv = ""

	-- used for string splitting the input string.
	local pattern_sep = " "

	-- NOTE: USER INUT

	-- boolean retval, string retvals_csv = reaper.GetUserInputs(string title, integer num_inputs, string captions_csv, string retvals_csv)
	--
	-- Get values from the user.
	--
	-- If a caption begins with *, for example "*password", the edit field will
	-- not display the input text.
	--
	-- Maximum fields is 16. Values are returned as a comma-separated string.
	-- Returns false if the user canceled the dialog. You can supply special
	-- extra information via additional caption fields: extrawidth=XXX to
	-- increase text field width, separator=X to use a different separator for
	-- returned fields.

	-- retval, retvals_csv = reaper.GetUserInputs("Rename Tracks", 1, "Name:,Separator,extrawidth=200", "")
	-- temp2, CCC = reaper.GetUserInputs("New Editcursor-position", 1, "Position in seconds,extrawidth=350", temp)
	-- local retval, NameFile = reaper.GetUserInputs("Name File", 1, "Name File,extrawidth=150", "-Stem-")

	local _, str_pat_input = reaper.GetUserInputs("pattern:", 1, input_placeholder, caption_csv, retvals_csv)

	local t_pattern_strings = s.split(str_pat_input, " ")

	-- TODO: STORE TO EXT STATE
	-- previous_midi_pattern_string = xyz

	-- FIX: pattern parsing and note insertion

	log.user("PATTERN STRING:", format.block(t_pattern_strings))
end

return midi_patterns
