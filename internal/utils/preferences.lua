local log = require("utils.log")
local format = require("utils.format")
local su = require("utils.string")

-- TODO:
-- 1. Move Config file to its own file
-- 2. MOve bitwise operators to util
-- 3. Move preferences to library???

-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------

-- Use this to find how many levels there are to a bitmask.
local function count_ones(bitmask)
    local count = 0
    while bitmask ~= 0 do
        count = count + (bitmask & 1)
        bitmask = bitmask >> 1
    end
    return count
end

local function find_lsb_position(bitfield)
    local position = 0
    while bitfield > 0 do
        if bitfield & 1 == 1 then
            return position
        end
        bitfield = bitfield >> 1
        position = position + 1
    end
    -- Handle case where bitfield is 0 (no bits set)
    return nil
end

-- Function to get indices where bits are set to 1 in a bitfield
local function get_set_indices(bitfield)
    local indices = {}
    local position = 0

    while bitfield > 0 do
        if bitfield % 2 == 1 then
            table.insert(indices, position)
        end
        bitfield = bitfield >> 1
        position = position + 1
    end

    return indices
end

local function set_variable_value(bitfield, variable_positions, new_value)
    -- Ensure variable_positions are within range and valid
    for _, position in ipairs(variable_positions) do
        if position < 0 or position >= 32 then
            error("Variable position must be between 0 and 31")
        end
    end

    -- Calculate the number of bits needed for the variable based on positions
    local num_bits = #variable_positions

    -- Clear the bits at variable_positions in bitfield
    for _, position in ipairs(variable_positions) do
        bitfield = bitfield & ~(1 << position)
    end

    -- Set the bits at variable_positions according to new_value
    for idx, position in ipairs(variable_positions) do
        local bit_value = (new_value >> (idx - 1)) & 1
        bitfield = bitfield | (bit_value << position)
    end

    return bitfield
end

-- Function to get the variable value from a bitmask based on combined positions
local function get_variable_value(bitfield, variable_positions)
    local value = 0

    -- Iterate over each position in variable_positions
    for idx, position in ipairs(variable_positions) do
        -- Extract the bit value at each position
        local bit_value = (bitfield >> position) & 1

        -- Construct the value by shifting and ORing the bit_value
        value = value | (bit_value << (idx - 1))
    end

    return value
end
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------

--- Helper class making working with reaper preference variable integer
--- bitfields easier.
--- @class Config
--- @field name string: The reaper preference string key.
--- @field config number The raw integer bitfield number.
--- @field options table Holding each option.
local Config = {}

-- FIX: right shift values so that I get the real preference value.
Config.__index = function(self, key)
    if Config[key] then
        return Config[key]
    else
        local ret, f
        if self.options[key] then
            local mask = self.options[key].mask
            local pos = find_lsb_position(mask)

            f = self.config & mask
            ret = f >> pos

            -- local mask = self.options[key].mask
            local positions = get_set_indices(mask)
            ret = get_variable_value(self.config, positions)

            -- log.user("__index", key, " -> ", ret)
        end
        -- log.user(string.format("mask = %s, >> = %s", su.makeStringLength(tostring(f), 4), ret))
        return ret
    end
end

Config.__tostring = function(self)
    -- TODO: print the real flag values, instead of 0/128
    local res = {}
    local str = "-------------\n"

    for k, v in pairs(self.options) do
        local op = { name = k, value = self[k] }
        table.insert(res, op)

        str = str .. "    " .. su.makeStringLength(k, 30) .. " = " .. self[k] .. "\n"
    end

    str = str .. "---\n"
    -- return format.block(res)
    return str
end

local mt = {}

--- Constructor
--- @param pref_key string Name of reaper preference variable. string: The name of the person
--- @param flags table Table with keys describing each flag
--- @return Config
function Config:new(pref_key, flags)
    local c = {}
    if c.options == nil then
        c.options = {}
        for k, v in pairs(flags) do
            if not k:match("^%_") then
                c.options[k] = v
            end
        end
    end
    c.config = reaper.SNM_GetIntConfigVar(pref_key, 0)
    c.name = pref_key

    setmetatable(c, self)

    -- log.user(format.block(o))
    return c
end

---Get the raw preference variable.
---@return number: The config value
function Config:raw()
    return self.config
end

--- Applies the config, eg if you have made modifications to the flags
function Config:apply()
    reaper.SNM_SetIntConfigVar(self.name, self.config)
end

function Config:_is_toggle(key)
    -- return self.options[key][3] == nil
    local bitmask = self.options[key].mask
    return bitmask > 0 and (bitmask & (bitmask - 1)) == 0
end

function Config:_is_mult(key)
    local bitmask = self.options[key].mask
    local count = 0
    while bitmask ~= 0 do
        count = count + (bitmask & 1)
        if count > 1 then
            return true
        end
        bitmask = bitmask >> 1
    end
end

function Config:is_mult(key)
    return self:_is_mult(key)
end

function Config:_set_single(key, newval)
    local mask = self.options[key].mask

    local function set(type)
        self.config = set_variable_value(self.config, get_set_indices(mask), newval)
    end

    if self:_is_toggle(key) then
        if newval == 0 or newval == 1 then
            set()
        end
    elseif self:_is_mult(key) then
        local max = (count_ones(mask) ^ 2) - 1
        if 0 <= newval and newval <= max then
            set()
        end
    end
end

function Config:toggle(key)
    if self:_is_toggle(key) then
        if self[key] == 1 then
            self:set(key, 0)
        else
            self:set(key, 1)
        end
    end
end

function Config:set(key, newval)
    if type(key) == "table" then
        for k, v in pairs(key) do
            self:_set_single(k, v)
        end
    else
        self:_set_single(key, newval)
    end
end

function Config:enable(key)
    if self:_is_toggle(key) then
        self:set(key, 0)
    end
end

function Config:disable(key)
    if self:_is_toggle(key) then
        self:set(key, 1)
    end
end

function Config:cycle(key, reverse)
    if self:_is_mult(key) then
        local mask = self.options[key].mask
        local flag = self[key]
        local levels = count_ones(mask) ^ 2

        if reverse then
            flag = (flag - 1) % levels -- Cycle through 2, 1, 0
            if flag < 0 then
                flag = levels
            end
        else
            flag = (flag + 1) % levels -- Cycle through 0, 1, 2
        end

        self:set(key, flag)
    end
end

-----------------------------------------------------------------------------
-----------------------------------------------------------------------------

local p = {}

-------------------------------------------------------------------------------
-- ACTIONS --------------------------------------------------------------------
-------------------------------------------------------------------------------

p.cueitems = {
    _meta = {
        cat = "actions",
        type = "integer actions variable",
        descr = "Toggle show media cues in items as triggered by action 40691(in sections Main, Media Explorer, MIDI Editor, MIDI Eventlist Editor, MIDI Inline Editor); 0 = OFF.",
    },
    toggle_show_media_cues_in_items = {
        mask = 1,
        name = "Toggle show media cues in items",
    },
}

