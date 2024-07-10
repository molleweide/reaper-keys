local JTake = require("project_classes.media_item_take")
-----------------------------------------------------------------------------
-- MEDIA ITEM
--

local JItem = {}
JItem.prototype = {pItem = false}
JItem.mt = {}

function JItem:new(o)
    local o = o or {}
    setmetatable(o, JItem.mt)
    return o
end

JItem.mt.__index = function (self, key)
    if MEDIA_ITEM_GET_INFO_VALUES[key] ~= nil then
        if not self.pItem then
			jError("JItem not initialized", J_ERROR_ERROR)
            return false
        end
        return reaper.GetMediaItemInfo_Value(self.pItem, MEDIA_ITEM_GET_INFO_VALUES[key])
	elseif MEDIA_ITEM_GET_SET_INFO_STRINGS[key] ~= nil then
		if not self.pItem then
			jError("JItem not initialized", J_ERROR_ERROR)
			return false
		end
		local retval, val = reaper.GetSetMediaItemInfo_String(self.pItem, MEDIA_ITEM_GET_SET_INFO_STRINGS[key], "", false)
		return val
	elseif key == "takecount" then
		return reaper.GetMediaItemNumTakes(self.pItem)
	-- end
	elseif JItem.prototype[key] ~= nil then
		return JItem.prototype[key]
	else
		jError("JItem key: ''" .. key .. "'' is not a GET property", J_ERROR_ERROR)
		return false
    end

    -- return JItem.prototype[key]

end

JItem.mt.__newindex = function (table, key, value)
    if MEDIA_ITEM_SET_INFO_VALUES[key] ~= nil then
        if not table.pItem then
			jError("JItem not initialized", J_ERROR_ERROR)
            return false
        end
        reaper.SetMediaItemInfo_Value(table.pItem, MEDIA_ITEM_SET_INFO_VALUES[key], value)
	elseif MEDIA_ITEM_GET_SET_INFO_STRINGS[key] ~= nil then
        if not table.pItem then
			jError("JItem not initialized", J_ERROR_ERROR)
			return false
        end
        reaper.GetSetMediaItemInfo_String(table.pItem, MEDIA_ITEM_GET_SET_INFO_STRINGS[key], value, true)
	elseif JItem.prototype[key] ~= nil then
		rawset(table, key, value)
	else
		jError("JItem key: ''" .. key .. "'' is not a SET property", J_ERROR_ERROR)
		return false
	end
end

function JItem.prototype:getReaperItem()
	return self.pItem
end

function JItem.prototype:getTake(idx)
	local idx = idx or 0
	local ta = JTake:new({pTake = reaper.GetMediaItemTake(self.pItem, idx), _parentItem = self})
	return ta
end

function JItem.prototype:getActiveTake()
	local ta = JTake:new({pTake = reaper.GetActiveTake(self.pItem)})
	return ta
end

function JItem.prototype:getTakes(start, num)
	-- Iterator to go through all the takes in the item
	-- start: nth selected item to start at to start at. First one is 0.
	-- num: (maximum) amount of items to return
	local i = start or 0
	local n = 0
	if num and i + num <= self.takecount then
		n = i + num
	else
		n = self.takecount
	end

	return function ()
		i = i + 1
		if i <= n then
			return self:getTake(i-1)
		end
	end
end

function JItem.prototype:split(p)
	pItemRightHand = reaper.SplitMediaItem(self.pItem, p)
	if pItemRightHand ~= nil then
		return JItem:new({pItem = pItemRightHand})
	else
		--msg("Nothing was split...")
		return false
	end
end

function JItem.prototype:getTrack()
	return self._parent
end

function JItem.prototype:delete()
	local res = reaper.DeleteTrackMediaItem(self:getTrack():getReaperTrack(), self.pItem)
	self = nil
	return res
end

function JItem.prototype:getStateChunk()
	local r, str = reaper.GetItemStateChunk(self:getReaperItem(), "")
	if r then
		return str
	end
end

function JItem.prototype:setStateChunk(newChunk)
	local r = reaper.SetItemStateChunk(self:getReaperItem(), newChunk)
	return r
end

return JItem
