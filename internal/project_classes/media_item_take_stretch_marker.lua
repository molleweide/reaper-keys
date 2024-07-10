-----------------------------------------------------------------------------
-- MEDIA ITEM TAKE STRETCH MARKER
--

local JStretchMarker = {}
JStretchMarker.prototype = {iStretchMarker = false, pos = false, srcpos = false, _parentTake = false}
JStretchMarker.mt = {}

function JStretchMarker:new(o)
    local o = o or {}
    setmetatable(o, JStretchMarker.mt)
    return o
end

JStretchMarker.mt.__index = function (self, key)
	if key == "slope" then
		return reaper.GetTakeStretchMarkerSlope(self._parentTake.pTake, self.iStretchMarker)
    end

    return JStretchMarker.prototype[key]

end

function JStretchMarker.prototype:set(p, srcp)
	if srcp then
		self.pos = p
		self.srcpos = srcp
		return reaper.SetTakeStretchMarker(self._parentTake.pTake, self.iStretchMarker, p, srcp)
	else
		self.pos = p
		return reaper.SetTakeStretchMarker(self._parentTake.pTake, self.iStretchMarker, p)
	end
end

function JStretchMarker.prototype:getTake()
	return self._parentTake
end

function JStretchMarker.prototype:isFirst()
	return self.iStretchMarker == 0
end

function JStretchMarker.prototype:isLast()
	return self.iStretchMarker == self._parentTake.stretchmarkercount - 1
end
--[[
JStretchMarker.mt.__newindex = function (table, key, value)
	if key == "pos" then
		self.pos = value
		return reaper.SetTakeStretchMarker(self._parentTake, self._iStretchMarker, self.pos, self.srcpos)
    else
        rawset(table, key, value)
    end
end
]]


return JStretchMarker