p.itemtexthide = {
    _meta = {
        cat = "actions",
        type = "integer actions variable",
        descr = "Toggle show/hide item labels; 0 = ON.",
    },
    toggle_show_media_cues_in_items = {
        mask = 1,
        name = "Toggle show media cues in items",
    },
}

-------------------------------------------------------------------------------
-- ENVELOPE MANAGER -----------------------------------------------------------
-------------------------------------------------------------------------------

p.envmgropts = {
    _meta = {
        cat = "envelope manager",
        type = "integer project variable",
        descr = "Several settings, as set in the context-menu of the envelope manager.",
    },
    toggle_show_media_cues_in_items = {
        mask = 1,
        name = "Target Envelope manager when clicking track/take envelope buttons(shift+click to override); 0 = OFF",
        info = "-- Stored in reaper.ini under the same name in the section REAPER, when Save as default project settings has been clicked.",
    },
}

-------------------------------------------------------------------------------
-- HELP -----------------------------------------------------------------------
-------------------------------------------------------------------------------

--
--
-- >Context-menu in performane meter display:
p.help = {
    _meta = {
        cat = "help menu",
        subcat = "help",
        type = "integer/integer-bitfield, help variable",
        descr = "Stores the settings for the help-information-display under the TCP, as set in it's accompanying context-menu, as well the performance meter window-context menu.",
    },
    display_what = {
        mask = 5,
        name = "Select what type of help/tips to show",
        options = {
            "0, No information display",
            "1, Reaper tips",
            "2, Track/item count",
            "3, selected track/item/envelope details",
            "4, CPU/RAM use, time since last save",
        },
    },
    show_mouse_editing = {
        mask = 65536,
        name = "show mouse editing, 0 = ON",
    },
    context_menu_perf_meter = {
        mask = { 131072, 262144 }, -- TODO: need to impl auto add together if table and mult vals..
        name = "Context-menu in performane meter display:",
        options = {
            "Display CPU utilization as 100% = all cores fully utilized",
            "Display CPU utilization as 1.0c = 1 core fully utilized",
            "Display CPU utilization as 1.0! = longest block is realtime (worst case)",
        },
    },
}

-------------------------------------------------------------------------------
-- MISC
-------------------------------------------------------------------------------
--
--
--
--
--

-- The fontsize of the Reascript/JSFX-IDE.
-- It is an integer, misc variable.
--
-- >negative values are treated like the positive value+1; 16 is default
--
-- Stored in reaper.ini under the same name in the section REAPER; is updated as soon as the variable is changed.

p.edit_fontsize = {}

-- It is a string of the filename with path of the project, though only accessible as integer, and therefore the first characters.
-- It is an integer, misc variable.
--
-- Don't access it as double, or Reaper might crash!

p.g_config_project = {}

-- The number of times, a markerlist in any project has been updated since Reaper started.
-- A markerlist is just the list of markers, that a project contains.
-- Counts up, if a marker is added, set, deleted from any project opened in Reaper.
-- This counter includes already closed projects as well
-- This is an integer-value, variable.
--
-- >0, no marker has been updated yet
-- >1 and higher, markers have been updated in any opened project

p.g_markerlist_updcnt = {}

-- Stores some kind of color-theme-settings for Reaper's IDE.
-- Seems not to store the colors themselves, but rather count up, when one or more colors are changed.
-- It is an integer, misc variable.
--
-- >0 to 2147483647; higher values become negative
p.ide_colors = {}

-- The currently used font in Reaper's IDE.
-- It is a string, misc variable.
--
-- When storing a new font, use "" to use the default-IDE-font.
--
-- Keep in mind, that only mono-spaced-fonts will look good. Other fonts might have artifacts.
--
-- Stored in reaper.ini under the same name in the section REAPER.
p.ide_font_face = {}

-- In project MIDI item-inputbox as set in Preferences -> Recording
-- It is a string, preferences variable.
--
-- Stored in reaper.ini under the same name in the section REAPER.

p.inprojmidi_wildcards = {}

-- Settings in the Item-Notes-dialog
-- It is an integer, item-note variable.
--
-- >&8=0, Word wrap-checkbox(updated only, when itemnotes window gets closed) - unchecked
-- >&8=1, Word wrap-checkbox(updated only, when itemnotes window gets closed) - checked
--
-- >256=0, Enter to close, Shift+Enter for new line-checkbox - unchecked
-- >256=1, Enter to close, Shift+Enter for new line-checkbox - checked
--
-- Stored in reaper.ini under the same name in the section REAPER.
--
--

p.itemnotes = {}

-- The currently selected theme.
-- It is a string, theme variable.
--
-- ><classic> for the classic-theme; others are path+filename.ReaperTheme
--
-- Stored in reaper.ini under the same name in the section REAPER.
--
--
p.lastthemefn5 = {}

--
-- The maximum shown peak-gain of the shown peaks in MediaItems
-- It is a double-float, misc variable.
--
--   >values, who change the gain range from -180(negative gain) to 3(positive gain, possibly higher?)
--   >0, seems to be no gain
--   >default is 64.0
p.maxspeakgain = {}

-- The Metronome through Monitor FX-menuentry, as set in Metronome and Pre-roll-settings-dialog(Action: 40363) -> I/O-Button
-- It is an integer, metronome variable.
--
--   >0, menu is unchecked; 1, menu is checked
--
-- Stored in reaper.ini under the same name in the section REAPER.
p.metronome_flags = {}

-- The Display gain, as set in the RMS metering settings-section of the Master VU settings-dialog, opened when right-clicking the Master-VU.
-- In the dialog, it is treated as a simple float, means, 111 becomes 11.1 in the dialog. Negative values input in the dialog will be
-- set to +1, means: -8 will become -7.9 in the variable and the next time you open the dialog.
-- It is an integer, master-vu-context variable.
--
-- >-9999989 to 9999999.0; in dB; 0 for 0dB
--
-- Stored in reaper.ini under the same name in the section REAPER.
p.mvu_rmsgain = {}

--
-- The Master VU settings, as set in the Master VU settings-dialog, opened when right-clicking the Master-VU.
-- It is an integer-bitfield, master-vu-context variable.
--
-- >&1 and &2
--
--   >> 0 0, Peak Only
--   >> 0 1, RMS Only
--   >> 1 0, Peak+RMS
--
-- >&4=0, Top Label: Peak
-- >&4=1, Top Label: RMS
--
-- Stored in reaper.ini under the same name in the section REAPER.
p.mvu_rmsmode = {}

-- The Display offset, as set in the RMS metering settings-section of the Master VU settings-dialog, opened when right-clicking the Master-VU.
-- In the dialog, it is treated as a simple float, means, 111 becomes 11.1 in the dialog. Negative values input in the dialog will be
-- set to +1, means: -8 will become -7.9 in the variable and the next time you open the dialog.
-- It is an integer, master-vu-context variable.
--
-- >-9999989 to 9999999.0; in dB; 0 for 0dB
--
-- Stored in reaper.ini under the same name in the section REAPER.
p.mvu_rmsoffs2 = {}

