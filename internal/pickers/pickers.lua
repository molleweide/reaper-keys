local project_state = require("utils.project_state")
local log = require("utils.log")
local format = require("utils.format")

local fzf = require("library.fzf")
local fu = require("utils.fzf")
local sf = require("utils.j_string_functions")
local tf = require("utils.j_tables")

local marks = require("utils.marks_regions")

local syntax = require("SYNTAX.syntax.syntax")

local data_loaders = require("pickers.data.load_plugins_data")

--
-- NOTE: Shouldn't pickers, which are obviously `custom actions`, be moved
-- to unders `internal/custom_actions/pickers` ??

-- does some nested requires that requires fzf to be loaded first, (for now...)
require("gui2.JProjectClass")

local home = os.getenv("HOME")

local definitions_dir = "/reaper/packages/reaper-keys/definitions"

-- move this to definitions dir
local RK_FZF_ENV = {
	SETTINGS_INI_FILE = home .. definitions_dir .. "/fx-finder-settings.ini",
	SETTINGS_DEFAULT_FILE = home .. definitions_dir .. "/defaults/fx-finder-settings-default.ini",
	RK_DATA = home .. "/reaper/packages/reaper-keys/data",
}

local pickers = {}

--
--
--

pickers.add_track_fx = function(meta)
	log.user(format.block(meta))

	-- TODO: maybe plugins data loading should go into the PROJECTS class?

	local ok, plugins_data = data_loaders.load_plugins_data(RK_FZF_ENV)
	if not ok then
		msg(
			"Something went wrong with loading of settings, aborting. Please check your settings file: \n"
			-- .. SETTINGS_INI_FILE
		)
		return false
	end

	-- TODO: this should be refactored into a default func where I can pass which
	-- table keys that I want to use to check for
	--
	local function sortByRating(a, b)
		if a.rating > b.rating then
			return true
		elseif a.rating == b.rating then
			return a.name < b.name
		else
			return false
		end
	end

	local function get_plugin_results()
		local results = {}
		tRatingData = fu.jReadVstData(pluginsData.DATA_INI_FILE)
		results = fu.jReadVstIni(pluginsData.VST_INI_FILE, tRatingData)

		tTemplates = fu.getTemplates(pluginsData.TEMPLATE_SUB_DIRS, pluginsData.TEMPLATE_ROOT_DIR, tRatingData)
		results = tf.jTablesGlue(tTemplates, results)

		tFXChains = fu.getFXChains(pluginsData.FXCHAIN_SUB_DIRS, pluginsData.FXCHAIN_ROOT_DIR, tRatingData)
		results = tf.jTablesGlue(tFXChains, results)

		local tJsfx = fu.jReadJsfxIni(pluginsData.JSFX_INI_FILE, tRatingData)
		results = tf.jTablesGlue(tJsfx, results)

		if pluginsData.LOAD_AU then
			local tAu = fu.jReadAuIni(pluginsData.AU_INI_FILE, tRatingData)
			results = tf.jTablesGlue(tAu, results)
		end

		-- NOTE: is this where mappings are attached??
		-- local time = os.clock()
		if pluginsData.LOAD_ACTIONS then
			local tActions = data_loaders.jGetActions()
			results = tf.jTablesGlue(tActions, results)
		end
		-- msg(os.clock() - time)

		-- table.sort(results, sortByRating)

		return results
	end

	local function selectFx(self, i)
		-- todo: i should prolly remove the undo points since
		-- those are handled by RK

		log.user("SELECT FX: ", i)

		if not self.t_search_results then
			return false
		end -- results is empty

		local fx = self.t_search_results[i]

		if not fx then
			return false
		end -- no such result

		self.t_results_data[fx.id].rating = self.t_results_data[fx.id].rating + 1

		reaper.Undo_BeginBlock2(J_PROJECT_DATA:getId())

		if fx.tracktemplate then
			-- This is a template, insert it
			reaper.Main_openProject(fu._jPath(fx.path .. fx.filename))
		elseif fx.fxchain then
			if not GUI.kb.control() then -- Control not held, insert on tracks
				-- Adds an FXCHAIN to a track. If there are no FX on the track an empty chain will be created first
				local selectedTracks = J_PROJECT_DATA:selectedTracks(0, 0, true)
				local bCreatedChain = false

				for _, t in pairs(selectedTracks) do
					if t.fxcount == 0 then
						J_PROJECT_DATA:unselectAllTracks()
						t.selected = 1
						jCreateTrackChainForSelectedTracks()
						bCreatedChain = true
					end
				end

				for _, t in pairs(selectedTracks) do
					if bCreatedChain then
						t.selected = 1
					end
					local numFxBefore = t.fxcount
					jFxChainAdd(t, fu.jReadFxChainFromFile(fu._jPath(fx.path .. fx.filename)))
					if pluginsData.FXCHAIN_FLOAT_WINDOWS then
						for iFX = numFxBefore, t.fxcount - 1 do
							t:getFx(iFX):show(3)
						end
					end
				end

				if pluginsData.TRACK_SHOW_FLAG == 1 and not pluginsData.FXCHAIN_FLOAT_WINDOWS then -- added for people using the fxchain window so the fx will show
					local focusTrack = selectedTracks[1]
					if focusTrack then
						focusTrack:getFx(focusTrack.fxcount - 1):show(pluginsData.TRACK_SHOW_FLAG)
					end
				end

				-- LEAVE THIS FOR FUTURE !!!!!!!!!!
				-- else -- control held, try to add chain to items
				-- reaper.ClearConsole()
				-- for i in J_PROJECT_DATA:selectedItems() do
				-- 	local take = i:getActiveTake()
				-- 	local chunk = i:getStateChunk()
				-- 	local takeNumber = math.tointeger(take.number)
				-- 	-- msg(chunk)
				-- 	-- msg("---")

				-- 	msg(math.tointeger( takeNumber))
				-- 	local fxChunk = ultraschall.GetFXStateChunk(chunk, takeNumber)
				-- 	msg(fxChunk)
				-- 	msg("after: ")
				-- 	local fxString = fu.jReadFxChainFromFile(fx.path .. fx.filename)
				-- 	if not fxChunk then
				-- 		-- No fx yet, create chunk:
				-- 		msg("create new chunk...")
				-- 		fxChunk = " <TAKEFX\n" .. fxString .. "\n  >"
				-- 		takeNumber = 0
				-- 	else
				-- 		fxChunk =  fxChunk:gsub(">$", '') -- remove closing ">"
				-- 		fxChunk = fxChunk .. "\n" .. fxString .. "\n>"
				-- 	end
				-- 	msg("fxChunk:")
				-- 	msg(fxChunk)
				-- 	msg("Chunk:")
				-- 	msg(chunk)
				-- 	local r, newChunk = ultraschall.SetFXStateChunk(chunk, fxChunk, takeNumber)
				-- 	-- msg(newChunk)
				-- 	-- i:setStateChunk(newChunk)

				-- end
			end
		elseif fx.action then
			-- NOTE: this is how I can call regular actions from a fuzzy list.
			-- This could also be used in combination with RK sequences and fuzzy
			-- search next step to take

			reaper.Main_OnCommandEx(fx.command, 1, 0)
		-- msg(fx.command)
		-- msg(fx.name)
		else
			-- this is a vst or a jsfx
			local typeInfo = ""
			if self.t_results_data[fx.id].vst3 and pluginsData.PREFER_VST3 then -- prefer VST3 where available
				typeInfo = "VST3:"
			end

			local fxString = ""
			if fx.jsfx then
				fxString = fx.filename
			elseif fx.au then
				fxString = fx.filename
			elseif fx.aui then
				fxString = fx.filename
			else
				fxString = typeInfo .. fu._removeVstiString(self.t_results_data[fx.id].name)
			end
			if not GUI.kb.control() then -- Control not held, insert on tracks
				for t in J_PROJECT_DATA:selectedTracks() do
					local r = t:addFx(fxString)
					if r then
						r:show(pluginsData.TRACK_SHOW_FLAG)
					end
				end
			else -- Control held, insert on items
				for i in J_PROJECT_DATA:selectedItems() do
					local take = i:getActiveTake()
					local r = take:addFx(fxString)
					if r >= 0 then
						reaper.TakeFX_Show(take:getReaperTake(), r, pluginsData.ITEM_SHOW_FLAG) -- show FX
					end
				end
			end
		end
		reaper.Undo_EndBlock2(J_PROJECT_DATA:getId(), "FAST FX FINDER: Add Fx", 0)

		UPDATE_RATINGS = true
		return true
	end

	fzf.init({
		env = RK_FZF_ENV,
		title = "Fast FX Finder",
		width = 1000,
		height = 700,
		x = 100,
		y = 100,
		on_select_func = selectFx,
		results = get_plugin_results(),
		entry_maker = require("pickers.entry_makers.add_fx"),
		sort_comp = sortByRating,
		results_filter = require("pickers.results_filter.add_fx"),
		on_exit_callback = function(self)
			if UPDATE_RATINGS then
				table.sort(self.t_results_data, self.sort_comp)
				fu.jWriteVstData(pluginsData.DATA_INI_FILE, self.t_results_data)
				log.user("Updated ratings file!!")
			end
		end,
	})
