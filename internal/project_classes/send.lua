
-----------------------------------------------------------------------------
-- SEND
--

local JSend = {}
JSend.mt = {}
JSend.prototype = {iSend = false, category = 0, _parent = false}

function JSend:new(o)
    local o = o or {}
    setmetatable(o, JSend.mt)
    return o
end

---
---
---
JSend.mt.__index = function (self, key)
    if TRACK_SEND_GET_INFO_VALUES[key] ~= nil then
        if not self.iSend then
			jError("JSend not initialized", J_ERROR_ERROR)
            return false
        end
        return reaper.GetTrackSendInfo_Value(self:getTrack():getReaperTrack(), self.category, self.iSend, TRACK_SEND_GET_INFO_VALUES[key])
	elseif key == "name" then
		local _, v = reaper.GetTrackSendName(self:getTrack():getReaperTrack(), self.iSend, "")
		return v
	elseif JSend.prototype[key] ~= nil then
		return JSend.prototype[key]
	else
		jError("JSend key: ''" .. key .. "'' is not a GET property", J_ERROR_ERROR)
		return false
    end

end

---
---
---
JSend.mt.__newindex = function (self, key, value)
    if TRACK_SEND_SET_INFO_VALUES[key] ~= nil then
        if not self.iSend then
			jError("JSend not initialized", J_ERROR_ERROR)
            return false
        end
        reaper.SetTrackSendInfo_Value(self:getTrack():getReaperTrack(), self.category, self.iSend, TRACK_SEND_GET_INFO_VALUES[key], value)
	elseif JItem.prototype[key] ~= nil then
		rawset(self, key, value)
	else
		jError("JSend key: ''" .. key .. "'' is not a SET property", J_ERROR_ERROR)
		return false
	end
end

---
---
---
function JSend.prototype:getTrack() -- Returns the track the send belongs to
	return self._parent -- This used to return self._partent.pTrack but its better if it just returns the track instead of the pTrack
end

---
---
---
function JSend.prototype:getDestTrack()
	return JTrack:new(reaper.BR_GetMediaTrackSendInfo_Track(self:getTrack():getReaperTrack(), 0, self.iSend, 1))
end

---
---
---
function JSend.prototype:delete()
	local r = reaper.RemoveTrackSend(self:getTrack():getReaperTrack(), self.category, self.iSend)
	if not r then
		jError("Deleting send failed, index: " .. self.iSend, J_ERROR_ERROR)
	end
	return r
end

return JSend
