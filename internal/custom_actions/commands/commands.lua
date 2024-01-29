local log = require("utils.log")
local format = require("utils.format")
local pickers = require("pickers.pickers")
local lib_tr = require("library.tracks")
local s = require("utils.string")

local fxu = require("library.fx")

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

-- TODO: when running fx_picker on a CHANNESPLITTER, then I should first
-- be prompted to select which S subtrack, etc, etc. so that I can mix/modify
-- all subtracks, from within, eg, ME when editing a larger screenset of
-- MC tracks within a group.

commands.picker_first_eq_on_focused_track = function()
	local focused_track_objects, _, context = lib_tr.get_focused_track_objects()
	local tr_node = focused_track_objects[1]
	local eq_instance = fxu.get_fx_objs_by_name_string(tr_node.guid, "ReaEQ")

	log.user("EQ INSTANCE:", format.block(tr_node.tr), format.block(eq_instance))

	-- Add EQ if doesn't exist.
	if eq_instance then
		pickers.track_fx_params(_, { node = tr_node, fx_index = eq_instance.idx })
	end
end
commands.picker_first_comp_on_focused_track = function()
	local focused_track_objects, _, context = lib_tr.get_focused_track_objects()
	local tr_node = focused_track_objects[1]
	local comp_instance = fxu.get_fx_objs_by_name_string(tr_node.guid, "ReaComp")
	log.user("EQ INSTANCE:", format.block(comp_instance))
	if comp_instance then
		pickers.track_fx_params(_, { node = tr_node, fx_index = comp_instance.idx })
	end
end

commands.open_route_ui = function(meta, opts)

	-- NOTE: what should this UI do?
end

commands.add_track_nodes_ui = function(meta, opts)
	-- ! string parse -> add nodes.

	-- ! should behavior be different in main/midi?

	-- This should allow me to easilly manage nodes.

	-- If this is used with the fuzzy UI, then i can use text for any inputs to
	-- reaper, and then see how good this window becomes for me.
	-- In the end this could almost become as like an AI text interface to the
	-- software, that then allows you to do some pretty fucking insane sounds.

	-- TODO: 1. parse string on each input.
	--       2. preview node(s) that will be affected.
	--       3. on keypress
	--              perform actions.
	--
	--      HACK: this can then be reused for the route_ui previewer above.

	-- FIX: later i can use multi lines for this and create one specific config
	-- for each line??

	-- NOTE: cases:
	-- 1. if no class is specified
	--    -> add default M track to current group if possible.
	--    (tesx) -> add `testx` midi track to current group
	--    -
	-- 2. G/nameX,nameY,nameZ
	--    Adds M tracks Y and Z to group X
	--    -
	-- 3. ZG/xxx,yyy
	--    Create zone `xxx` and populate it with group `yyy`
	-- 4. G/xx,yy4
	--    The final number specifies that I want N num of tracks add to group.
	-- 5. Z/arst
	--    Only adding a Zone requires one to also add user input name for new
	--    contained group.
	-- TEST: In other words prefixed ZGS expect names, and then each following
	-- name will be a default track in that group.
	--
	-- It will be very interesting to see how the previewing of this will work
	-- so that one can select from a list of matching combinations.

	local input_placeholder = ""
	local route_help_str = "add nodes:"

	local _, add_nodes_str = reaper.GetUserInputs("ADD NEW NODES:", 1, route_help_str, input_placeholder)

	local input_units = s.split(add_nodes_str, "/")

	-- TODO: get branch class ZGS opts
	-- split string at each of `ZGS`

	-- TODO: get leaf node opts
	-- split each by comma

	log.user(format.block(input_units))

	-- TEST: ~ SYNTAX BASED HIDING -> picker all tracks > manage track_params
	--   eg. show/hide/solo/mute/volume/phase/
end