end

--
--
--

pickers.test_picker = function()
	-- if not loadSettings() then
	-- 	msg(
	-- 		"Something went wrong with loading of settings, aborting. Please check your settings file: \n"
	-- 			.. SETTINGS_INI_FILE
	-- 	)
	-- 	return false
	-- end

	local function onenter(self, i)
		if not self.t_search_results then
			return false
		end -- results is empty
		local fx = self.t_search_results[i]
		if not fx then
			return false
		end -- no such result

		log.user("onenter:", i, format.block(fx))

		return true
	end

	fzf.init({
		env = RK_FZF_ENV,
		title = "Test Picker",
		on_select_func = onenter,
		results = {
			"this",
			"is",
			"a",
			"picker",
			"test",
			"xxxxxx",
			"aaaaaa",
			"vvvvvv",
			"arst",
			"XXX",
			"89",
			"=644ney",
			"9n$)",
			"(()())",
		},
		results_filter = function(vstTable, sPattern, iInstance, iMaxResults, find_plain)
			-- what todo here ??
			return vstTable
		end,
	})
end

pickers.all_tracks = function()
	fzf.init({
		env = RK_FZF_ENV,
		title = "All Tracks",

		-- TODO: create a good minimal default for on_select_func

		on_select_func = function(self, i)
			if not self.t_search_results then
				return false
			end
			local selection = self.t_search_results[i]
			if not selection then
				return false
			end
			log.user("onenter:", i, format.block(selection))
			return true
		end,
		results = syntax.get_list_of_track_objects(),
		sort_comp = "name",

		-- FIX: is there a good default that could be added here?
		results_filter = function(vstTable, sPattern, iInstance, iMaxResults, find_plain)
			-- what todo here ??
			return vstTable
		end,

		-- TODO: create a good minimal default for entry_maker

		entry_maker = function(tButtons, tResults)
			for i, cIds in ipairs(tButtons) do
				local b = cIds[1]
				local info = cIds[2]
				local iStart = fu._round(i + SCROLL_RESULTS)
				local highlights = sf.jStringExplode(textBox.value, " ")
				local showing

				if iStart <= #tResults then
					showing = iStart
				else
					showing = #tResults
				end

				LABEL_STATS.label = "(" .. showing .. "/" .. #tResults .. ")"

				if tResults and iStart <= #tResults then
					local item = tResults[iStart]
					b.label = item.name
					b.visible = true
					info.visible = true
					b.highlight = highlights
				else
					b.visible = false
					info.visible = false
				end
			end
		end,
	})
