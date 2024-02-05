local log = require("utils.log")
local format = require("utils.format")
local pickers = require("pickers.pickers")
local lib_tr = require("library.tracks")
local s = require("utils.string")
local midi_patterns = require("library.midi_patterns")

local fzf = require("library.fzf")

local fxu = require("library.fx")
local tbl = require("utils.table")

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
	local function me_select_reg_and_edit_track(not_first)
		pickers.marks_and_regions(_, {
			title = "ME: 1. select regions/marks; 2. select track edit",
			filter = "MCS",
			next = function(_, data)
				-- log.user("selection data", format.block(data))
				local mark_sel = data.selection
				pickers.all_tracks(meta, {
					filter = "MCS",
					-- FIX: use on_select_func instead here
					next = function(_, data2)
						-- log.user("selection data2", format.block(data2), "sel mark->", format.block(data))
						require("library.midi_editor").createEditMidiItemAtPositionForTrack(
							_,
							data2.selection,
							mark_sel.left,
							mark_sel.right
						)
						reaper.SetEditCurPos(mark_sel.left, false, false)
					end,
					extended_mappings = {
						["C-z"] = function()
							me_select_reg_and_edit_track(true)
						end,
					},
				})
			end,
		})
	end

	me_select_reg_and_edit_track()
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

