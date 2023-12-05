local log = require("utils.log")
local reaper_utils = {}

-- keep generalized utils for reaper
--
-- NOTE: this file should not import any modules except for logging

function reaper_utils.isSel()
  return reaper.CountSelectedTracks(0) ~= 0
end

--- Get info for tracks matching search_name pattern
function reaper_utils.getMatchedTrackGUIDs(search_name)
  if not search_name then
    return nil
  end
  local found = false
  local t = {}
  for i = 0, reaper.CountTracks(0) - 1 do
    local tr = reaper.GetTrack(0, i)
    local _, current_name = reaper.GetTrackName(tr)
    -- log.info("["..current_name .." = " .. search_name .. "], ", current_name:match(search_name))
    if current_name:match(search_name) then
      t[#t + 1] = { name = current_name, guid = reaper.GetTrackGUID(tr) }

      found = true
    end
  end
  if found then
    return t
  else
    return false
  end
end

-- TODO
--
-- tr, tr_index // move this to RK main util???
--
-- or should there maybe be a `track` file under lib/ where we'd put
-- any kind of base track functions.
function reaper_utils.getGUIDByTrack(tr)
  for i = 0, reaper.CountTracks(0) - 1 do
    local GUID = reaper.GetTrackGUID(tr)
    if GUID ~= nil or GUID ~= "" then
      return GUID
    end
  end
  return false
end

-- add return track name also??
--
-- TODO: if table of guids passed return list of track references.
--
-- TODO: allow passing tobj, or list of tobjs
--
function reaper_utils.getTrackByGUID(search_guid)
  -- local tr = reaper.BR_GetMediaTrackByGUID( 0, search_guid )
  -- if type(tr) == 'userdata' then return tr else return false end
  -- or just nil >> but it is really nice to get idx together with guid sometimes..
  for i = 0, reaper.CountTracks(0) - 1 do
    local tr = reaper.GetTrack(0, i)
    local GUID = reaper.GetTrackGUID(tr)
    if GUID == search_guid then
      return tr, i
    end
  end
  return false
end

-- tr nil checks

reaper_utils.get_single_track_state_chunk = function(tr)
  local ret, state = reaper.GetTrackStateChunk(tr, "", false)
  return state
end

reaper_utils.set_single_track_state_chunk = function(tr, state)
  return reaper.SetTrackStateChunk(tr, state, false)
end

-- error handling
reaper_utils.get_track_and_item_count_for_node = function(node)
  local tr = reaper_utils.getTrackByGUID(node.guid)
  local item_count = reaper.CountTrackMediaItems(tr)
  return tr, item_count
end

-- error handling
reaper_utils.get_item_and_first_take = function(tr, i)
  local item = reaper.GetTrackMediaItem(tr, i)
  local take = reaper.GetMediaItemTake(item, 0) -- active take
  return item, take
end

return reaper_utils