-- The Red threshold, as set in the RMS metering settings-section of the Master VU settings-dialog, opened when right-clicking the Master-VU.
-- In the dialog, it is treated as a simple float, means, 111 becomes 11.1 in the dialog. Negative values input in the dialog will be
-- set to +1, means: -8 will become -7.9 in the variable and the next time you open the dialog.
-- It is an integer, master-vu-context variable.
--
-- >-9999989 to 9999999.0; in dB; 0 for 0dB
--
-- Stored in reaper.ini under the same name in the section REAPER.
p.mvu_rmsred = {}

-- The Window size, as set in the RMS metering settings-section of the Master VU settings-dialog, opened when right-clicking the Master-VU.
-- It is an integer, master-vu-context variable.
--
-- >0 to 9999999; milliseconds
--
-- Stored in reaper.ini under the same name in the section REAPER.
p.mvu_rmssize = {}

-- The several preroll-settings, as set in the Pre-Roll-section of the "Metronome and pre-roll settings"-dialog(also options-menu)
-- It is an integer-bitfield, metronome variable.
--
-- Can be affected by the following actions:
--   Pre-roll: Toggle pre-roll on record [deprecated duplicate]
--   Pre-roll: Toggle pre-roll on play
--   Pre-roll: Toggle pre-roll on record
--
-- >&1=0, Pre-roll before playback(off) - unchecked
-- >&1=1, Pre-roll before playback(on) - checked
--
-- >&2=0, Pre-roll before recording(off) - unchecked
-- >&2=1, Pre-roll before recording(on) - checked
--
-- >&4=0, Start pre-roll at start of measure(on) - checked
-- >&4=1, Start pre-roll at start of measure(off) - unchecked
--
-- >&8=0, Start count-in at start of measure(set in the Metronome-section)(off) - unchecked
-- >&8=1, Start count-in at start of measure(set in the Metronome-section)(on) - checked
--
-- Stored in reaper.ini under the same name in the section REAPER.
p.preroll = {}

-- The Pre-roll measures-inputbox, as set in the Pre-Roll-section of the "Metronome and pre-roll settings"-dialog(also options-menu)
-- It is a double-float, metronome variable.
--
-- >0 to 1e+021; higher values can't be set in the reaper.ini, though in the variable
--
-- Stored(with higher precision) in reaper.ini under the same name in the section REAPER.
p.prerollmeas = {}

-- Several settings, as set in Quantize Item Positions(action 40316)
-- It is an integer-bitfield, preferences variable.
--
-- >&1=0, Move grouped items with selected items(off) - unchecked
-- >&1=1, Move grouped items with selected items(on) - checked
--
-- >&2=0, Extend start of items to overlap with earlier items by-checkbox(off)- unchecked
-- >&2=1, Extend start of items to overlap with earlier items by-checkbox(on)- checked
--
-- >&4=0, Shorten earlier items if quantized items overlap by more than-checkbox(off) - unchecked
-- >&4=1, Shorten earlier items if quantized items overlap by more than-checkbox(on) - checked
--
-- >&8=0, Quantize item ends and stretch item to fit(off) - unchecked
-- >&8=1, Quantize item ends and stretch item to fit(on) - checked
--
-- Stored in reaper.ini under the same name in the section REAPER.
p.quantflag = {}

-- Extend start of items to overlap with earlier items by-inputbox, as set in Quantize Item Positions(action 40316)
-- It is an integer, preferences variable.
--
-- >0 to 2147483647; in milliseconds; higher values become negative;
--
-- Stored in reaper.ini under the same name in the section REAPER.
p.quantolms = {}

--
-- Shorten earlier items if quantized items overlap by more than-inputbox, as set in Quantize Item Positions(action 40316)
-- It is an integer, preferences variable.
--
-- >0 to 2147483647; in milliseconds; higher values become negative;
--
-- Stored in reaper.ini under the same name in the section REAPER.
p.quantolms2 = {}

-- Quantize to-dropdown/inputlist, as set in Quantize Item Positions(action 40316)
-- It is a double-float, preferences variable.
--
-- >0.00390625(1/256)
-- >0.0078125(1/128)
-- >0.015625(1/64)
-- >0.020833333333333(1/32T)
-- >0.03125(1/32)
-- >0.041666666666667(1/16T)
-- >0.0625(1/16)
-- >0.083333333333333(1/8T)
-- >0.125(1/8)
-- >0.16666666666667(1/4T)
-- >0.25(1/4)
-- >0.5(1/2)
-- >1.0(1)
-- >2.0(2)
-- >4.0(4)
-- >other values are possible as well, with minimum 1/256
--
-- Stored in reaper.ini under the same name in the section REAPER.
p.quantsize2 = {}

-- The settings behind the Edit fields-Button, as set in Screensets/Layouts located in menu View -> Screensets/Layouts
-- It is an integer, preferences variable.
-- The value is negative for some reason...
--
-- >&4=0, Views -> Track cursor position(on) - checked
-- >&4=1, Views -> Track cursor position(off) - unchecked
--
-- >&8=0, Views -> Track scroll positions(on) - checked
-- >&8=1, Views -> Track scroll positions(off) - unchecked
--
-- >&16=0, Views -> Track TCP status(on) - checked
-- >&16=1, Views -> Track TCP status(off) - unchecked
--
--
-- >&64=0, Views -> Track mixer status(on) - checked
-- >&64=1, Views -> Track mixer status(off) - unchecked
--
-- >&128=0, Views -> Horizontal zoom(on) - checked
-- >&128=1, Views -> Horizontal zoom(off) - unchecked
--
-- Stored in reaper.ini under the same name in the section REAPER.
p.screenset_as_views = {}

-- The settings behind the Edit fields-Button, as set in Screensets/Layouts located in menu View -> Screensets/Layouts
-- The value is negative for some reason...
-- It is an integer, preferences variable.
--
-- >&1=0, Windows -> Main window position(on) - checked
-- >&1=1, Windows -> Main window position(off) - unchecked
--
-- >&2=0, Windows -> Tool window position(on) - checked
-- >&2=1, Windows -> Tool window position(off) - unchecked
--
-- >&32=0, Windows -> Docker selected tab(on) - checked
-- >&32=1, Windows -> Docker selected tab(off) - unchecked
--
-- >&512=0, Windows -> Mixer flags(on) - checked
-- >&512=1, Windows -> Mixer flags(off) - unchecked
--
-- >&1024=0, Windows -> Last focus(on) - checked
-- >&1024=1, Windows -> Last focus(off) - unchecked
--
-- >&2048=0, Windows -> Layouts(on) - checked
-- >&2048=1, Windows -> Layouts(off) - unchecked
--
-- Stored in reaper.ini under the same name in the section REAPER.
p.screenset_as_win = {}

