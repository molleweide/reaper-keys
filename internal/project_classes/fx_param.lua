local log = require("utils.log")
local format = require("utils.format")

local JParam = {}
JParam.mt = {}
JParam.prototype = { iParam = false, _parent = false }

-- TODO: Needs:
-- ~ get value -> do this with a getter but also with __index.
-- ~ should I be able to set values by __newindex

function JParam:new(o)
    local o = o or {}
    setmetatable(o, JParam.mt)
    return o
end

-- msg("looking in fx for: " .. key)
--msg(table._parent.pTrack)
JParam.mt.__index = function(self, key, args)
    if key == "name" then
        local _, r = reaper.TrackFX_GetParamName(self:getTrack():getReaperTrack(), self:getFx(), self.iParam, "")
        return r
    end
    return JParam.prototype[key]
end

-- Returns the reaper MediaTrack pointer to the track that the FX belongs to for which this is a paramater
function JParam.prototype:getTrack()
    return self._parent:getTrack() -- Returns parent FX
end

-- Returns the index of the FX for which this is a paramater
function JParam.prototype:getFx()
    return self._parent.iFx
end

-- Set the parameter
-- Returns reaper's bolean value for succes or not
function JParam.prototype:set(value)
    return reaper.TrackFX_SetParam(self:getTrack():getReaperTrack(), self:getFx(), self.iParam, value)
end

-- Set the NORMALIZED parameter
-- Returns reaper's bolean value for succes or not
function JParam.prototype:setNormalized(value)
    return reaper.TrackFX_SetParamNormalized(self:getTrack():getReaperTrack(), self:getFx(), self.iParam, value)
end

return JParam
