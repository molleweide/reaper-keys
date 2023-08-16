local log = require("utils.log")
local format = require("utils.format")

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

return midi_patterns
