local log = require("utils.log")
local format = require("utils.format")

return function(selector)
	if selector == nil then
		return function(self, i)
		  log.user("on select nil")
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
	elseif type(selector) == "boolean" then
		return function(self, i)
		  log.user("on select boolean")
			if not self.t_search_results then
				return false
			end
			local selection = self.t_search_results[i]
			if not selection then
				return false
			end
			log.user("Picker selection:", i, format.block(selection))
			return selector
		end
	elseif type(selector) == "string" or type(selector) == "number" then
	elseif type(selector) == "function" then
		return selector
	end
end