end

-- * WHAT THINGS CAN BE CONTROLLED VIA FZF:
--
-- ** REAPERS PREFERENCES
--
--   This will allow me to automate and control anything in the preferences
--   through the fzf interface.
--
-- *** Any text based configs etc. (.ini)

pickers.browse_reaper_preferences = function()
	-- todo: read the plugins data and

	-- local RK_FZF_ENV = {
	--   SETTINGS_INI_FILE = home .. definitions_dir .. "/fx-finder-settings.ini",
	--   SETTINGS_DEFAULT_FILE = home .. definitions_dir .. "/defaults/fx-finder-settings-default.ini",
	--   RK_DATA = home .. "/reaper/packages/reaper-keys/data",
	-- }

	--  	local SETTINGS_INI_FILE = env.SETTINGS_INI_FILE
	-- local SETTINGS_DEFAULT_FILE = env.SETTINGS_DEFAULT_FILE
	--
	-- log.user(SETTINGS_INI_FILE, SETTINGS_DEFAULT_FILE)
	--
	-- settings.jSettingsCreate(SETTINGS_INI_FILE, SETTINGS_DEFAULT_FILE)
	-- SETTINGS = assert(settings.jSettingsReadFromFile(SETTINGS_INI_FILE), "Could not open settings file.")

	fzf.init({
		env = RK_FZF_ENV,
		title = "Reaper preferences",
		on_select_func = onenter,
		results = {},
		results_filter = function(vstTable, sPattern, iInstance, iMaxResults, find_plain)
			-- what todo here ??
			return vstTable
		end,
	})
