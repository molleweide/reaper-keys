local log = require("utils.log")
local ru = require("custom_actions.utils")
local config = require("definitions.config")
local format = require("utils.format")
local fx = require("library.fx")
local io = require("definitions.io")
local project_state = require("utils.project_state")
local tu = require("utils.table")

-- FIX: all custom actions should recieve an `opts` table from the
-- runner function, so that you always know that you have all the info
-- about the current state of new_state and all that pertains to the
-- command.

local utils = require("custom_actions.utils")

local midi = require("library.midi")

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

custom_actions.midiChordPicker = function(meta, opts)
	local pickers = require("pickers.pickers")

	pickers.chord(meta, {
		next = midi.insertMidiNoteChunk,
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

-- FIX: it is a bit stupid to pass chords here. i should make it possible to
-- pass single note / relative interval

custom_actions.midiStepRel_P1 = function(meta)
	midi.insertMidiNoteChunk(meta, { move_cursor = true, chord = { "midi_step_rel_pitch_chord_name", { 1 } } })
end

custom_actions.midiStepRel_m2 = function(meta, opts)
	midi.insertMidiNoteChunk(meta, { move_cursor = true, chord = { "midi_step_rel_pitch_chord_name", { 2 } } })
end

custom_actions.midiStepRel_M2 = function(meta, opts)
	midi.insertMidiNoteChunk(meta, { move_cursor = true, chord = { "midi_step_rel_pitch_chord_name", { 3 } } })
end

custom_actions.midiStepRel_m3 = function(meta)
	midi.insertMidiNoteChunk(meta, { move_cursor = true, chord = { "midi_step_rel_pitch_chord_name", { 4 } } })
end

custom_actions.midiStepRel_M3 = function(meta, opts)
	midi.insertMidiNoteChunk(meta, { move_cursor = true, chord = { "midi_step_rel_pitch_chord_name", { 5 } } })
end

custom_actions.midiStepRel_P4 = function(meta, opts)
	midi.insertMidiNoteChunk(meta, { move_cursor = true, chord = { "midi_step_rel_pitch_chord_name", { 6 } } })
end

custom_actions.midiStepRel_b5 = function(meta, opts)
	midi.insertMidiNoteChunk(meta, { move_cursor = true, chord = { "midi_step_rel_pitch_chord_name", { 7 } } })
end

custom_actions.midiStepRel_P5 = function(meta, opts)
	midi.insertMidiNoteChunk(meta, { move_cursor = true, chord = { "midi_step_rel_pitch_chord_name", { 8 } } })
end

custom_actions.midiStepRel_m6 = function(meta, opts)
	midi.insertMidiNoteChunk(meta, { move_cursor = true, chord = { "midi_step_rel_pitch_chord_name", { 9 } } })
end

custom_actions.midiStepRel_M6 = function(meta, opts)
	midi.insertMidiNoteChunk(meta, { move_cursor = true, chord = { "midi_step_rel_pitch_chord_name", { 10 } } })
end

custom_actions.midiStepRel_m7 = function(meta, opts)
	midi.insertMidiNoteChunk(meta, { move_cursor = true, chord = { "midi_step_rel_pitch_chord_name", { 11 } } })
end

custom_actions.midiStepRel_M7 = function(meta, opts)
	midi.insertMidiNoteChunk(meta, { move_cursor = true, chord = { "midi_step_rel_pitch_chord_name", { 12 } } })
end

custom_actions.midiStepToggleDirection = function(meta, opts)
	local exists, midi_step_state = project_state.get("mode_state", "midi_step")
	local new_midi_step_state
	if not exists then
	  -- maybe i should craft a default state table for the mode that should be
	  -- kept under constants in state machine??
		new_midi_step_state = {
			direction = false,
		}
	else
		new_midi_step_state = midi_step_state
		new_midi_step_state.direction = not new_midi_step_state.direction
	end
	log.user(exists, midi_step_state, format.block(new_midi_step_state))
	project_state.overwrite("mode_state", "midi_step", new_midi_step_state)
end

return custom_actions
