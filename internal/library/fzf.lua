local log = require("utils.log")
local format = require("utils.format")
local tbl = require("utils.table")
local fu = require("utils.fzf")
local su = require("utils.string")
local sf = require("utils.j_string_functions")
local settings = require("utils.j_settings_functions")
require("gui2.JGui")

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-- TODO: move all picker variables to GUI

-- TODO: start using pluginsData ???

-- TODO: Show prev picker in left upper corner if there is a previous picker,

-- HACK: Add a default keybind that shows the help menu legend overlayed across
-- screen so that one can easilly study/view help files and mappings.
-- ~ toggle
-- ~ show new GFX window
-- ~ loop binds and print grid

-- TEST: PICKER PROMPT UPDATE VALUE
-- -> Say, eg. that I am using the track manager menu and I want to update
-- the name of select(ed) tracks, then I will fire up a new prompt, and upon
-- exiting this renaming-prompt, I will be brought back to the main track
-- manager.

-- TODO: keybinding -> store current value as default for selected param
-- in the `plugins/<plugin_x>.lua` file.

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-- ALL OF THE BELOW SHOULD GO INTO THE SAME CONFIG TABLE
-- -> PUT UNDER DEFINITIONS

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

    -- fix: (deprecated) This option has to be removed because now that the picker is
    -- general purpose, this means that we cannot expect a `saved` state to
    -- make sense.
    -- window_save_state = true,

    window_dock_state = 0,
    -- Think of this as the line height of the picker. Increasing this option
    -- increases the size of all elements in the picker UI.
    gui_size = 20,
    -- Elem separation in Y direction
    gui_spread = 5,
    meta = {},
    extended_mappings = nil,
    next = nil, -- next picker func should default to nil ie close prev picker.
    calling_command_meta = nil,
    column_legend_enabled = false,
}

-- All of these types of symbols etc. should go into a picker default config
-- file under definitions.

local picker_config = {
    -- This var is redundant since `GUI.gui_size` determines the "line height".
    column_legend_height = 50,
    symbols = {
        entry_selected = "x",
        entry_separator = "|",
    },
}

-- Remove this msg function...
-- function msg(m)
-- 	return reaper.ShowConsoleMsg(tostring(m) .. "\n")
-- end

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
-- TODO: There should be a Picker class, and the _jscroll func should be a method
-- on this class.
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

