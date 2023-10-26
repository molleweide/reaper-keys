local log = require("utils.log")
local format = require("utils.format")

-- // MIDI HELPER VARIABLE
-- WAS_FILTERED = 1024;  // array for storing which notes are filtered
-- PASS_THRU_CC = 0;

local MODE = 0

-- TYPE_MASK=0xF0;
-- CHANNEL_MASK=0x0F;
-- //OMNI=0x00;
local NOTE_ON = 0x90
local NOTE_OFF = 0x80
local VEL = 0x50 -- dec 80
-- //IN_GM=0x00;
-- //ORPHAN_KILL=0x00;
-- //ORPHAN_REMAP=0x01;
-- //OUT_AD=0x00;
-- //OUT_BFD=0x01;
-- //OUT_SD=0x02;

local midi = {}

-- for i=0, 127 do
--    midi['vkb_send_note_' .. i] = function() sendMidiNote(i) end
-- end
--
--  [1] = { val = function(note_start_index, range)
--          return note_start_index + range - 1 end} -- high thresh

function midi.sendMidiNote_71()
	sendMidiNote(61)
end

function midi.sendMidiNote_70()
	sendMidiNote(70)
end

function midi.sendMidiNote_69()
	sendMidiNote(69)
end

function midi.sendMidiNote_68()
	sendMidiNote(68)
end

function midi.sendMidiNote_67()
	sendMidiNote(67)
end

function midi.sendMidiNote_66()
	sendMidiNote(66)
end

function midi.sendMidiNote_65()
	sendMidiNote(65)
end

function midi.sendMidiNote_64()
	sendMidiNote(64)
end

function midi.sendMidiNote_63()
	sendMidiNote(63)
end

function midi.sendMidiNote_62()
	sendMidiNote(62)
end

function midi.sendMidiNote_61()
	sendMidiNote(61)
end

function midi.sendMidiNote_60()
	sendMidiNote(60)
end

function midi.sendMidiNote_59()
	sendMidiNote(59)
end

function midi.sendMidiNote_58()
	sendMidiNote(58)
end

function midi.sendMidiNote_57()
	sendMidiNote(57)
end

function midi.sendMidiNote_56()
	sendMidiNote(56)
end

function midi.sendMidiNote_55()
	sendMidiNote(55)
end

function midi.sendMidiNote_54()
	sendMidiNote(54)
end

function midi.sendMidiNote_53()
	sendMidiNote(53)
end

function midi.sendMidiNote_52()
	sendMidiNote(52)
end

function midi.sendMidiNote_51()
	sendMidiNote(51)
end

function midi.sendMidiNote_50()
	sendMidiNote(50)
end

function midi.sendMidiNote_49()
	sendMidiNote(49)
end

function midi.sendMidiNote_48()
	sendMidiNote(48)
end

function midi.sendMidiNote_47()
	sendMidiNote(47)
end

function midi.sendMidiNote_46()
	sendMidiNote(46)
end

function midi.sendMidiNote_45()
	sendMidiNote(45)
end

function midi.sendMidiNote_44()
	sendMidiNote(44)
end

function midi.sendMidiNote_43()
	sendMidiNote(43)
end

function midi.sendMidiNote_42()
	sendMidiNote(42)
end

function midi.sendMidiNote_41()
	sendMidiNote(41)
end

function midi.sendMidiNote_40()
	sendMidiNote(40)
end

function midi.sendMidiNote_39()
	sendMidiNote(39)
end

function midi.sendMidiNote_38()
	sendMidiNote(38)
end

function midi.sendMidiNote_37()
	sendMidiNote(37)
end

function midi.sendMidiNote_36()
	sendMidiNote(36)
end

function midi.sendMidiNote_35()
	sendMidiNote(35)
end

function midi.sendMidiNote_34()
	sendMidiNote(34)
end

function midi.sendMidiNote_33()
	sendMidiNote(33)
end

function midi.sendMidiNote_32()
	sendMidiNote(32)
end

