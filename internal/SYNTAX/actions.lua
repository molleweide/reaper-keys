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

function actions.sidechainTracks()
  if tr_util.isSel() then -- FALLBACK SRC SEL
  end
    -- rp['src_guids'] = ru.getSelectedTracksGUIDs()
  -- -- insert reacomp
  -- local reacompid = TrackFX_AddByName( dest_tr, 'ReaComp (Cockos)', false, 1 )
  -- TrackFX_SetOpen(dest_tr, reacompid, true)
  -- TrackFX_SetParam(dest_tr, reacompid, 0, threshold)
  -- TrackFX_SetParam(dest_tr, reacompid, 1, ratio)
  -- TrackFX_SetParam(dest_tr, reacompid, 8, (1/1084)*2)

  for i = 1, reaper.CountSelectedTracks(0) do
    local tr = reaper.GetSelectedTrack(0,i-1)

    -- if has fx named GHOST_SC
      -- add fx last

    -- local zeroth_idx_name = fx.getSetTrackFxNameByFxChainIndex(tr, 0, true) -- TODO rec fx
    -- if zeroth_idx_name == 'RK_MIDI_PRE_PROCESSOR' then
    --   updateMidiPreProcessorByInputDevice(tr)
    -- else
    --   local fx_str = 'midi-rec-pre.jsfx' -- INSERT MIDI PRE PROCESSOR JSFX
    --   fx.insertFxAtIndex(tr, fx_str, 0, true)
    --   fx.getSetTrackFxNameByFxChainIndex(tr,0, true, 'RK_MIDI_PRE_PROCESSOR')
    --   updateMidiPreProcessorByInputDevice(tr)
    -- end

  end
end

return actions
