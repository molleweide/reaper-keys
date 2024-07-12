local req = require("project_classes.JProjectClassReq")
local JTrack = require("project_classes.track")
local JItem = require("project_classes.media_item")

-----------------------------------------------------------------------------
-- PROJECT
--

local JProject = {}
JProject.prototype = { pId = 0 }
JProject.mt = {}

function JProject:new(o)
    local o = o or {}
    setmetatable(o, JProject.mt)

    return o
end

JProject.mt.__index = function(table, key)
    if key == "trackcount" then
        return reaper.CountTracks(table.pId)
    elseif key == "selectedtrackcount" then
        return reaper.CountSelectedTracks2(table.pId, true)
    elseif key == "selecteditemcount" then
        return reaper.CountSelectedMediaItems(table.pId)
    elseif JProject.prototype[key] ~= nil then
        return JProject.prototype[key]
    else
        req.jError("JProject key: ''" .. key .. "'' is not a GET property", J_ERROR_ERROR)
        return false
    end
end

JProject.mt.__tostring = function() end

-- TODO: 1. option return all JTracks
-- 2. tracks by filters
--
-- Iterator to go through all the tracks in the project
-- start: index of the track to start at
-- num: (maximum) amount of track to return
function JProject.prototype:tracks(start, num)
    local i = start or 0
    local n = 0
    if num and i + num <= self.trackcount then
        n = i + num
    else
        n = self.trackcount
    end

    return function()
        i = i + 1
        if i <= n then
            return self:getTrack(i - 1)
        end
    end
end

function JProject.prototype:get_all_tracks()
    local res = {}
    for t in self:tracks() do
        table.insert(res, t)
    end

    return res
end

-- TODO: 1. option return all JTracks
-- 2. tracks by filters
--
---Iterator to go through all the SELECTED tracks in the project
---start: nth selected track to start at to start at. First one is 0.
---num: (maximum) amount of track to return, set to 0 for ALL.
---bReturnAll: set to true to get a table.
function JProject.prototype:selectedTracks(start, num, bReturnAll)
    local i = start or 0
    local n = 0
    if num and num > 0 and i + num <= self.selectedtrackcount then
        n = i + num
    else
        n = self.selectedtrackcount
    end

    -- UPDATED this function so it first gets the full list of selected tracks before it starts iterating
    -- otherwise deselecting tracks while in the loop could cause strange behavior
    -- ALL other iterators should be changed to this behavior...
    local selectedTracks = {}
    for j = i, n - 1 do
        table.insert(selectedTracks, self:getSelectedTrack(j))
    end

    if bReturnAll then
        return selectedTracks
    end

    i = 0
    return function()
        i = i + 1
        if i <= n then
            return selectedTracks[i]
        end
    end
end

function JProject.prototype:unselectAllTracks()
    local selectedTracks = self:selectedTracks(0, 0, true)
    for _, t in pairs(selectedTracks) do
        t.selected = 0
    end
end

-- Return's the track at index position idx for the project.
-- First track is 0.
-- If there is no such track then it returns false
function JProject.prototype:getTrack(idx)
    local idx = idx or 0
    local t = JTrack:new({ pTrack = reaper.GetTrack(self.pId, idx), _parentProject = self })
    if not t.pTrack then
        req.jError("project:getTrack(idx), no track idx: " .. tostring(i), J_ERROR_NOTICE)
        return false
    end
    return t
end

function JProject.prototype:getSelectedTrack(i)
    -- First track is 0
    local i = i or 0
    --local project = project or 0
    local t = JTrack:new()
    t.pTrack = reaper.GetSelectedTrack2(self.pId, i, true)
    t._parentProject = self
    if not t.pTrack then
        req.jError("project:getSelectedTrack(), no selected track i: " .. tostring(i), J_ERROR_NOTICE)
        return false
    end
    return t
end

function JProject.prototype:insertTrackAtIndex(i)
    reaper.InsertTrackAtIndex(i, false)
    return self:getTrack(i)
