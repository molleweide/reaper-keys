-- local format = require('utils.format')
local reaper_utils = require("custom_actions.utils")
local log = require("utils.log")
local rk_config = require("definitions.config")

local sx_lib_util = {}

-- wtf never use tr idx
function sx_lib_util.gt(child_obj)
  local tr = reaper.GetTrack(0, child_obj.trackIndex)
  return tr
end

-- NOTE: should this be moved into each class module?
--
function sx_lib_util.setClassTrackInfo(class_conf, trk_obj)
  -- local trk = reaper.GetTrack(0,trk_obj.trackIndex)
  local trk, i = reaper_utils.getTrackByGUID(trk_obj.guid)
  local trkh = class_conf[trk_obj.class].trackProps.trackHeight

  -- log.user(trk_obj.name, trk_obj.trackIndex, trk)
  if trk ~= nil then
    reaper.SetMediaTrackInfo_Value(trk, trkh.attrString, trkh.attrVal)
  end
end

-- TODO: move to utils/strings
-- #1   any string
-- #2   string of chars we want to see if any of them exists in str
-- stringHasOneOfChars
function sx_lib_util.strHasOneOfChars(str, char_set)
  local s, e = string.find(str, "[" .. char_set .. "]")
  -- log.user('matchSingleChar: ', string.find(str, "[".. char_set .."]"))
  if s == 1 then
    return true
  end
end

function sx_lib_util.trackObjHasOption(trk_obj, opt)
  if trk_obj.options ~= nil then
    if trk_obj.options[opt] ~= nil then
      return true
    else
      log.user("TrackOptionError: " .. trk_obj.trackIndex .. " : Track does not have option: `" .. opt .. "`.") -- add group name to this err msg
      return false
    end
  else
    -- log.user("TrackOptionError: "..trk_obj.trackIndex.." : Track does not have any options.") -- add group name to this err msg
    return false
  end
end

-- MV TO MAIN UTIL?? ALSO rename to getSelEdgeIndices !!!
function sx_lib_util.getTrackIndicesOfTrackSel()
  local seltr = reaper.CountSelectedTracks()
  local trFirst = reaper.GetSelectedTrack(0, 0)
  local trLast = reaper.GetSelectedTrack(0, seltr - 1)
  local trGuidFirst = reaper.GetTrackGUID(trFirst)
  local trGuidLast = reaper.GetTrackGUID(trLast)
  local low_idx = nil
  local high_idx = nil

  -- log.user('get first / last index of sel tracks.')
  for i = 0, reaper.CountTracks(0) - 1 do
    local tr = reaper.GetTrack(0, i)
    local tr_guid = reaper.GetTrackGUID(tr)
    if trGuidFirst == tr_guid then
      -- log.user('track number of first: ' .. i+1)
      low_idx = i
    end
    if trGuidLast == tr_guid then
      -- log.user('track number of last: ' .. i+1)
      high_idx = i
    end
  end

  return low_idx, high_idx
end

--
-- TODO: return table ...
--

function sx_lib_util.get_track_object_group(vtt, tobj)
  local tr_count = reaper.CountTracks(0)
  local prevGroup = nil
  local parent_found = false
  local parent_group_obj = nil
  local parent_group_tr = nil
  local parent_group_idx = nil
  local last_z = false
  local last_g = false
  -- reaper.CountTracks(0)
  -- local guid = reaper.GetTrackGUID(tr)
  -- reaper_utils.getTrackByGUID(giv_guid)

  for i, LVL1_obj in pairs(vtt) do
    last_g = false -- reset
    if i == #vtt then
      last_z = true
    end
    -- log.user(i, LVL1_obj.name, #vtt, last_z)

    for j, LVL2_obj in pairs(LVL1_obj.children) do
      local LVL2_tr, LVL2_tr_idx = reaper_utils.getTrackByGUID(LVL2_obj.guid)
      -- log.user(LVL2_tr, LVL2_tr_idx, #LVL1_obj.children)
      --
      --

      if j == #LVL2_obj.children then
        last_g = true
      end

      -- log.user(LVL2_obj.children[j+1] == nil, i,#LVL1_obj.children, '||',tobj,LVL2_tr_idx, last_z, last_g,LVL2_obj.name)
      -- this will always return the wrong group
      --

      if tobj.trackIndex < LVL2_tr_idx then
        -- log.user('<')
        parent_found = true

        return prevGroup, prevTr, prevTrIdx
      elseif last_z then
        if LVL1_obj.children[j + 1] == nil then
          --
          -- what can I add here to bullet proof this
          --
          parent_found = true
          parent_group_obj = LVL2_obj
          parent_group_tr = LVL2_tr
          parent_group_idx = LVL2_tr_idx
          -- log.user('lastzg', parent_group_obj.name)
          return parent_group_obj, parent_group_tr, parent_group_idx
        end
      end

      prevGroup = LVL2_obj
      prevTr = LVL2_tr
      prevTrIdx = LVL2_tr_idx
    end
  end

  log.user("get_track_object_group | should never reach here...")
  return parent_group_obj
end

sx_lib_util.get_drum_lane_start_idx_from_child_track = function(parent_group_obj, child_track_obj)
  local note_row
  local lane_idx = 0
  for i = #parent_group_obj.children, 1, -1 do
    local the_child = parent_group_obj.children[i]
    if sx_lib_util.strHasOneOfChars(the_child.class, "MC") then
      if sx_lib_util.trackObjHasOption(the_child, "nr") then
        if the_child.guid == child_track_obj.guid then
          lane_idx = lane_idx + 1
          break
        else
          lane_idx = lane_idx + tonumber(the_child.options.nr)
        end
      else
        lane_idx = lane_idx + 1
        if the_child.guid == child_track_obj.guid then
          break
        end
      end
    end
  end
  note_row = lane_idx + rk_config.drum_lanes_low_note_start - 1
  return note_row
end

-- input name
-- return 'drums', 'music', 'fx', 'vocals'
function sx_lib_util.trackNameMatchCategory(name)

  -- for each cat_type
  --    for each name prefix
  --      match ^prefix
  --        return cat_type

  -- return false
end

return sx_lib_util
