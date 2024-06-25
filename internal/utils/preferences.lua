local log = require("utils.log")
local format = require("utils.format")

local p = {}

local Config = {}
local mt = {
    -- is self refering to the base table here?
    __index = function(self, key)
        if self.options[key] then
            local op = self.options[key][1]
            local flag = self.options[key][2]
            if op == "mod" then
                return self.config % flag
            elseif op == "and" then
                return self.config & flag
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
function Config:new(o)
  local c = {}
    if o.options == nil then
        c.options = {}
    end
    for k, v in pairs(o) do
        c.options[k] = v
    end
    c.config = reaper.SNM_GetIntConfigVar("midieditor", 0)
    setmetatable(c, mt)
    self.__index = self
  -- log.user(format.block(o))
    return c
end

function Config:raw()
    return self.config
end

--- Returns a list of each option/flag for use with eg. pickers.
function Config:to_list()
    return self.config
end

--- Applies the config, eg if you have made modifications to the flags
function Config:apply()
    reaper.SNM_SetIntConfigVar("midieditor", self.config)
end

function Config:_is_toggle(key)
    return rawget(self, key)[3] == nil
end

function Config:_is_mult(key)
    return rawget(self, key)[3] ~= nil
end

function Config:toggle(key)
    if self:_is_toggle(key) then
        self.config = self.config - self[key] + rawget(self, key)[2]
        return true
    end
end

function Config:set(key, newval)
    if type(key) == "table" then
    else
        -- if is_mult(self, key) then
        -- elseif is_toggle(self, key) then
        -- end
    end
end

function Config:enable(key)
    -- if is_toggle(self, key) then
    --     -- ..
    -- new_config = new_config - cfg.active_item_follows_selection + 128

    --     return true
    -- end
end

function Config:disable(key)
    -- if is_toggle(self, key) then
    --     -- ..
    --     return true
    -- end
end

function Config:cycle(key, do_backwards)
    -- if is_mult(self, key) then
    --   if not do_backwards then
    --   -- forward
    --   else
    -- elseif is_toggle(self, key) then
    --       -- backwards
    --   end
    -- end
end

-----------------------------------------------------------------------------
-- wrap each preference

p.midieditor = function()
  log.user("make midi editor config")
    return Config:new({
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
