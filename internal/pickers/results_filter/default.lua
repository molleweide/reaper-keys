local log = require("utils.log")
local format = require("utils.format")

return function(filter)
	-- basic default
	if not filter then
		return function(t_results_data, sPattern, iMaxResults)
			local t_ret = {}
			local iCount = 0
			for i, t in ipairs(t_results_data) do
				if t.name then
					if t.name:lower():find(sPattern) then
						iCount = iCount + 1
						t.id = i -- keep track of position in main table
						t_ret[#t_ret + 1] = t
						if iMaxResults then
							if #t_ret >= iMaxResults then -- check if we already have enough results
								log.user(format.block(t_ret))
								return t_ret
							end
						end
					end
				end
			end
			return t_ret
		end

	-- check compare with custom key in results table
	elseif type(filter) == "string" or type(filter) == "number" then
		return function(t_results_data, sPattern, iMaxResults)
			local t_ret = {}
			local iCount = 0

			-- log.user("filter:", filter, "[" .. sPattern .. "]")

			for i, t in ipairs(t_results_data) do
				if t[filter] then
					if t[filter]:lower():find(sPattern) then
						iCount = iCount + 1
						t.id = i -- keep track of position in main table
						t_ret[#t_ret + 1] = t
						if iMaxResults then
							if #t_ret >= iMaxResults then -- check if we already have enough results
								log.user(format.block(t_ret))
								return t_ret
							end
						end
					end
				end
			end
			return t_ret
		end

	-- do nothing..
	elseif type(filter) == "function" then
		return filter
	end
end
