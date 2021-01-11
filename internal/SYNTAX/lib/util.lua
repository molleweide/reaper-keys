-- local format = require('utils.format')
local log = require('utils.log')

local util = {}

function util.setClassTrackInfo(class_conf, trk_obj)
    -- local trk = reaper.GetTrack(0,trk_obj.trackIndex)
    local trk, i = util.VF_GetTrackByGUID(trk_obj.guid)
    local trkh = class_conf[trk_obj.class].trackProps.trackHeight

    -- log.user(trk_obj.name, trk_obj.trackIndex, trk)
    if trk ~= nil then
      reaper.SetMediaTrackInfo_Value(trk, trkh.attrString, trkh.attrVal)
    end
end


-- #1   any string
-- #2   string of chars we want to see if any of them exists in str
-- stringHasOneOfChars
function util.strHasOneOfChars(str,char_set)
  local s,e = string.find(str, "[".. char_set .."]")
  -- log.user('matchSingleChar: ', string.find(str, "[".. char_set .."]"))
  if s == 1 then return true end
end

function util.trackObjHasOption(trk_obj, opt)
  if trk_obj.options ~= nil then
    if trk_obj.options[opt] ~= nil then
      return true
    else
      log.user("TrackOptionError: "..trk_obj.trackIndex.." : Track does not have option: `" .. opt .."`.") -- add group name to this err msg
      return false
    end
  else
    -- log.user("TrackOptionError: "..trk_obj.trackIndex.." : Track does not have any options.") -- add group name to this err msg
    return false
  end
end

-- mv to main util??
function util.getTrackIndicesOfTrackSel()
  local seltr = reaper.CountSelectedTracks()
  local trFirst = reaper.GetSelectedTrack(0, 0)
  local trLast  = reaper.GetSelectedTrack(0, seltr - 1)
  local trGuidFirst = reaper.GetTrackGUID(trFirst)
  local trGuidLast  = reaper.GetTrackGUID(trLast)
  local low_idx = nil
  local high_idx  = nil

  -- log.user('get first / last index of sel tracks.')
  for i=0, reaper.CountTracks(0) - 1 do
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

-- tr, tr_index // move this to RK main util???
function util.VF_GetTrackByGUID(giv_guid)
  for i = 0, reaper.CountTracks(0) - 1 do
    local tr = reaper.GetTrack(0,i)
    local GUID = reaper.GetTrackGUID( tr )
    if GUID == giv_guid then return tr, i end
  end
end

function util.getParentGroupByTrIdx(vtt, child_idx)
  local tr_count      = reaper.CountTracks(0)
  local prevGroup         = nil
  local parent_found      = false
  local parent_group_obj  = nil
  local parent_group_tr  = nil
  local parent_group_idx  = nil
  local last_z            = false
  local last_g        = false
  -- reaper.CountTracks(0)
  -- local guid = reaper.GetTrackGUID(tr)
  -- util.VF_GetTrackByGUID(giv_guid)

  for i, LVL1_obj in pairs(vtt) do
    last_g = false -- reset
    if i == #vtt then last_z = true end
    -- log.user(i, LVL1_obj.name, #vtt, last_z)

    for j, LVL2_obj in pairs(LVL1_obj.children) do
      local LVL2_tr, LVL2_tr_idx = util.VF_GetTrackByGUID(LVL2_obj.guid)
      -- log.user(LVL2_tr, LVL2_tr_idx, #LVL1_obj.children)
      --
      --

      if j == #LVL2_obj.children then last_g = true end

      -- log.user(LVL2_obj.children[j+1] == nil, i,#LVL1_obj.children, '||',child_idx,LVL2_tr_idx, last_z, last_g,LVL2_obj.name)
      -- this will always return the wrong group
      --

      if child_idx < LVL2_tr_idx then
        -- log.user('<')
        parent_found = true

        return prevGroup, prevTr, prevTrIdx
      elseif last_z then
        if LVL1_obj.children[j+1] == nil then
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
      prevTrIdx =  LVL2_tr_idx
    end
  end

  log.user('getParentGroupByTrIdx | should never reach here...')
  return parent_group_obj, parent_group_tr, parent_group_idx
end

return util
