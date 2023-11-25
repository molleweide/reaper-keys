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
			apply_funcs.applyMappedOptMChildren(gobj, opt_m_children, count_w_range)
		end,
	},
}
