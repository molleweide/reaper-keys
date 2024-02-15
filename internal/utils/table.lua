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

function tbl.copy(orig) --http://lua-users.org/wiki/CopyTable
	local orig_type = type(orig)
	local copy
	if orig_type == "table" then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[tbl.copy(orig_key)] = tbl.copy(orig_value)
		end
		setmetatable(copy, tbl.copy(getmetatable(orig)))
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

-- create a new table by copying and adding together.
function tbl.copy_add(orig, tbl_add)
	local copy = tbl.copy(orig)
	-- extend with
	for k, v in pairs(tbl_add) do
		copy[k] = v
	end
	return copy
end

tbl.filter = function(t, condition, debug)
	local result = {}
	for i, item in ipairs(t) do
		if condition(item, i) then
			if debug then
				log.user(format.block(item))
			end
			table.insert(result, item)
		end
	end
	return result
end

---
---@param t table
---@param compare_key string
---@param search_value string
---@return number|boolean, any
tbl.findIndexOf = function(t, compare_key, search_value)
	for i, val in ipairs(t) do
		if compare_key then
			if val[compare_key] == search_value then
				return i, val
			end
		else
			if val == search_value then
				return i, val
			end
		end
	end
	return false
end

tbl.deep_extend = function(destination, ...)
	for _, source in ipairs({ ... }) do
		for key, value in pairs(source) do
			if type(value) == "table" and type(destination[key]) == "table" then
				destination[key] = tbl.deep_extend(destination[key], value)
			else
				destination[key] = value
			end
		end
	end
	return destination
end

return tbl
