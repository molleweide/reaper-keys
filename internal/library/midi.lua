local log = require("utils.log")
local format = require("utils.format")
local project_state = require("utils.project_state")
local tbl = require("utils.table")

--
-- UTILITY FOR DEALING WITH MIDI DATA
--

-- TODO: look at chordgun for good midi library functions

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

-- -- this is a test function i copied from MPLs scripts
-- midi.reorderNotes = function()
-- 	-- for key in pairs(reaper) do
-- 	-- 	_G[key] = reaper[key]
-- 	-- end
--
-- 	function ReorderNotes(percent)
-- 		local ME = reaper.MIDIEditor_GetActive()
-- 		if not ME then
-- 			return
-- 		end
-- 		local take = reaper.MIDIEditor_GetTake(ME)
-- 		if not take or not reaper.TakeIsMIDI(take) then
-- 			return
-- 		end
--
-- 		local last_t
-- 		for i = 1, ({ reaper.MIDI_CountEvts(take) })[2] do
-- 			local _, selected, muted, startppqpos, endppqpos, chan, pitch, vel = MIDI_GetNote(take, i - 1)
-- 			if selected and i > 1 then
-- 				local len = endppqpos - startppqpos
-- 				startppqpos = last_t.endppqpos + 1
-- 				endppqpos = startppqpos + len
-- 				reaper.MIDI_SetNote(take, i - 1, true, muted, startppqpos, endppqpos, chan, pitch, vel, true)
-- 			end
-- 			last_t = { startppqpos = startppqpos, endppqpos = endppqpos }
-- 		end
-- 		reaper.MIDI_Sort(take)
-- 	end
--
-- 	Undo_BeginBlock()
-- 	ReorderNotes()
-- 	Undo_EndBlock("Reorder notes", 0)
-- end

--
-- operator / command
--
-- insert chunks of midi notes
--

-- TODO: make sure I don't use midi step state when executing as a regular
-- command. >>> maybe the midi_step_state should be passed down to the
-- insertMidiNoteChunk func - then i can just chek if meta.mode == midi_step,
-- and then also only retrieve the state if the correct mode
--
-- rename: buildNoteChunkForInsertion()
--
function midi.insertMidiNoteChunk(meta, opts)
	opts = opts or {}

	local exists, midi_step_state = midi.get_midi_step_state()

	log.user("midi_step_state:", exists, format.block(midi_step_state))

	local ret, ctxm = require("library.midi_editor").getMidiValidContext()
	if not ret then
		return
	end

	-- TODO: move to
	-- lib/cursor.get()
	-- lib/midi.get_active_note_row()
	-- lib/midi.get_important_contexts() -- merge getMidiValidContext with these and return table.
	local cursor_pos = reaper.GetCursorPosition()
	local active_note_row = reaper.MIDIEditor_GetSetting_int(ctxm.editor, "active_note_row")

	local t_note_pitches = {}
	local t_midi_notes = {}
	local sixteen_note_len = 0.25 / 2
	local step_len = sixteen_note_len
	local note_end_gap = 0.005
	local note_duration = sixteen_note_len - note_end_gap
	local direction_mult = midi_step_state.direction and 1 or -1
	local octave_add = midi_step_state.octave_next and (midi_step_state.octave_next * 12) or 0

	if opts.move_cursor then
		local new_pos = meta.end_pos and meta.endpos or reaper.GetCursorPosition() + step_len
		reaper.SetEditCurPos(new_pos, false, false)
	end

	if midi_step_state.silent then
		return
	end

	-- fix: handle incoming chord here...
	--
	-- fix: handle single incoming pitches as well??
	--
	-- fix: handle direction ->
	--
	--
	-- FIX: If chord, then we don't move the pitch/active or whatever,
	-- ONLY if single note?
	-- Or should there be a possible to insert a chord and also move the
	-- active center pitch all at once?

	if opts.chord then
		for _, chord_rel_pitch in ipairs(opts.chord[2]) do
			-- TODO: ADD OCTAVE
			local new_pitch = active_note_row + octave_add + (chord_rel_pitch - 1) * direction_mult

			table.insert(t_note_pitches, new_pitch)
		end
	else
		table.insert(t_note_pitches, active_note_row)
	end

	-- move active note row
	reaper.MIDIEditor_SetSetting_int(
		ctxm.editor,
		"active_note_row",
		active_note_row + octave_add + (opts.chord[2][1] - 1) * direction_mult
	)

	for i in ipairs(t_note_pitches) do
		local t_new_note = {}
		t_new_note.pitch = t_note_pitches[i]

		if meta.action_type == "timeline_operator" then
			t_new_note.time_pos_start = meta.start_pos
			t_new_note.time_pos_end = meta.end_pos
		elseif meta.action_type:match("command$") then
			t_new_note.time_pos_start = cursor_pos
			t_new_note.time_pos_end = cursor_pos + note_duration
		end
		table.insert(t_midi_notes, t_new_note)
	end

	log.user("###", format.block(t_midi_notes))

	midi.insert_notes({
		take = ctxm.take,
		notes = t_midi_notes,
	})

	-- reset state
	midi_step_state.octave_next = nil
	project_state.overwrite("mode_state", "midi_step", midi_step_state)
end

-- todo: move to state.

midi.get_midi_step_state = function()
	local did_exist, midi_step_state = project_state.get("mode_state", "midi_step")
	if not did_exist then
		midi_step_state = {
			silent = false,
			direction = true,
		}
	end
	return did_exist, midi_step_state