end

function JProject.prototype:getId()
    return self.pId
end

--
-- ITEM FUNCTIONS
--

function JProject.prototype:getItem(idx)
    local idx = idx or 0
    local it = JItem:new({ pItem = reaper.GetMediaItem(self.pId, idx) })
    return it
end

function JProject.prototype:items()
    -- Code taken from Tracks iterator
    --
    --
    --
    --   local i = start or 0
    -- local n = 0
    -- if num and i + num <= self.trackcount then
    --     n = i + num
    -- else
    --     n = self.trackcount
    -- end
    --
    -- return function()
    --     i = i + 1
    --     if i <= n then
    --         return self:getTrack(i - 1)
    --     end
    -- end
end

-- FIX: Getting the parent needs to be a method on
function JProject.prototype:getSelectedItem(i)
    i = i or 0
    local item = reaper.GetSelectedMediaItem(self.pId, i)
    local track = JTrack:new({ pTrack = reaper.GetMediaItem_Track(item), _parentProject = self })
    local it = JItem:new({ pItem = item, _parent = track })
    return it
end

-- Iterator to go through all the SELECTED items in the project
-- start: nth selected item to start at to start at. First one is 0.
-- num: (maximum) amount of items to return
function JProject.prototype:selectedItems(start, num, bWantTable)
    local i = start or 0
    local bWantTable = false or bWantTable
    local n = 0
    if num and i + num <= self.selecteditemcount and num ~= -1 then
        n = i + num
    else
        n = self.selecteditemcount
    end

    -- UPDATED this function so it first gets the full list of selected tracks before it starts iterating
    -- otherwise deselecting tracks while in the loop could cause strange behavior
    -- ALL other iterators should be changed to this behavior...
    local selectedTable = {}
    for j = i, n - 1 do
        -- local x = self:getSelectedItem(j)
        -- msg("J: " .. j .. ": " .. x.length .. " pitem: " .. tostring(x.pItem))
        table.insert(selectedTable, self:getSelectedItem(j))
    end
    if bWantTable then
        return selectedTable
    end
    -- for k,v in ipairs(selectedTable) do
    -- 	msg("table, k: " .. k .. ", v: " .. v.length .. ", p: " .. tostring(v.pItem))
    -- end
    i = 0
    return function()
        i = i + 1
        if i <= n then
            -- msg(i .. " : " .. selectedTable[i].length)
            return selectedTable[i]
        end
    end
end

function JProject.prototype:getTracksByName(sPattern, iInstance, find_init, find_plain)
    -- Search track(s) by name
    -- sPattern: Specify pattern to look for
    -- iInstance: leave empty (or false) to get a TABLE of all the tracks that match the pattern. Specify a number > 0 to get the nth track that matches
    -- The default searches from the first character (find_init = 1) and uses plain string (find_plain = true). See Lua's string.find() for more info

    local iInstance = iInstance or false
    local find_init = find_init or 1
    local find_plain = find_plain or true

    local tResult = {}
    local iCount = 0

    if type(iInstance) == "number" and iInstance <= 0 then
        req.jError(
            "project:getTracksByName(), instance <= 0. First instance is 1! iInstance: " .. tostring(iInstance),
            J_ERROR_ERROR
        )
        return false
    end

    local iTracks = self.trackcount

    for t in self:tracks() do
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

function JProject.prototype:getTrackByName(sPattern, iInstance, find_init, find_plain)
    local iInstance = iInstance or 1
    return self:getTracksByName(sPattern, iInstance, find_init, find_plain)
end

function JProject.prototype:getMaster()
    local t = JTrack:new({ pTrack = reaper.GetMasterTrack(self.pId), _parentProject = self })
    return t
end

-------------------------------------------------------------------------------
-- PROJECT > ENVELOPES
--

-- TODO: project envelopes

---Iterator all envelopes across project
function JProject.prototype:envelopes() end

return JProject
