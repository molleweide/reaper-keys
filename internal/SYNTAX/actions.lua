local ru = require('custom_actions.utils')
local fx_util = require('library.fx')
local format = require('utils.format')
local log = require('utils.log')
local syntax = require('SYNTAX.syntax.syntax')
local ypc = require('SYNTAX.lib.ypc')
local syntax_utils = require('SYNTAX.lib.util')
local apply_funcs = require('SYNTAX.syntax.util')
local config = require('SYNTAX.config.config')

local actions = {}

-- make recursive
function actions.applyConfigs()
  log.clear()
  local vtt = syntax.getVerifiedTree()
  for i, LVL1_obj in pairs(vtt) do ------------------------------ lvl 1 ------------
    syntax_utils.setClassTrackInfo(config.classes, LVL1_obj)

    for j, LVL2_obj in pairs(LVL1_obj.children) do ------------- lvl 2 ------------

      local count_w_range = 24 -- put in config
      syntax_utils.setClassTrackInfo(config.classes, LVL2_obj)
      local opt_m_children = {}

      for k, LVL3_obj in pairs(LVL2_obj.children) do ----------- lvl 3 ------------

        syntax_utils.setClassTrackInfo(config.classes, LVL3_obj) -- why pass config? stupid..
        opt_m_children = apply_funcs.prepareMidiTracksForLaneMapping(LVL2_obj, LVL3_obj, opt_m_children)
        apply_funcs.applyChannelSplitRouting(LVL3_obj) -- mv to lvl4 ??
        apply_funcs.applyZoneDefaultRoutes(LVL3_obj, LVL1_obj.name)

        for l, LVL4_obj in pairs(LVL3_obj.children) do ----------- lvl 4 ------------

          apply_funcs.applyZoneDefaultRoutes(LVL4_obj, LVL1_obj.name) -- only works for MA not S atm

        end -- l
      end -- k
      apply_funcs.applyMappedOptMChildren(LVL2_obj, opt_m_children, count_w_range)
    end -- j
  end -- i
end

function actions.gyank()
  ypc.customGroupYpc("yank")
end

function actions.gcut()
  ypc.customGroupYpc("cut")
  actions.applyConfigs()
end

function actions.gput()
  ypc.customGroupYpc("put")
  actions.applyConfigs()
end

-- TODO
--
-- if 'MASB' ??
function actions.sidechainToGhosKick()

  local t_sel = ru.getSelectedTracksGUIDs()

  for i, t_tr in pairs(t_sel) do

    if not fx_util.trackHasFxChainString(t_tr.guid, 'SC_GHOST_KICK', false) then


    -- EXAMPLE
    --
    -- -- insert reacomp
    -- local reacompid = TrackFX_AddByName( dest_tr, 'ReaComp (Cockos)', false, 1 )
    -- TrackFX_SetOpen(dest_tr, reacompid, true)
    -- TrackFX_SetParam(dest_tr, reacompid, 0, threshold)
    -- TrackFX_SetParam(dest_tr, reacompid, 1, ratio)

    -- -- this has to be setting to recieve from aux track.
    -- TrackFX_SetParam(dest_tr, reacompid, 8, (1/1084)*2) -- what is this?



    -- ADD REACOMP <<<<<<
      local fx_search_str = "ReaSamplOmatic5000"
      local fx_idx = fx_util.insertFxToLastIndex(t_tr.guid, fx_search_str, false)
      local tc = reaper.TrackFX_GetCount(tr) - 1



      -- fix never use guids!!!
      local tr = ru.getTrackByGUID(t_tr.guid)

      fx.getSetTrackFxNameByFxChainIndex(tr, tc, true, 'SC_GHOST_KICK')



      -- FX_IDX
      --
      --  set reacomp params
      --
      -- TrackFX_SetParam(dest_tr, reacompid, 0, threshold)
      -- TrackFX_SetParam(dest_tr, reacompid, 1, ratio)
      -- TrackFX_SetParam(dest_tr, reacompid, 8, (1/1084)*2)



      -- recieve into reacomp track
      -- rlib.update('',,)



    end
  end
end

return actions
