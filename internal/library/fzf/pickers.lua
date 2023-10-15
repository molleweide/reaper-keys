local log = require("utils.log")
local format = require("utils.format")

local fzf = require("library.fzf.fzf")

-- does some nested requires that requires fzf to be loaded first, (for now...)
require("library.fzf.REQ.JProjectClass")

-- TODO: split `load_settings` into load vst settigs, and load GUI settings

local pickers = {}

-- leader j f

----------------------------------------------
--
--

pickers.add_track_fx = function()
	p = JProject:new()

	fzf.reset_variables()

	if not loadSettings() then
		msg(
			"Something went wrong with loading of settings, aborting. Please check your settings file: \n"
				.. SETTINGS_INI_FILE
		)
		return false
	end

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
		tRatingData = jReadVstData(DATA_INI_FILE)
		results = jReadVstIni(VST_INI_FILE, tRatingData)

		tTemplates = getTemplates(TEMPLATE_SUB_DIRS, TEMPLATE_ROOT_DIR, tRatingData)
		results = jTablesGlue(tTemplates, results)

		tFXChains = getFXChains(FXCHAIN_SUB_DIRS, FXCHAIN_ROOT_DIR, tRatingData)
		results = jTablesGlue(tFXChains, results)

		local tJsfx = jReadJsfxIni(JSFX_INI_FILE, tRatingData)
		results = jTablesGlue(tJsfx, results)

		if LOAD_AU then
			local tAu = jReadAuIni(AU_INI_FILE, tRatingData)
			results = jTablesGlue(tAu, results)
		end

		-- NOTE: is this where mappings are attached??
		-- local time = os.clock()
		if LOAD_ACTIONS then
			local tActions = jGetActions()
			results = jTablesGlue(tActions, results)
		end
		-- msg(os.clock() - time)

		-- table.sort(results, sortByRating)

		return results
	end

	local function entry_maker() end

	local function selectFx(i)
		-- todo: i should prolly remove the undo points since
		-- those are handled by RK

		log.user("SELECT FX: ", i)

		if not tSearchResults then
			return false
		end -- results is empty

		local fx = tSearchResults[i]

		if not fx then
			return false
		end -- no such result

		T_RESULTS[fx.id].rating = T_RESULTS[fx.id].rating + 1

		reaper.Undo_BeginBlock2(p:getId())

		if fx.tracktemplate then
			-- This is a template, insert it
			reaper.Main_openProject(_jPath(fx.path .. fx.filename))
		elseif fx.fxchain then
			if not GUI.kb.control() then -- Control not held, insert on tracks
				-- Adds an FXCHAIN to a track. If there are no FX on the track an empty chain will be created first
				local selectedTracks = p:selectedTracks(0, 0, true)
				local bCreatedChain = false

				for _, t in pairs(selectedTracks) do
					if t.fxcount == 0 then
						p:unselectAllTracks()
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
					jFxChainAdd(t, jReadFxChainFromFile(_jPath(fx.path .. fx.filename)))
					if FXCHAIN_FLOAT_WINDOWS then
						for iFX = numFxBefore, t.fxcount - 1 do
							t:getFx(iFX):show(3)
						end
					end
				end

				if TRACK_SHOW_FLAG == 1 and not FXCHAIN_FLOAT_WINDOWS then -- added for people using the fxchain window so the fx will show
					local focusTrack = selectedTracks[1]
					if focusTrack then
						focusTrack:getFx(focusTrack.fxcount - 1):show(TRACK_SHOW_FLAG)
					end
				end

				-- LEAVE THIS FOR FUTURE !!!!!!!!!!
				-- else -- control held, try to add chain to items
				-- reaper.ClearConsole()
				-- for i in p:selectedItems() do
				-- 	local take = i:getActiveTake()
				-- 	local chunk = i:getStateChunk()
				-- 	local takeNumber = math.tointeger(take.number)
				-- 	-- msg(chunk)
				-- 	-- msg("---")

				-- 	msg(math.tointeger( takeNumber))
				-- 	local fxChunk = ultraschall.GetFXStateChunk(chunk, takeNumber)
				-- 	msg(fxChunk)
				-- 	msg("after: ")
				-- 	local fxString = jReadFxChainFromFile(fx.path .. fx.filename)
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
			if T_RESULTS[fx.id].vst3 and PREFER_VST3 then -- prefer VST3 where available
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
				fxString = typeInfo .. _removeVstiString(T_RESULTS[fx.id].name)
			end
			if not GUI.kb.control() then -- Control not held, insert on tracks
				for t in p:selectedTracks() do
					local r = t:addFx(fxString)
					if r then
						r:show(TRACK_SHOW_FLAG)
					end
				end
			else -- Control held, insert on items
				for i in p:selectedItems() do
					local take = i:getActiveTake()
					local r = take:addFx(fxString)
					if r >= 0 then
						reaper.TakeFX_Show(take:getReaperTake(), r, ITEM_SHOW_FLAG) -- show FX
					end
				end
			end
		end
		reaper.Undo_EndBlock2(p:getId(), "FAST FX FINDER: Add Fx", 0)

		UPDATE_RATINGS = true
		return true
	end

	local opts = {
		title = "Fast FX Finder",
		width = 1000,
		height = 700,
		x = 100,
		y = 100,
		on_select_func = selectFx,
		results = get_plugin_results(),
		entry_maker = require("entry_makers.add_fx"),
		sort_comp = sortByRating,
		results_filter = require("results_filter.add_fx"),
		on_exit_callback = function(self)
			if UPDATE_RATINGS then
				table.sort(T_RESULTS, self.sort_comp)
				jWriteVstData(DATA_INI_FILE, T_RESULTS)
			  log.user("Updated ratings file!!")
			end
		end,
	}

	if fzf.init(opts, onenter) then
		-- TODO: this logic should be put inside of init, so that I don't have to
		-- keep reference of the GUI in this function
		GUI:setReaperFocus()
		loop()
	end
