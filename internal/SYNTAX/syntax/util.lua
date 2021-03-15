local rc = require('definitions.routing')
local syntax_utils = require('SYNTAX.lib.util')
local trr = require('library.routing')
local fx_util = require('library.fx')
local fx = require('SYNTAX.lib.fx')
local midi = require('SYNTAX.lib.midi')

local mod = {}

function mod.prepareMidiTracksForLaneMapping(parent_obj, child_obj, opt_m_children)
  if syntax_utils.strHasOneOfChars(child_obj.class, 'MC') and syntax_utils.trackObjHasOption(parent_obj, 'm') then
    trr.updateState('-#', parent_obj.guid) -- remove all sends
    opt_m_children[#opt_m_children+1] = child_obj -- collect m_opt_obj for reverse looping later
  end
  return opt_m_children
end

function mod.applyChannelSplitRouting(trk_obj)
  if trk_obj.class == 'C' then
    trr.updateState('-#', trk_obj.guid)
    for s, split_obj in pairs(trk_obj.children) do
      trr.updateState('{0|'..s..'}', trk_obj.guid, split_obj.guid)
    end
  end
end

function mod.applyZoneDefaultRoutes(trk_obj, zone_name)
  if syntax_utils.strHasOneOfChars(trk_obj.class, 'MAS') then
    -- should include 'A' as well!!!
    local has_sends = trr.trackHasSends(trk_obj.guid, rc.flags.CAT_SEND)
    if not has_sends then

      if zone_name == 'DRUMS_ZONE' then
        trr.updateState('(SUM_DRUMS)#[0|0]', trk_obj.guid)

      elseif zone_name == 'MUSIC_ZONE' then
        trr.updateState('(SUM_MUSIC)#[0|0]', trk_obj.guid)

      elseif zone_name == 'FX_ZONE' then
        trr.updateState('(SUM_FX)#[0|0]', trk_obj.guid)

      elseif zone_name == 'VOCALS_ZONE' then
        -- trr.updateState('{0|'..s..'}', LVL2_obj.guid, split_obj.guid)
        --
      else
        trr.updateState('(MIX_BUSS)#[0|0]', trk_obj.guid)
      end

    end

    -- setup ghost kicks | mv to fn
    if trk_obj.name:match('^kick') then
      trr.updateState('(ghostkick)#[0|0]', trk_obj.guid)
    end
  end
end


-- CREATE MIDI LANE MAPPINGS
function mod.applyMappedOptMChildren(parent_obj, opt_m_children, count_w_range)
  for k=1, #opt_m_children do
    local rev_idx = #opt_m_children + 1 - k -- reverse idx !!!
    local trk_obj = opt_m_children[rev_idx]
    trr.updateState('#{0|0}', parent_obj.guid, trk_obj.guid)
    fx.applyConfFxToChildObj(trk_obj, count_w_range, 'm')
    count_w_range = midi.updatePianoRoll(parent_obj, trk_obj, count_w_range)
  end
end


function mod.sidechainToGhostKick(rec_from_track_name_match, fx_gui_name, fn_filt)

  -- use class filter, 'MASB' to make sure i only route tracks
  -- that make sense. ie. in this case only audio out tracks.
  -- not midi out tracks, eg. 'GC'
  --
  -- pass this as a filter function.
  -- so that I can submit a pr without having to submit my sytax files.

  local t_sel = ru.getSelectedTracksGUIDs()
  for i, t_tr in pairs(t_sel) do

    -- CHECK IF GUI NAME EXISTS
    if not fx_util.trackHasFxChainString(t_tr.guid, fx_gui_name, false) then


    -- ADD FX >>> insertFxToLastIdxAndGuiRename(trguid, fx_search_str,fx_gui_name) ??
    --    how do i search and replace all tr >>> guid
    local fx_search_str = "ReaSamplOmatic5000"
    local fx_idx = fx_util.insertFxToLastIndex(t_tr.guid, fx_search_str, false)
    local tr = ru.getTrackByGUID(t_tr.guid) -- fix
    fx_util.getSetTrackFxNameByFxChainIndex(tr, fx_idx, true, fx_gui_name)


    --  SET FX PARAMS | thresh, ratio, aux
    local t_params = { [0] = 0.25, [1] = 0.06, [8] = ((1/1084)*2) }
    fx_util.setFxParamsFromTable(tr_guid, fx_idx, t_params)


    -- ROUTE CREATE RECIEVE FROM GHOST
    local route_str = '('..rec_from_track_name_match..')$[0|2]'
    log.user('route_str: ' .. route_str)
    -- trr.updateState(route_str, t_tr.guid)

    end
  end
end

return mod
