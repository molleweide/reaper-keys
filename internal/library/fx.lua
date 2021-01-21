-- dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")
local log = require('utils.log')
-- local util = require('library.util')

local fx_util = {}

function fx_util.insertFxAtIndex(child_obj, fx_str, fx_insertTo_idx)
  local tr     = reaper.GetTrack(0, child_obj.trackIndex)
  local is_move_flag = true
  reaper.TrackFX_AddByName(tr, fx_str, false, -1) -- add to last index
  local fx_idx_last = reaper.TrackFX_GetCount(tr) - 1
  if fx_idx_last ~= fx_insertTo_idx then
    reaper.TrackFX_CopyToTrack(tr, fx_idx_last, tr, fx_insertTo_idx, is_move_flag)
  end
end

function fx_util.replaceFxAtIndex(child_obj, fx_str, fx_insertTo_idx)
  removeFxAtIndex(child_obj, fx_insertTo_idx)
  insertFxAtIndex(child_obj, fx_str, fx_insertTo_idx)
end

function fx_util.removeFxAtIndex(child_obj, fx_rm_idx)
  local tr = reaper.GetTrack(0, child_obj.trackIndex)
  reaper.TrackFX_Delete(tr, fx_rm_idx)
end

function fx_util.removeAllFXAfterIndex(child_obj, index)
  local trk     = reaper.GetTrack(0, child_obj.trackIndex)
  local tc = reaper.TrackFX_GetCount(trk)
  local num_fx_after_i = tc - index
  while(num_fx_after_i > 0 ) do
    for i = index, tc - 1 do
      reaper.TrackFX_Delete(trk, i)
    end
    tc = reaper.TrackFX_GetCount(trk)
    num_fx_after_i = tc - index
  end
end

function fx_util.getSetTrackFxNameByFxChainIndex(tr,idx_fx,newName)
  local strT, found, slot = {}
  local Pcall,FXGUID = pcall(reaper.TrackFX_GetFXGUID,tr,idx_fx)
  if not Pcall or not FXGUID then return false end
  local retval, str = reaper.GetTrackStateChunk(tr,"",false)
  local trFxNameStr

  -- https://lua.programmingpedia.net/en/tutorial/5829/pattern-matching
  for l in (str.."\n"):gmatch(".-\n") do
    table.insert(strT,l) -- add each line to table
  end

  for i = #strT,1,-1 do
    if strT[i]:match(FXGUID:gsub("%p","%%%0")) then
      found = true
    end
    if strT[i]:match("^<") and found and not strT[i]:match("JS_SER") then
      found = nil
      local nStr = {}
      for S in strT[i]:gmatch("%S+") do
        if not X then
          nStr[#nStr+1] = S
        else
          nStr[#nStr] = nStr[#nStr].." "..S
        end
        if S:match('"') and not S:match('""')and not S:match('".-"') then
          if not X then
            X = true
          else
            X = nil
          end
        end
      end
      if strT[i]:match("^<%s-JS") then
        slot = 3
      elseif strT[i]:match("^<%s-AU")
        then
        slot = 4
      elseif strT[i]:match("^<%s-VST") then
        slot = 5
      end
      if not slot then error("Failed to rename/access name",2)
      end
      trFxNameStr = nStr[slot]
      if newName ~= nil and type(newName) == 'string' then
        nStr[slot] = newName:gsub(newName:gsub("%p","%%%0"),'"%0"')
      end
      nStr[#nStr+1]="\n"
      strT[i] = table.concat(nStr," ")
      break
    end
  end

  if newName ~= nil and type(newName) == 'string' then
    return reaper.SetTrackStateChunk(tr,table.concat(strT),false)
  end
  return trFxNameStr
end

function fx_util.bypassFX()
  --  TODO
  --
  --    - arspt
end

return fx_util
