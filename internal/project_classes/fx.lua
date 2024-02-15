-----------------------------------------------------------------------------
-- FX
-- This is an FX class. It can be created bt a Track class. It holds a
-- reference to its parent Track class. It should be noted that in reaper an
-- actual effect is linked to a JTrack. I.e. an FX can't excist without its
-- parent JTrack. Here an instance of this FX class could still live while its
-- parent track was deleted. It wouldnt know. However when calling most
-- functions in this class the pointer to the parent track would be pointing to
-- nothing which will result in errors. Because there are some usages
-- advantages to having a seperate FX class this implementation was chosen.
-- Mostly because it makes it a lot easier to find a certain fx (either by name
-- or index) and then do multiple things with this JFx.
--

JFx = {}
JFx.mt = {}
JFx.prototype = {iFx = false, _parent = false}

function JFx:new(o)
    local o = o or {}
    setmetatable(o, JFx.mt)
    return o
end

JFx.mt.__index = function (self, key, args)
    -- msg("looking in fx for: " .. key)
    -- msg(table._parent.pTrack)
    if key == "name" then
		local _, r = reaper.TrackFX_GetFXName(self:getTrack():getReaperTrack(), self.iFx, "")
		return r
	elseif key == "paramcount" then
		return reaper.TrackFX_GetNumParams(self:getTrack():getReaperTrack(), self.iFx)
	elseif key == "enabled" then
		return reaper.TrackFX_GetEnabled(self:getTrack():getReaperTrack(), self.iFx)
	end
    return JFx.prototype[key]
end

JFx.mt.__newindex = function (self, key, value)
	if key == "enabled" then
		return reaper.TrackFX_SetEnabled(self:getTrack():getReaperTrack(), self.iFx, value)
    else
        rawset(table, key, value)
    end
end

function JFx.prototype:getTrack()
	-- Returns the reaper MediaTrack pointer to the track that the FX belongs to
	-- TODO?: Should this remain a direct access or should this turn into a function that also checks if the track still exists?
	-- TODO?: Should this not just return a JTrack object?
	return self._parent
end

function JFx.prototype:show(showFlag)
	-- Shows the floating window.
	-- Showflag can be used to use reaper functionality to show it with the chain (or even to hide it)
	showFlag = showFlag or 3
	reaper.TrackFX_Show(self:getTrack():getReaperTrack(), self.iFx, showFlag)
	return true
end

function JFx.prototype:hide()
	reaper.TrackFX_Show(self:getTrack():getReaperTrack(), self.iFx, 2)
	return true
end

function JFx.prototype:getParam(iParam)
	-- Get an fx parameter by number, 0 for the first
	-- Returns number retval, number minval, number maxval
	--[[ SAFETY CHECK?
	if iParam >= self.paramcount then
		jError("JFx:getParam(), effect param not found, iParam: " .. tostring(iParam), J_ERROR_WARNING)
		return false
	end
	]]
	retval, minval, maxval = reaper.TrackFX_GetParam(self:getTrack():getReaperTrack(), self.iFx, iParam)
	local p = JParam:new({iParam = iParam, value = retval, minval = minval, maxval = maxval, _parent = self})
	return p
end

function JFx.prototype:setParam(iParam, value)
	-- Directly set an FX's parameter, can be handy sometimes
	return reaper.TrackFX_SetParam(self:getTrack():getReaperTrack(), self.iFx, iParam, value)
end

function JFx.prototype:params(start, num)
	-- Iterator to go through all the tracks in the project
	-- start: index of the track to start at
	-- num: (maximum) amount of track to return
	local i = start or 0
	local n = 0
	if num and i + num <= self.paramcount then
		n = i + num
	else
		n = self.paramcount
	end

	return function ()
		i = i + 1
		if i <= n then
			return self:getParam(i-1)
		end
	end
end

function JFx.prototype:getParamsByName(sPattern, iInstance, find_init, find_plain)
    -- Search by name
	-- sPattern: Specify pattern to look for
	-- iInstance: leave empty (or false) to get a TABLE of all the tracks that match the pattern. Specify a number > 0 to get the nth track that matches
	-- The default searches from the first character (find_init = 1) and uses plain string (find_plain = true). See Lua's string.find() for more info

	local iInstance = iInstance or false
	local find_init = find_init or 1
	local find_plain = find_plain or true

    local tResult = {}
    local iCount = 0

	if type(iInstance) == "number" and iInstance <= 0 then
		jError("JFx:getParamsByName(), instance <= 0. First instance is 1! iInstance: " .. tostring(iInstance), J_ERROR_ERROR)
		return false
	end

    local iTracks = self.trackcount

	for t in self:params() do
		if t.name:lower():find(sPattern:lower(), find_init, find_plain) then
			iCount = iCount + 1
            if iInstance == false then
                tResult[#tResult + 1] = t
            elseif iInstance == iCount then
                return t
            end
        end
    end

    if not iInstance then
        -- return table
        if #tResult == 0 then
            return false
        else
            return tResult
        end
    else
        -- instance not found
        return false
    end
end


