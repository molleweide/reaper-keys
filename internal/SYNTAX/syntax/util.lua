local rc = require('definitions.routing')
local syntax_utils = require('SYNTAX.lib.util')
local trr = require('library.routing')
local fx = require('SYNTAX.lib.fx')
local midi = require('SYNTAX.lib.midi')


local mod = {}


-- M

-- refactor into MC applyMidiLaneMapping(parent_obj, child_obj)

function mod.prepareMidiTracksForLaneMapping(parent_obj, child_obj, opt_m_children)
  if syntax_utils.strHasOneOfChars(child_obj.class, 'MC') and syntax_utils.trackObjHasOption(parent_obj, 'm') then
    trr.updateState('-#', parent_obj.guid) -- remove all sends
    opt_m_children[#opt_m_children+1] = child_obj -- collect m_opt_obj for reverse looping later
  end
  return opt_m_children
end

-- refactor into C applyChannelSplits(parent_obj, child_obj)
function mod.applyChannelSplitRouting(trk_obj)
  if trk_obj.class == 'C' then
    trr.updateState('-#', trk_obj.guid)
    for s, split_obj in pairs(trk_obj.children) do
      trr.updateState('{0|'..s..'}', trk_obj.guid, split_obj.guid)
    end
  end
end

-- refactor into MS applyZoneDefaultRoutes(parent_obj, child_obj, zone_name)
function mod.applyZoneDefaultRoutes(trk_obj, zone_name)

  -- right now this will only create mapping for 'M'
  --l

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
  end
end


-- refactor applyGhostSends

-- if syntax_utils.strHasOneOfChars(LVL3_obj.class, 'MS') then
  --   -- should include 'A' as well!!!
  --   -- name ^kick . send to 'ghostkick'
-- end

function mod.applyMappedOptMChildren(parent_obj, opt_m_children, count_w_range)
  -- local count_w_range = count_w_range
  for k=1, #opt_m_children do
    local rev_idx = #opt_m_children + 1 - k -- reverse idx !!!
    local trk_obj = opt_m_children[rev_idx]
    trr.updateState('#{0|0}', parent_obj.guid, trk_obj.guid)
    fx.applyConfFxToChildObj(trk_obj, count_w_range, 'm')
    count_w_range = midi.updatePianoRoll(parent_obj, trk_obj, count_w_range)
  end
end

return mod