-- Auto-save when switching screensets-checkbox, as set in Screensets/Layouts located in menu View -> Screensets/Layouts
-- It is an integer, preferences variable.
--
-- >0, Auto-save when switching screensets(off) - unchecked
-- >1, Auto-save when switching screensets(on) - checked
--
-- Stored in reaper.ini under the same name in the section REAPER.
p.screenset_autosave = {}

-- Scroll view when tracks activated-entry, as set in the Mixer-context-menu.
-- It is an integer, preferences variable.
--
-- Can be affected by the following actions:
--   Mixer: Toggle scroll view when tracks activated
--
-- >0, don't scroll view(off) - unchecked
-- >1, scroll view(on) - checked
--
-- Stored in reaper.ini under the same name in the section REAPER.
p.showctinmix = {}

-- Show master track, as set in the TrackControlPanel-context menu
-- It is an integer, preferences variable.
--
-- Can be affected by the following actions:
--   View: Toggle master track visible
--   Toggle show master tempo envelope
--   Toggle show master track and tempo envelope
--
-- >0, don't show master track - unchecked
-- >1, show master track - checked
--
-- Stored in reaper.ini under the same name in the section REAPER, when Save as default project settings has been clicked.
p.showmaintrack = {}

-- Stores the Opacity-fader for Spectral Peaks, as set in the Peaks Display Settings from View -> Peaks Display Settings
-- It is an integer, preferences variable.
--
-- >0 to 255; 192 for default
--
-- Stored in reaper.ini under the same name in the section REAPER.
p.specpeak_alpha = {}

-- Stores the variance-level for Spectral Peaks, as set in the Peaks Display Settings from View -> Peaks Display Settings
-- It is an integer, preferences variable.
--
-- >0(for displayed value 0) to 256(for displayed value 1.00); default 96(for displayed value 0.38)
--
-- Stored in reaper.ini under the same name in the section REAPER.
p.specpeak_bv = {}

-- Fade non tonal content to theme peaks color-context menu for Spectral Peaks, as set in the Peaks Display Settings from View -> Peaks Display Settings
-- It is an integer, preferences variable.
--
-- >0, don't fade - unchecked
-- >1, fade - checked
--
-- Stored in reaper.ini under the same name in the section REAPER.
p.specpeak_ftp = {}

-- The high-end of the spectrum, starting point for Spectral Peaks, as set in the Peaks Display Settings from View -> Peaks Display Settings
-- That means, the right side of the spectrum.
-- It is a double-float, preferences variable.
--
-- >0.513 is default settings; lower push the spectrum together; higher, stretch it apart until about 1.585(default value from specpeak_huel),
--    from which it's pushed together again
--
-- Stored in reaper.ini under the same name in the section REAPER.
--
p.specpeak_hueh = {}

-- The low-end of the spectrum, starting point for Spectral Peaks, as set in the Peaks Display Settings from View -> Peaks Display Settings
-- That means, the left side of the spectrum.
-- It is a double-float, preferences variable.
--
-- >1.585 is default settings; higher push the spectrum together; lower, stretch it apart until about 0.513(default value from specpeak_hueh),
--    from which it's pushed together again
--
-- Stored in reaper.ini under the same name in the section REAPER.
--
p.specpeak_huel = {}

-- The lo-frequency-part for Spectral Peaks, as set in the Peaks Display Settings from View -> Peaks Display Settings
-- That means, the frequency shown in the lower part of the preview-Spectral-Peaks-area.
-- It is a double float, preferences variable.
--
-- >0(for displayed 14Hz to 3904Hz) to 200(14Hz to 7985Hz); default is 0
--
-- Stored in reaper.ini under the same name in the section REAPER.
p.specpeak_lo = {}

-- Stores the Noise Threshold-fader for Spectral Peaks, as set in the Peaks Display Settings from View -> Peaks Display Settings
-- It is a double-float, preferences variable.
--
-- >16(for displayed value 0.25) to 0.5(for displayed value 8.0); default is 257(for displayed value 1.0)
--
-- Stored in reaper.ini under the same name in the section REAPER.
p.specpeak_na = {}

-------------------------------------------------------------------------------
-- MISC -> MIDI
-------------------------------------------------------------------------------
--
--

-- Use all MIDI inputs-checkbox, as set Scale Finder located in View -> Scale Finder as well as in
--   Preferences -> Mouse Modifiers(only MIDI CC event, MIDI CC lane and MIDI CC segment-Modifiers ) and in MIDI Editor -> Options -> Velocity editing lane and
--   in MIDI Editor -> Options -> CC events in multiple media items.
-- It is an integer-bitfield, preferences variable.
--
-- >&2=0, Allow selecting a single event in a CC lane with a mouse click(on) - checked
-- >&2=1, Allow selecting a single event in a CC lane with a mouse click(off) - unchecked
--
-- >&8=0, Use all MIDI inputs(on) - checked
-- >&8=1, Use all MIDI inputs(off) - unchecked
--
-- >&16=0, Draw and edit on all tracks(MIDI Editor -> Options -> CC events in multiple media items)
-- >&16=1, Edit on all tracks(MIDI Editor -> Options -> CC events in multiple media items)
--
-- >&32=0, Edit CC-Events on all tracks(Tracklist in MIDI-Editor) ->unchecked
-- >&32=1, Edit CC-Events on all tracks(Tracklist in MIDI-Editor) ->checked
--
-- >&64=0, Edit previous note within current grid division(MIDI Editor -> Options -> Velocity editing lane)
-- >&64=1, Edit only when mouse is over velocity bar(MIDI Editor -> Options -> Velocity editing lane)
--
-- >&128=0, Right click deletes CC events-checkbox(Preferences -> Mouse modifiers -> MIDI CC segment - left click/drag) -> checked
-- >&128=1, Right click deletes CC events-checkbox(Preferences -> Mouse modifiers -> MIDI CC segment - left click/drag) -> unchecked
--
-- >&256=0, Draw/edit immediately on mouse click-checkbox(Preferences -> Mouse modifiers -> MIDI CC segment - left click/drag) -> unchecked
-- >&256=1, Draw/edit immediately on mouse click-checkbox(Preferences -> Mouse modifiers -> MIDI CC segment - left click/drag) -> checked
p.scnotes = {}

-- The minimum length of a note, in the notation-view of the MIDI-Editor.
-- It is an integer, preferences variable.
--
--   >4, one full note; lower than 4 are fractions of a note
--
-- Stored in reaper.ini under the same name in the section REAPER, when Save as default project settings has been clicked.
p.scoreminnotelen = {}

-- unknown
-- It is an integer, unknown variable.
--
-- Stored in reaper.ini under the same name in the section REAPER, when Save as default project settings has been clicked.
p.scorequant = {}

-------------------------------------------------------------------------------
-- PREFERENCES (reaper preferences panel UI)
-------------------------------------------------------------------------------

--
-- PREFERENCES -> APPEARANCE
--

