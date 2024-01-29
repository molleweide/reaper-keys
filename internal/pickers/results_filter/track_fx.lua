local log = require("utils.log")
local format = require("utils.format")

return function(t_results_data, sPattern, iMaxResults)
	local t_ret = {}
	local iCount = 0

	local function add(i, t)
		iCount = iCount + 1
		t.id = i -- keep track of position in main table
		t_ret[#t_ret + 1] = t
	end

	for i, t in ipairs(t_results_data) do
		if t.name and t.name ~= '""' and t.name:lower():find(sPattern) then
			add(i, t)
		elseif t.pname and t.pname:lower():find(sPattern) then
			add(i, t)
		end
		if iMaxResults then
			if #t_ret >= iMaxResults then -- check if we already have enough results
				log.user(format.block(t_ret))
				return t_ret
			end
		end
	end -- for
	return t_ret
end
