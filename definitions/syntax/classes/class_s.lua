return {
  prefix = "S",
  treeProps = { -- classTreeAttrs
    level = 4,
    nxt = "ZGMCABTS",
    rep = true,
  },
  trackProps = {
    trackHeight = { attrString = "I_HEIGHTOVERRIDE", attrVal = 20 },
    trackColor = { attrString = "I_CUSTOMCOLOR", val = 122 },
  },
  default_routing = function(trk_obj)
    local trr = require("library.routing")
    local rc = require("definitions.routing")
    local has_sends = trr.trackHasSends(trk_obj.guid, rc.flags.CAT_SEND)
    if not has_sends then
      if trk_obj.zone.name == "DRUMS_ZONE" then
        trr.updateState("(SUM_DRUMS)#[0|0]", trk_obj.guid)
      elseif trk_obj.zone.name == "MUSIC_ZONE" then
        trr.updateState("(SUM_MUSIC)#[0|0]", trk_obj.guid)
      elseif trk_obj.zone.name == "FX_ZONE" then
        trr.updateState("(SUM_FX)#[0|0]", trk_obj.guid)
      elseif trk_obj.zone.name == "VOCALS_ZONE" then
      else
        trr.updateState("(MIX_BUSS)#[0|0]", trk_obj.guid)
      end
    end
  end,
}
