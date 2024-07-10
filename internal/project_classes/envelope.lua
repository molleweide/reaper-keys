-----------------------------------------------------------------------------
-- ENVELOPE
--

local JEnvelope = {}
JEnvelope.mt = {}
JEnvelope.prototype = { category = 0, _parent = false }

function JEnvelope:new(o)
    local o = o or {}
    setmetatable(o, JEnvelope.mt)
    return o
end

---
---
---
JEnvelope.mt.__index = function(self, key)
    --    if TRACK_SEND_GET_INFO_VALUES[key] ~= nil then
    --        if not self.iSend then
    -- 		jError("JEnvelope not initialized", J_ERROR_ERROR)
    --            return false
    --        end
    --        return reaper.GetTrackSendInfo_Value(self:getTrack():getReaperTrack(), self.category, self.iSend, TRACK_SEND_GET_INFO_VALUES[key])
    -- elseif key == "name" then
    -- 	local _, v = reaper.GetTrackSendName(self:getTrack():getReaperTrack(), self.iSend, "")
    -- 	return v
    -- elseif JEnvelope.prototype[key] ~= nil then
    -- 	return JEnvelope.prototype[key]
    -- else
    -- 	jError("JEnvelope key: ''" .. key .. "'' is not a GET property", J_ERROR_ERROR)
    -- 	return false
    --    end
end

---
---
---
JEnvelope.mt.__newindex = function(self, key, value)
    --    if TRACK_SEND_SET_INFO_VALUES[key] ~= nil then
    --        if not self.iSend then
    -- 		jError("JEnvelope not initialized", J_ERROR_ERROR)
    --            return false
    --        end
    --        reaper.SetTrackSendInfo_Value(self:getTrack():getReaperTrack(), self.category, self.iSend, TRACK_SEND_GET_INFO_VALUES[key], value)
    -- elseif JItem.prototype[key] ~= nil then
    -- 	rawset(self, key, value)
    -- else
    -- 	jError("JEnvelope key: ''" .. key .. "'' is not a SET property", J_ERROR_ERROR)
    -- 	return false
    -- end
end

---
---
---
function JEnvelope.prototype:getTrack() -- Returns the track the envelope belongs to
    -- return self._parent -- This used to return self._partent.pTrack but its better if it just returns the track instead of the pTrack
end

---
---
---
function JEnvelope.prototype:delete()
    -- local r = reaper.RemoveTrackSend(self:getTrack():getReaperTrack(), self.category, self.iSend)
    -- if not r then
    -- 	jError("Deleting send failed, index: " .. self.iSend, J_ERROR_ERROR)
    -- end
    -- return r
end

---Iterator to go through all the takes in the item
---start: nth selected item to start at to start at. First one is 0.
---num: (maximum) amount of items to return
function JEnvelope.prototype:points(start, num)
    local i = start or 0
    local n = 0
    if num and i + num <= self.takecount then
        n = i + num
    else
        n = self.takecount
    end
    return function()
        i = i + 1
        if i <= n then
            return self:getTake(i - 1)
        end
    end
end

return JEnvelope
