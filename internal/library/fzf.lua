--[[
@description Fast FX Finder
@author n0ne
@about
	# Fast VST/FX Rack/Template Finder

	-- TODO: move all picker variables to GUI
	--
	-- TODO: start using pluginsData

-- TODO: Add a master title for the current picker when initiating the
-- UI, then i create a jGui class function that can update the window title.
-- --
-- I can update the window name with ` reaper.JS_Window_SetTitle( windowHWND, title )`
-- This should go into the jGui class file.
--
-- FIX: user control over whether or not to reset the text input if the on_select_func
-- returns false. Eg. this is not wanted when writing add track node strings,
-- since we might just want to correct a minor typo.

  A little window that allows for quick searching of FX (can be VST, templates or fxrack).

	The script stores how often you select a certain FX and orders the list by how many times something is used.
@version 0.7.27
@changelog
	0.7.27
	+ Added support for copy/pasting. CTRL + C will copy the whole textfield.  CTRL + V will paste at the carret.
	0.7.26
	+ added more comments to default settings file to make it easier to costumize things
	0.7.25
	+ Fix window focus when opening in dock
	0.7.24
	+ Fix negative screen coordinates error message
	+ Updated error message when JSFX ini file does not exist. Updating Reaper deletes this file and you need to run the default FX browser once.
	+ Added colors for different type's of FX
	+ Added option to float fx windows after adding FXCHAIN
	0.7.22
	+ Fix bug with paths in Reaper 6.04
	0.7.21
	+ Add Audio Unit support
	0.7.19
	+ Fixed textbox bug
	+ Improve textbox: use ctrl+backspace for deleting the last word, ctrl+shift+backspace to clear the field. Home and end work too!
	0.7.18
	+ Allow blacklist search to also look in plugin filename (add dll to skip VST version or VSTi to skip instruments for example)
	+ Only pull actual template and fxchain files from directories
	+ Don't filter when you start typing a '@' tag. If you want to filter for a word starting with '@', escape it like: \@
	+ Added support for JSFX and @js tag!
	+ Cleaned up default settings ini, left some test comments in there ;p
	+ Add (experimental) support for loading actions. Turn on in settings. Can use @a tag. Right now only main window actions.
	0.7.17
	+ Allow resizing of GUI and change number of results
	+ Store window position
	+ Scroll down list with tab and arrow keys
	+ Add setting to open FX in chain
	+ Fix searching in hidden filename parts
	+ Add support for searching with tags: @fx, @chain, @temp, @i, @vst3, @vst
	+ Improve format of ini file. Backwards compatible but recommended to update (see REQ/ settings default)
@provides
	REQ/j_file_functions.lua
	REQ/JProjectClass.lua
	REQ/JProjectClassReq.lua
	REQ/j_tables.lua
	REQ/JGui.lua
	REQ/JGuiColors.lua
	REQ/JGuiControls.lua
	REQ/JGuiFunctions.lua
	REQ/j_trackstatechunk_functions.lua
	REQ/j_settings_functions.lua
	REQ/j_string_functions.lua
	REQ/jKeyboard.lua
	REQ/mouse.lua
	REQ/fx-finder-settings-default.ini
--]]

local log = require("utils.log")
local format = require("utils.format")

local tbl = require("utils.table")

local sf = require("utils.j_string_functions")
local settings = require("utils.j_settings_functions")

require("gui2.JGui")

-- TODO: always open fzf at cursor/selection so that I don't need to move
-- my eyes.

-- TODO: remove this msg function -> replace all instances with `log.<level>`

function msg(m)
	return reaper.ShowConsoleMsg(tostring(m) .. "\n")
end

local fzf = {}

--
-- TODO: i think that these should be private vars attached to jGui.
-- 1. add these vars to the jGui class
-- 2. add a jGui method for resetting the vars
-- 3. pass the GUI ref to all callbacks, so that vars can be referenced further.
-- (4.) RATINGS only pertain to FX list.
--          this needs to be passed to the picker as an option cb..

