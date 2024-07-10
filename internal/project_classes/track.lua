-----------------------------------------------------------------------------
-- TRACK
-- This is a Track "class". It can be created by a Project class and is linked
-- to a track in reaper by its MediaTrack pointer.

local JTrack = { fx = {} }
JTrack.prototype = { pTrack = false, _parentProject = false }
JTrack.mt = {}

function JTrack:new(input)
    local o
    if type(input) == "table" then
        o = input
    elseif input == nil then
        o = {}
    else
        o = { pTrack = input }
    end
    setmetatable(o, JTrack.mt)
    return o
end

JTrack.mt.__index = function(self, key)
    if MEDIA_TRACK_GET_INFO_VALUES[key] ~= nil then
        if not self.pTrack then
            --msg("Track not initialized!")
            return false
        end
        return reaper.GetMediaTrackInfo_Value(self.pTrack, MEDIA_TRACK_GET_INFO_VALUES[key])
    elseif MEDIA_TRACK_GET_SET_INFO_STRINGS[key] ~= nil then
        if not self.pTrack then
            --msg("Track not initialized!")
            return false
        end
        local _, r = reaper.GetSetMediaTrackInfo_String(self.pTrack, MEDIA_TRACK_GET_SET_INFO_STRINGS[key], "", false)
        return r
    elseif key == "name" then
    -- needs an equivalent setter
        return reaper.GetTrackName(self.pTrack)
    elseif key == "fxcount" then
        return reaper.TrackFX_GetCount(self.pTrack)
    elseif key == "sendcount" then
        return reaper.GetTrackNumSends(self.pTrack, 0)
    elseif key == "receivecount" then
        return reaper.GetTrackNumSends(self.pTrack, -1)
    elseif key == "hardwareoutcount" then
        return reaper.GetTrackNumSends(self.pTrack, 1)
    elseif key == "itemcount" then
        return reaper.GetTrackNumMediaItems(self.pTrack)
    end

    return JTrack.prototype[key]
end

JTrack.mt.__newindex = function(table, key, value)
    if MEDIA_TRACK_SET_INFO_VALUES[key] ~= nil then
        if not table.pTrack then
            --msg("Track not initialized!")
            return false
        end
        reaper.SetMediaTrackInfo_Value(table.pTrack, MEDIA_TRACK_SET_INFO_VALUES[key], value)
    elseif MEDIA_TRACK_GET_SET_INFO_STRINGS[key] ~= nil then
        if not table.pTrack then
            --msg("Track not initialized!")
            return false
        end
        reaper.GetSetMediaTrackInfo_String(table.pTrack, MEDIA_TRACK_GET_SET_INFO_STRINGS[key], value, true)
    else
        rawset(table, key, value)
    end
end

---
---
---
function JTrack.prototype:getTrackGUID()
    return
end


---
---
---
function JTrack.prototype:getReaperTrack()
    return self.pTrack
end

---
---
---
function JTrack.prototype:getItem(idx)
    local i = reaper.GetTrackMediaItem(self:getReaperTrack(), idx)

    if not i then
        jError("JTrack:getItem(idx), returned false for idx: " .. tostring(idx), J_ERROR_WARNING)
        return false
    end
    return JItem:new({ pItem = i, _parent = self })
end

---
---
---
function JTrack.prototype:getFx(idx)
    -- Returns fx at position idx. Starts with 0.
    -- Returns false if there is no fx at that position
    -- SAFETY CHECK?
    if idx >= self.fxcount then
        jError("JTrack:getFx(idx), no fx idx: " .. tostring(idx), J_ERROR_WARNING)
        return false
    end

    return JFx:new({ iFx = idx, _parent = self })
end

---
---
---
function JTrack.prototype:getSend(idx)
    -- Returns send at position idx. Starts with 0.
    -- Returns false if there is no send at that position
    -- SAFETY CHECK?
    if idx >= self.sendcount then
        jError("JTrack:getSend(idx), no send idx: " .. tostring(idx), J_ERROR_WARNING)
        return false
    end

    return JSend:new({ iSend = idx, category = 0, _parent = self })
end

