local reaper_state = require('utils.reaper_state')
local format = require('utils.format')
local log = require('utils.log')
local trr = require('library.routing')
local rc = require('definitions.routing')
local trackObj = require('SYNTAX.lib.track_obj')
local syntax = require('SYNTAX.syntax.syntax')
local fx = require('SYNTAX.lib.fx')
local midi = require('SYNTAX.lib.midi')
local ypc = require('SYNTAX.lib.ypc')
local utils = require('custom_actions.utils')
local syntax_utils = require('SYNTAX.lib.util')
local apply_funcs = require('SYNTAX.syntax.util')
local config = require('SYNTAX.config.config')

local actions = {}
------------------------------------------------------------------------------------------
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
        apply_funcs.applyChannelSplitRouting(LVL3_obj) -- mv to lvl4
        apply_funcs.applyZoneDefaultRoutes(LVL3_obj, LVL1_obj.name)
        for l, LVL4_obj in pairs(LVL3_obj.children) do ----------- lvl 4 ------------
          apply_funcs.applyZoneDefaultRoutes(LVL4_obj, LVL1_obj.name) -- only works for MA not S atm

        end
      end

      apply_funcs.applyMappedOptMChildren(LVL2_obj, opt_m_children, count_w_range)

    end -- LEVEL 2
  end -- LEVEL 1
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

return actions