fzf.reset_variables = function()
	UPDATE_RATINGS = false
	UPDATE_RESULTS = false
	SCROLL_RESULTS = 0
	RESULT_COUNT = 0
	NEW_PICKER_VIEW = false
end

--
-- TODO: jscroll should be moved inside the GUI class
--

function _jScroll(amount)
	SCROLL_RESULTS = SCROLL_RESULTS + amount
	local maxScroll = RESULT_COUNT - RESULTS_PER_PAGE
	if SCROLL_RESULTS > maxScroll then
		SCROLL_RESULTS = maxScroll
	end
	if SCROLL_RESULTS < 0 then
		SCROLL_RESULTS = 0
	end
	UPDATE_RESULTS = true
end

--
-- NOTE: picker gui initiations
--

jGuiHighlightControl = jGuiControl:new({ highlight = {}, color_highlight = { 1, 0.9, 0, 0.2 } })

function jGuiHighlightControl:_drawLabel()
	-- msg(self.label)

	gfx.setfont(1, self.label_font, self.label_fontsize)
	self:__setLabelXY()

	if self.highlight and #self.highlight > 0 then
		for _, word in pairs(self.highlight) do
			if word and word ~= "" then
				local parts, r = sf.jStringExplode(self.label, word, true)
				local totalX = 0
				if #parts > 1 then
					local highLightW, highLightH = gfx.measurestr(word)
					for i = 1, #parts - 1 do -- do all but the last
						local noLightW, noLightH = gfx.measurestr(parts[i])
						-- Draw highlight
						self:__setGfxColor(self.color_highlight)
						gfx.rect(gfx.x + totalX + noLightW, gfx.y, highLightW + 1, highLightH, 1)

						totalX = totalX + noLightW + highLightW
					end
					-- tablePrint(parts)
				end
			end
		end
	end

	self:_setStateColor()
	gfx.drawstr(tostring(self.label))
end

--
-- NOTE: this creates the `results` list buttons and populates the
-- `tResultButtons` table with them.
--