function midi.sendMidiNote_31()
	sendMidiNote(31)
end

function midi.sendMidiNote_30()
	sendMidiNote(30)
end

function midi.sendMidiNote_29()
	sendMidiNote(29)
end

function midi.sendMidiNote_28()
	sendMidiNote(28)
end

function midi.sendMidiNote_27()
	sendMidiNote(27)
end

function midi.sendMidiNote_26()
	sendMidiNote(26)
end

function midi.sendMidiNote_25()
	sendMidiNote(25)
end

function midi.sendMidiNote_24()
	sendMidiNote(24)
end

function midi.sendMidiNote_23()
	sendMidiNote(23)
end

function midi.sendMidiNote_22()
	sendMidiNote(22)
end

function midi.sendMidiNote_21()
	sendMidiNote(21)
end

function midi.sendMidiNote_20()
	sendMidiNote(20)
end

function midi.sendMidiNote_19()
	sendMidiNote(19)
end

function midi.sendMidiNote_18()
	sendMidiNote(18)
end

function midi.sendMidiNote_17()
	sendMidiNote(17)
end

function midi.sendMidiNote_16()
	sendMidiNote(16)
end

function midi.sendMidiNote_15()
	sendMidiNote(15)
end

function midi.sendMidiNote_14()
	sendMidiNote(14)
end

function midi.sendMidiNote_13()
	sendMidiNote(13)
end

function midi.sendMidiNote_12()
	sendMidiNote(12)
end

function midi.sendMidiNote_11()
	sendMidiNote(11)
end

function midi.sendMidiNote_10()
	sendMidiNote(10)
end

function midi.sendMidiNote_09()
	sendMidiNote(9)
end

function midi.sendMidiNote_08()
	sendMidiNote(8)
end

function midi.sendMidiNote_07()
	sendMidiNote(7)
end

function midi.sendMidiNote_06()
	sendMidiNote(6)
end

function midi.sendMidiNote_05()
	sendMidiNote(5)
end

function midi.sendMidiNote_04()
	sendMidiNote(4)
end

function midi.sendMidiNote_03()
	sendMidiNote(3)
end

function midi.sendMidiNote_02()
	sendMidiNote(2)
end

function midi.sendMidiNote_01()
	sendMidiNote(1)
end

function midi.sendMidiNote_00()
	sendMidiNote(0)
end

--  TODO
--
--    how can I use key-release here??
--      write an issue > ask Mike about this

function sendMidiNote(note_num)
	reaper.StuffMIDIMessage(MODE, NOTE_ON, note_num, VEL)
	-- wait()
	reaper.StuffMIDIMessage(MODE, NOTE_OFF, note_num, VEL)
end

-- this string color makes it easier to read...
local easy_read = [[
\*\ eaper.StuffMIDIMessage(integer mode, integer msg1, integer msg2, integer msg3)

  Stuffs a 3 byte MIDI message into either the Virtual MIDI Keyboard queue, or
  the MIDI-as-control input queue, or sends to a MIDI hardware output.  mode=0
  for VKB, 1 for control (actions map etc), 2 for VKB-on-current-channel; 16
  for external MIDI device 0, 17 for external MIDI device 1, etc; see
  GetNumMIDIOutputs, GetMIDIOutputName.

\*\ integer reaper.GetNumMIDIOutputs()

  returns max number of real midi hardware outputs

\*\ boolean retval, string nameout = reaper.GetMIDIOutputName(integer dev, string nameout)

  returns true if device present
]]

