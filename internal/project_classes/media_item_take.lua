-----------------------------------------------------------------------------
-- MEDIA ITEM TAKE
--

local JTake = {}
JTake.prototype = {pTake = false, _parentItem = false}
JTake.mt = {}

function JTake:new(o)
    local o = o or {}
    setmetatable(o, JTake.mt)
    return o
end

JTake.mt.__index = function (self, key)
    if MEDIA_ITEM_TAKE_GET_INFO_VALUES[key] ~= nil then
        if not self.pTake then
			msg("Take not initialized!")
            return false
		end
        return reaper.GetMediaItemTakeInfo_Value(self.pTake, MEDIA_ITEM_TAKE_GET_INFO_VALUES[key])
	elseif MEDIA_ITEM_TAKE_GET_SET_INFO_STRINGS[key] ~= nil then
		if not self.pTake then
			msg("Take not initialized!")
			return false
		end
		local retval, val = reaper.GetSetMediaItemTakeInfo_String(self.pTake, MEDIA_ITEM_TAKE_GET_SET_INFO_STRINGS[key], "", false)
		return val
	elseif key == "stretchmarkercount" then
         return reaper.GetTakeNumStretchMarkers(self.pTake)
    end

    return JTake.prototype[key]

end

JTake.mt.__newindex = function (table, key, value)
    if MEDIA_ITEM_TAKE_SET_INFO_VALUES[key] ~= nil then
        if not table.pTake then
            msg("Take not initialized!")
            return false
        end
		reaper.SetMediaItemTakeInfo_Value(table.pTake, MEDIA_ITEM_TAKE_SET_INFO_VALUES[key], value)
	elseif MEDIA_ITEM_TAKE_GET_SET_INFO_STRINGS[key] ~= nil then
        if not table.pTake then
            --msg("Track not initialized!")
            return false
        end
        reaper.GetSetMediaItemTakeInfo_String(table.pTake, MEDIA_ITEM_TAKE_GET_SET_INFO_STRINGS[key], value, true)
    else
        rawset(table, key, value)
    end
end

function JTake.prototype:getReaperTake()
	return self.pTake
end

function JTake.prototype:getItem()
	return self._parentItem
end

function JTake.prototype:getStretchMarker(idx)
	local idx = idx or 0
	local retval, pos, srcpos = reaper.GetTakeStretchMarker(self.pTake, idx)
	if retval >= 0 then
		local sm = JStretchMarker:new({iStretchMarker = idx, pos = pos, srcpos = srcpos, _parentTake = self})
		return sm
	else
		msg("Trying to get stretchmarker that doesn't exist, idx: " .. idx .. ", pTake: " .. tostring(self.pTake))
	end
end

function JTake.prototype:getStretchMarkers(start, num)
	-- Iterator to go through all the takes in the item
	-- start: nth selected item to start at to start at. First one is 0.
	-- num: (maximum) amount of items to return
	local i = start or 0
	local n = 0
	if num and i + num <= self.stretchmarkercount then
		n = i + num
	else
		n = self.stretchmarkercount
	end

	return function ()
		i = i + 1
		if i <= n then
			return self:getStretchMarker(i-1)
		end
	end
end

function JTake.prototype:addStretchMarker(p, srcp)
	local r = reaper.SetTakeStretchMarker(self.pTake, -1, p, srcp)
	if r >= 0 then
		return self:getStretchMarker(r)
	else
		msg("Could not insert stretchmarker")
		return false
	end
end

function JTake.prototype:deleteStretchMarkers(idx, num)
	return reaper.DeleteTakeStretchMarkers(self.pTake, idx, num)
end

function JTake.prototype:deleteAllStretchMarkers()
	return reaper.DeleteTakeStretchMarkers(self.pTake, 0, self.stretchmarkercount)
end

function JTake.prototype:addFx(sFxName)
	-- Inserts an effect by name. If succesful returns the fx index (number)

	local r = reaper.TakeFX_AddByName(self.pTake, sFxName, -1)
	if r >= 0 then
		return r
	else
		return false
	end
end


return JTake