local function createResultButtons(gui, tControls, iResultsPerPage, y_start)
	local height = gui.gui_size
	local x_start = 10
	local y_space = 0
	local n_to_remove = 0

	log.user(string.format(
		[[[lib.fzf#createResultButtons()]: #tctrl=%s ires=%s ------
	-- NEW_PICKER_VIEW=%s
	-----------------------------------------------
	]],
		#tControls,
		iResultsPerPage,
		NEW_PICKER_VIEW
	))

	-- TODO: NEW_PICKER_VIEW_attached_mappings ??

	for i = 1, math.max(#tControls, iResultsPerPage) do
		if i > #tControls and i <= iResultsPerPage then
			log.user("entered buttons attach mappings")
			local ResultsEntryControl = jGuiHighlightControl:new({
				title = "results_entry_control",
				height = height,
				label_fontsize = height - 2,
				label_align = "l",
				label_font = "Courier",
				border = false,
				focus_index = i + 1, --gui:getFocusIndex()
				border_focus = true,
				x = x_start,
				y = y_start + (i - 1) * (height + y_space),
			})

			local ResultsEntryInfo = jGuiText:new({
				title = "results_entry_info",
				width = 40,
				height = height,
				label_fontsize = math.tointeger((height - 2) / 2 + 3),
				label_align = "r",
				label_valign = "m",
				border = false,
				y = ResultsEntryControl.y,
			})

			if gui.attach_mappings then
				log.user("CREATE RESULT BUTTONS -> attach mappings")
				function ResultsEntryControl:onKeyboard(key)
					-- gui.attach_mappings(gui, key, i + SCROLL_RESULTS)
					local s_key = tostring(key)
					local lookup_str = s_key:gsub("%.0$", "")
					local key_bind_function = GUI.attach_mappings[tostring(lookup_str)]
					if type(key_bind_function) == "function" then
						-- key_bind_function(gui, key, i + SCROLL_RESULTS)
						key_bind_function({
							gui_ref = gui,
							key = key,
							sel_idx = i + SCROLL_RESULTS,
						})
					end
				end
			end

			function ResultsEntryControl:onMouseClick()
				gui.on_select_func(gui, i + SCROLL_RESULTS)
				gui:setFocus(textBox)
				UPDATE_RESULTS = true

				if not gui.kb.shift() then
					-- this allows the picker to keep running for the next picker.
					-- if not gui.next_is_picker then
						self.parentGui:exit()
					-- end
				end
			end

			function ResultsEntryControl:onMouseWheel(mw) -- it looks like SCROLL_RESULTS can be a value between 0 and 1, should be a whole number?
				_jScroll(mw / 120 * -1)
			end

			function ResultsEntryControl:onArrowDown()
				return ResultsEntryControl:onTab()
			end

			function ResultsEntryControl:onArrowUp()
				return ResultsEntryControl:onShiftTab()
			end

			function ResultsEntryControl:onShiftTab()
				if i == 1 and SCROLL_RESULTS ~= 0 then
					_jScroll(-1)
					return false
				end
				return true -- else
			end

			function ResultsEntryControl:onTab()
				if i == #tControls then
					_jScroll(1)
					return false
				end
				return true -- else
			end

			gui:controlAdd(ResultsEntryControl)
			gui:controlAdd(ResultsEntryInfo)
			tControls[i] = { ResultsEntryControl, ResultsEntryInfo }

		-- ENDS: if i > #tControls and i <= iResultsPerPage then
		elseif i > iResultsPerPage then
			local b = tControls[i][1]
			local ResultsEntryInfo = tControls[i][2]
			gui:controlDelete(b)
			gui:controlDelete(ResultsEntryInfo)
			n_to_remove = n_to_remove + 1
		elseif NEW_PICKER_VIEW then
			local b = tControls[i][1]
			log.user(b.title)
			if gui.attach_mappings then
				-- log.user("CREATE RESULT BUTTONS -> attach mappings")
				function b:onKeyboard(key)
					-- gui.attach_mappings(gui, key, i + SCROLL_RESULTS)
					local s_key = tostring(key)
					local lookup_str = s_key:gsub("%.0$", "")
					local key_bind_function = GUI.attach_mappings[tostring(lookup_str)]
					if type(key_bind_function) == "function" then
						-- key_bind_function(gui, key, i + SCROLL_RESULTS)
						key_bind_function({
							gui_ref = gui,
							key = key,
							sel_idx = i + SCROLL_RESULTS,
						})
					end
				end
			end
		end

		if i <= #tControls and i <= iResultsPerPage then
			local b = tControls[i][1]
			local ResultsEntryInfo = tControls[i][2]
			b.width = gui.width - 20
			ResultsEntryInfo.x = 10 + b.width - ResultsEntryInfo.width
		end
	end

	for i = 1, n_to_remove do
		table.remove(tControls, #tControls)
	end

	if NEW_PICKER_VIEW then
		NEW_PICKER_VIEW = false
	end

	-- log.user("# tControls after creation:", #tControls)
end

local function gui_create_main_text_box(gui, on_enter)
	local text_input = jGuiTextInput:new({
		title = "main_input",
		x = 10,
		y = 10,
		width = 480,
		height = math.tointeger(gui.gui_size * 1.5),
		label_fontsize = math.tointeger(gui.gui_size * 1.5),
		label_align = "l",
		label_font = "Courier",
		focus_index = gui:getFocusIndex(),
		label_padding = 3,
	})

	log.user(gui.attach_mappings)

	if gui.attach_mappings then
		function text_input:onKeyboard(key)
			log.user("key = ", key)
			-- add custom bindings here.
			-- gui.attach_mappings(gui, key, 1)
			local s_key = tostring(key)
			local lookup_str = s_key:gsub("%.0$", "")
			local key_bind_function = GUI.attach_mappings[tostring(lookup_str)]
			if type(key_bind_function) == "function" then
				key_bind_function({
					gui_ref = gui,
					key = key,
					sel_idx = 1,
				})
			end
		end
	end

	function text_input:onEnter()
		-- FIX: n ext_is_picker dosen't make any sense anymore, remove this...
		-- --
		-- If `on_select_func` returns true, that should be interpreted as you
		-- are expecting the GUI to exit.

		if gui.on_select_func(gui, 1) then
			-- this allows the picker to keep running for the next picker.
			-- if not gui.next_is_picker then
				gui:exit()
			-- else
				-- log.user("controlDeleteAll")
			-- end
		end

		textBox.value = ""
	end

	textBox = text_input
	return textBox
end

local function create_control_label_stats(gui)
	local ls = jGuiControl:new({
		width = 50,
		x = gui.width - 11, --ls.width - 12,
		y = 10,
		label_fontsize = math.tointeger(gui.gui_size * 0.75),
		label_align = "r",
		border = false,
	})
	LABEL_STATS = ls
	return LABEL_STATS
end

--
-- NOTE: gui default funcs
--

local function gui_default_on_resize(self)
	log.user("GUI_DEFAULT_ON_RESIZE")
	textBox.width = self.width - 20
	LABEL_STATS.x = GUI.width - LABEL_STATS.width - 12
	local buttonsSpaceH = GUI.height - BUTTON_Y_START - 4

	-- NOTE: this is where the results list is created.
	-- Doesn't it make sense to add these types of option to the
	-- GUI object so that I can always access settings via the GUI
	-- name.

	RESULTS_PER_PAGE = math.tointeger(buttonsSpaceH // self.gui_size)

	-- msg(buttonsSpaceN)
	createResultButtons(GUI, tResultButtons, RESULTS_PER_PAGE, BUTTON_Y_START)
	UPDATE_RESULTS = true
	self:controlInitAll()
end

local function gui_default_update(self)
	if lastSearch ~= textBox.value then
		SCROLL_RESULTS = 0 -- reset scrollbar on search update
	end
	if lastSearch ~= textBox.value or UPDATE_RESULTS then
		-- search changed, update results
		UPDATE_RESULTS = false

		table.sort(self.t_results_data, self.sort_comp)

		if lastSearch ~= textBox.value then -- only search again when input changes, not on scroll
			--
			-- TODO: attach results_filter as a method on GUI inside init()
			-- so that I can call GUI.make_filter_results()
			--

			self.t_search_results = self.results_filter(self.t_results_data, textBox.value, self.max_results, false)

			log.user("#search_results", #self.t_search_results)

			lastSearch = textBox.value
		end
		RESULT_COUNT = #self.t_search_results

		--
		-- TODO: attach as method on GUI named `make_display_results`
		--

		self.entry_maker(tResultButtons, self.t_search_results)
	end
end

-- in gui_default_on_exit the SETTINGS_INI_FILe is referenced which
-- means that i have to handle these variables differently. outside
-- of the load plugins data func, and then pass them into the func.

local function gui_default_on_exit(self)
	-- log.user("GUI ON DEFAULT EXIT")

	if type(self.onExitUserCallback) == "function" then
		-- because func is not created inside jGui, i need to pass self..
		self.onExitUserCallback(self)
	end
	if self.window_save_state then
		local dockstate, wx, wy, ww, wh = gfx.dock(-1, 0, 0, 0, 0)
		local dockstr = string.format("%d", dockstate)

		-- TODO: is this a good location for this??..
		--
		-- maybe i should have custom save state for each picker by name/key?

		if self.env then
			settings.jSettingsWriteToFileMultiple(self.env.SETTINGS_INI_FILE, {
				{ "gui", "window_x", math.tointeger(wx) },
				{ "gui", "window_y", math.tointeger(wy) },
				{ "gui", "window_width", math.tointeger(ww) },
				{ "gui", "window_height", math.tointeger(wh) },
				{ "gui", "window_dock_state", dockstr },
			}, true)
		end
	end
end

-- RESOURCES:
--     reateam > amagalma_Toggle show editing guide line on item under mouse cursor in Main Window or in MIDI Editor.lua
--
local function get_xy_intersection()
	local windows = require("library.windows")
	local mtracks = require("library.tracks")
	local tl = require("library.timeline")

	local cursor_info = tl.get_cursor_info()

	local function get_active_window()
		reaper.JS_Window_GetFocus()

		-- MidiWindow = reaper.MIDIEditor_GetActive()
		-- midiview = MidiWindow and reaper.JS_Window_FindChildByID(MidiWindow, 0x3E9)
		-- 		reaper.JS_Window_GetClientSize(reaper.JS_Window_FindChildByID(reaper.GetMainHwnd(), 0x3E8))

		--     local cur_view = set_window == 0 and midiview or trackview
		-- local _, scrollposv = reaper.JS_Window_GetScrollInfo( cur_view, "v" )
		-- local _, scrollposh = reaper.JS_Window_GetScrollInfo( cur_view, "h" )
	end

	local active_window_type = get_active_window()

	if active_window_type == "midi" then
	-- note_row
	-- cursor
	elseif active_window_type == "main" then
		-- track
		local t_tr_dim = mtracks.get_dimensions_for(track)

		-- cursor
	end

	return x, y
end

--
-- NOTE: init picker funcs below
--

--
-- FIX: REQUIRED OPTS
--
--  ~ make results func
--  ~ sorting_func ??
--  ~ on_select func ??
--

local DEFAULT_OPTS = {
	-- max_results = 50,
	width = 500,
	height = 250,
	x = 400,
	y = 1400,
	window_save_state = true,
	window_dock_state = 0,
	gui_size = 20,
	meta = {},
	extended_mappings = nil,
	next = nil, -- next picker func should default to nil ie close prev picker.
	calling_command_meta = nil
}

-- TODO: update master title for every new picker view

local function build_picker(opts, on_enter)
	-- FIX: use these for x and y coordinates instead..
	local x, y = get_xy_intersection()

	-- reaper.ClearConsole()
	-- apply defaults if not given
	for k, v in pairs(DEFAULT_OPTS) do
		local use_default = "n"
		-- log.user("opts[k]", k, opts[k])
		if opts[k] == nil then
			opts[k] = v
			use_default = "y"
		end
		-- log.user(string.format("Option [%s] (%s): %s", k, use_default, opts[k]))
	end

	tResultButtons = {}

	opts.on_select_func = require("pickers.selectors.default")(opts.on_select_func)
	opts.results_filter = require("pickers.results_filter.default")(opts.results_filter)
	opts.sort_comp = require("pickers.sorters.default")(opts.sort_comp)
	opts.entry_maker = require("pickers.entry_makers.default")(opts.entry_maker)
	opts.attach_mappings = opts.attach_mappings and opts.attach_mappings or {}

	GUI = jGui:new(opts)

	if type(GUI.attach_mappings) == "function" then
		GUI.attach_mappings = GUI.attach_mappings(GUI)
	end

	if opts.extended_mappings then
		for k, v in pairs(opts.extended_mappings) do
			if k:match("^C%-") then
				local temp = "control_" .. k:sub(3, 3)
				local new_key = GUI.kb[temp]
				log.user("type v:", type(v))
				GUI.attach_mappings[tostring(new_key)] = v
			elseif k:match("^M%-") then
				local temp = "meta_" .. k:sub(3, 3)
				local new_key = GUI.kb[temp]
				GUI.attach_mappings[tostring(new_key)] = v
			end
		end
	end

	GUI.t_results_data = opts.results

	-- log.user("fzf build_picker() [" .. opts.title .. "]", #GUI.t_results_data)

	-- todo: if sort_comp = false, then don't sort, ie. don't use default sort comparator
	table.sort(GUI.t_results_data, GUI.sort_comp)

	GUI:controlAdd(gui_create_main_text_box(GUI, on_enter))

	GUI:controlAdd(create_control_label_stats(GUI))
	BUTTON_Y_START = GUI.gui_size * 1.5 + 15
	-- createResultButtons(GUI, tResultButtons, RESULTS_PER_PAGE, BUTTON_Y_START)
	GUI:setFocus(textBox)

	-- add methods
	GUI.onResize = gui_default_on_resize
	GUI.update = gui_default_update
	if type(opts.on_exit_callback) == "function" then
		GUI.onExitUserCallback = opts.on_exit_callback
	end
	GUI.onExit = gui_default_on_exit

	GUI:init()

	return true
end


--
-- TODO: refactor this into a method onto the jGui class
--

local function reset_new_picker(opts)
	for k, v in pairs(DEFAULT_OPTS) do
		GUI[k] = opts[k] and opts[k] or v
	end
	GUI.on_select_func = require("pickers.selectors.default")(opts.on_select_func)
	GUI.results_filter = require("pickers.results_filter.default")(opts.results_filter)
	GUI.sort_comp = require("pickers.sorters.default")(opts.sort_comp)
	GUI.entry_maker = require("pickers.entry_makers.default")(opts.entry_maker)
	GUI.attach_mappings = opts.attach_mappings and opts.attach_mappings(GUI) or {}
	-- GUI.attach_mappings = opts.attach_mappings and opts.attach_mappings(GUI) or nil
	-- ow
	-- log.user("#GUI.attach_mappings", format.block(GUI.attach_mappings))

	if opts.extended_mappings then
		-- log.user("add ext map")
		for k, v in pairs(opts.extended_mappings) do
			if k:match("^C%-") then
				local temp = "control_" .. k:sub(3, 3)
				local new_key = GUI.kb[temp]
				-- log.user("type v:", type(v))
				GUI.attach_mappings[tostring(new_key)] = v
			elseif k:match("^M%-") then
				local temp = "meta_" .. k:sub(3, 3)
				local new_key = GUI.kb[temp]
				GUI.attach_mappings[tostring(new_key)] = v
			end
		end
	end

	local _, main_input = tbl.findIndexOf(GUI.controls, "title", "main_input")

	-- resets
	main_input.value = ""
	GUI:setFocus(textBox)

	if GUI.attach_mappings then
		-- local _, main_input = tbl.findIndexOf(GUI.controls, "title", "main_input")
		if main_input then
			function main_input:onKeyboard(key)
				log.user("key =", key)
				local s_key = tostring(key)
				local lookup_str = s_key:gsub("%.0$", "")
				local key_bind_function = GUI.attach_mappings[tostring(lookup_str)]
				if type(key_bind_function) == "function" then
					key_bind_function({
						gui_ref = GUI,
						key = key,
						sel_idx = 1,
					})
				end
			end
		end
	end

	GUI.t_results_data = opts.results
	table.sort(GUI.t_results_data, GUI.sort_comp)
end

-----

local function loop()
	if GUI:loop() then
		reaper.defer(loop)
	else
		gfx.quit()
	end
end

fzf.init = function(opts, onenter)
	log.user(" ----- NEW PICKER VIEW:", opts.title, "-----")

	if GUI then
		NEW_PICKER_VIEW = true
		reset_new_picker(opts)
	else
		J_PROJECT_DATA = JProject:new()
		fzf.reset_variables()

		if build_picker(opts, onenter) then
			GUI:setReaperFocus()
			loop()
		end
	end
end

return fzf