-- Include default menu as submenu-checkbox in Menu-Editor as well as some settings in Preferences -> Appearance
-- It is an integer-bitfield, preferences variable.
--
-- >&1=0, include default menus as submenu(Menueditor)(off) - unchecked
-- >&1=1, include default menus as submenu(Menueditor)(on) - checked
--
-- >&4=0, Don't scale toolbar buttons below 1:1(off) - unchecked
-- >&4=1, Don't scale toolbar buttons below 1:1(on) - checked
--
-- >&16=0, Don't scale toolbar buttons above 1:1 (on) - checked
-- >&16=1, Don't scale toolbar buttons above 1:1 (off) - unchecked
--
-- >&256=0, Frameless floating toolbar windows(off) - unchecked
-- >&256=1, Frameless floating toolbar windows(on) - checked
--
-- Stored in reaper.ini under the same name in the section REAPER.
p.custommenu = {}

-- Several settings, as set in Preferences -> Envelope Display as well as in Preferences -> Appearance and Preferences -> Peaks/Waveforms
-- It is an integer-bitfield, preferences variable.
--
-- >&1=0, Show new envelopes in separate envelope lanes-checkbox(Preferences -> Envelope Display)(off) - unchecked
-- >&1=1, Show new envelopes in separate envelope lanes-checkbox(Preferences -> Envelope Display)(on) - checked
--
-- >&2=0, Changing envelope in lane: Moves old envelope to media lane(Preferences -> Envelope Display)
-- >&2=1, Changing envelope in lane: Hides old envelope(Preferences -> Envelope Display)
--
-- >&4=0, Draw faint peaks in automation envelope lanes(Preferences -> Peaks/Waveforms)(off) - unchecked
-- >&4=1, Draw faint peaks in automation envelope lanes(Preferences -> Peaks/Waveforms)(on) - checked
--
-- >&8=0, Antialiased fades and envelopes(on) - checked
-- >&8=1, Antialiased fades and envelopes(off) - unchecked
--
-- >&16=0, Filled automation envelopes(on) - checked
-- >&16=1, Filled automation envelopes(off) - unchecked
--
-- >&32=0, Filled envelopes when drawn over media(only available with &16=1)(off) - unchecked
-- >&32=1, Filled envelopes when drawn over media(only available with &16=1)(on) - checked
-- >&64=0, Horizontal grid lines in automation layers(on) - checked
-- >&64=1, Horizontal grid lines in automation layers(off) - unchecked
--
-- Stored in reaper.ini under the same name in the section REAPER.
p.envlanes = {}

-- Show dotted grid lines-checkbox, as set in Preferences -> Appearance
-- It is an integer, preferences variable.
--
-- >0, don't show dotted grid-line(off) - unchecked
-- >1, don't show dotted grid-line(on) - checked
--
-- Stored in reaper.ini under the same name in the section REAPER.
p.griddot = {}


-- ^ griddot
-- Show dotted grid lines-checkbox, as set in Preferences -> Appearance
-- It is an integer, preferences variable.
--
-- >0, don't show dotted grid-line(off) - unchecked
-- >1, don't show dotted grid-line(on) - checked
--
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ gridinbg
-- Grid line Z order-dropdownlist, as set in Preferences -> Appearance
-- It is an integer, preferences variable.
--
-- >0, Over items
-- >1, Through items
-- >2, Under items
--
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ gridinbg2
-- Marker line Z order-dropdownlist, as set in Preferences -> Appearance
-- It is an integer, preferences variable.
--
-- >0, Over items
-- >1, Through items
-- >2, Under items
--
-- Stored in reaper.ini under the same name in the section REAPER.


-- ^ guidelines2
-- Show guide lines when editing-checkbox, as set in Preferences -> Appearance
-- It is an integer, preferences variable.
--
-- >0, don't show guide lines(off) - unchecked
-- >1, show guide lines(on) - checked
--
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ itemvolmode
-- Item volume control-dropdownlist, as set in Preferences -> Media
-- This is not(!) located in Preferences -> Appearance-Media!
-- When setting &16384 of config variable itemicons, you can set knob-representation
-- It is an integer, preferences variable.
--
-- >0, Handle: +0dB is top of item
-- >1, Handle: +0dB is center of item
--
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ maxitemlanes
-- Maximum number of lanes, when showing overlapping items in lanes-inputbox, as set in Preferences -> Appearance
-- It is an integer, preferences variable.
--
-- >1 to 2147483647; in lanes
--
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ nativedrawtext
-- Faster text rendering (reduces antialiasing)-checkbox, as set in Preferences -> Appearance
-- It is an integer, preferences variable.
--
-- >0, Faster text rendering(on) - checked
-- >1, don't use faster text rendering(off) - unchecked
--
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ peaks_minheight
-- The minimum height-inputbox as set in Preferences -> Appearance -> Peaks/Waveforms.
-- It is an integer, preferences variable.
--
--   >0 to 999 pixels
--
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ playcursormode
-- Play cursor width-inputbox, as set in Preferences -> Appearance
-- It is an integer, preferences variable.
--
-- >1 to 2147483647; in pixels
--
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ rulerlabelspacing
-- Ruler label spacing-slider, as set in Preferences -> Appearance
-- It is an integer, preferences variable.
--
-- >0 to 100
--
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ rulerlayout
-- The ruler layout-settings, as set in the Ruler layout-section of the Ruler context-menu as well as in Preferences -> Appearance and
-- with actions in the actions-dialog
-- It is an integer-bitfield, preferences variable.
--
-- Can be affected by the following actions:
--   Ruler: Display project regions in lanes
--   Ruler: Display project markers in lanes
--   Ruler: Display tempo and time signature changes in separate lanes (when size permits)
--   Ruler: Display tempo changes
--   Ruler: Display time signature changes
--   Ruler: Display project regions/markers as gridlines in arrange view
--   Ruler: Display time signature changes as gridlines in arrange view
--   Ruler: Display region number even if region is named
--   Ruler: Display region number/name when region edge is not visible
--
-- >&1=0, Display project regions in lanes(on) - checked
-- >&1=1, Display project regions in lanes(off) - unchecked
--
-- >&2=0, Display project markers in lanes(on) - checked
-- >&2=1, Display project markers in lanes(off) - unchecked
--
-- >&4=0, Display tempo and time signature changes in separate lanes(off) - unchecked
-- >&4=1, Display tempo and time signature changes in separate lanes(on) - checked
--
-- >&8=0, Display tempo changes(on) - checked
-- >&8=1, Display tempo changes(off) - unchecked
--
-- >&16=0, Display time signature changes(on) - checked
-- >&16=1, Display time signature changes(off) - unchecked
--
-- >&32=0, Show project regions/markers in grid(Preferences -> Appearance)(action 42328) (state on) - checked
-- >&32=1, Show project regions/markers in grid(Preferences -> Appearance)(action 42328) (state off) - unchecked
--
-- >&64=0, Show time signature changes in grid(Preferences -> Appearance) (action 42329) (state on) - checked
-- >&64=1, Show time signature changes in grid(Preferences -> Appearance) (action 42329) (state off) - unchecked
--
-- Stored in reaper.ini under the same name in the section REAPER.




