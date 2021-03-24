-- dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")
local ru = require('custom_actions.utils')
local log = require('utils.log')

local fx_util = {}


local REC_FX = 0x1000000

--[[-------------------------------

TODO

- make sure only GUIDS are used in this file as arguments

- bypass fx

-- rec/norec could be refactored into base fn

-----------------------------------


retval, minval, maxval = reaper.TrackFX_GetParam(track, fx_idx, param_idx)

retval, buf = reaper.TrackFX_GetParamName(track, fx_idx, param_idx, string buf)

----------------------------------

integer reaper.TrackFX_GetRecCount(track)

  To access record input FX, use a FX indices
  [0x1000000..0x1000000+n). On the master track, this accesses monitoring FX
  rather than record input FX.

---------------------------------

reaper.TrackFX_CopyToTrack(src_track, src_fx, dest_track, dest_fx, is_move)

  Copies (or moves) FX from src_track to dest_track.

  Can be used with src_track=dest_track to reorder, FX indices have 0x1000000 set
  to reference input FX.

-----------------------------------]]--


function fx_util.insertFxToLastIndex(guid_tr, fx_str, is_rec_fx)
  local tr = ru.getTrackByGUID(guid_tr)
  return reaper.TrackFX_AddByName(tr, fx_str, is_rec_fx, -1) -- add to last index
end


-- check if named fx exists. this is much more specific than only looking for a
-- specific fx since two instances of same fx can different purposes...
function fx_util.trackHasFxChainString(guid_tr, fx_str, is_rec_fx)
  local found = false

  local tr = ru.getTrackByGUID(guid_tr)

  if is_rec_fx then
    local tc = reaper.TrackFX_GetRecCount(tr) - 1
    for i = 0, tc - 1 do
      local fxc_str = fx_util.getSetTrackFxNameByFxChainIndex(guid_tr, i, true) -- TODO rec fx
      if fx_str == fxc_str then found = true end
    end

  else
    local tc = reaper.TrackFX_GetCount(tr) - 1
    for i = 0, tc do
      local fxc_str = fx_util.getSetTrackFxNameByFxChainIndex(guid_tr, i, false) -- TODO rec fx
      -- log.user(fxc_str, fx_str)
      if fx_str == fxc_str then found = true end
    end
  end
  return found
end


-- add ability to add last fx index
function fx_util.insertFxAtIndex(guid_tr, fx_str, fx_insertTo_idx, is_rec_fx)
  local tr, tr_idx = getTrackByGUID(search_guid)
  local is_move_flag = true -- required on order to reorder tracks
  if is_rec_fx then
    reaper.TrackFX_AddByName(tr, fx_str, true, -1) -- add to last index
    local fx_idx_last = reaper.TrackFX_GetRecCount(tr) - 1
    if fx_idx_last ~= fx_insertTo_idx then
      reaper.TrackFX_CopyToTrack(
        tr,
        REC_FX + fx_idx_last,
        tr,
        REC_FX + fx_insertTo_idx,
        is_move_flag)
    end
  else
    reaper.TrackFX_AddByName(tr, fx_str, false, -1) -- add to last index
    local fx_idx_last = reaper.TrackFX_GetCount(tr) - 1
    if fx_idx_last ~= fx_insertTo_idx then
      reaper.TrackFX_CopyToTrack(tr, fx_idx_last, tr, fx_insertTo_idx, is_move_flag)
    end
  end
end

function fx_util.replaceFxAtIndex(guid_tr, fx_str, fx_insertTo_idx, is_rec_fx)
  if is_rec_fx then
    fx_util.removeFxAtIndex(guid_tr, fx_insertTo_idx, true)
    fx_util.insertFxAtIndex(guid_tr, fx_str, fx_insertTo_idx, true)
  else
    fx_util.removeFxAtIndex(guid_tr, fx_insertTo_idx)
    fx_util.insertFxAtIndex(guid, fx_str, fx_insertTo_idx)
  end
end

function fx_util.removeFxAtIndex(guid_tr, fx_rm_idx, is_rec_fx)
  local tr, tr_idx = getTrackByGUID(guid_tr)
  if is_rec_fx then
    reaper.TrackFX_Delete(tr, REC_FX + fx_rm_idx)
  else
    reaper.TrackFX_Delete(tr, fx_rm_idx)
  end
end

function fx_util.removeAllFXAfterIndex(guid_tr, index)
  local tr, tr_idx = getTrackByGUID(guid_tr)
  local tc = reaper.TrackFX_GetCount(tr)
  local num_fx_after_i = tc - index
  while(num_fx_after_i > 0 ) do
    for i = index, tc - 1 do
      reaper.TrackFX_Delete(tr, i)
    end
    tc = reaper.TrackFX_GetCount(tr)
    num_fx_after_i = tc - index
  end
end

function fx_util.setParamForFxAtIndex(guid_tr, fx_idx, param, value, is_rec_fx)
  local tr, tr_idx = getTrackByGUID(guid_tr)
  if is_rec_fx then
      reaper.TrackFX_SetParam(guid_tr, REC_FX + fx_idx, param, value)
  else
      reaper.TrackFX_SetParam(guid_tr, fx_idx, param, value)
  end
end



function fx_util.setFxParamsFromTable(guid_tr, fx_idx, t_params)
    local tr = ru.getTrackByGUID(guid_tr)
    for i, parm in pairs(t_params) do
      retval, parname = reaper.TrackFX_GetParamName( tr, fx_idx, i, '' )
      -- log.user(i, parname, parm)
      local ret = reaper.TrackFX_SetParam(tr, fx_idx, i, parm)
    end
end


-- function insertFxToLastIdxAndGuiRename(guid_tr, fx_search_str, fx_gui_name)
--     local fx_idx = fx_util.insertFxToLastIndex(guid_tr, fx_search_str, false)
--     fx_util.getSetTrackFxNameByFxChainIndex(guid_tr, fx_idx, true, fx_gui_name)
-- end


-- DON'T USE  `TRACKS`
--    ONLY GUID
function fx_util.getSetTrackFxNameByFxChainIndex(guid_tr, idx_fx, is_rec_fx, newName)
  local tr, tr_idx = ru.getTrackByGUID(guid_tr)
  local strT, found, slot = {}
  local Pcall
  local FXGUID

  if is_rec_fx then
    Pcall,FXGUID = pcall(reaper.TrackFX_GetFXGUID, tr, REC_FX + idx_fx)
  else
    Pcall,FXGUID = pcall(reaper.TrackFX_GetFXGUID, tr, idx_fx)
  end

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
    return reaper.SetTrackStateChunk(tr, table.concat(strT), false)
  end
  return trFxNameStr
end


function fx_util.insertFxToLastIdxAndGuiRename(guid_tr, fx_search_str,fx_gui_name)
  local fx_idx = fx_util.insertFxToLastIndex(guid_tr, fx_search_str, false)
  fx_util.getSetTrackFxNameByFxChainIndex(guid_tr, fx_idx, false, fx_gui_name)
  return fx_idx
end


function fx_util.fxSetBypass(guid_tr, fx_idx, bypass)
  -- 0 = off
  -- 1 = one
  -- 2 = toggle
end

function fx_util.fxBypassToggle(guid_tr, fx_idx)
  fx_util.fxSetBypass(guid_tr, fx_idx, 2)
end

return fx_util
