local log = require("utils.log")
local format = require("utils.format")

local tbl = {}

function tbl.tableConcat(t1, t2)
	if type(t1) ~= "table" or type(t2) ~= "table" then
		return false
	end
	for i = 1, #t2 do
		t1[#t1 + 1] = t2[i] --corrected bug. if t1[#t1+i] is used, indices will be skipped
	end
	return t1
end

function tbl.shallow_copy(t)
	local t2 = {}
	for k, v in pairs(t) do
		t2[k] = v
	end
	return t2
end

tbl.filter = function(t, condition, debug)
	local result = {}
	for _, item in ipairs(t) do
		if condition(item) then
		  if debug then
		    log.user(format.block(item))
		  end
			table.insert(result, item)
		end
	end
	return result
end

tbl.findKey = function(t, key, search_value)
	for _, item in ipairs(t) do
		if item[key] == search_value then
		  return item
		end
	end
	return false
end

return tbl