-- ^ showlastundo
-- Show last undo point in menu bar-checkbox, as set in Preferences -> Appearance
-- It is an integer, preferences variable.
--
-- >0, don't show last undo point(off) - unchecked
-- >1, show last undo point(on) - checked
--
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ showpeaksbuild
-- The Show status window-checkbox, as set in Preferences -> Media
-- This is not(!) located in Preferences -> Appearance-Media!
-- It is an integer, preferences variable.
--
-- >0, don't show peaks build status
-- >1, show peaks build status window
--
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ textflags
-- Draw vertical text bottom-up-checkbox, as set in Preferences -> Appearance
-- It is an integer
--
-- >0, don't draw vertical text bottom-up(off) - unchecked
-- >1, don't draw vertical text bottom-up(on) - checked
--
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ timeseledge
-- Solid edge-settings, as set in Preferences -> Appearance
-- It is an integer-bitfield
--
-- >&1=0, Solid edge on time selection highlight(off) - unchecked
-- >&1=1, Solid edge on time selection highlight(on) - checked
--
-- >&2=0, Solid edge in loop selection(off) - unchecked
-- >&2=1, Solid edge in loop selection(on) - checked
--
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ tooltipdelay
-- Tooltip delay-slider in Preferences -> Appearance
-- The variable is updated, when dragging the slider, but the reaper.ini-entry is only updated when hitting apply or ok!
-- It is an integer, preferences variable.
--
-- >200 to 1000; probably milliseconds
--
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ tooltips
-- Several settings about tooltips, as set in Preferences -> Appearance
-- It is an integer-bitfield, preferences variable.
--
-- >&1=0, Tooltips for items/envelopes(on) - checked
-- >&1=1, Tooltips for items/envelopes(off) - unchecked
--
-- >&2=0, Tooltips for UI elements(on) - checked
-- >&2=1, Tooltips for UI elements(off) - unchecked
--
-- >&4=0, Envelope tooltips on hover(on) - checked
-- >&4=1, Envelope tooltips on hover(off) - unchecked
--
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ trackgapmax
-- Visual track spacer size-inputbox, as set in Preferences -> Appearance
-- It is an integer, preferences variable.
--
-- >0-2147483647
--
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ trackitemgap
-- Pixels between items on adjacent tracks-inputbox, as set in Preferences -> Appearance
-- It is an integer, preferences variable.
--
-- >0 to 2147483647; in pixels; higher values become negative
--
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ vgrid
-- Divide arrange view vertically every-checkbox AND inpubox, as set in Preferences -> Appearance
-- It is an integer-bitfield, preferences variable.
--
-- Can be affected by the following actions:
--   Grid: Divide arrange view vertically by measures
--
-- >0, zoom dependent
-- >1 to 4095; measures
--
-- >&4096=0, checkbox(off) - unchecked
-- >&4096=1, checkbox(on) - checked
--
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ applyfxtail
-- Tail length when using Apply FX to items in milliseconds, as set in Preferences -> Media
-- This is not(!) located in Preferences -> Appearance-Media!
-- The accompanying entry in the reaper.ini is always config-var-setting+1.
-- It is an integer
--
-- >0 to 2147483647; higher values become negative
--
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ copyimpmedia
-- Some checkboxes in the Media Settings-section, as set in Preferences -> Media
-- This is not(!) located in Preferences -> Appearance-Media!
-- It is an integer-bitfield, preferences variable.
--
-- Can be affected by the following actions:
--   Options: When importing, copy imported media to project media directory
--
-- >&1=0, Copy imported media to project media directory - unchecked
-- >&1=1, Copy imported media to project media directory - checked
--
-- >&2=0, Automatically name unnamed tracks on media import - checked
-- >&2=1, Automatically name unnamed tracks on media import - unchecked
--
-- >&4=0, Removing trailing numbers - checked
-- >&4=1, Removing trailing numbers - unchecked
--
-- >&8=0, Allow drag-import to insert tracks - unchecked
-- >&8=1, Allow drag-import to insert tracks - checked
--
-- >&16=0, Also copy media when pasting into project - unchecked
-- >&16=1, Also copy media when pasting into project - unchecked
--
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ allstereopairs
-- Show non-standard stereo channel pairs(i.e Input2/Input3 etc)-checkbox in the Channel naming/mapping-section, as set in Preferences -> Audio
-- It is an integer, Preferences setting
--
-- >0, don't show non standard stereo channel pairs(off) - unchecked
-- >1, show non standard stereo channel pairs(on) - checked
--
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ audiocloseinactive
-- Several settings regarding closing audio-devices, as set in Preferences -> Audio
-- It's an integer-bitfield, preferences variable.
--
-- >&1=0, Close audio device when stopped and application is inactive(off) - unchecked
-- >&1=1, Close audio device when stopped and application is inactive(on) - checked
--
-- >&2=0, Close audio device when inactive and tracks are record armed(off) - unchecked
-- >&2=1, Close audio device when inactive and tracks are record armed(on) - checked
--
-- >&4=0, Close audio device when inactive and ReWire devices are open(off) - unchecked
-- >&4=1, Close audio device when inactive and ReWire devices are open(on) - checked
--
-- >&8=0, Close control surface device when stopped and not active applications, as set in Preferences -> Control/OSC/web, unchecked
-- >&8=1, Close control surface device when stopped and not active applications, as set in Preferences -> Control/OSC/web, checked
--
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ audioclosestop
-- Close audio device when stopped and active(less responsive)-checkbox, as set in Preferences -> Audio
-- It's an integer, preferences variable.
--
-- >0, don't close audio when stopped - unchecked
-- >1, close audio device when stopped - checked
--
-- Stored in reaper.ini under the same in the section REAPER.

-- ^ errnowarn
-- Several error-messages, that shall be shown, as set in several dialogs, as well as in Preferences -> Audio and in Preferences -> Recording and Preferences -> Track/Send Defaults
-- It's an integer-bitfield, preferences variable.
--
-- >&1=0, Warn when unable to open audio devices(Preferences -> Audio)(on) - checked
-- >&1=1, Warn when unable to open audio devices(Preferences -> Audio)(off) - unchecked
--
-- >&2=0, MIDI devices-checkbox(Preferences -> Audio)(on) - checked
-- >&2=1, MIDI devices-checkbox(Preferences -> Audio)(off) - unchecked
--
-- >&4=0, Warn when errors opening surface MIDI devices(Preferences -> Control/OSC/web) - unchecked
-- >&4=1, Warn when errors opening surface MIDI devices(Preferences -> Control/OSC/web) - checked
--
-- >&8=0, Warn when recording without tracks armed(Prompt)(Prevent recording from starting when no tracks armed)(off) - unchecked
-- >&8=1, Warn when recording without tracks armed(Prompt)(Prevent recording from starting when no tracks armed)(on) - checked
--
-- >&16=0, Warn when changing volume envelope scaling will change envelope sound(Preferences -> Track/Send Defaults)(on) - checked
-- >&16=1, Warn when changing volume envelope scaling will change envelope sound(Preferences -> Track/Send Defaults)(off) - unchecked
--
-- >&32=0, Warn when enabled MIDI devices are not present - checked
-- >&32=1, Warn when enabled MIDI devices are not present - unchecked
--
-- >&4096=0, Stop processing audio while warning of failed disk writes/disk full - unchecked
-- >&4096=1, Stop processing audio while warning of failed disk writes/disk full - checked
--
-- Stored in reaper.ini under the same name in the section REAPER.



