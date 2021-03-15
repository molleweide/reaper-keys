-- dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")
local log = require('utils.log')
local RS_TrObj = require('SYNTAX.lib.track_obj')
local class_conf = require('SYNTAX.config.config').classes

local reaper_utils = require('custom_actions.utils')
local util = require('SYNTAX.lib.util') -- rename to sxutil
-- local fx_util = require('SYNTAX.lib.fx_util')
local fx_util = require('library.fx')

local fx = {}

function fx.applyConfFxToChildObj(child_obj, proll_start_idx, opt_type) -- change to drum_map_note_start

  local tr, tr_idx    = reaper_utils.getTrackByGUID(child_obj.guid)
  if tr == nil then return end
  local tr_range      = 1
  local tr_has_range  = RS_TrObj.trackHasOption(child_obj, 'nr')
  if tr_has_range then tr_range = child_obj.options.nr end

  local RSFX_LIST = class_conf[child_obj.class].fx_syntax[opt_type]
  local old_fx_chain_count = reaper.TrackFX_GetCount(tr)
  local new_fx_chain_idx  = 0
  local div = '_'

  -- syntax fx --
  for RSFX_IDX=0, #RSFX_LIST do -- each syntax component =======================
    local spawn_num = 1 -- is
    local rsfx_use_spawn = RSFX_LIST[RSFX_IDX].spawnByRange -- if fx allows for tr_range
    if tr_has_range and rsfx_use_spawn then spawn_num = child_obj.options.nr end

    for i1=0, spawn_num - 1 do -- syntax spawn num =============================
      local old_fx_name   = fx_util.getSetTrackFxNameByFxChainIndex(child_obj.guid, new_fx_chain_idx, false)
      -- log.user('##chob/old_fx_name: ' .. child_obj.name .. ' | '.. tostring(old_fx_name))
      local old_has_div = false
      if type(old_fx_name) == 'string' then
        if old_fx_name:match('_A_') then
          old_has_div = true
        end
      end
      -- log.user(old_has_div)
      local old_tr_name
      local old_rsfx_str
      if old_has_div then
        old_tr_name = old_fx_name:sub( 0, old_fx_name:find(div)-1)
        old_rsfx_str  =  old_fx_name:sub(old_fx_name:find(div), -1)
      else
        old_tr_name = 'xxx'
        old_rsfx_str = 'xxx' -- a bit hacky
      end

      local new_fx_name   = getSingleRSFXName(child_obj, new_fx_chain_idx, RSFX_IDX, i1, RSFX_LIST[RSFX_IDX])
      local new_rsfx_str  =  new_fx_name:sub(new_fx_name:find(div), -1)

      local tr_name_match   = false
      local rsfx_str_match  = false

      if old_tr_name == child_obj.name then tr_name_match = true end
      if old_rsfx_str == new_rsfx_str then rsfx_str_match = true end
      -- log.user(
      --   '\n\n - fx info -----------------------------\n' ..
      --   'tr_range: ' .. tr_range .. '\n' ..
      --   'old/new tr name: \t' .. old_tr_name .. ' => ' .. child_obj.name .. '\n' ..
      --   -- 'new_pre_fx_count' .. new_pre_fx_count .. '\n' ..
      --   'rsfx_str old/new: \t' .. tostring(old_rsfx_str) .. ' => ' .. new_rsfx_str ..  '\n' ..
      --   'match name/rsfx: \t' .. tostring(tr_name_match) .. ' | ' .. tostring(rsfx_str_match) .. '\n'
      --   )

      -- A -----------------------------------------------------------------------
      if RSFX_LIST[RSFX_IDX].code ~= nil then
        if old_has_div then
          if not rsfx_str_match then -- missmatch

            local tr = reaper.GetTrack(0, child_obj.trackIndex) -- use guid!!!!!!!!!!!!!

            fx_util.replaceFxAtIndex(tr, RSFX_LIST[RSFX_IDX].search_str, new_fx_chain_idx) -- after existing
          end
        else -- prev not pre, but still pre syntax > insert at end of pre
          -- local tr = reaper.GetTrack(0, child_obj.trackIndex)
          fx_util.insertFxAtIndex(child_obj.guid, RSFX_LIST[RSFX_IDX].search_str, new_fx_chain_idx) -- after existing
        end
        rs_fx_pre_count = new_fx_chain_idx + 1
      else
        if old_has_div then
          local tr = reaper.GetTrack(0, child_obj.trackIndex)
          util.removeFxAtIndex(tr, new_fx_chain_idx)
        end
      end -- A, then B,C

      if not tr_name_match or not rsfx_str_match then -- update name
        fx_util.getSetTrackFxNameByFxChainIndex(child_obj.guid, new_fx_chain_idx, false, new_fx_name) -- update fxc name
      end

      for k,rsfx_parm in pairs(RSFX_LIST[RSFX_IDX].fx_params) do
        reaper.TrackFX_SetParam(tr, new_fx_chain_idx, k, rsfx_parm.val(proll_start_idx, tr_range, i1))
      end
      new_fx_chain_idx = new_fx_chain_idx + 1
    end -- FX
  end -- RSFX_LIST

  -- post syntax fx --
  if 0 < old_fx_chain_count - new_fx_chain_idx then
    for p1=new_fx_chain_idx, old_fx_chain_count - 1 do
      local ofxn = fx_util.getSetTrackFxNameByFxChainIndex(child_obj.guid, new_fx_chain_idx, false)
      local old_has_div = false
      if type(ofxn) == 'string' then
        if ofxn:match('_A_') then
          old_has_div = true
        end
      end
      if old_has_div then
        local tr = reaper.GetTrack(0, child_obj.trackIndex)
        fx_util.removeFxAtIndex(tr, new_fx_chain_idx) -- don't increment index if we remove
        -- log.user('rm excess pre')
      else
        new_fx_chain_idx = new_fx_chain_idx + 1
      end
    end
  end

  -- log.user('new fx chain count: ' .. new_fx_chain_idx .. '\n\n\n')

  return true
end

function getSingleRSFXName( child_obj, new_fx_chain_idx, RSFX_IDX, ridx, rsfx)
  local div = '_'
  local name_str = rsfx.code .. div .. new_fx_chain_idx .. div .. rsfx.rsfx_name .. div .. ridx
  name_str = child_obj.name .. div .. name_str
  return name_str
end

function computeSyntaxLength(child_obj,RSFX_LIST)
  local fx_tot    = 0
  local tr_range     = 1
  for i=0, #RSFX_LIST do
    if RSFX_LIST[i].spawnByRange and RS_TrObj.trackHasOption(child_obj, 'nr') then
      tr_range = child_obj.options.nr
      for r=0, tr_range - 1 do
        fx_tot = fx_tot + 1
      end
    else
      fx_tot = fx_tot + 1
    end
  end
  return fx_tot
end

return fx