end

----------------------------------------------
--
--

pickers.test_picker = function()
	p = JProject:new()

	fzf.reset_variables()

	-- if not loadSettings() then
	-- 	msg(
	-- 		"Something went wrong with loading of settings, aborting. Please check your settings file: \n"
	-- 			.. SETTINGS_INI_FILE
	-- 	)
	-- 	return false
	-- end

	local function onenter(i)
		if not tSearchResults then
			return false
		end -- results is empty
		local fx = tSearchResults[i]
		if not fx then
			return false
		end -- no such result

		log.user("onenter:", i, format.block(fx))

		return true
	end

	local opts = {
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
		sort_comp = function(a, b)
			if a > b then
				return true
			elseif a == b then
				return a < b
			else
				return false
			end
		end,
		results_filter = function(vstTable, sPattern, iInstance, iMaxResults, find_plain)
			-- what todo here ??
			return vstTable
		end,
		entry_maker = function(tButtons, tResults)
			for i, cIds in ipairs(tButtons) do
				local b = cIds[1]
				local info = cIds[2]
				local iStart = _round(i + SCROLL_RESULTS)
				local highlights = jStringExplode(textBox.value, " ")

				local showing
				if iStart <= #tResults then
					showing = iStart
				else
					showing = #tResults
				end
				LABEL_STATS.label = "(" .. showing .. "/" .. #tResults .. ")"

				if tResults and iStart <= #tResults then
					local item = tResults[iStart]
					b.label = item
					b.visible = true
					info.visible = true
					b.highlight = highlights
				else
					b.visible = false
					info.visible = false
				end
			end
		end,
	}

	if fzf.init(opts, onenter) then
		-- TODO: this logic should be put inside of init, so that I don't have to
		-- keep reference of the GUI in this function
		GUI:setReaperFocus()
		loop()
	end
end

-- * WHAT THINGS CAN BE CONTROLLED VIA FZF:
--
-- ** REAPERS PREFERENCES
--
--   This will allow me to automate and control anything in the preferences
--   through the fzf interface.
--
-- *** Any text based configs etc. (.ini)

pickers.browse_reaper_preferences = function() end

--
-- ** TRACK FX LIST / CHAIN
--
--   I can use this window as a custom UI replacement for the FX window.
--   Add custom actions for navigating up/down.
--   I would have to create a new custom context for the FZF window.
--
--   TODO: get table of track_fx_list
--   ~ full names
--   ~ other info
--   ...

