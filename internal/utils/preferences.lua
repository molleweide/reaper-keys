local log = require("utils.log")
local format = require("utils.format")

local p = {}

--- Helper class making working with reaper preference variable integer
--- bitfields easier.
--- @class Config
--- @field name string: The reaper preference string key.
--- @field config number The raw integer bitfield number.
--- @field options table Holding each option.
local Config = {}

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

local mt = {
    -- FIX: right shift values so that I get the real preference value.
    __index = function(self, key)
        if self.options[key] then
            local op = self.options[key][1]
            local flag = self.options[key][2]
            if op == "mod" then
                return (self.config % flag) >> flag
            elseif op == "and" then
                return (self.config & flag) >> flag
            end
        end
        return nil
    end,

    __tostring = function(self)
        -- TODO: print the real flag values, instead of 0/128
        local res = {}
        for k, v in pairs(self.options) do
            local op = { name = k, value = self[k] }
            table.insert(res, op)
        end
        return format.block(res)
    end,
}

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

    setmetatable(c, mt)
    self.__index = self
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
    return self.options[key][3] == nil
end

function Config:_is_mult(key)
    return self.options[key][3] ~= nil
end

function Config:_set_single(key, newval)
    if self:_is_toggle(key) then
        if newval == 0 or newval == 1 then
            -- set value
        end
    elseif self:_is_mult(key) then
        local min = self.options[key][3][1]
        local max = self.options[key][3][2]
        if min <= newval and newval <= max then
            -- set value
        end
    end
end

--- I took this func from chat gpt
function Config:toggle(key)
    if self:_is_toggle(key) then
        self.config = self.config ~ (1 << self.options[key][2])
    end
end

-- FIX: safe checks!!!
-- First verify all keys exist.
-- Second, ensure that all values lie within correct range.
-- Third, go ahead and set values.
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
        self.config = self.config | (1 << self.options[key][2])
    end
end

-- FIX: [2] should be a key called position.

function Config:disable(key)
    if self:_is_toggle(key) then
        self.config = self.config & ~(1 << self.options[key][2])
    end
end

-- TODO: Understand how this works!!

-- Function to cycle a two-bit flag at a given position
-- @param bitfield number: The integer bitfield
-- @param position number: The starting position of the two-bit flag (0-based)
-- @return number: The modified bitfield with the flag cycled
local function cycle_flag(bitfield, position) end

function Config:cycle(key, reverse)
    if self:_is_mult(key) then
        local position = self.options[key][2]
        local bitfield = self.config
        -- Extract the two-bit flag
        local mask = 3 << position -- Mask for two bits
        local flag = (bitfield & mask) >> position
        -- Cycle the flag
        if reverse then
            flag = (flag - 1) % 3 -- Cycle through 2, 1, 0
            if flag < 0 then
                flag = 2
            end
        else
            flag = (flag + 1) % 3 -- Cycle through 0, 1, 2
        end
        -- Clear the original flag and set the new flag
        self.config = (bitfield & ~mask) | (flag << position)
    end
end

-----------------------------------------------------------------------------
-- wrap each preference

p.midieditor = function()
    return Config:new("midieditor", {
        -- &1 and &2, One MIDI editor per; 00=media item; 01=track; 10=project
        -- NOTE: Using modulo 4 extracts range lower two bits
        editor_type = { "mod", 4, { 0, 2 } }, -- how to get the value
        -- &4, (and &16,) Behavior for "open items in built-in MIDI editor
        --   11, Open clicked MIDI item only
        --   00, Open all selected MIDI items
        --   01, Open all MIDI on the same track
        --   10, Open all MIDI in the project
        --   NOTE: Bitmas `&` only checks if 10100 is present or not
        behavior_type = { "and", 20, { 0, 3 } },
        -- &32=0/1, Close editor when the active item is deleted in the arrange
        -- view
        close_upon_item_deletion = { "and", 32 },
        -- &128=0/1, Active MIDI item follows selection changes in arrange
        -- view
        active_item_follows_selection = { "and", 128 },
        -- &256=0/1, Only MIDI items on the same track as the active item are
        -- editable
        other_tracks_editable = { "and", 256 },
        -- &512=0/1, Selection is linked to editability(also MIDI-Editor-action 40891)
        editability = { "and", 512 },
        -- &1024=0/1, Media item selection is linked to visibility
        visibility = { "and", 1024 },
        -- &2048=0/1, All media items are editable in notation view(MIDI Editor ->
        -- Contents -> Behavior for "open items in built-in MIDI Editor")
        all_items_are_editable_in_notation_view = { "and", 2048 },
        -- &4096=0/1, Make secondary items editable by default
        secondary_items_editable_by_default = { "and", 4096 },
    })
end

return p