end

pickers.track_fx = function()
	local t_track_fx = {}

	-- ~ look at my track syntax
	--
	-- ~ get all track fx in table
	--
	-- ~ show in picker.

	p = JProject:new()
	reset_variables()
	-- if not loadSettings() then
	-- 	msg(
	-- 		"Something went wrong with loading of settings, aborting. Please check your settings file: \n"
	-- 			.. SETTINGS_INI_FILE
	-- 	)
	-- 	return false
	-- end

	local function onenter(self, i)
		if not self.t_search_results then
			return false
		end -- results is empty
		local fx = self.t_search_results[i]
		if not fx then
			return false
		end -- no such result

		log.user("onenter:", i, format.block(fx))

		return true
	end

	local make_results = function()
		local selectedTracks = J_PROJECT_DATA:selectedTracks(0, 0, true)

		log.user("selectedTracks in browse_fx_list:", selectedTracks)
	end

	fzf.init({
		title = "Browse track FX list",
		on_select_func = onenter,
		results = {
			"this",
			"is",
			"a",
			"picker",
			"test",
			"xxxxxx",
			"aaaaaa",
			"vvvvvv",
			"arst",
			"XXX",
			"89",
			"=644ney",
			"9n$)",
			"(()())",
		},
		results_filter = function(vstTable, sPattern, iInstance, iMaxResults, find_plain)
			-- what todo here ??
			return vstTable
		end,
	})
end

pickers.track_fx_params = function()
	-- local the_fx = ??

	local t_fx_params

	-- connect this to track_fx with next = this
	--
	-- ~ for selected fx
	--
	-- ~ make list of fx params

	fzf.init({
		env = RK_FZF_ENV,
		title = "Fx params for <fx_name> on track <track_name>",
		on_select_func = onenter,
		results = {},
		results_filter = function(vstTable, sPattern, iInstance, iMaxResults, find_plain)
			-- what todo here ??
			return vstTable
		end,
	})
end

pickers.track_channel_mix_params = function()
	local t_track_params = {
		-- volume =
		-- pan =
		-- phase =
		-- solo =
		-- mute =
		-- active =
		-- armed =
		-- record_monitoring =
		-- fx = next > fx menu
		-- routing
	}

	fzf.init({
		env = RK_FZF_ENV,
		title = "Track params for track: <trackname>",
		on_select_func = onenter,
		results = {},
		results_filter = function(vstTable, sPattern, iInstance, iMaxResults, find_plain)
			-- what todo here ??
			return vstTable
		end,
	})

	-- ~ create list of relevant track params
	-- ~ figure out how i can show them all in one picker.
end

pickers.track_attributes = function()
	--   boolean retval, string stringNeedBig = reaper.GetSetMediaTrackInfo_String(MediaTrack tr, string parmname, string stringNeedBig, boolean setNewValue)
	-- Get or set track string attributes.
	-- P_NAME : char * : track name (on master returns NULL)
	-- P_ICON : const char * : track icon (full filename, or relative to resource_path/data/track_icons)
	-- P_MCP_LAYOUT : const char * : layout name
	-- P_RAZOREDITS : const char * : list of razor edit areas, as space-separated triples of start time, end time, and envelope GUID string.
	-- Example: "0.0 1.0 \"\" 0.0 1.0 "{xyz-...}"
	-- P_RAZOREDITS_EXT : const char * : list of razor edit areas, as comma-separated sets of space-separated tuples of start time, end time, optional: envelope GUID string, fixed/fipm top y-position, fixed/fipm bottom y-position.
	-- Example: "0.0 1.0,0.0 1.0 "{xyz-...}",1.0 2.0 "" 0.25 0.75"
	-- P_TCP_LAYOUT : const char * : layout name
	-- P_EXT:xyz : char * : extension-specific persistent data
	-- P_UI_RECT:tcp.mute : char * : read-only, allows querying screen position + size of track WALTER elements (tcp.size queries screen position and size of entire TCP, etc).
	-- GUID : GUID * : 16-byte GUID, can query or update. If using a _String() function, GUID is a string {xyz-...}.

	fzf.init({
		env = RK_FZF_ENV,
		title = "Track attributes (tr: <trackname>)",
		on_select_func = onenter,
		results = {},
		results_filter = function(vstTable, sPattern, iInstance, iMaxResults, find_plain)
			-- what todo here ??
			return vstTable
		end,
	})
end

