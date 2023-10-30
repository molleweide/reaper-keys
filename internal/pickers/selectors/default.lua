local log = require("utils.log")
local format = require("utils.format")

return function(selector)
	if not selector then
		return function(self, i)
			if not self.t_search_results then
				return false
			end
			local selection = self.t_search_results[i]
			if not selection then
				return false
			end
			log.user("Picker selection:", i, format.block(selection))
			return true
		end
	elseif type(selector) == "string" or type(selector) == "number" then
	elseif type(selector) == "function" then
		return selector
	end
end