-- this is a test function i copied from MPLs scripts
midi.reorderNotes = function()
	-- for key in pairs(reaper) do
	-- 	_G[key] = reaper[key]
	-- end

	function ReorderNotes(percent)
		local ME = reaper.MIDIEditor_GetActive()
		if not ME then
			return
		end
		local take = reaper.MIDIEditor_GetTake(ME)
		if not take or not reaper.TakeIsMIDI(take) then
			return
		end

		local last_t
		for i = 1, ({ reaper.MIDI_CountEvts(take) })[2] do
			local _, selected, muted, startppqpos, endppqpos, chan, pitch, vel = MIDI_GetNote(take, i - 1)
			if selected and i > 1 then
				local len = endppqpos - startppqpos
				startppqpos = last_t.endppqpos + 1
				endppqpos = startppqpos + len
				reaper.MIDI_SetNote(take, i - 1, true, muted, startppqpos, endppqpos, chan, pitch, vel, true)
			end
			last_t = { startppqpos = startppqpos, endppqpos = endppqpos }
		end
		reaper.MIDI_Sort(take)
	end

	Undo_BeginBlock()
	ReorderNotes()
	Undo_EndBlock("Reorder notes", 0)
end

function midi.getMidiValidContext()
	local ME = reaper.MIDIEditor_GetActive()
	local take = reaper.MIDIEditor_GetTake(ME)
	local retval = true
	if not ME or (not take or not reaper.TakeIsMIDI(take)) then
		retval = false
	end
	return retval, ME, take
end

--
-- operator / command
--
-- insert chunks of midi notes
--

function midi.insertMidiNoteChunk(meta, opts)
	opts = opts or {}
	-- log.user("META:", format.block(meta))

	-- TODO: move to definitions/constants.lua
	local midi_insertion_data_default = {
		selected = false,
		muted = false,
		chan = 0,
		noSortIn = true,
	}

	local ret, ME, take = midi.getMidiValidContext()
	if not ret then
		return
	end

	local cursor_pos = reaper.GetCursorPosition()
	local active_note_row = reaper.MIDIEditor_GetSetting_int(ME, "active_note_row")

	-- NOTE: when run as an operator + motion, then the LTr is already reset.
	-- so i have to pass down the start/end positions manually via opts.

	-- local start_sel, end_sel = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)

	local t_note_pitches = {}
	local t_midi_notes = {}

	-- duration
	local sixteen_note_len = 0.25
	local step_len = sixteen_note_len
	local note_end_gap = 0.005
	local note_duration = sixteen_note_len - note_end_gap

	if opts.move_cursor then
	  -- FIX: GetCursorPosition should be collected inside ASF??
		local new_pos = meta.end_pos and meta.endpos or reaper.GetCursorPosition() + step_len
		reaper.SetEditCurPos(new_pos, false, false)
	end

	-- FIX: handle incoming chord here...

	if opts.chord then
		for _, chord_rel_pitch in ipairs(opts.chord[2]) do
			table.insert(t_note_pitches, active_note_row + chord_rel_pitch - 1)
		end
	else
		table.insert(t_note_pitches, active_note_row)
	end

	--
	-- NOTE:
	--

	local function note_start()
		if meta.action_type == "timeline_operator" then
			return meta.start_pos
		elseif meta.action_type:match("command$") then
			return cursor_pos
		end
	end

	local function note_end()
		log.user("!!", format.block(meta))

		if meta.action_type == "timeline_operator" then
			return meta.end_pos
		-- elseif meta.action_type == "command" then
		elseif meta.action_type:match("command$") then
			return cursor_pos + note_duration
		end
	end

	for i in ipairs(t_note_pitches) do
		local n = {
			pitch = t_note_pitches[i],
			time_pos_start = note_start(),
			time_pos_end = note_end(),
		}
		table.insert(t_midi_notes, n)
		log.user("N:", format.block(n))
	end

	-- log.user(format.block(t_midi_notes))

	for _, t_note in ipairs(t_midi_notes) do
		local ret = reaper.MIDI_InsertNote(
			take,
			midi_insertion_data_default.selected,
			midi_insertion_data_default.muted,
			reaper.MIDI_GetPPQPosFromProjTime(take, t_note.time_pos_start),
			reaper.MIDI_GetPPQPosFromProjTime(take, t_note.time_pos_end),
			midi_insertion_data_default.chan,
			t_note.pitch,
			80,
			midi_insertion_data_default.noSortIn
		)
	end

	reaper.MIDI_Sort(take)
end

return midi