pickers.track_routing = function()
	-- revisit my route lib
	--
	-- get all routes for track
	--
	-- reuse my track logging function but here instead.

	fzf.init({
		env = RK_FZF_ENV,
		title = "Routing @track: <trackname>",
		on_select_func = onenter,
		results = {},
		results_filter = function(vstTable, sPattern, iInstance, iMaxResults, find_plain)
			-- what todo here ??
			return vstTable
		end,
	})
end

pickers.midi_editor_take_screensets = function()

	--
end

pickers.track_list_ui = function() end

pickers.projects = function()
	-- ReaProject retval, optional string projfn = reaper.EnumProjects(integer idx)
	-- -- idx=-1 for current project,projfn can be NULL if not interested in filename. use idx 0x40000000 for currently rendering project, if any.

	-- maybe i just need to do a bash script to collect all projects from
	-- my projects dir.

	fzf.init({
		env = RK_FZF_ENV,
		title = "Projects listing",
		on_select_func = onenter,
		results = {},
		results_filter = function(vstTable, sPattern, iInstance, iMaxResults, find_plain)
			-- what todo here ??
			return vstTable
		end,
	})
end

-- 	FIX: make vtt into a class
-- 	I need to make the vtt into a class so that I can attach methods to it
-- 	that make it a bit easier to filter the tree.

pickers.track_syntax = function()
	-- 	local vtt = syntax.getVerifiedTree()
	-- 	vtt.for_each_real_track()
	-- 	   ie. loop zone > G > collect all real tracks (classes AM).
	-- 	   put these in picker.
	--
end

pickers.vtt_zones = function()
	fzf.init({
		env = RK_FZF_ENV,
		title = "syntax: zones",
		on_select_func = onenter,
		results = {},
		results_filter = function(vstTable, sPattern, iInstance, iMaxResults, find_plain)
			-- what todo here ??
			return vstTable
		end,
	})
end

pickers.vtt_groups = function() end

pickers.vtt_mcsab_by_group_name = function()
	fzf.init({
		env = RK_FZF_ENV,
		title = "syntax: MSCAB",
		on_select_func = onenter,
		results = {},
		results_filter = function(vstTable, sPattern, iInstance, iMaxResults, find_plain)
			-- what todo here ??
			return vstTable
		end,
	})
end

pickers.vtt_all_fx_tracks = function() end

pickers.vtt_utils = function() end

pickers.vtt_drum_kits = function()
	fzf.init({
		env = RK_FZF_ENV,
		title = "drum kits",
		on_select_func = onenter,
		results = {},
		results_filter = function(vstTable, sPattern, iInstance, iMaxResults, find_plain)
			-- what todo here ??
			return vstTable
		end,
	})
end

pickers.marks = function()
	-- local ok, old_mark = project_state.get("marks", register)
	-- mark['index'] = reaper.AddProjectMarker(0, true, mark.left, mark.right, register, -1)
	local t_regions = marks.get_all(false)

	fzf.init({
		env = RK_FZF_ENV,
		title = "project marks",
		on_select_func = onenter,
		results = {},
		results_filter = function(vstTable, sPattern, iInstance, iMaxResults, find_plain)
			-- what todo here ??
			return vstTable
		end,
	})
end

pickers.regions = function()
	-- integer retval, integer num_markers, integer num_regions = reaper.CountProjectMarkers(ReaProject proj)
	--
	-- integer retval, boolean isrgn, number pos, number rgnend, string name,
	-- integer markrgnindexnumber, integer color =
	-- reaper.EnumProjectMarkers3(ReaProject proj, integer idx)
	--

	local t_regions = marks.get_all(true)
	-- pass this to picker

	fzf.init({
		env = RK_FZF_ENV,
		title = "project regions",
		on_select_func = onenter,
		results = {},
		results_filter = function(vstTable, sPattern, iInstance, iMaxResults, find_plain)
			-- what todo here ??
			return vstTable
		end,
	})
end

pickers.midi_patterns = function()
	-- get patterns from the midi patterns config file
	-- definitions/midi_patterns.lua

	fzf.init({
		env = RK_FZF_ENV,
		title = "midi patterns",
		on_select_func = onenter,
		results = {},
		results_filter = function(vstTable, sPattern, iInstance, iMaxResults, find_plain)
			-- what todo here ??
			return vstTable
		end,
	})
end