commands.regions_manager_fuzzy_ui = function(meta, opts)
	-- TODO: CRUD ui that allows me to manage regions easilly.
	--
	-- >> on each key press -> reparse the commandline string,
	-- so that I can preview everything that I am typing.
	--
	-- NOTE: this will be very interesting because it gives me a convenient
	-- global way of managing the tracks.
	-- With this i could again create a simple DSL, that allows me to
	-- control what should happen with regions and structuring tracks.
	--
	-- this is a lot of fun and I just cant wait to understand what will
	-- happen in a couple of months now that this music engine is getting
	-- finalized, and that is pretty fucking cool. it is not something that
	-- i will be able to show him. this is going to be fucking amazing.
	--
	-- so i haven't really had time to get to use this very much
	--
	-- there is something about the undo works.
	--
	local _, ui_str = reaper.GetUserInputs("REGIONS UI:", 1, "regions string:", "")

	local input_units = s.split(ui_str, "/")

	-- TEST: delete region -> if region contains item data -> user will be prompted
	-- "Region contains item data - Are you sure you want to proceed? (Y/n)"
end

commands.show_hide_track_ui = function()
	-- TODO: create a picker of all track nodes.
	-- 1. keybind -> attach `hide` flag to each entry.
	-- 2. apply.
	--
	-- NOTE: hide tracks of class X, or if you say hide G, then all children
	-- will also be hidden.
	--
	--
	-- FIX: Need action/command to un-hide all tracks easy
	--
	-- NOTE: THIS SHOULD PROLLY GO INTO THE TRACK_NODE_UI ABOVE?!
end

-- TEST: Later, this should be modified to create a MIDI edit SCREENSET from
-- the group selection screenset.
commands.MIDI_picker_edit_tracks_CHAIN_region_and_group = function()

	-- 1. first select region.
	-- 2. then, select which Group,
	-- 3. then, select track.
end

commands.MIDI_picker_tracks_edit_existing_items_at_cursor = function() end

commands.routing_user_string = function()
	local route = require("library.routing")

	route.updateState()
end

-- TODO: i need to figure out how I can make it possible to go back to previous
-- picker so that I can select which FX i want again
--
commands.track_fx_ui = function(meta, opts)
	local focused_track_objects, _, context = lib_tr.get_focused_track_objects()
	local tr_node = focused_track_objects[1]
	local fx_results = fxu.get_track_fx_chain_info(tr_node.tr)

	log.user(tr_node.name, format.block(fx_results))

	-- wrap this in a function that can be called on going back from the FX
	-- pickers.

	pickers.track_fx(_, {
		title = "TRACK FX UI | fx list",
		results = fx_results,
		next_is_picker = true,
		next = function(meta, data, self)
			local fx_selected = data.selection
			-- log.user("selected fx:", format.block(fx_selected.idx))

			log.user("self.title:", self.title)

			-- self.next_is_picker = false

			local t_fx_params = fxu.get_track_fx_info(tr_node.tr, fx_selected.idx)
			self.t_results_data = t_fx_params.parameters

			self.meta = {}
			self.meta.node = tr_node
			self.meta.fx_index = fx_selected.idx

			self.sort_comp = require("pickers.sorters.default")("name")
			self.entry_maker = require("pickers.entry_makers.fx_parameters")

			self.title = string.format("FXparams: NODE(%s) -> FX(%s)", "xxx", t_fx_params.name)

			self.attach_mappings = require("pickers.attach_mappings.fx_parameters")

			local gui = self

			for _, value in ipairs(self.controls) do
				if value.title == "main_input" then
					log.user("found:", value.title, value.onKeyboard)
					function value:onKeyboard(key)
						-- add custom bindings here.
						gui.attach_mappings(gui, key, 1)
						-- require("pickers.attach_mappings.fx_parameters")(self, key, 1)
					end
				end
			end

			-- log()

			-- entry_maker = require("pickers.entry_makers.fx_parameters"),

			-- self.entry_maker = require("pickers.entry_makers.default")(opts.entry_maker)

			-- return

			-- pickers.track_fx_params(meta2, {
			-- 	title = "TRACK FX UI | fx params for: (plugin name)",
			-- 	node = tr_node,
			-- 	fx_index = fx_selected.idx,
			-- 	next_is_picker = false,
			-- })
		end,
	})
end

return commands
