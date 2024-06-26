local log = require("utils.log")
local format = require("utils.format")
local su = require("utils.string")

local p = {}

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

-- config["x"] -> return real value, ie. [0, max]
-- config:toggle('x') -> toggle x if possible
-- config:set("x", val) -> set x to val if possible
-- tostring(config) -> return printable list of all vars and their value.
-- config:set({
--     key = val,
--     ...
-- }) -> if all keys passed are real keys, then go ahead and set, otherwise, return false.
-- config:cycle("x") -> try cycle increment values by one.
-- config:to_list() is basically the same as what __tostring does.

local mt = {}

--- Constructor
--- @param pref_key string Name of reaper preference variable. string: The name of the person
--- @param flags table Table with keys describing each flag
--- @return Config
function Config:new(pref_key, flags)
    local c = {}
    if c.options == nil then
        c.options = {}
    end
    for k, v in pairs(flags) do
        c.options[k] = v
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

-- Unnecessary, since __index already does this.
-- function Config:formatted(key)
--     -- instead of returning 0/128 it should return the real value for the
--     -- requested preference.
-- end

-- Unnecessary, since __tostring...
-- --- Returns a list of each option/flag for use with eg. pickers.
-- function Config:to_list()
--     return self.config
-- end

--- Applies the config, eg if you have made modifications to the flags
function Config:apply()
    reaper.SNM_SetIntConfigVar(self.name, self.config)
end

-- WARN: only checking for [3] is a bit unsafe..

function Config:_is_toggle(key)
    -- return self.options[key][3] == nil
    local bitmask = self.options[key].mask
    return bitmask > 0 and (bitmask & (bitmask - 1)) == 0
end

function Config:_is_mult(key)
    -- return self.options[key][3] ~= nil
    local bitmask = self.options[key].mask

    local count = 0
    while bitmask ~= 0 do
        count = count + (bitmask & 1)
        if count > 1 then
            return true
        end
        bitmask = bitmask >> 1
    end
    -- return count
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
-----------------------------------------------------------------------------
-- Wrap each preference
-----------------------------------------------------------------------------

p.midieditor = function()
    -- FIX: rename "name" to "descr"

    return Config:new("midieditor", {
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
    })
end

return p