pickers.chord_progression = function()
	-- start building out basic atomic (very important) progressions
	-- that can be picked to insert chord data. Should be usable
	-- with motion so that you can do `apply progression to` motion, eg beats, bar, or region.

	fzf.init({
		env = RK_FZF_ENV,
		title = "chord progressions",
		on_select_func = onenter,
		results = {},
		results_filter = function(vstTable, sPattern, iInstance, iMaxResults, find_plain)
			-- what todo here ??
			return vstTable
		end,
	})
end

pickers.chord = function(meta, opts)
	log.user("picker chord:", format.block(opts))

	-- refactor into data
	local t_chords = {
		{
			"major",
			{ 1, 5, 8 },
		},
		{
			"minor",
			{ 1, 4, 8 },
		},
	}

	fzf.init({
		env = RK_FZF_ENV,
		title = string.format("%s: chord", meta.action_type),
		on_select_func = function(self, i)
			local chord = self.t_search_results[i]
			-- log.user("selected chord:", format.block(chord))
			opts.next(meta, {
				chord = chord,
				move_cursor = opts.move_cursor,
			})
		end,
		results = t_chords,
		sort_comp = 1,

		-- RENAME: vstTable...
		results_filter = function(vstTable, sPattern, iInstance, iMaxResults, find_plain)
			-- what todo here ??
			return vstTable
		end,
		entry_maker = function(tButtons, tResults)
			for i, cIds in ipairs(tButtons) do
				local b = cIds[1]
				local info = cIds[2]
				local iStart = fu._round(i + SCROLL_RESULTS)
				local highlights = sf.jStringExplode(textBox.value, " ")
				local showing

				if iStart <= #tResults then
					showing = iStart
				else
					showing = #tResults
				end

				LABEL_STATS.label = "(" .. showing .. "/" .. #tResults .. ")"

				if tResults and iStart <= #tResults then
					local item = tResults[iStart]
					b.label = item[1]
					b.visible = true
					info.visible = true
					b.highlight = highlights
				else
					b.visible = false
					info.visible = false
				end
			end
		end,
	})
end

pickers.envelope_template = function()
	local t_env_templates = {}
end

pickers.midi_cc_templates = function()
	-- i can start sketching these out in a config table.
	-- definitions/midi_cc_curves.lua
	local t_midi_cc_curves = {}
end

pickers.midi_note_articulation = function()
	-- definitions/midi_articulations.lua
	local t_midi_articulations = {}
end

pickers.all_items = function()
	-- TODO: i should use the flat array from vtt here!!

	local t_all_tracks = {}
	for i = 0, reaper.CountTracks(0) - 1 do
		local tr = reaper.GetTrack(0, i)
		local guid = reaper.GetTrackGUID(tr)
		local _, track_name_raw = reaper.GetTrackName(tr)
		table.insert(t_all_tracks, {
			tr = tr,
			guid = guid,
			name = track_name_raw,
		})
	end

	local t_all_items = {}
	for _, trk_obj in pairs(t_all_tracks) do
		num_items = reaper.GetTrackNumMediaItems(trk_obj.tr)
		if num_items > 0 then
			-- first_item = reaper.GetTrackMediaItem(track, 0)
			-- first_item_sel = reaper.IsMediaItemSelected(first_item)

			for i = 0, num_items - 1 do
				item = reaper.GetTrackMediaItem(trk_obj.tr, i)
				local item_cur_take = reaper.GetTake(item, 0)
				local take_name = reaper.GetTakeName(item_cur_take)
				table.insert(t_all_items, {
					parent_track_id = guid,
					item_idx = reaper.GetMediaItemInfo_Value(item, "IP_ITEMNUMBER"),
					name = take_name,
				})
			end
		end
	end

	log.user(format.block(t_all_items))

	fzf.init({
		env = RK_FZF_ENV,
		title = "all items",
		on_select_func = onenter,
		results = t_all_items,
		results_filter = function(vstTable, sPattern, iInstance, iMaxResults, find_plain)
			-- what todo here ??
			return vstTable
		end,
		sort_comp = "name",
		entry_maker = function(tButtons, tResults)
			for i, cIds in ipairs(tButtons) do
				local b = cIds[1]
				local info = cIds[2]
				local iStart = fu._round(i + SCROLL_RESULTS)
				local highlights = sf.jStringExplode(textBox.value, " ")
				local showing

				if iStart <= #tResults then
					showing = iStart
				else
					showing = #tResults
				end

				LABEL_STATS.label = "(" .. showing .. "/" .. #tResults .. ")"

				if tResults and iStart <= #tResults then
					local item = tResults[iStart]
					b.label = item.name
					b.visible = true
					info.visible = true
					b.highlight = highlights
				else
					b.visible = false
					info.visible = false
				end
			end
		end,
	})