end

midi.insert_notes = function(opts)
	if not opts.notes then
		return
	end
	local note_defaults = require("constants.constants").midi_note_defaults
	local take = opts.take

	for _, t_note in ipairs(opts.notes) do
		if not t_note.silent then
			local ret = reaper.MIDI_InsertNote(
				take,
				note_defaults.selected,
				note_defaults.muted,
				reaper.MIDI_GetPPQPosFromProjTime(take, t_note.time_pos_start),
				reaper.MIDI_GetPPQPosFromProjTime(take, t_note.time_pos_end),
				note_defaults.chan,
				t_note.pitch,
				note_defaults.velocity,
				note_defaults.noSortIn
			)
		end
	end
	if opts.sort ~= false then
		reaper.MIDI_Sort(take)
	end
end

-- TODO: move to midi library and rename to midi.remove_notes({opts})
-- improve by adding a range from [60, 64]
-- range opt
-- note filter opt, eg notes outside of scale or predicate.

midi.remove_notes = function(take, t_midi_events, active_note_row, filter_indices)
	if not t_midi_events then
		return
	end

	-- log.user("tme",format.block(t_midi_events))

	for i = 1, t_midi_events[2] do
		local note_idx = i - 1
		local _, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, note_idx)
		if pitch == active_note_row then
			reaper.MIDI_DeleteNote(take, note_idx)
		end
	end
end

--
-- midi selection
--

-- make it easier to select midi chunks close in time proximity
midi.select_notes = function()

	-- vertical | chords
	-- similar onset time or playing simultaneously

	-- horizontal | scales / patterns
	--
end

-- this function should prolly go into lib/items
--
--
-- TODO: add filter params so that i can easilly pass filters
-- ~ pitch
-- ~ muted
-- ~ sel
-- ~ ch
-- ~ vel
-- ~ ppq_s
-- ~ ppq_e
midi.get_midi_data_from_take = function(take, opts)
	if not take then
		log.debug("No take was supplied to midi.get_midi_data_from_take")
		return
	end

	local filter = opts.filter or {}
	local note_filter = filter.notes or {}
	local cc_filter = filter.cc or {}
	local syx_filter = filter.syx or {}
	local no_filters = not note_filter and not cc_filter and not syx_filter

	local t_notes = {}
	local t_cc = {}
	local t_syx = {}

	log.debug(string.format([[get_midi_data_from_take; filter=%s, noflt=%s ]], filter, no_filters))

	local ret, notecnt, ccevtcnt, textsyxevtcnt = reaper.MIDI_CountEvts(take)

	-- notes
	for i = 0, notecnt do
		local ret, sel, muted, ppq_s, ppq_e, ch, pitch, vel = reaper.MIDI_GetNote(take, i)
		-- if filt_low <= pitch and pitch <= filt_high then
		table.insert(t_notes, {
			muted = muted,
			ppq_s = ppq_s,
			ppq_e = ppq_e,
			ch = ch,
			-- real_pitch = pitch,
			pitch = pitch,
			vel = vel,
		})
		-- end
	end

	-- TODO: manually filter each prop. it is easier, so that we can customize
	-- opts for each value.


	-- implement below so that I can make filters of types:
	-- bool
	-- single numbers
	-- ranges
	--
	--
	-- >>> each of these could go into utils.tables
	--
	-- i can still do this with my loop below but i have to make an if statement
	-- to check if bool type or numb/table type...

	if no_filters or note_filter.sel then
	  -- true
	  --
	  -- false
	end
	if no_filters or note_filter.muted then
	  -- true
	  --
	  -- false
	end
	if no_filters or note_filter.ppqs then
	  -- if single number
	  --
	  -- if table
	  --    if subtable number > single number
	  --    if subtable table > use a range for each table
	  --
	end
	if no_filters or note_filter.ppqe then
	  -- if single number
	  --
	  -- if table
	  --    if subtable number > single number
	  --    if subtable table > use a range for each table
	  --
	end
	if no_filters or note_filter.chan then
	  -- if single number
	  --
	  -- if table
	  --    if subtable number > single number
	  --    if subtable table > use a range for each table
	  --
	end
	if no_filters or note_filter.pitch then
	  -- if single number
	  --
	  -- if table
	  --    if subtable number > single number
	  --    if subtable table > use a range for each table
	  --
	end
	if no_filters or note_filter.vel then
	  -- if single number
	  --
	  -- if table
	  --    if subtable number > single number
	  --    if subtable table > use a range for each table
	  --
	end

	if no_filters or note_filter then
		for k, v in pairs(note_filter) do
			if type(v) == "boolean" then
				t_notes = tbl.filter(t_notes, function(note)
					return note.sel == v
				end)
			end

			if type(v) == "table" and #v == 2 then
				t_notes = tbl.filter(t_notes, function(note)
					return v[1] <= note.pitch and note.pitch <= v[2]
				end)
			end

			if type(v) == "function" then
				t_notes = tbl.filter(t_notes, v) -- pass filter func
			end
		end
	end

	if no_filters or cc_filter then
		for k, v in pairs(cc_filter) do
		end
	end

	if no_filters or syx_filter then
		for k, v in pairs(syx_filter) do
		end
	end

	return {
		notes = t_notes,
		cc = t_cc,
		syx = t_syx,
	}
end

return midi