---
---
---
function JTrack.prototype:getInstrument()
    local r = reaper.TrackFX_GetInstrument(self.pTrack)
    if r >= 0 then
        return JFx:new({ iFx = r, _parent = self })
    else
        return false
    end
end

-- TODO: Need to test this one and see if it works on the name string or the raw
-- VST name?
---
---
---
function JTrack.prototype:getFxByName(sPattern, iInstance, find_init, find_plain)
    -- Search by name
    -- sPattern: Specify pattern to look for, case insensitive.
    -- iInstance: leave empty (or false) to get a TABLE of all the tracks that match the pattern. Specify a number >= 0 to get the nth track that matches
    -- The default searches from the first character (find_init = 1) and uses plain string (find_plain = true). See Lua's string.find() for more info

    local iInstance = iInstance or false
    local find_init = find_init or 1
    local find_plain = find_plain or true

    local tResult = {}
    local iCount = 0

    if type(iInstance) == "number" and iInstance <= 0 then
        jError(
            "JTrack:getFxByName(), instance <= 0. First instance is 1! iInstance: " .. tostring(iInstance),
            J_ERROR_ERROR
        )
        return false
    end

    local iTracks = self.fxcount

    for t in self:fx() do
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

---
---
---
function JTrack.prototype:getSendByName(sPattern, iInstance, find_init, find_plain)
    -- Search by name
    -- sPattern: Specify pattern to look for, case insensitive.
    -- iInstance: leave empty (or false) to get a TABLE of all the tracks that match the pattern. Specify a number >= 0 to get the nth track that matches
    -- The default searches from the first character (find_init = 1) and uses plain string (find_plain = true). See Lua's string.find() for more info
    -- When a table is requested it will be returned in reverse order

    local iInstance = iInstance or false
    local find_init = find_init or 1
    local find_plain = find_plain or true

    local tResult = {}
    local iCount = 0

    if type(iInstance) == "number" and iInstance <= 0 then
        jError(
            "JTrack:getSendByName(), instance <= 0. First instance is 1! iInstance: " .. tostring(iInstance),
            J_ERROR_ERROR
        )
        return false
    end

    local iTracks = self.sendcount

    for t in self:sends() do
        if t.name:lower():find(sPattern:lower(), find_init, find_plain) then
            iCount = iCount + 1
            if iInstance == false then
                -- tResult[#tResult + 1] = t
                table.insert(tResult, 1, t) -- Reverse the order, this makes sense when deleting
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

---Iterator to go through all the fx on the track
---start: index of the track to start at
---num: (maximum) amount of track to return
function JTrack.prototype:fx(start, num)
    local i = start or 0
    local n = 0
    if num and i + num <= self.fxcount then
        n = i + num
    else
        n = self.fxcount
    end

    return function()
        i = i + 1
        if i <= n then
            return self:getFx(i - 1)
        end
    end
end

function JTrack.prototype:get_all_fx()
  local res = {}
    for t in self:fx() do
        table.insert(res, t)
    end
    return res
end



---Iterator to go through all the sends on the track
---start: index of the track to start at
---num: (maximum) amount of track to return
function JTrack.prototype:sends(start, num)
    local i = start or 0
    local n = 0
    if num and i + num <= self.sendcount then
        n = i + num
    else
        n = self.sendcount
    end

    return function()
        i = i + 1
        if i <= n then
            return self:getSend(i - 1)
        end
    end
end

---Iterator to go through all the items on a tracks
---start: nth selected track to start at to start at. First one is 0.
---num: (maximum) amount of track to return
---returnTable: to true to get the whole table instead of iterator
function JTrack.prototype:items(start, num, returnTable)
    local returnTable = returnTable or false

    local i = start or 0
    local n = 0
    if num and i + num <= self.itemcount then
        n = i + num
    else
        n = self.itemcount
    end

    local itemTable = {}
    for j = i, n - 1 do
        table.insert(itemTable, self:getItem(j))
    end

    if returnTable then
        return itemTable
    else
        i = 0
        return function()
            i = i + 1
            if i <= n then
                return itemTable[i]
            end
        end
    end
end

function JTrack.prototype:get_all_items()
  local res = {}
    for t in self:items() do
        table.insert(res, t)
    end
    return res
end


---
---
---
function JTrack.prototype:addFx(sFxName, recFx)
    -- Inserts an effect by name. If succesful returns the fx (class)

    local bRecFx = recFx or false
    local r = reaper.TrackFX_AddByName(self.pTrack, sFxName, bRecFx, -1)
    if r >= 0 then
        return self:getFx(r)
    else
        return false
    end
end

---
---
---
function JTrack.prototype:addSend(tDest)
    local r = reaper.CreateTrackSend(self.pTrack, tDest:getReaperTrack())
    if r >= 0 then
        return self:getSend(r)
    else
        return false
    end
end

---
---
---
function JTrack.prototype:getParentTrack()
    local r = reaper.GetParentTrack(self.pTrack)
    if r then
        return JTrack:new({ pTrack = r, _parentProject = self._parentProject })
    else
        return false
    end
end

---
---
---
function JTrack.prototype:getTopParentTrack()
    -- If this track is a child of a child track (so in a subgroup) this function will return the highest group parent
    -- If this track is not part of any group it will return the track itself

    local parent = self:getParentTrack()
    local topMost = false
    while parent do
        topMost = parent
        parent = parent:getParentTrack()
    end

    if topMost then
        return topMost
    else
        return self
    end
end

---
---
---
function JTrack.prototype:getLastRelatedChildTrack()
    if not self:isChildTrack() and not self:isParentTrack() then
        return self
    end

    local topMostParent = self:getTopParentTrack()
    return topMostParent:getChildTracks(false, true, true)
end

---
---
---
function JTrack.prototype:isParentTrack()
    return self.folderdepth == 1
end

---
---
---
function JTrack.prototype:isChildTrack()
    return reaper.GetParentTrack(self.pTrack) ~= nil
end

---
---
---
function JTrack.prototype:getNextTrack()
    return self._parentProject:getTrack(self.tracknumber)
end

---
---
---
function JTrack.prototype:getChildTracks(returnTable, recursive, returnOnlyLastTrack)
    local returnTable = returnTable or false
    local recursive = recursive or false
    local returnOnlyLastTrack = returnOnlyLastTrack or false

    if not self:isParentTrack() then
        jError("getChildTracks(): not a parent track", J_ERROR_NOTICE)
        if returnTable or returnOnlyLastTrack then -- Must check otherwise expecting an iterator
            return false
        else
            return function() end
        end
    end

    local tChildren = {}
    local nextTrack = self:getNextTrack()
    local iLevel = 1
    while nextTrack do
        -- Keep a score of entering folder tracks and leaving them
        iLevel = iLevel + nextTrack.folderdepth

        if recursive or iLevel - nextTrack.folderdepth == 1 then
            table.insert(tChildren, nextTrack)
        end
        if iLevel <= 0 then -- found the closing child
            if returnTable then
                return tChildren
            elseif returnOnlyLastTrack then
                return tChildren[#tChildren]
            else -- return iterator
                local i = 0
                return function()
                    i = i + 1
                    return tChildren[i]
                end
            end
        end
        nextTrack = nextTrack:getNextTrack()
    end

    jError(
        "getChildTracks(): did not find a closing track, it could be that the parent track is not properly closed.	",
        J_ERROR_ERROR
    )
    return false -- coult not find a closing child
end

---
---
---
function JTrack.prototype:getStateChunk(bIsUndo)
    local bIsUndo = bIsUndo or false
    local retval, str = reaper.GetTrackStateChunk(self.pTrack, "", bIsUndo)

    if not retval then
        jError("JTrack:getStateChunk() unsuccesful, return value: " .. tostring(retval), J_ERROR_NOTICE)
        return false
    else
        return str
    end
end

---
---
---
function JTrack.prototype:setStateChunk(strIn, bIsUndo)
    local bIsUndo = bIsUndo or false
    local retval = reaper.SetTrackStateChunk(self.pTrack, strIn, bIsUndo)

    if not retval then
        jError("JTrack:setStateChunk() unsuccesful, return value: " .. tostring(retval), J_ERROR_NOTICE)
    end
    return retval
end

-------------------------------------------------------------------------------
-- TRACK > ENVELOPES
--

---Iterator to go through all the envelopes on the track
function JTrack.prototype:envelopes()
    return function() end
end

return JTrack