-- ^ hwfadex
-- Tiny-fade-checkboxes, as set in Preferences -> Audio
-- It is an integer-bitfield, preferences variable.
--
-- >&1=0, Tiny fade out on playback stop(off) - unchecked
-- >&1=1, Tiny fade out on playback stop(on) - checked
--
-- >&2=0, Tiny fade out on playback stop(off) - unchecked
-- >&2=1, Tiny fade in on playback start(on) - checked
--
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ metronome_defout
-- Default metronome output-dropdownlist in the Channel naming/mapping-section, as set in Preferences -> Audio
-- The track-number; set &1024=1 additional to select only mono-channels
-- It is an integer-bitfield, preferences variable.
--
-- >-1, Use all project master outs
-- >0 to 62, stereo pairs channel 1/2 to 63/64(maybe higher possible?)
-- >1024 to 1087, channel 1 to 64(maybe higher possible?)
--
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ optimizesilence
-- Reduce CPU use of silent tracks during playback (experimental)-checkbox, as set in Preferences -> Audio  as well as
-- Disable FX auto-bypass when using offline render/apply FX/render stems-checkbox, as set in Preferences -> Rendering
-- It is an integer, preferences variable.
--
-- >&1=0, Reduce CPU use of silent tracks during playback (experimental)-checkbox - unchecked
-- >&1=1, Reduce CPU use of silent tracks during playback (experimental)-checkbox - checked
--
-- >&4=0, Auto-bypass FX (when set via project or manual setting) even when FX configuration is open-checkbox - unchecked
-- >&4=1, Auto-bypass FX (when set via project or manual setting) even when FX configuration is open-checkbox - checked
--
-- >&8=0, Disable FX auto-bypass when using offline render/apply FX/render stems-checkbox - unchecked
-- >&8=1, Disable FX auto-bypass when using offline render/apply FX/render stems-checkbox - checked
--
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ useinnc
-- The Input/Output-channel name aliasing-checkboxes in the section Channel naming/mapping  as set in Preferences -> Audio
-- It is an integer-bitfield, preferences variable.
--
-- >&1=0, Input channel name aliasing/remapping-checkbox(off) - unchecked
-- >&1=1, Input channel name aliasing/remapping-checkbox(on) - checked
--
-- >&2=0, Input channel name aliasing/remapping-checkbox(off) - unchecked
-- >&2=1, Input channel name aliasing/remapping-checkbox(on) - checked
--
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ autoreturntime
-- Automation recording return speed-inputbox, as set in Preferences -> Automation
-- It is given in seconds.
-- It is a double-float preferences variable.
--
-- >0 to 100000000000000.00000000; higher values are possible but produce weird values stored.
--
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ autoreturntime_action
-- Automation transition time-inputbox, as set in Preferences -> Automation
-- It is given in seconds.
-- It is a double-float preferences variable.
--
-- >0 to 100000000000000.00000000; higher values are possible but produce weird values stored.
--
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ env_autoadd
-- Several settings from the Automation-section, as set in Preferences -> Automation.
-- It is an integer-bitfield, preferences variable.
--
-- >&1=0, Automatically add envelopes when tweaking parameters in automation write modes(off) - unchecked
-- >&1=1, Automatically add envelopes when tweaking parameters in automation write modes(on) - checked
--
-- >&2=0, Hidden envelopes: Display read automation feedback(on) - checked
-- >&2=1, Hidden envelopes: Display read automation feedback(off) - unchecked
--
-- >&4=0, Hidden envelopes: Allow writing automation(off) - unchecked
-- >&4=1, Hidden envelopes: Allow writing automation(on) - checked
--
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ env_options
-- Several settings from the Automation-section, as set in Preferences -> Automation as well as the Envelope Manager-context menu.
-- It is an integer-bitfield, preferences variable.
--
-- >&1=0, Reset latch state when looping(on) - checked
-- >&1=1, Reset latch state when looping(off) - unchecked
--
-- >&2=0, Default: All FX parameters expanded
-- >&2=1, Default: All FX parameters collapsed
--
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ envtrimadjmode
-- When adding volume/pan envelopes, apply trim to envelope and reset trim-dropdownlist from the Automation-section, as set in Preferences -> Automation.
-- It is an integer-bitfield, preferences variable.
--
-- >&1 and &2, the dropdownlist
--
--   >> 0 0, Always
--   >> 1 0, In read/write
--   >> 0 1, Never
--
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ envwritepasschg
-- When adding volume/pan envelopes, apply trim to envelope and reset trim-dropdownlist from the Automation-section, as set in Preferences -> Automation.
-- It is an integer, preferences variable.
--
-- >0, Switch to trim/read mode
-- >1, Switch to read mode
-- >2, Switch to touch mode
-- >3, Remain in write mode
-- >4, Switch to latch mode
--
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ pooledenvtranstime
-- Default edge transition time for new automation items ms(max 200)-inputbox, as set in Preferences -> Automation -> Automation items
-- It is a double, preferences variable.
--
--   0 to 200(though higher values can be set)
--
-- Stored in reaper.ini under the same name in the section REAPER, but with higher precision.

-- ^ autosavebackuplimit
-- Limit auto-saved backups to most recent-inputbox, as set in Preferences -> Backups
-- It is an integer, preferences variable.
--
-- >0 - 2147483647 days
--
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ autosaveint
-- Auto-save interval-inputbox from the Auto save-section, as set in Preferences -> Backups.
-- It is an integer preferences variable.
--
-- >0 to 2147483647; in seconds; higher values become negative
--
-- Stored in reaper.ini under the same name in the section REAPER.






























































--
-- PREFERENCES -> APPAERANCE-MEDIA
--

--
-- PREFERENCES -> AUDIO
--

--
-- PREFERENCES -> AUTOMATION
--

--
-- PREFERENCES -> BACKUP
--

--
-- PREFERENCES -> BUFFERING
--

--
-- PREFERENCES -> COMPATABILITY
--

--
-- PREFERENCES -> CONTEXT MENU
--

--
-- PREFERENCES -> CONTROL/OSC/WEB
--

--
-- PREFERENCES -> DEVICE
--

--
-- PREFERENCES -> EDITING BEHAVIOR
--

--
-- PREFERENCES -> ENVELOPE DISPLAY
--

--
-- PREFERENCES -> FADES/CROSSFADES
--

--
-- PREFERENCES -> GENERAL
--

--
-- PREFERENCES -> ITEM FADE DEFAULTS
--

--
-- PREFERENCES -> ITEM LOOP DEFAULTS
--