---Creates the actual button controls responsible for hosting/rendering the
---data for result entries if there are any. It is called once when
---initializing the picker and then for every default resize update call.
---IE. the number of button controls depends on the size of the picker window,
---and NOT on the number of result entries (entries returned after filtering).
---@param gui any
---@param tControls any
---@param iResultsPerPage any
---@param y_start any
local function createResultButtons(gui, tControls, iResultsPerPage, y_start)
    local height = gui.gui_size
    local x_start = MID_LEFT + 10
    local y_space = GUI.gui_spread
    local n_to_remove = 0

    log.user(string.format(
        [[[lib.fzf#createResultButtons()]:
            #tControls=%s
            iResultsPerPage=%s
            ------
	-- NEW_PICKER_VIEW=%s
	-----------------------------------------------
	]],
        #tControls,
        iResultsPerPage,
        NEW_PICKER_VIEW
    ))

    -- TODO: NEW_PICKER_VIEW_attached_mappings ??

    -- Loop the largest of actual controls and number of current results.
    for i = 1, math.max(#tControls, iResultsPerPage) do
        if i > #tControls and i <= iResultsPerPage then
            -- log.user("entered buttons attach mappings")
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
                -- log.user("CREATE RESULT BUTTONS -> attach mappings")
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
                local last_idx = i + SCROLL_RESULTS
                gui:set_last_selection_idx(last_idx)
                local should_exit = gui.on_select_func(gui, last_idx)
                gui:setFocus(textBox)
                UPDATE_RESULTS = true

                if should_exit and not gui.kb.shift() then
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
            -- elseif NEW_PICKER_VIEW then
            --     local b = tControls[i][1]
            --     -- log.user(b.title)
            --     if gui.attach_mappings then
            --         -- log.user("CREATE RESULT BUTTONS -> attach mappings")
            --         function b:onKeyboard(key)
            --             -- gui.attach_mappings(gui, key, i + SCROLL_RESULTS)
            --             local s_key = tostring(key)
            --             local lookup_str = s_key:gsub("%.0$", "")
            --             local key_bind_function = GUI.attach_mappings[tostring(lookup_str)]
            --             if type(key_bind_function) == "function" then
            --                 -- key_bind_function(gui, key, i + SCROLL_RESULTS)
            --                 key_bind_function({
            --                     gui_ref = gui,
            --                     key = key,
            --                     sel_idx = i + SCROLL_RESULTS,
            --                 })
            --             end
            --         end
            --     end
        end

        if i <= #tControls and i <= iResultsPerPage then
            local b = tControls[i][1]
            local ResultsEntryInfo = tControls[i][2]
            b.width = WIDTH_MID - 20
            -- b.width = gui.width - 20
            ResultsEntryInfo.x = 10 + b.width - ResultsEntryInfo.width
        end
    end

    -- TEST: Can i remove this??
    -- Is this even doing anything??
    for i = 1, n_to_remove do
        table.remove(tControls, #tControls)
    end

    -- if NEW_PICKER_VIEW then
    --     NEW_PICKER_VIEW = false
    -- end

    -- log.user("# tControls after creation:", #tControls)
end

---Create the main text input field for the picker
---@param gui any
---@param on_enter any
---@return unknown
local function gui_create_main_text_box(gui, on_enter)
    local x_start = MID_LEFT
    local text_input = jGuiTextInput:new({
        title = "main_input",
        x = x_start + 10,
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

            local selected_element = gui:get_on_enter_selection()

            -- event on each key press updaters
            if gui.context_helpers then
                for _, xh in ipairs(gui.context_helpers.all) do
                    if type(xh.func) == "function" and xh.on_key_press then
                        local elem = gui.context_helpers.elements[xh.position]
                        xh.func(gui, textBox.value, elem)
                    end
                end

                -- if #gui.context_helpers.on_focus_change > 0 then
                --     for _, v in ipairs(gui.context_helpers.on_focus_change) do
                --         if type(v.func) == "function" then
                --             v.func(gui, lastSearch, selected_element)
                --         end
                --     end
                -- end
            end

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
        gui:set_last_selection_idx(1)

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

-- TODO: types here.

---Creates the (selected/outOfTotalEntries) UI element so that user can keep
---track of how many entries are showing at the moment.
---@param gui any
---@return unknown
local function create_control_label_stats(gui)
    -- local x_start = MID_LEFT

    local ls = jGuiControl:new({
        width = 50,
        x = MID_RIGHT - 11, -- gui.width - 11, --ls.width - 12,
        y = 10,
        label_fontsize = math.tointeger(gui.gui_size * 0.75),
        label_align = "r",
        border = false,
    })
    LABEL_STATS = ls
    return LABEL_STATS
end

---Create the column legend positionned above the results entries and below the
---user input field.
---@param gui any
local function create_column_legend(gui)
    local x_start = MID_LEFT + 10
    local y_space = GUI.gui_spread
    local height = gui.gui_size
    local width = WIDTH_MID - x_start * 2

    local accomodate_for_main_input = GUI.gui_size * 1.5
    local extra = 15

    ---------------------------------
    -- I can replace all this code with the same pattern used in entry maker
    -- wrapper.
    local label_str = ""

    local function add(s)
        label_str = label_str .. s
    end

    local function gutter(first)
        if first == 1 then
            add("| ")
        elseif first == 2 then
            add(" |")
        else
            add(" | ")
        end
    end

    gutter(1)
    gutter(1)

    for i, v in ipairs(gui.columns_legend) do
        add(su.makeStringLength(v[2], v[1]))
        gutter()
    end

    ---------------------------------

    -- local ResultsEntryControl = jGuiHighlightControl:new({
    --     title = "results_entry_control",
    --     height = height,
    --     label_fontsize = height - 2,
    --     label_align = "l",
    --     label_font = "Courier",
    --     border = false,
    --     focus_index = i + 1, --gui:getFocusIndex()
    --     border_focus = true,
    --     x = x_start,
    --     y = y_start + (i - 1) * (height + y_space),
    -- })

    -- create legend
    local ColumnLegend = jGuiText:new({
        title = "picker_column_legend",
        width = width,
        height = height,
        label_fontsize = height - 2,
        label_font = "Courier",
        -- label_fontsize = math.tointeger((height - 2) / 2 + 3),
        label = label_str,
        label_align = "l",
        label_valign = "m",
        border = true,
        -- y = ResultsEntryControl.y,
        x = x_start,
        y = accomodate_for_main_input + extra, --y_start + (i - 1) * (height + y_space),
    })

    -- TODO: gui:

    return ColumnLegend
end

---comment
---@param self any
local function gui_default_on_resize(self)
    log.user("GUI_DEFAULT_ON_RESIZE", "button y start ==", BUTTON_Y_START, "self = type,real ->", GUI.title)
    textBox.width = WIDTH_MID - 20
    LABEL_STATS.x = WIDTH_MID - LABEL_STATS.width - 12
    local buttonsSpaceH = self.height - BUTTON_Y_START - 4

    -- NOTE: this is where the results list is created.
    -- Doesn't it make sense to add these types of option to the
    -- GUI object so that I can always access settings via the GUI
    -- name.

    RESULTS_PER_PAGE = math.tointeger(buttonsSpaceH // self.gui_size)

    -- msg(buttonsSpaceN)
    createResultButtons(self, tResultButtons, RESULTS_PER_PAGE, BUTTON_Y_START)
    UPDATE_RESULTS = true
    self:controlInitAll()
end

---Handler of rendering each picker entry. This function takes care of applying
---or overriding defaults, and then applies custom displays.
---@param tButtons any: table of control buttons
---@param gui any: The picker gui object itself, which hosts the search results table.
local function entry_maker_refact_wrapper(tButtons, gui)
    local tResults = gui.t_search_results
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

        -- why is label stats here??
        LABEL_STATS.label = "(" .. showing .. "/" .. #tResults .. ")"

        if tResults and iStart <= #tResults then
            local item = tResults[iStart]
            local label_str = ""
            local t_entry_makers_parts = type(gui.entry_maker) == "function" and gui.entry_maker(item)
                or gui.entry_maker
            local columns = {}
            for ei, entry_def in ipairs(t_entry_makers_parts) do
                local entry_width
                local str_part
                if type(entry_def) == "table" then
                    str_part = entry_def[1]
                    entry_width = entry_def[2]
                else
                    str_part = entry_def
                    entry_width = 25 -- base fallback
                end
                if GUI.columns_legend then
                    entry_width = GUI.columns_legend[ei][1]
                end
                columns[ei] = su.makeStringLength(tostring(str_part), entry_width)
            end
            label_str = label_str .. "| " .. table.concat(columns, " | ") .. " |"

            if gui.mult_select_allowed then
                local is_selected = item.selected and picker_config.symbols.entry_selected or " "
                label_str = "|" .. is_selected .. label_str
            end

            b.label = label_str
            b.visible = true
            info.visible = true
            b.highlight = highlights
        else
            b.visible = false
            info.visible = false
        end
    end
end

---Function for handling GUI updating. Called on every loop UI loop iteration
---but only applies an update if checks are passed.
---@param self any
local function gui_default_update(self)
    log.debug("fzf.gui_default_update -> A. entered", UPDATE_RESULTS, NEW_PICKER_VIEW)

    if lastSearch ~= textBox.value then
        SCROLL_RESULTS = 0 -- reset scrollbar on search update
    end
    if lastSearch ~= textBox.value or UPDATE_RESULTS or NEW_PICKER_VIEW then
        -- search changed, update results
        UPDATE_RESULTS = false

        table.sort(self.t_results_data, self.sort_comp)

        log.debug(
            string.format(
                "fzf.gui_default_update -> BB. RES=%s, NEW=%s, lastSearch=[%s] | textBox.value=[%s]",
                UPDATE_RESULTS,
                NEW_PICKER_VIEW,
                lastSearch,
                textBox.value
            )
        )

        if lastSearch ~= textBox.value or NEW_PICKER_VIEW then -- only search again when input changes, not on scroll
            NEW_PICKER_VIEW = false

            -- TODO: attach results_filter as a method on GUI inside init()
            -- so that I can call GUI.make_filter_results()
            self.t_search_results = self.results_filter(self.t_results_data, textBox.value, self.max_results, false)

            log.debug("fzf.gui_default_update -> CCC. #search_results", #self.t_search_results)

            lastSearch = textBox.value

            -- if #self.context_helpers.on_focus_change > 0 then
            if self.context_helpers then
                for _, v in ipairs(self.context_helpers.all) do
                    local on_enter_sel = self:get_on_enter_selection()
                    if type(v.func) == "function" and v.on_focus_change and on_enter_sel ~= nil then
                        v.func(self, lastSearch, on_enter_sel)
                    end
                end
            end
            -- end
        end
        RESULT_COUNT = #self.t_search_results

        --
        -- TODO: migrate to new entry_maker_refact_wrapper
        --

        entry_maker_refact_wrapper(tResultButtons, self)
        -- self.entry_maker(tResultButtons, self.t_search_results)
    end
end

-- in gui_default_on_exit the SETTINGS_INI_FILe is referenced which
-- means that i have to handle these variables differently. outside
-- of the load plugins data func, and then pass them into the func.

---Logic called upon exiting the picker. If picker has a custom exit callback it will be
---ran here.
---@param self any
local function gui_default_on_exit(self)
    -- log.user("GUI ON DEFAULT EXIT")

    if type(self.onExitUserCallback) == "function" then
        -- because func is not created inside jGui, i need to pass self..
        self.onExitUserCallback(self)
    end

    -- FIX: this should be moved to the picker definition for `add_fx`
    -- NOTE: What happens: if save state -> write names to picker settings file.
    -- if self.window_save_state then
    --     local dockstate, wx, wy, ww, wh = gfx.dock(-1, 0, 0, 0, 0)
    --     local dockstr = string.format("%d", dockstate)
    --     if self.env then
    --         settings.jSettingsWriteToFileMultiple(self.env.SETTINGS_INI_FILE, {
    --             { "gui", "window_x", math.tointeger(wx) },
    --             { "gui", "window_y", math.tointeger(wy) },
    --             { "gui", "window_width", math.tointeger(ww) },
    --             { "gui", "window_height", math.tointeger(wh) },
    --             { "gui", "window_dock_state", dockstr },
    --         }, true)
    --     end
    -- end
end

local function render_context_helper(gui)
    -- CONTEXT_HELPERS =
end

local function setup_context_helpers(gui, configs)
    gui.context_helpers = {
        all = {},
        on_key_press = {},
        on_focus_change = {},
        on_static = {},
    }

    for _, cfg in ipairs(configs) do
        table.insert(gui.context_helpers.all, cfg)
    end

    -- for _, cfg in ipairs(configs) do
    --     -- log.user("?>>>",format.block(cfg))
    --     if cfg.on_key_press then
    --         table.insert(gui.context_helpers.on_key_press, cfg)
    --     end
    --     if cfg.on_focus_change then
    --         table.insert(gui.context_helpers.on_focus_change, cfg)
    --     end
    --     if cfg.on_static then
    --         table.insert(gui.context_helpers.on_static, cfg)
    --     end
    -- end
end

local function render_context_helpers(gui)
    gui.context_helpers.elements = {}

    -- gui.context_helpers = {
    --     all = {},
    -- }

    -- Create text field for each xh table.
    --
    -- The update functions have to target the correct textfields.
    --
    -- Attach context helper UI Elements Windows by a specific key in `gui.context_helpers.elements = {<key>}`
    -- I could:
    -- 1. Attach the updater functions in a table by the key of the id by which
    -- the UI elements are stored in jGui, ie.
    -- gui.context_helpers.elements = {key = elem}
    -- gui.context_helpers.observers = {key = func}
    --
    -- The same key has to be used -> So that I can super quickly iterate over
    -- and update stuff without having to incur multiple ipair loops for each
    -- key press. only one single pairs() over like max 10 elems
    --
    -- They key to use is the positioning arg of each context window.
    --
    --
    -- !!! The fuzzy picker ui controls are added with :controlAdd but these
    -- new context windows dont need to be written in that manner.

    local font_size = gui.gui_size * 1.1 / 2 -- 2

    for _, xh in ipairs(gui.context_helpers.all) do
        log.user(format.block(xh))

        local x_start
        local y_start = 10
        local width = xh.width
        local height = gui.height

        if xh.position == "left" then
            x_start = EDGE_LEFT
        end

        if xh.position == "right" then
            x_start = MID_RIGHT
            -- height = 100
        end

        local ctxh = jGuiText:new({
            title = "ctxh_" .. xh.position,
            width = width - 2 * 10,
            height = height - 2 * 10,
            x = x_start + 10,
            y = y_start,
            label_fontsize = font_size,
            label_align = "l",
            label_valign = "m",
            border = true,
        })

        gui:controlAdd(ctxh)
        gui.context_helpers.elements[xh.position] = ctxh
    end

    -- TODO: modify this and see if i can make a larger text field with a custom
    -- color background.

    -- TODO: gui:controlAdd(column)
end

-- TODO: first level -> One row AND three columns, (ie. Left, Main prompt, Right)

-- all of the vars will be contained within gui, so it feels like this should be
-- a method on the jGui class insead.
--
---Compute the layout grid variables for current picker configuration. So that
---can then render child views within this layout.
---@param gui any
local function reset_layout_vars(gui)
    -- What if a user supplies two windows with position = "left"??

    -- ! The middle width, ie. the prompt window, is the width/height params supplied
    -- in the picker opts.

    gui.layout_grid = { { 0, 0, gui.width, gui.width } }

    -- NOTE: Because I dont have all in one big table it makes it super
    -- annoying to do this shit

    if gui.context_helpers then
        for i, v in ipairs(gui.context_helpers.all) do
            if v.position == "left" then
                for ir, row in ipairs(gui.layout_grid) do
                    -- for ic, col in ipairs(row) do
                    --     row[ic] = col + v.width
                    -- end
                    row[2] = v.width
                    row[3] = row[2] + row[3]
                end
            end

            -- for ir, row in ipairs(gui.layout_grid) do
            --     if v.position == "left" then
            --         for ic, col in ipairs(row) do
            --             row[ic] = col + v.width
            --         end
            --     end
            --     table.insert(row, 1, 0)
            -- end

            -- for ir, row in ipairs(gui.layout_grid) do
            --     table.insert(row, 1, 0)
            -- end

            if v.position == "right" then
                for ir, row in ipairs(gui.layout_grid) do
                    -- table.insert(row, row[#row] + v.width)
                    row[4] = row[3] + v.width
                end
            end
        end
    end

    EDGE_LEFT = gui.layout_grid[1][1]
    MID_LEFT = gui.layout_grid[1][2]
    MID_RIGHT = gui.layout_grid[1][3]
    EDGE_RIGHT = gui.layout_grid[1][4]

    WIDTH_MID = MID_RIGHT - MID_LEFT
    WIDTH_TOTAL = EDGE_RIGHT
end

-- RESOURCES:
--     reateam > amagalma_Toggle show editing guide line on item under mouse cursor in Main Window or in MIDI Editor.lua
--
-- NOTE: This function is general purpose and should go into another module.
--
---Find XY coordinates of cursor. The purpose is to add the feature of having the
---picker always initiate at position where cursor is/user keeps her eyes.
---Since we are not using the mouse-pointer we need to compute the x y coordinates
---from the location where you are working instead - try looking at whatever
---row and col we are at in the window that is focused and then get the XY
---coordinates from this point.
---@return unknown
local function get_xy_intersection()
    local windows = require("library.windows")
    local mtracks = require("library.tracks")
    local tl = require("library.timeline")

    -- TODO: This snippet computes the screen dimensions
    --
    -- This snippet teaches about how to get the proper XY coordinates.
    local retval, left, top, right, bottom = reaper.JS_Window_GetClientRect(reaper.GetMainHwnd())
    local monitor_left, monitor_top, monitor_right, monitor_bottom =
        reaper.my_getViewport(0, 0, 0, 0, left, top, right, bottom, false)
    local width = monitor_right - monitor_left
    log.user(monitor_left, monitor_top, monitor_right, monitor_bottom, width)
    -------------------------------------------------------

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

-- TODO: merge build AND reset into one function
--
---Build picker UI on first initialization. Currently subsequent chained pickers
---are loaded/reset with the `reset_new_picker()` function.
---@param opts any
---@param on_enter any
---@return boolean
local function build_picker(opts, on_enter)
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

    -- This one should be attached to the jGui object itself.
    -- Or actually the Picker class object but I haven't impl that yet.
    tResultButtons = {}

    opts.on_select_func = require("pickers.selectors.default")(opts.on_select_func)
    opts.results_filter = require("pickers.results_filter.default")(opts.results_filter)
    opts.sort_comp = require("pickers.sorters.default")(opts.sort_comp)
    opts.entry_maker = require("pickers.entry_makers.default")(opts.entry_maker)
    opts.attach_mappings = opts.attach_mappings and opts.attach_mappings or {}

    GUI = jGui:new(opts)

    -- I have to make sure that opts.context_helpers is not written to the Picker
    -- gui object so that there becomes a clash...
    if opts.context_helpers then
        setup_context_helpers(GUI, opts.context_helpers)
    end
    -- log.user("CTXH ->", format.block(GUI.context_helpers))

    -- layout vars can only be computed after context helpers check
    reset_layout_vars(GUI)

    log.user("PICKER LAYOUT: \n", format.block(GUI.layout_grid), "\ntotal width =", WIDTH_TOTAL)
    GUI.width = WIDTH_TOTAL

    if type(GUI.attach_mappings) == "function" then
        GUI.attach_mappings = GUI.attach_mappings(GUI)
    end

    if opts.extended_mappings then
        for k, v in pairs(opts.extended_mappings) do
            if k:match("^C%-") then
                local temp = "control_" .. k:sub(3, 3)
                local new_key = GUI.kb[temp]
                --             log.user(string.format(
                --                 [[ extended mappings:
                -- type v: %s
                -- temp: %s
                -- new_key: %s
                --   ]],
                --                 type(v),
                --                 temp,
                --                 new_key
                --             ))
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

    -- why is this commented out here??????
    -- createResultButtons(GUI, tResultButtons, RESULTS_PER_PAGE, BUTTON_Y_START)

    GUI:setFocus(textBox)

    if GUI.column_legend_enabled then
        -- todo
        GUI:controlAdd(create_column_legend(GUI))
    end

    -- Determines where the positioning of the Result Buttons should start on the
    -- Y axis.

    PICKER_COLUMN_LEGEND_HEIGHT = GUI.column_legend_enabled and GUI.gui_size or 0

    local accomodate_for_main_input = GUI.gui_size * 1.5
    local extra = 15
    BUTTON_Y_START = accomodate_for_main_input + extra + PICKER_COLUMN_LEGEND_HEIGHT + GUI.gui_spread

    -- create context helpers
    if opts.context_helpers then
        render_context_helpers(GUI)
    end

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
-- FIX: refactor this into a method onto the jGui class
--

---Chain reset a picker view onto an already existing / running picker.
---@param opts any
local function reset_new_picker(opts)
    GUI:reset_current_selection()

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

    -- clean up
    if GUI.context_helpers then
        GUI.context_helpers = nil
    end
    if opts.context_helpers then
        setup_context_helpers(GUI, opts.context_helpers)
    end

    log.user("CTXH ->", format.block(GUI.context_helpers))

    -- after context helpers have been reset, now we can update the layout variables.
    reset_layout_vars(GUI)
    log.user("PICKER LAYOUT: \n", format.block(GUI.layout_grid))

    -- TODO: refactor into func.
    -- This logic shifts the button positions to accomodate for if the new
    -- picker view has a column legend or not.
    PICKER_COLUMN_LEGEND_HEIGHT = GUI.column_legend_enabled and GUI.gui_size or 0
    local BUTTON_Y_START_PREV = BUTTON_Y_START
    BUTTON_Y_START = GUI.gui_size * 1.5 + 15 + PICKER_COLUMN_LEGEND_HEIGHT + GUI.gui_spread
    local button_y_diff = BUTTON_Y_START - BUTTON_Y_START_PREV
    if button_y_diff ~= 0 then
        if button_y_diff < 0 then
            local _, legend = tbl.findIndexOf(GUI.controls, "title", "picker_column_legend")
            GUI:controlDelete(legend)
        else
            GUI:controlAdd(create_column_legend(GUI))
        end
        for _, v in ipairs(tResultButtons) do
            v[1].y = v[1].y + button_y_diff
        end
    end

    GUI.on_focus_next = opts.on_focus_next

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

    GUI:setTitle(opts.title)

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

                        -- FIX: use self.lastChar instead...
                        key = key,

                        -- FIX: assign this to jGui instead, so that this can be accessed
                        -- by gui:current_sel_idx
                        sel_idx = 1,
                    })
                end
            end
        end
    end

    GUI.t_results_data = opts.results
    table.sort(GUI.t_results_data, GUI.sort_comp)

    -- UPDATE_RESULTS = true

    -- GUI:refresh()
    -- GUI:refresh()
end

-----

---Function for handling the UI main loop.
local function loop()
    if GUI:loop() then
        reaper.defer(loop)
    else
        gfx.quit()
    end
end

---Entry point for initializing a new picker UI window.
---@param opts any
---@param onenter any
fzf.init = function(opts, onenter)
    log.debug(" ----- fzf.init()", opts.title, "-----")

    if GUI then
        NEW_PICKER_VIEW = true
        reset_new_picker(opts)
    -- fzf.reset_variables()
    -- log.user("post reset variables")
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
