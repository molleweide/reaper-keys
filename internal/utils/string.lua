local string_util = {}

-- return string split by pattern
-- returns full string if not pattern found
function string_util.getStringSplitPattern(pString, pPattern)
	local Table = {}
	local fpat = "(.-)" .. pPattern
	local last_end = 1
	local s, e, cap = pString:find(fpat, 1)
	while s do
		if s ~= 1 or cap ~= "" then
			table.insert(Table, cap)
		end
		last_end = e + 1
		s, e, cap = pString:find(fpat, last_end)
	end
	if last_end <= #pString then
		cap = pString:sub(last_end)
		table.insert(Table, cap)
	end
	return Table
end

-- TODO: move to utils/strings
-- #1   any string
-- #2   string of chars we want to see if any of them exists in str
-- stringHasOneOfChars
string_util.strHasOneOfChars = function(str, char_set)
	local s, _ = string.find(str, "[" .. char_set .. "]")
	-- log.user('matchSingleChar: ', string.find(str, "[".. char_set .."]"))
	if s == 1 then
		return true
	end
	return false
end

string_util.split = function(str, sep)
	local parts = {}
	local pattern = string.format("([^%s]+)", sep)
	for part in string.gmatch(str, pattern) do
		table.insert(parts, part)
	end
	return parts
end

string_util.remove_brackets_of_type = function(str, bracket_type)
	for r in str:gmatch("%b" .. bracket_type) do
		str = str:gsub("%(" .. r .. "%)", "")
	end
	return str
end

string_util.extract_string_inside_brackets = function(str, encl)
	local data
	for p in str:gmatch("%b" .. encl) do
		data = str.sub(p, 2, str.len(p) - 1)
	end
	str = string_util.remove_brackets_of_type(str, encl)
	return data, str
end

-- TODO: option to trim off each bracket found.
--- NOTE: currently only works with two bracket pairs found
-- FIX: throw error if found more brackets than requested.
-- >> pass mult args: str, expected_num
--
--- Extract sequentially found brackets in a string.
---@param str
---@return
string_util.extract_parenthesis = function(str)
	local pcount = 0
	local pDest, pSrc
	for p in str:gmatch("%b()") do
		pcount = pcount + 1
		if pcount == 1 then
			pDest = str.sub(p, 2, str.len(p) - 1)
		end
		if pcount == 2 then
			pSrc = pDest
			pDest = str.sub(p, 2, str.len(p) - 1)
			break
		end
	end
	str = string_util.remove_brackets_of_type(str, "()")
	return retval, pSrc, pDest, str
end

return string_util
