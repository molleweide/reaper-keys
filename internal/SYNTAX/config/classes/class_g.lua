return {
  prefix = "G",
  treeProps = { level = 2, nxt = "MCABT", rep = false, cont = true },
  trackProps = {
    trackHeight = { attrString = "I_HEIGHTOVERRIDE", attrVal = 50 },
    trackColor = { attrString = "I_CUSTOMCOLOR", val = 122 },
  },
  options = {
    -- m = ?, -- mapped drum gobj
  },
  routing = {

    m = function(gobj, rk_config)
      local sxu = require("SYNTAX.lib.util")
      local trr = require("library.routing")
      local apply_funcs = require("SYNTAX.syntax.util")

      local count_w_range = require("definitions.config").drum_lanes_low_note_start
      local opt_m_children = {}
      for _, mcab_obj in pairs(gobj.children) do
        if sxu.strHasOneOfChars(mcab_obj.class, "MC") and sxu.trackObjHasOption(gobj, "m") then
          trr.updateState("-#", gobj.guid) -- remove all sends
          opt_m_children[#opt_m_children + 1] = mcab_obj -- collect m_opt_obj for reverse looping later
        end
      end

      for k = 1, #opt_m_children do
        local rev_idx = #opt_m_children + 1 - k -- reverse idx !!!
        local group_child_obj = opt_m_children[rev_idx]

        trr.updateState("#{0|0}", gobj.guid, group_child_obj.guid)

        require("SYNTAX.lib.fx").track_apply_fx_configs(group_child_obj, count_w_range, "m")

        count_w_range = require("SYNTAX.lib.midi").updatePianoRoll(gobj, group_child_obj, count_w_range)
      end
    end,
  },
}
