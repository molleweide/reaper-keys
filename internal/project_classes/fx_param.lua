local JParam = {}
JParam.mt = {}
JParam.prototype = {iParam = false, _parent = false}

function JParam:new(o)
    local o = o or {}
    setmetatable(o, JParam.mt)
    return o
end

JParam.mt.__index = function (self, key, args)
    -- msg("looking in fx for: " .. key)
    --msg(table._parent.pTrack)
    if key == "name" then
		local _, r = reaper.TrackFX_GetParamName(self:getTrack(), self:getFx(), self.iParam, "")
		return r
    end
    return JParam.prototype[key]
end

function JParam.prototype:getTrack()
	-- Returns the reaper MediaTrack pointer to the track that the FX belongs to for which this is a paramater
	return self._parent:getTrack() -- Returns parent FX
end

function JParam.prototype:getFx()
	-- Returns the index of the FX for which this is a paramater
	return self._parent.iFx
end

function JParam.prototype:set(value)
	-- Set the parameter
	-- Returns reaper's bolean value for succes or not
	return reaper.TrackFX_SetParam(self:getTrack():getReaperTrack(), self:getFx(), self.iParam, value)
end

function JParam.prototype:setNormalized(value)
	-- Set the NORMALIZED parameter
	-- Returns reaper's bolean value for succes or not
	return reaper.TrackFX_SetParamNormalized(self:getTrack():getReaperTrack(), self:getFx(), self.iParam, value)
end