--
-- PREFERENCES -> KEYBOARD/MULTITOUCH
--

--
-- PREFERENCES -> LV2
--

--
-- PREFERENCES -> loop recording
--

--
-- PREFERENCES -> MIDI DEVICES
--

--
-- PREFERENCES -> midi editor
--

--
-- MIDI

-- ^ midiccdensity
-- Events per quarter note when drawing in CC lines-inputbox, as set in Preferences -> MIDI Editor
-- It is an integer, preferences variable.
-- The zoom-dependent-checkbox is signalled with a negative version of this value!
-- >0 to 2147483647; higher values become negative; default is 32
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ midiccenv
-- The Default shape for CC segments-dropdownlist, as set in Preferences -> MIDI Editor
-- It is an integer, preferences variable.
-- >0, Square
-- >1, Linear
-- >2, Slow start/end
-- >3, Fast start
-- >4, Fast end
-- >5, Bezier
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ midiccinterp
-- The Playback interpolation-inputbox, as set in Preferences -> MIDI Editor
-- It is an integer, preferences variable.
-- >0 to 2147483647 in ppq
-- Stored in reaper.ini under the same name in the section REAPER.

-- ^ mididefcolormap
-- Default note color map-inputbox, as set in the Preferences -> MIDI Editor
-- It is a string, preferences variable.
-- Stored in reaper.ini under the same name in the section REAPER.

-- FIX: rename "name" to "descr"??
p.midieditor = {
    _meta = {
        cat = "preferences",
        subcat = "midi editor",
    },
    editor_type = {
        mask = 3, -- &1 and &2, One MIDI editor per; 00=media item; 01=track; 10=project
        name = "One MIDI editor per",
        options = { "One MIDI editor per media item", "One MIDI editor per track", "One MIDI editor per project" },
    }, -- how to get the value
    behavior_type = {
        mask = 20, -- &4, (and &16,) Behavior for "open items in built-in MIDI editor
        name = "Behavior for `open items in built-in MIDI editor`",
        {
            "Open clicked MIDI item only",
            "Open all selected MIDI items",
            "Open all MIDI on the same track",
            "Open all MIDI in the project",
        },
    },
    -- &32=0/1, Close editor when the active item is deleted in the arrange
    -- view
    close_upon_item_deletion = { mask = 32, name = "Close editor when the active item is deleted in the arrange" },
    -- &128=0/1, Active MIDI item follows selection changes in arrange
    -- view
    active_item_follows_selection = { mask = 128 },
    -- &256=0/1, Only MIDI items on the same track as the active item are
    -- editable
    other_tracks_editable = { mask = 256 },
    -- &512=0/1, Selection is linked to editability(also MIDI-Editor-action 40891)
    editability = { mask = 512 },
    -- &1024=0/1, Media item selection is linked to visibility
    visibility = { mask = 1024 },
    -- &2048=0/1, All media items are editable in notation view(MIDI Editor ->
    -- Contents -> Behavior for "open items in built-in MIDI Editor")
    all_items_are_editable_in_notation_view = { mask = 2048 },
    -- &4096=0/1, Make secondary items editable by default
    secondary_items_editable_by_default = { mask = 4096 },
}

--
-- PREFERENCES -> midi settings
--

--
-- PREFERENCES -> MIDI
--

--
-- PREFERENCES -> MEDIA ITEM POSITIONONG
--

--
-- PREFERENCES -> xx
--

--
-- PREFERENCES -> xx
--

--
-- PREFERENCES -> xx
--

--
-- PREFERENCES -> xx
--

--
-- PREFERENCES -> xx
--

--
-- PREFERENCES -> xx
--

-------------------------------------------------------------------------------
-- PROJECT SETTINGS
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- TRANSPORT
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- UNKNOWN
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- USER INTERFACE
-------------------------------------------------------------------------------

-- FIX: rename "name" to "descr"??
p.midieditor = {
    _meta = {
        cat = "preferences",
        subcat = "midi editor",
    },
    editor_type = {
        mask = 3, -- &1 and &2, One MIDI editor per; 00=media item; 01=track; 10=project
        name = "One MIDI editor per",
        options = { "One MIDI editor per media item", "One MIDI editor per track", "One MIDI editor per project" },
    }, -- how to get the value
    behavior_type = {
        mask = 20, -- &4, (and &16,) Behavior for "open items in built-in MIDI editor
        name = "Behavior for `open items in built-in MIDI editor`",
        options = {
            "Open clicked MIDI item only",
            "Open all selected MIDI items",
            "Open all MIDI on the same track",
            "Open all MIDI in the project",
        },
    },
    -- &32=0/1, Close editor when the active item is deleted in the arrange
    -- view
    close_upon_item_deletion = { mask = 32, name = "Close editor when the active item is deleted in the arrange" },
    -- &128=0/1, Active MIDI item follows selection changes in arrange
    -- view
    active_item_follows_selection = { mask = 128 },
    -- &256=0/1, Only MIDI items on the same track as the active item are
    -- editable
    other_tracks_editable = { mask = 256 },
    -- &512=0/1, Selection is linked to editability(also MIDI-Editor-action 40891)
    editability = {
        -- NOTE: For proper Midi Editor source management, this should be OFF
        mask = 512,
    },
    -- &1024=0/1, Media item selection is linked to visibility
    visibility = {
        -- NOTE: For proper Midi Editor source management, this should be OFF
        mask = 1024,
    },
    -- &2048=0/1, All media items are editable in notation view(MIDI Editor ->
    -- Contents -> Behavior for "open items in built-in MIDI Editor")
    all_items_are_editable_in_notation_view = { mask = 2048 },
    -- &4096=0/1, Make secondary items editable by default
    secondary_items_editable_by_default = { mask = 4096 },
}

local M = {}

M.preferences_raw = p

M.make = function(key)
    return Config:new(key, p[key])
end

M.all = function()
    local ret = {}
    for key, _ in pairs(p) do
        ret[key] = M.make(key)
        -- log.user("KEY=",ret[key])
    end
    return ret
end

M.picker_friendly = function()
    local ac = M.all()
    -- log.user(format.block(ac))
    local pickable_config_result_entries = {}
    for key, def in pairs(p) do
        -- log.user(format.block(ac[key]))
        for j, cfg_var in pairs(def) do
            if not j:match("^%_") then
                if ac[key] then
                    local real_val = ac[key][j]

                    local is_mult = ac[key]:is_mult(j)

                    table.insert(pickable_config_result_entries, {
                        config = ac[key], -- BUG: Why is this always nil, except for maybe the first iteration?
                        key = key,
                        real_value = real_val,
                        cat = def._meta.cat,
                        subcat = def._meta.subcat,
                        var_name = j,
                        var_def = cfg_var,
                        is_mult = is_mult,
                    })
                else
                    log.user("No AC obj for key = ", key)
                end
            end
        end
    end
    log.user("results", format.block(pickable_config_result_entries))
    return pickable_config_result_entries
end

return M