end

pickers.all_visible_items = function()
	-- NOTE: vtt should return an array of all track objects as well as the tree.
	-- BOTH data structurs are important.

	local tracks_cnt = reaper.GetNumTracks()
	reaper.PreventUIRefresh(1)
	local _, _, tcp_height = reaper.JS_Window_GetClientSize(reaper.JS_Window_FindChildByID(reaper.GetMainHwnd(), 0x3E8))

	local start_time, end_time = reaper.GetSet_ArrangeView2(0, false, 0, 0)

	local prev_tr_visible = false

	for tr = 0, tracks_cnt - 1 do
		local track = reaper.GetTrack(0, tr)
		local track_pos = reaper.GetMediaTrackInfo_Value(track, "I_TCPY")
		local track_h = track_pos + reaper.GetMediaTrackInfo_Value(track, "I_TCPH")

		if reaper.IsTrackVisible(track, false) and track_pos >= 0 and track_h <= tcp_height then
			prev_tr_visible = true
			local item_cnt = reaper.GetTrackNumMediaItems(track)
			local prev_visible = false

			for i = 0, item_cnt - 1 do
				local item = reaper.GetTrackMediaItem(track, i)
				local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
				local item_end = item_start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
				if item_start >= start_time and item_end <= end_time then
					reaper.SetMediaItemSelected(item, true)
					prev_visible = true
				else
					if prev_visible then
						break
					end
				end
			end
		else
			if prev_tr_visible then
				break
			end
		end
	end
	reaper.PreventUIRefresh(-1)
	reaper.UpdateArrange()

	fzf.init({
		env = RK_FZF_ENV,
		title = "visible items (lightspeed)",
		on_select_func = onenter,
		results = {},
		results_filter = function(vstTable, sPattern, iInstance, iMaxResults, find_plain)
			-- what todo here ??
			return vstTable
		end,
	})
end

pickers.item_parameters = function()
	-- number reaper.GetMediaItemInfo_Value(MediaItem item, string parmname)
	-- Get media item numerical-value attributes.
	local t_item_params = {
		-- B_MUTE : bool * : muted (item solo overrides). setting this value will clear C_MUTE_SOLO.
		-- B_MUTE_ACTUAL : bool * : muted (ignores solo). setting this value will not affect C_MUTE_SOLO.
		-- C_LANEPLAYS : char * : in fixed lane tracks, 0=this item lane does not play, 1=this item lane plays exclusively, 2=this item lane plays and other lanes also play (read-only)
		-- C_MUTE_SOLO : char * : solo override (-1=soloed, 0=no override, 1=unsoloed). note that this API does not automatically unsolo other items when soloing (nor clear the unsolos when clearing the last soloed item), it must be done by the caller via action or via this API.
		-- B_LOOPSRC : bool * : loop source
		-- B_ALLTAKESPLAY : bool * : all takes play
		-- B_UISEL : bool * : selected in arrange view
		-- C_BEATATTACHMODE : char * : item timebase, -1=track or project default, 1=beats (position, length, rate), 2=beats (position only). for auto-stretch timebase: C_BEATATTACHMODE=1, C_AUTOSTRETCH=1
		-- C_AUTOSTRETCH: : char * : auto-stretch at project tempo changes, 1=enabled, requires C_BEATATTACHMODE=1
		-- C_LOCK : char * : locked, &1=locked
		-- D_VOL : double * : item volume, 0=-inf, 0.5=-6dB, 1=+0dB, 2=+6dB, etc
		-- D_POSITION : double * : item position in seconds
		-- D_LENGTH : double * : item length in seconds
		-- D_SNAPOFFSET : double * : item snap offset in seconds
		-- D_FADEINLEN : double * : item manual fadein length in seconds
		-- D_FADEOUTLEN : double * : item manual fadeout length in seconds
		-- D_FADEINDIR : double * : item fadein curvature, -1..1
		-- D_FADEOUTDIR : double * : item fadeout curvature, -1..1
		-- D_FADEINLEN_AUTO : double * : item auto-fadein length in seconds, -1=no auto-fadein
		-- D_FADEOUTLEN_AUTO : double * : item auto-fadeout length in seconds, -1=no auto-fadeout
		-- C_FADEINSHAPE : int * : fadein shape, 0..6, 0=linear
		-- C_FADEOUTSHAPE : int * : fadeout shape, 0..6, 0=linear
		-- I_GROUPID : int * : group ID, 0=no group
		-- I_LASTY : int * : Y-position (relative to top of track) in pixels (read-only)
		-- I_LASTH : int * : height in pixels (read-only)
		-- I_CUSTOMCOLOR : int * : custom color, OS dependent color|0x1000000 (i.e. ColorToNative(r,g,b)|0x1000000). If you do not |0x1000000, then it will not be used, but will store the color
		-- I_CURTAKE : int * : active take number
		-- IP_ITEMNUMBER : int : item number on this track (read-only, returns the item number directly)
		-- F_FREEMODE_Y : float * : free item positioning or fixed lane Y-position. 0=top of track, 1.0=bottom of track
		-- F_FREEMODE_H : float * : free item positioning or fixed lane height. 0.5=half the track height, 1.0=full track height
		-- I_FIXEDLANE : int * : fixed lane of item (fine to call with setNewValue, but returned value is read-only)
		-- B_FIXEDLANE_HIDDEN : bool * : true if displaying only one fixed lane and this item is in a different lane (read-only)
		-- P_TRACK : MediaTrack * : (read-only)
	}

	fzf.init({
		env = RK_FZF_ENV,
		title = "item params for: <item>",
		on_select_func = onenter,
		results = {},
		results_filter = function(vstTable, sPattern, iInstance, iMaxResults, find_plain)
			-- what todo here ??
			return vstTable
		end,
	})