-- ::: ADD TRACK NODES UI :::
--
-- 3. ZG/xxx,yyy
--    Create zone `xxx` and populate it with group `yyy`
--
-- 4. G/xx,yy4
--    The final number that I want N number of leaf tracks.
--
-- 5. Z/arst
--    Only adding a Zone requires one to also add user input name for new
--    contained group.
--
-- 6. feat: add class T, A, and B.
--
-- 7. feat: specify templates/presets/patches/etc.
--
-- 8.
--
-- Words prefixed w/ ZGS expect names, and then each following
-- name will be a default track in that group.
--
--
commands.add_track_nodes_ui = function(meta, opts)
	local main_divider = "/"
	local name_divider = ","

	local function handle_add_nodes_string(add_nodes_str)
		local valid = true
		local initial_slash = add_nodes_str:match("^/")
		local trailing_slash = add_nodes_str:match("/$")
		local input_units = s.split(add_nodes_str, main_divider)
		local zgs_match
		local names_index
		local name_idx_counter = 1
		local node_creation_type
		local t_final = {}
		local t_branches = {}
		local t_leaves = {}

		log.user("length # input_units:", #input_units, format.block(input_units))

		if #input_units == 1 then
			names_index = 1

			if initial_slash then
				node_creation_type = "only_leaves" -- /arst
			elseif trailing_slash then
				node_creation_type = "only_branches" -- arst/
			else
				node_creation_type = "only_leaves" -- `arst`
			end
		else
			node_creation_type = "both" -- (/)arst/arst(/...)
			names_index = 2
		end

		if node_creation_type == "only_branches" or node_creation_type == "both" then
			zgs_match = input_units[1]:match("^z?g?s?$")
			if zgs_match == "zs" then
				zgs_match = false
			end
		end

		local add_to_current_parrent = not zgs_match
		local names_match = s.split(input_units[names_index], name_divider)

		log.user(string.format(
			[[
		---
		  zgs match = %s
		  add to pas = %s
		  name match = %s
		  type = %s
		  ----
		  ]],
			zgs_match,
			add_to_current_parrent,
			format.block(names_match),
			node_creation_type
		))

		-- log.user("zgs_match:", zgs_match, add_to_current_parrent)
		-- log.user("names:", format.block(names_match))

		local function incr()
			name_idx_counter = name_idx_counter + 1
		end

		local function verify_name()
			if node_creation_type == "only_branches" then
				return false
			end

			if names_match[name_idx_counter] ~= nil then
				local name = names_match[name_idx_counter]
				incr()
				return name
			else
				return false
			end
		end

		if zgs_match then
			if zgs_match:find("z") then
				table.insert(t_branches, {
					class = "z",
					name = verify_name(),
				})
			end

			if zgs_match:find("g") then
				table.insert(t_branches, {
					class = "g",
					name = verify_name(),
				})
				-- incr()
			end

			if zgs_match:find("s") then
				table.insert(t_branches, {
					class = "s",
					name = verify_name(),
				})
				-- incr()
			end

			t_final["branches"] = t_branches
		end

		local function containsOnlyAlphanumericAndPeriod(str)
			return not string.match(str, "[^%w%.]")
		end

		if node_creation_type ~= "only_branches" then
			log.user(name_idx_counter)
			for i = name_idx_counter, #names_match, 1 do
				local name = verify_name()
				if not containsOnlyAlphanumericAndPeriod(name) then
					valid = false
				end
				table.insert(t_leaves, {
					name = name,
				})
			end
			t_final["leaves"] = t_leaves
		end

		log.user(format.block(t_final))

		return valid, data
	end

	fzf.init({
		title = "Add track nodes",
		x = 200,
		width = 1100,
		height = 75,
		on_select_func = function(self)
			local _, main_input = tbl.findIndexOf(GUI.controls, "title", "main_input")
			if main_input then
				log.user("-------- ADD NODES STRING:", main_input.value)
				local ret, data = handle_add_nodes_string(main_input.value)
				return ret
			end
			return true
		end,
	})
end

-- NOTE:
-- A. Initially, this should only work on the focused track selection.
--    >>> Later, add ability to target specific tracks.
--    --
-- B. Specify how long / repetitions for a given insertion.
--    --
commands.main_insert_midi_block_from_string_UI = function()
	-- TODO: Reuse this in order to get measure pos and existing item/take
	-- local focused_track_objects, _, context = lib_tr.get_focused_track_objects()
	-- if context == "main" then
	-- 	local focus_track_obj = focused_track_objects[1]
	-- 	log.user(">>>", focus_track_obj)
	-- 	midi_editor.createEditMidiItemAtPositionForTrack(_, focus_track_obj)
	-- end

	local function handle_midi_string(insert_midi_str)
		log.user("MIDI BLOCK STRING:", insert_midi_str)

		local function countCharInString(inputString, charToCount)
			local count = 0
			local prev = 0
			local t_res = {}

			for i = 1, #inputString do
				if string.sub(inputString, i, i) == charToCount then
					count = count + 1
					if i - prev < 2 then
						table.insert(t_res, "")
					else
						table.insert(t_res, inputString:sub(prev + 1, i - 1))
					end
					prev = i
				end

				if i == #inputString then
					if i - prev < 2 then
						table.insert(t_res, "")
					else
						table.insert(t_res, inputString:sub(prev + 1, i))
					end
				end
			end
			return count, t_res
		end

		local function apply_note_data_to_pattern(t_pattern_midi_notes, note_pool_str, arp_expr_str)
			local use_expr = arp_expr_str ~= "" and true

			-- parse note pool string
			if note_pool_str == "" then
				log.user("note pool: > empty use default")
			else
				log.user("note pool: > scale")
			end

			-- apply note pool to each pattern atom

			if use_expr then
			-- parse expr
			-- apply expr
			else
				for _, atom in ipairs(t_pattern_midi_notes) do
					log.user(format.block(atom))
				end
			end
		end

		-- NOTE: brainstorming
		-- 1. parse string
		--    ~ pattern
		--    ~ note_pool (single/chord/scale)
		-- 2. render pattern string
		-- 3. assign note pool to each rhythm event
		--    (if arp expr then ...)
		-- 4. check if an item exists at [first note, last note]
		-- 5. ensure/create new item.
		-- 6. insert midi notes by calling `midi.insertNoteChunk({})`

		local main_divider = "/"

		if insert_midi_str == "" then
			return
		end

		local num_main_dividers, input_units = countCharInString(insert_midi_str, main_divider)

		log.user("midi_block", #input_units, format.block(input_units))

		local input_pattern
		local input_note_pool
		local input_arp_expr

		-- If no pattern then use eight notes as default?
		--
		-- Use root note as default note pool if none is passed
		--

		if #input_units == 1 then
			input_pattern = input_units[1]
		elseif #input_units == 2 then
			input_pattern = input_units[1]
			input_note_pool = input_units[2]
		elseif #input_units > 2 then
			input_pattern = input_units[1]
			input_note_pool = input_units[2]
			input_arp_expr = input_units[3]
		end

		-- BUILD PATTERNS

		local t_pattern_midi_notes

		if input_pattern == "" then
		-- TODO: if no input_pattern, then fill the measure with a full measure note.
		else
			_, t_pattern_midi_notes = midi_patterns.create_insert_midi_pattern_by_string(_, {
				pattern = input_pattern,
				dry_run = true, -- only return data, DON'T try insert any midi
				start_at_measure = true,
			})
		end

		-- log.user(format.block(t_patterns_state))
		-- log.user(format.block(t_pattern_midi_notes))

		apply_note_data_to_pattern(t_pattern_midi_notes, input_note_pool, input_arp_expr)

		--
		-- TODO: ensure/create item/take
		--

		-- TODO: INSERT NOTES
		-- for each pattern atom
		--    for each atom.notes
		--       insert_notes
		--
		--       this is now just a matter of inserting the notes and but i first
		--

		--
	end

	fzf.init({
		title = "Add MIDI blocks",
		x = 200,
		width = 1100,
		height = 75,
		on_select_func = function(self)
			local _, main_input = tbl.findIndexOf(GUI.controls, "title", "main_input")
			if main_input then
				local ret, data = handle_midi_string(main_input.value)
				return ret
			end
			return true
		end,
	})
end

-- TODO:
-- ~ Connect this with the command/parser from above `main_insert_midi_block_from_string_UI`
-- ~ Chain pickers [ SelectRegion->Prompt ]
--
-- - Add ability to randomize some type of parameter change every N bars, so that
--   the listener always percieves that "stuff" is happening.
--
--
commands.MIDI_insert_fill_region = function()
	--
end

-- Create a UI that allows me to CRUD meta/macro info for a project so
-- that this will be used later when rendering, eg. regions from project
-- info.
commands.project_patterns_and_harmony_manager = function()

	-- ALL THEMES
	-- keybind -> add theme
	--     (a theme is a set of information that can be used as base input when
	--     rendering sections)
	--
	-- keybind -> add theme
	--         -> edit theme
	--         -> remove theme
	--         -> enter theme (SINGLE THEME)
	--
	-- SINGLE THEME
	-- keybind -> add entry
	--         -> edit entry
	--         -> delete entry
	--
	-- A theme should have
	-- rhythm patterns
	-- bass patterns
	-- comp patterns
	-- lead patterns
	-- fx/bkg
	-- key/center
	-- harmony / chord progression
end

-- ::: REGION UI :::
--
-- This one is going to be fun to build, since this allows me to sketch out
-- structure easilly and play around with copying songs.
--
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

local function get_focus_track_with_fx_chain_info()
	local focused_track_objects, _, context = lib_tr.get_focused_track_objects()
	local tr_node = focused_track_objects[1]
	local fx_results = fxu.get_track_fx_chain_info(tr_node.tr)
	return tr_node, fx_results
end

commands.track_fx_ui = function(meta, opts)
	local tr_node, fx_results = get_focus_track_with_fx_chain_info()

	local function track_fx_ui(not_first)
		pickers.track_fx(_, {
			master_title = "TRACK FX UI",
			results = fx_results,
			next_is_picker = not_first and false or true,
			next = function(meta, data, self)
				local t_fx_params = fxu.get_track_fx_info(tr_node.tr, data.selection.idx)
				pickers.track_fx_params(_, {
					node = tr_node,
					fx_index = data.selection.idx,
					results = t_fx_params.parameters,
					sort_comp = require("pickers.sorters.default")("name"),
					entry_maker = require("pickers.entry_makers.fx_parameters"),
					extended_mappings = {
						["C-z"] = function()
							track_fx_ui(true)
						end,
					},
				})
			end,
		})
	end

	track_fx_ui()
end

-- A. Base picker it `all tracks`
-- B. on_select -> open attributes for selected track
-- C. If `multiple selection`, then with key binds I can batch toggle.
--
-- D. Eg. `hiding` on a branch-node will also hide all contained nodes.
--
-- E. I can pretty much reuse the FX mixing keybinds for controlling
--      track attributes/parameters
--
-- F. combine!! channel_mix_params && track_attributes
--
commands.track_manager_ui = function()
	-- 1. put together all of the `result` properties.
	--     Compile nice sub-tables with all necessary info.
	-- 2.

	local function track_manager(not_first)
		pickers.track_fx(_, {
			master_title = "TRACK MANAGER: [ATTRS/PARAMS]",
			results = {},
			next = function(meta, data, self)
				-- local t_fx_params = fxu.get_track_fx_info(tr_node.tr, data.selection.idx)
				pickers.track_attributes_and_params(_, {
					-- node = tr_node,
					-- fx_index = data.selection.idx,
					results = {},
					-- sort_comp = require("pickers.sorters.default")("name"),
					-- entry_maker = require("pickers.entry_makers.fx_parameters"),
					extended_mappings = {
						["C-z"] = function()
							track_manager(true)
						end,
					},
				})
			end,
		})
	end

	track_manager()
end

-- Move this to pickers main file later..
commands.rk_master_menu = function()
	local fzf = require("library.fzf")

	local rk_main_menu = {
		{ name = "preferences" },
		{ name = "tracks" },
		{ name = "regions" },
		{ name = "automation" },
		{ name = "tempo" },
		{ name = "samples" },
		{ name = "audio_file_loops" },
	}
	local rk_main_prefs = {
		"audio devices",
		"midi devices",
		"buffering",
	}
	local rk_main_tracks = {
		"add new tracks",
		"remove tracks",
		"hide tracks",
	}
	local rk_main_regions = {
		"add region",
		"extend regions",
		"rename regions",
	}
	local rk_main_automation = {
		"add auto",
		"extend auto",
		"rename auto",
	}
	local rk_main_tempo = {
		"add tempo",
		"extend tempo",
		"rename tempo",
	}
	local rk_main_samples = {
		"open sample library",
		"preview samples",
	}
	local rk_main_loops = {
		"open loops",
		"preview loops",
	}

	fzf.init({
		title = "RK MAIN MENU",
		width = 500,
		height = 700,
		x = 0,
		y = 1100,
		results = rk_main_menu,
		on_select_func = false,
		sort_comp = "name",
		entry_maker = "name",
		-- attach_mappings = require("pickers.attach_mappings.fx_parameters"),
		-- extended_mappings = opts.extended_mappings or nil,
	})
end

commands.automation_ui = function()
	local rk_main_menu = {
		{ name = "ramp up" },
		{ name = "ramp down" },
		{ name = "flat bar" },
	}

	fzf.init({
		title = "AUTOMATION UI",
		width = 500,
		height = 700,
		x = 0,
		y = 1100,
		results = rk_main_menu,
		on_select_func = false,
		sort_comp = "name",
		entry_maker = "name",
		-- attach_mappings = require("pickers.attach_mappings.fx_parameters"),
		-- extended_mappings = opts.extended_mappings or nil,
	})
end

commands.sample_library_file_browser = function()
	-- TODO:
	-- 1. add sample library dir to def/config
	-- 2. on selection -> recursive call picker with the selected dir.
	-----
	-- On C-z, if previous dir is beyond base sample dir, don't do anything,
	-- else move back one step.
	-----
	-- C-f, preview sample,
	--      Hit C-f again to stop current preview, eg. if file is a loop.
	-----
	-- C-t, toggle play selected sample on change.

	fzf.init({
		title = "SAMPLE LIBRARY BROWSER",
		width = 1000,
		height = 800,
		x = 0,
		y = 1100,
		-- results = rk_main_menu,
		on_select_func = false,
		sort_comp = "name",
		entry_maker = "name",
		-- attach_mappings = require("pickers.attach_mappings.fx_parameters"),
		-- extended_mappings = opts.extended_mappings or nil,
	})
end

commands.master_prompt = function()

	-- text field that has basic vim bindings implemented.
	-- maybe i could just reuse the current state machine implementation
	-- and check if the context is main / midi / or jgui_norm
	--
	--
	-- ooh if i just add a new context, then i can always access modality
	-- from within the jgui
	--
	-- TODO: create a default switch command, that sets a flag inside
	-- jgui, that determines wether `insert_mode = true`.
	--
	-- If `insert_mode` -> that means that we just allow all keys to pass
	--    >>> if `esc switch` then we toggle the switch to false.
	--
	-- If FALSE, then we pass every key through the state_machine,
	-- and each ASF will then operate on the gui.text_field input, and
	-- apply all actions to the gui.text_field.
	--
	-- This would allow me to further refactor the core and allow the project
	-- to be even more modular.

	-- TODO: IMPORTANT
	--       There needs to be a `Proceed` prompt that clearly states what will
	--       be done to a project, so that you know for sure what will happen
	--       when executing the prompt.
end

commands.MIDI_AI_PROMPT = function()
	-- TODO: play around with a base promt that ensures we get data correctly
	-- formatted so that I can be confident that the AI always returns the
	-- correct type of info
	-- --
	-- I need to create a file-spec for how each type of data information should
	-- be formatted by the AI. This spec explanation will always be injected
	-- before the user-prompt so that an AI prompt always will give it all necessary
	-- details.
end

return commands
