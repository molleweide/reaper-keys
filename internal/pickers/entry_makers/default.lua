local log = require("utils.log")
local format = require("utils.format")

local fu = require("utils.fzf")
local sf = require("utils.j_string_functions")

local function make_entries(label_maker)
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

			if tResults and iStart <= #tResults then
				local item = tResults[iStart]
				b.label = label_maker(item)
				b.visible = true
				info.visible = true
				b.highlight = highlights
			else
				b.visible = false
				info.visible = false
			end
		end
	end
end

return function(em)
	if not em then
		return make_entries(function(item)
			return item
		end)
	elseif type(em) == "string" or type(em) == "number" then
		return make_entries(function(item)
			return item[em]
		end)
	elseif type(em) == "table" then
		return make_entries(function(item)
			local res = ""
			for _, v in ipairs(em) do
				res = res .. tostring(item[v]) .. "; "
			end
			return res
		end)
	elseif type(em) == "function" then
		return em
	end
end