end

pickers.take_parameters = function()
	-- number reaper.GetMediaItemTakeInfo_Value(MediaItem_Take take, string parmname)
	-- Get media item take numerical-value attributes.
	local t_take_params = {
		-- D_STARTOFFS : double * : start offset in source media, in seconds
		-- D_VOL : double * : take volume, 0=-inf, 0.5=-6dB, 1=+0dB, 2=+6dB, etc, negative if take polarity is flipped
		-- D_PAN : double * : take pan, -1..1
		-- D_PANLAW : double * : take pan law, -1=default, 0.5=-6dB, 1.0=+0dB, etc
		-- D_PLAYRATE : double * : take playback rate, 0.5=half speed, 1=normal, 2=double speed, etc
		-- D_PITCH : double * : take pitch adjustment in semitones, -12=one octave down, 0=normal, +12=one octave up, etc
		-- B_PPITCH : bool * : preserve pitch when changing playback rate
		-- I_LASTY : int * : Y-position (relative to top of track) in pixels (read-only)
		-- I_LASTH : int * : height in pixels (read-only)
		-- I_CHANMODE : int * : channel mode, 0=normal, 1=reverse stereo, 2=downmix, 3=left, 4=right
		-- I_PITCHMODE : int * : pitch shifter mode, -1=projext default, otherwise high 2 bytes=shifter, low 2 bytes=parameter
		-- I_CUSTOMCOLOR : int * : custom color, OS dependent color|0x1000000 (i.e. ColorToNative(r,g,b)|0x1000000). If you do not |0x1000000, then it will not be used, but will store the color
		-- IP_TAKENUMBER : int : take number (read-only, returns the take number directly)
		-- P_TRACK : pointer to MediaTrack (read-only)
		-- P_ITEM : pointer to MediaItem (read-only)
		-- P_SOURCE : PCM_source *. Note that if setting this, you should first retrieve the old source, set the new, THEN delete the old.
	}

	fzf.init({
		env = RK_FZF_ENV,
		title = "take params for: <take>",
		on_select_func = onenter,
		results = {},
		results_filter = function(vstTable, sPattern, iInstance, iMaxResults, find_plain)
			-- what todo here ??
			return vstTable
		end,
	})
end

pickers.load_track_from_presets = function()

	-- how are track templates/presets loaded and created in fzf?
	--
	--
	-- Archie_Track;  Smart template - Load Track template by name.lua
end

pickers.samples_explorer = function()
	-- NOTE: this script supposedly show you how to preview audio samples.
	-- /Users/hjalmarjakobsson/reaper/app/reaper/Scripts/ReaTeam Scripts/Project Properties/solger_ReaLauncher.lua

	-- 1. make locateDb out of media samples.
	-- (!)  set samples dir in user config + cronjob that updates this
	-- 2. pass locate db output to picker.
	-- 3. on select -> preview sample AND close
end

pickers.sample_selector = function() end
pickers.file_browser = function() end

return pickers
