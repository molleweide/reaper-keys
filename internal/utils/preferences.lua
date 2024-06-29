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

-- View: Toggle show media cues in items as triggered by action 40691(in sections Main, Media Explorer, MIDI Editor, MIDI Eventlist Editor, MIDI Inline Editor)
-- It is an integer, actions variable.
--
-- Can be affected by the following actions:
--   View: Toggle show media cues in items
--
-- >0, togglestate off
-- >1, togglestate on
--
-- Stored in reaper.ini under the same name in the section REAPER.
-- p.cueitems = {
--     cat = "actions",
--     mask = 5,
-- }

-- View: Toggle show/hide item  labels
-- It is an integer, actions variable.
--
-- Can be affected by the following actions:
--   View: Toggle show/hide item labels
--
-- >0, action is toggled on
-- >1, action is toggled off
--
-- Stored in reaper.ini under the same name in the section REAPER.
-- p.itemtexthide = {
--     cat = "actions",
-- }

-------------------------------------------------------------------------------
-- ENVELOPE MANAGER -----------------------------------------------------------
-------------------------------------------------------------------------------

-- Several settings, as set in the context-menu of the envelope manager
-- It is an integer, project variable.
--
-- >&1=0, Target Envelope manager when clicking track/take envelope buttons(shift+click to override) - unchecked
-- >&1=1, Target Envelope manager when clicking track/take envelope buttons(shift+click to override) - checked
--
-- Stored in reaper.ini under the same name in the section REAPER, when Save as default project settings has been clicked.
-- p.envmgropts = { cat = "envelope manager" }

-------------------------------------------------------------------------------
-- HELP -----------------------------------------------------------------------
-------------------------------------------------------------------------------

-- Stores the settings for the help-information-display under the TCP, as set
-- in it's accompanying context-menu, as well the performance meter
-- window-context menu. It is an integer/integer-bitfield, help variable.
--
-- >Only one of the following can be set:
--    0, No information display
--    1, Reaper tips
--    2, Track/item count
--    3, selected track/item/envelope details
--    4, CPU/RAM use, time since last save
--
-- >This one can be set all the times:
--    &65536=0, Show mouse editing-help(on), checked
--    &65536=1, Show mouse editing-help(off), unchecked
--
-- >Context-menu in performane meter display:
--    &131072=0, &262144=0, Display CPU utilization as 100% = all cores fully utilized
--    &131072=1, &262144=0, Display CPU utilization as 1.0c = 1 core fully utilized
--    &131072=1, &262144=1, Display CPU utilization as 1.0! = longest block is realtime (worst case)
p.help = {
    _meta = { cat = "help menu", subcat = "help" },
    show_mouse_editing = {
        mask = 65536,
        name = "show mouse editing",
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

-------------------------------------------------------------------------------
-- MISC -> MIDI
-------------------------------------------------------------------------------
--
--

-------------------------------------------------------------------------------
-- PREFERENCES (reaper preferences panel UI)
-------------------------------------------------------------------------------

--
-- PREFERENCES -> APPEARANCE
--

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
