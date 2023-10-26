local log = require("utils.log")
local ru = require("custom_actions.utils")
local config = require("definitions.config")
local format = require("utils.format")
local fx = require("library.fx")
local io = require("definitions.io")

-- FIX: all custom actions should recieve an `opts` table from the
-- runner function, so that you always know that you have all the info
-- about the current state of new_state and all that pertains to the
-- command.

local utils = require("custom_actions.utils")

--  Motion start/end points can be retrieved with the (temporary selection)
--    local start_sel, end_sel = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
--  being made inside of the

local custom_actions = {
	move = require("custom_actions.movement"),
	select = require("custom_actions.selection"),
}

function custom_actions.clearTimeSelection()
	local current_position = reaper.GetCursorPosition()
	reaper.GetSet_LoopTimeRange(true, false, current_position, current_position, false)
end

function getUserGridDivisionInput()
	local _, num_string = reaper.GetUserInputs("Set Grid Division", 1, "Fraction/Number", "")
	local first_num = num_string:match("[0-9.]+")
	local divider = num_string:match("/([0-9.]+)")

	local division = nil
	if first_num and divider then
		division = first_num / divider
	elseif first_num then
		division = first_num
	else
		log.error("Could not parse specified grid division.")
		return nil
	end

	return division
end

function custom_actions.setMidiGridDivision()
	local division = getUserGridDivisionInput()
	if division then
		reaper.SetMIDIEditorGrid(0, division)
	end
end

function custom_actions.clearSelectedTimeline()
	local current_position = reaper.GetCursorPosition()
	reaper.GetSet_LoopTimeRange(true, false, current_position, current_position, false)
end

function custom_actions.setGridDivision()
	local division = getUserGridDivisionInput()
	if division then
		reaper.SetProjectGrid(0, division)
	end
end

-- this one avoids splitting all items across tracks in time selection, if no items are selected
function custom_actions.splitItemsAtTimeSelection()
	if reaper.CountSelectedMediaItems(0) == 0 then
		return
	end
	local SplitAtTimeSelection = 40061
	reaper.Main_OnCommand(SplitAtTimeSelection, 0)
end

function custom_actions.updatePrefixOfSelectedTracks()
	trackUpdateName(1)
end

function custom_actions.updateNameOfSelectedTracks()
	trackUpdateName(0)
end

-- mv to util/track.lua
function trackUpdateName(set_prefix)
	log.clear()
	local num_sel = reaper.CountSelectedTracks(0)
	local _, new_name_string = reaper.GetUserInputs("Change track name", 1, "Track name:", "")
	if num_sel == 0 then
		return
	end

	if num_sel > 0 then
		for i = 1, num_sel do
			local tr = reaper.GetSelectedTrack(0, i - 1)
			local ret, old_name_full = reaper.GetTrackName(tr)
			local s, e = string.find(old_name_full, config.name_prefix_match_str)
			if s == nil then
				s = 0
				e = 0
			end
			local old_prefix = string.sub(old_name_full, s, e)
			local old_name = string.sub(old_name_full, e + 1)

			local new_name_full
			if set_prefix == 1 then
				new_name_full = new_name_string .. old_name
			else
				new_name_full = old_prefix .. new_name_string
			end
			local _, str = reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", new_name_full, 1)
		end
		return
	end
end

function updateMidiPreProcessorByInputDevice(guid_tr)
	local tr, tr_idx = ru.getTrackByGUID(guid_tr)
	local tr_rec_in = reaper.GetMediaTrackInfo_Value(tr, "I_RECINPUT")
	local midi_device_offset = 4096
	local device_mask = 2016
	local dev_id = ((tr_rec_in - midi_device_offset) & device_mask) >> 5
	local retval, nameout = reaper.GetMIDIInputName(dev_id, "")

	local enabled_device
	for k, device_str in pairs(io.midi) do
		if nameout:lower():match(device_str:lower()) then
			enabled_device = device_str
		end
	end

	if enabled_device == nil then
		return
	end
	if enabled_device == io.midi.vkb then
		fx.setParamForFxAtIndex(guid_tr, 0, 1, 0, true) -- set device
		fx.setParamForFxAtIndex(guid_tr, 0, 2, 0, true) -- set mode
	end

	if enabled_device == io.midi.qmk then
		fx.setParamForFxAtIndex(guid_tr, 0, 1, 1, true) -- set device
		fx.setParamForFxAtIndex(guid_tr, 0, 2, 4, true) -- set mode
	end

	if enabled_device == io.midi.roland then
		fx.setParamForFxAtIndex(guid_tr, 0, 1, 2, true) -- set device
		fx.setParamForFxAtIndex(guid_tr, 0, 2, 8, true) -- set mode
	end
end

