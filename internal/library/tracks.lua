local log = require("utils.log")
local format = require("utils.format")

local tracks = {}

--- Return table of track GUIDs matching string
---@return table
tracks.getTrackGuidsByName = function()

  -- TODO: this should already be implemented in the routing UI
  -- refactor and move that function to here.

  local t = {}

  -- get all tracks
  -- for each find pattern
  -- return set
  return t
end

-- function JProject.prototype:getTracksByName(sPattern, iInstance, find_init, find_plain)
--     -- Search track(s) by name
-- 	-- sPattern: Specify pattern to look for
-- 	-- iInstance: leave empty (or false) to get a TABLE of all the tracks that match the pattern. Specify a number > 0 to get the nth track that matches
-- 	-- The default searches from the first character (find_init = 1) and uses plain string (find_plain = true). See Lua's string.find() for more info
--
--
-- 	local iInstance = iInstance or false
-- 	local find_init = find_init or 1
-- 	local find_plain = find_plain or true
--
--     local tResult = {}
--     local iCount = 0
--
-- 	if type(iInstance) == "number" and iInstance <= 0 then
-- 		jError("project:getTracksByName(), instance <= 0. First instance is 1! iInstance: " .. tostring(iInstance), J_ERROR_ERROR)
-- 		return false
-- 	end
--
--     local iTracks = self.trackcount
--
-- 	for t in self:tracks() do
-- 		if t.name:lower():find(sPattern:lower(), find_init, find_plain) then
-- 			iCount = iCount + 1
--             if iInstance == false then
--                 tResult[#tResult + 1] = t
--             elseif iInstance == iCount then
--                 return t
--             end
--         end
--     end
--
--     if not iInstance then
--         -- return table
--         if #tResult == 0 then
--             return false
--         else
--             return tResult
--         end
--     else
--         -- instance not found
--         return false
--     end
-- end
--
-- function JProject.prototype:getTrackByName(sPattern, iInstance, find_init, find_plain)
-- 	local iInstance = iInstance or 1
-- 	return self:getTracksByName(sPattern, iInstance, find_init, find_plain)
-- end

return tracks