pickers.browse_track_fx_list = function()
	p = JProject:new()
	reset_variables()
	if not loadSettings() then
		msg(
			"Something went wrong with loading of settings, aborting. Please check your settings file: \n"
				.. SETTINGS_INI_FILE
		)
		return false
	end

	local function onenter(i)
		if not tSearchResults then
			return false
		end -- results is empty
		local fx = tSearchResults[i]
		if not fx then
			return false
		end -- no such result

		log.user("onenter:", i, format.block(fx))

		return true
	end

	local make_results = function()
		local selectedTracks = p:selectedTracks(0, 0, true)

		log.user("selectedTracks in browse_fx_list:", selectedTracks)
	end

	local opts = {
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
		sort_comp = function(a, b)
			if a > b then
				return true
			elseif a == b then
				return a < b
			else
				return false
			end
		end,
		results_filter = function(vstTable, sPattern, iInstance, iMaxResults, find_plain)
			-- what todo here ??
			return vstTable
		end,
		entry_maker = function(tButtons, tResults)
			for i, cIds in ipairs(tButtons) do
				local b = cIds[1]
				local info = cIds[2]
				local iStart = _round(i + SCROLL_RESULTS)
				local highlights = jStringExplode(textBox.value, " ")

				local showing
				if iStart <= #tResults then
					showing = iStart
				else
					showing = #tResults
				end
				LABEL_STATS.label = "(" .. showing .. "/" .. #tResults .. ")"

				if tResults and iStart <= #tResults then
					local item = tResults[iStart]
					b.label = item
					b.visible = true
					info.visible = true
					b.highlight = highlights
				else
					b.visible = false
					info.visible = false
				end
			end
		end,
	}

	if fzf.init(opts, onenter) then
		-- TODO: this logic should be put inside of init, so that I don't have to
		-- keep reference of the GUI in this function
		GUI:setReaperFocus()
		loop()
	end
end

--
-- ** TRACK FX PARAMTERS, EG. REAEQ
--
--   Use the FZF window to filter fx parameters and perform mixing.
--
--   TODO: pick fx params for fx at index X in track Y

pickers.track_fx_params = function() end

--
-- ** TRACK MIXER
--
--   Manage all basic reaper track parameters
--
--   TODO: volume, pan, sends/recieves, phase, etc..

pickers.track_channel_mix_params = function() end

--
-- 5. TRACK ROUTES
--
--   CRUD UI for routes
--
--   TODO: list sends/recieves for track

pickers.track_channel_mix_params = function() end

--
-- 6. MIDI EDITOR TAKE-SELECTION-SETS
--
--   Select what group combination of tracks and items/takes that currently
--   should be shown/visible in the MIDI Editor

pickers.midi_editor_take_screensets = function() end

-- 7. TRACK LIST UI
--
--   Control and manage track list

pickers.track_list_ui = function() end

-- 7. BROWSE PROJECTS/TABS (OPEN IN NEW TAB)
--

pickers.browse_projects = function() end

-- 8. BROWSE SYNTAX ZONES/GROUPS/TRACKS
--
--   ..and control parameters. implement multiple selection etc. for more
--   granular selections and ability to customize the arrangement view.
--
--   TODO: zone, grouts, ...

pickers.track_syntax = function() end

--
-- 9. BROWSE MARKS / REGIONS
--
--   For super fast navigation and shit.

pickers.marks = function() end

pickers.regions = function() end

--
-- PICKER: patterns
--
--   For super fast navigation and shit.

pickers.midi_patterns = function() end

--
-- PICKER: file browser / sample selector
--
--   For super fast navigation and shit.

pickers.sample_selector = function() end

pickers.file_browser = function() end

--
-- PICKER: music theory
--
--   For super fast navigation and shit.

pickers.chord_progressions = function() end

--
-- PICKER: envelopes / modulation
--
--   For super fast navigation and shit.

pickers.envelope_template = function() end

pickers.midi_cc_templates = function() end

pickers.midi_note_articulation = function() end

return pickers