function custom_actions.setupMidiInputPreProcessorOnSelTrks()
	local t_sel = ru.getSelectedTracksGUIDs()
	for i = 1, #t_sel do
		local guid_tr = t_sel[i].guid

		-- log.user('insid setup io', guid_tr)

		local zeroth_idx_name = fx.getSetTrackFxNameByFxChainIndex(guid_tr, 0, true) -- TODO rec fx
		if zeroth_idx_name == "RK_MIDI_PRE_PROCESSOR" then
			updateMidiPreProcessorByInputDevice(guid_tr)
		else
			local fx_str = "midi-rec-pre.jsfx" -- INSERT MIDI PRE PROCESSOR JSFX
			fx.insertFxAtIndex(guid_tr, fx_str, 0, true)
			fx.getSetTrackFxNameByFxChainIndex(guid_tr, 0, true, "RK_MIDI_PRE_PROCESSOR")
			updateMidiPreProcessorByInputDevice(guid_tr)
		end
	end
end

function custom_actions.sidechainCompTracks(key_track_name)

	-- check if not `FX_SC_GKICK` exists
	-- add last fx
	-- create recieve for sel track
	-- from ghost 1/2 into 3/4
end

--
-- TODO: refactor / move to library/midi.lua
--

function custom_actions.insertMidiNoteChunk(meta, opts)
	opts = opts or {}
	-- log.user("META:", format.block(meta))

	if opts.move_cursor then
		reaper.SetEditCurPos(meta.end_pos, false, false)
	end

	-- TODO: move to definitions/constants.lua
	local midi_insertion_data_default = {
		selected = false,
		muted = false,
		chan = 0,
		noSortIn = true,
	}

	local ret, ME, take = utils.getMidiValidContext()
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
	local note_end_gap = 0.005
	local note_duration = sixteen_note_len - note_end_gap

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

custom_actions.midiChordPicker = function(meta, opts)
	local pickers = require("pickers.pickers")

	pickers.chord(meta, {
		next = custom_actions.insertMidiNoteChunk,
		move_cursor = true,
	})
end

--
-- fuzzy picker actions for jumping to objects
--
--   marker
--   region
--   item audio/midi
--   take
--   note
--      by name
--
--      this would allow one to search around fast as fuck.

local function moveToSelectObjectAndDo(config)
	config = config or {}
	log.user("MOVE TO OBJ ->", log.user(config))

	if config.type == "item" then
		pickers.all_items(meta, {
			next = function(meta, opts)
				-- with selected item do wath
				if config.midi == "enter" then
					log.user("JUMP TO AND ENTER MIDI")

				-- jump to midi item and enter MIDI Editor
				else
					-- jump to item in main
					log.user("JUMP TO ITEM IN MAIN")
				end
			end,
		})
	end

	if config.type == "region" then
		pickers.all_region(meta, {
			next = function(meta, opts)
				if config.midi == "enter" then
					log.user("JUMP TO REGION + TRY TO ENTER MIDI somehow...")
				else
					if config.loop then
						-- jump to item in main
						log.user("JUMP TO REGION AND LOOP")
					end
				end
			end,
		})
	end
end

--

custom_actions.jumpToItemInMain = function()
	moveToSelectObjectAndDo({
		type = "item",
	})
end

custom_actions.jumpToMidiItemAndEnter = function(opts)
	moveToSelectObjectAndDo({
		type = "item",
		midi = "enter",
	})
end

custom_actions.jumpToRegionAndLoop = function(opts)
	moveToSelectObjectAndDo({
		type = "region",
		midi = "enter",
		loop = true,
	})
end

-- 0 / same
custom_actions.midiStepRel_P1 = function(meta, opts)
	custom_actions.insertMidiNoteChunk(meta, opts)
end

-- 1 / minor second
custom_actions.midiStepRel_m2 = function(meta, opts)
	custom_actions.insertMidiNoteChunk(meta, opts)
end

-- 2 / major second
custom_actions.midiStepRel_M2 = function(meta, opts)
	custom_actions.insertMidiNoteChunk(meta, opts)
end

-- 3 / minor third
custom_actions.midiStepRel_m3 = function(meta, opts)
	custom_actions.insertMidiNoteChunk(meta, opts)
end

-- 4 / major third
custom_actions.midiStepRel_M3 = function(meta, opts)
	custom_actions.insertMidiNoteChunk(meta, opts)
end

-- 5 / Perfect Fourth
custom_actions.midiStepRel_P4 = function(meta, opts)
	custom_actions.insertMidiNoteChunk(meta, opts)
end

-- 6 / Tritone
custom_actions.midiStepRel_b5 = function(meta, opts)
	custom_actions.insertMidiNoteChunk(meta, opts)
end

-- 7 / Perfect Fifth
custom_actions.midiStepRel_P5 = function(meta, opts)
	custom_actions.insertMidiNoteChunk(meta, opts)
end

return custom_actions
