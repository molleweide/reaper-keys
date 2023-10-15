--[[
@description Fast FX Finder
@author n0ne
@about
	# Fast VST/FX Rack/Template Finder

	-- TODO: move all picker variables to GUI
	--
	-- TODO: start using pluginsData

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

local script_path = debug.getinfo(1, "S").source:match([[^@?(.*[\/])[^\/]-$]])
package.path = package.path .. ";" .. script_path .. "?.lua"

require("REQ.j_file_functions")
require("REQ.j_tables")
require("REQ.jGui")
require("REQ.j_trackstatechunk_functions")
require("REQ.j_settings_functions")

-- SOME SETUP
-- local SETTINGS_BASE_FOLDER = script_path

-- -- move this to definitions dir
-- local SETTINGS_INI_FILE = script_path .. "fx-finder-settings.ini"
-- local SETTINGS_DEFAULT_FILE = script_path .. "REQ/fx-finder-settings-default.ini"

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
--
-- GUI

fzf.reset_variables = function()
	UPDATE_RATINGS = false
	UPDATE_RESULTS = false
	SCROLL_RESULTS = 0
	RESULT_COUNT = 0
end


jGuiHighlightControl = jGuiControl:new({ highlight = {}, color_highlight = { 1, 0.9, 0, 0.2 } })

function jGuiHighlightControl:_drawLabel()
	-- msg(self.label)

	gfx.setfont(1, self.label_font, self.label_fontsize)
	self:__setLabelXY()

	if self.highlight and #self.highlight > 0 then
		for _, word in pairs(self.highlight) do
			if word and word ~= "" then
				local parts, r = jStringExplode(self.label, word, true)
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

-- TODO: jscroll should be moved inside the GUI class

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
-- NOTE: this creates the `results` list buttons and populates the
-- `tResultButtons` table with them.
--

local function createResultButtons(gui, tControls, n, y_start)
	local height = gui.gui_size
	local x_start = 10
	local y_space = 0
	local n_to_remove = 0

	for i = 1, math.max(#tControls, n) do
		if i > #tControls and i <= n then
			local c = jGuiHighlightControl:new()
			c.height = height
			c.label_fontsize = height - 2
			c.label_align = "l"
			c.label_font = "Calibri"
			c.border = false
			c.focus_index = i + 1 --gui:getFocusIndex()
			c.border_focus = true

			c.x = x_start
			c.y = y_start + (i - 1) * (c.height + y_space)

			local info = jGuiText:new()
			info.width = 40
			info.height = height
			info.label_fontsize = math.tointeger((height - 2) / 2 + 3)
			c.label_font = "Calibri"
			info.label_align = "r"
			info.label_valign = "m"
			info.border = false
			info.y = c.y

			function c:onMouseClick()
				gui.on_select_func(gui, i + SCROLL_RESULTS)

				-- selectFx(i + SCROLL_RESULTS)

				gui:setFocus(textBox)
				UPDATE_RESULTS = true
				if not gui.kb.shift() then
					self.parentGui:exit()
				end
			end

			function c:onMouseWheel(mw) -- it looks like SCROLL_RESULTS can be a value between 0 and 1, should be a whole number?
				_jScroll(mw / 120 * -1)
			end

			function c:onArrowDown()
				return c:onTab()
			end

			function c:onArrowUp()
				return c:onShiftTab()
			end

			function c:onShiftTab()
				if i == 1 and SCROLL_RESULTS ~= 0 then
					_jScroll(-1)
					return false
				end
				return true -- else
			end

			function c:onTab()
				if i == #tControls then
					_jScroll(1)
					return false
				end
				return true -- else
			end

			gui:controlAdd(c)
			gui:controlAdd(info)
			tControls[i] = { c, info }
		elseif i > n then
			local b = tControls[i][1]
			local info = tControls[i][2]
			gui:controlDelete(b)
			gui:controlDelete(info)
			n_to_remove = n_to_remove + 1
		end

		if i <= #tControls and i <= n then
			local b = tControls[i][1]
			local info = tControls[i][2]

			b.width = gui.width - 20
			info.x = 10 + b.width - info.width
		end
	end

	for i = 1, n_to_remove do
		table.remove(tControls, #tControls)
	end
end

local function gui_create_main_text_box(gui, on_enter)
	local text_input = jGuiTextInput:new()
	text_input.x = 10
	text_input.y = 10
	text_input.width = 480
	text_input.height = math.tointeger(gui.gui_size * 1.5)
	text_input.label_fontsize = math.tointeger(gui.gui_size * 1.5)
	text_input.label_align = "l"
	text_input.label_font = "Calibri"
	text_input.focus_index = gui:getFocusIndex()
	text_input.label_padding = 3

	function text_input:onEnter()
		-- NOTE: this is where an FX is selected and applied to a track

		if gui.on_select_func(gui, 1) then
			gui:exit()
		end
		textBox.value = ""
	end

	textBox = text_input
	return textBox
end

local function create_control_label_stats(gui)
	local ls = jGuiControl:new()
	ls.width = 50
	ls.x = gui.width - ls.width - 12
	ls.y = 10
	ls.label_fontsize = math.tointeger(gui.gui_size * 0.75)
	ls.label_align = "r"
	ls.border = false
	LABEL_STATS = ls
	return LABEL_STATS
end

--
-- NOTE: gui default funcs
--

local function gui_default_on_resize(self)
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

			self.t_search_results =
				self.results_filter(self.t_results_data, textBox.value, false, self.max_results)

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
	if type(self.onExitUserCallback) == "function" then
		-- because func is not created inside jGui, i need to pass self..
		self.onExitUserCallback(self)
	end
	if self.window_save_state then
		local dockstate, wx, wy, ww, wh = gfx.dock(-1, 0, 0, 0, 0)
		local dockstr = string.format("%d", dockstate)
		jSettingsWriteToFileMultiple(self.env.SETTINGS_INI_FILE, {
			{ "gui", "window_x", math.tointeger(wx) },
			{ "gui", "window_y", math.tointeger(wy) },
			{ "gui", "window_width", math.tointeger(ww) },
			{ "gui", "window_height", math.tointeger(wh) },
			{ "gui", "window_dock_state", dockstr },
		}, true)
	end
end

--
-- FIX: REQUIRED OPTS
--
--  ~ make results func
--  ~ sorting_func ??
--  ~ on_select func ??
--

function fzf.init(opts, on_enter)
	-- reaper.ClearConsole()
	local DEFAULT_OPTS = {
		max_results = 50,
		width = 500,
		height = 250,
		x = 100,
		y = 100,
		window_save_state = true,
		window_dock_state = 0,
		gui_size = 20,
	}

	-- apply defaults if not given
	for k, v in pairs(DEFAULT_OPTS) do
		local use_default = "n"
		-- log.user("opts[k]", k, opts[k])
		if opts[k] == nil then
			opts[k] = v
			use_default = "y"
		end
		log.user(string.format("Option [%s] (%s): %s", k, use_default, opts[k]))
	end

	tResultButtons = {}

	GUI = jGui:new(opts)

	-- needs to be attached to GUI somehow, so that I can access them inside
	-- of eg. on_select_func
	GUI.t_results_data = opts.results

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

function loop()
	if GUI:loop() then
		reaper.defer(loop)
	else
		gfx.quit()
	end
end

return fzf
