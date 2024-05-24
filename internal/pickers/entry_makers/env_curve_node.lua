local log = require("utils.log")
local format = require("utils.format")

local su = require("utils.string")

local fu = require("utils.fzf")
local sf = require("utils.j_string_functions")

-- local function makeStringLength(inputString, maxLength, repl_str)
-- 	if #inputString < maxLength then
-- 		local numSpacesToAdd = maxLength - #inputString
-- 		local spaces = string.rep(repl_str, numSpacesToAdd)
-- 		return inputString .. spaces
-- 	else
-- 		return inputString
-- 	end
-- end

return function(tButtons, tResults)
	for i, cIds in ipairs(tButtons) do
		local b = cIds[1]
		local info = cIds[2]
		local iStart = fu._round(i + SCROLL_RESULTS)
		local highlights = sf.jStringExplode(textBox.value, " ")
		local showing

		if iStart <= #tResults then
			showing = iStart
		else
			showing = #tResults
		end

		LABEL_STATS.label = "(" .. showing .. "/" .. #tResults .. ")"

		local repl

		if tResults and iStart <= #tResults then
			local item = tResults[iStart]

			local label_str = ""

			if item.name == "start" then
			  repl = "-"
			else
			  repl = " "
			end

			if item.pt_idx then
				local part = string.format("#%s", item.pt_idx)
				label_str = label_str .. su.makeStringLength(part, 8, repl)
			end

			-- if item.tpos then
			-- 	local part = string.format("%s", item.tpos)
			-- 	label_str = label_str .. su.makeStringLength(part, 12, repl)
			-- end
			--

			if item.real_pos then
				local part = string.format("pos:[%s]", item.real_pos)
				label_str = label_str .. su.makeStringLength(part, 12, repl)
			end


			if item.name then
				local part = string.format("[%s]", item.name)
				label_str = label_str .. su.makeStringLength(part, 18, repl)
			end


			if item.pt_idx and item.pt_idx2 then
				local part = string.format("pt_idices:[%s, %s]", item.pt_idx, item.pt_idx2)
				label_str = label_str .. su.makeStringLength(part, 20, repl)
			end

			if item.tpos and item.tpos2 then
				local part = string.format("pt_pos:[%s, %s]", tostring(item.tpos), tostring(item.tpos2))
				label_str = label_str .. su.makeStringLength(part, 18, repl)
			end





			b.label = label_str

			b.visible = true
			info.visible = true
			b.highlight = highlights
		else
			b.visible = false
			info.visible = false
		end
	end
end
