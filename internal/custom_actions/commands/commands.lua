local log = require("utils.log")
local format = require("utils.format")
local pickers = require("pickers.pickers")

local project_state = require("utils.project_state")

local midi = require("library.midi")
local midi_editor = require("library.midi_editor")

local commands = {}

commands.MIDI_ChangeActiveSelection = function(meta, opts)
	pickers.all_tracks(_, {
		title = "jump to track midi",
		filter = "MCS", -- filter track_obj.class = [MCS]
		next = function(_, data)
			midi_editor.createEditMidiItemAtPositionForTrack(_, data.selection)
		end,
	})
end

commands.MIDI_EditMidiAtCurPosForTrack = function()
	local log = require("utils.log")
	local format = require("utils.format")
	local lib_tr = require("library.tracks")

	-- this function could be renamed to `get_rk_context()` and return all possible
	-- useful information.
	local focused_track_objects, _, context = lib_tr.get_focused_track_objects()

	if context == "main" then
		local focus_track_obj = focused_track_objects[1]
		log.user(">>>", focus_track_obj)
		midi_editor.createEditMidiItemAtPositionForTrack(_, focus_track_obj)
	end
end

commands.Midi_EditMidiForRegionsMarksAndSelectTrack = function(meta, opts)
	pickers.marks_and_regions(_, {
		filter = "MCS",
		next_is_picker = true,
		next = function(meta, data)
			local log = require("utils.log")
			local format = require("utils.format")
			log.user("selection data", format.block(data))
			local mark_sel = data.selection

			-- # tResultButtons 10.0
			-- selection data {
			--   selection = {
			--     id = 1,
			--     index = 1,
			--     left = 8.0,
			--     name = "testing",
			--     position = 10.0,
			--     register = "r",
			--     right = 16.0,
			--     time = 1699895229,
			--     track_position = 169.0,
			--     track_selection = {
			--       169.0
			--     },
			--     type = "region"
			--   }
			-- }

			pickers.all_tracks(meta, {
				title = "Choose track for editing @ region = [" .. data.selection.name .. "]",
				filter = "MCS",
				next_is_picker = false,
				next = function(meta2, data2)
					log.user("selection data2", format.block(data2), "sel mark->", format.block(data))
					require("library.midi_editor").createEditMidiItemAtPositionForTrack(
						_,
						data2.selection,
						mark_sel.left,
						mark_sel.right
					)
					-- move edit cursor
					-- note: i dunno if this is the best place to put the move command.
					reaper.SetEditCurPos(mark_sel.left, false, false)
				end,
			})

			-- pickers.all_tracks
			--     >>> next = reuse next from above
			--        >>>> first - move it into library.
		end,
	})
end

commands.MidiEditor_go_insert = function(meta, opts)
	midi.jump_to_position_and_insert_by_string()
end

return commands
