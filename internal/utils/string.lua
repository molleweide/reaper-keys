local log = require("utils.log")
local format = require("utils.format")

local string_util = {}

-- return string split by pattern
-- returns full string if not pattern found
function string_util.getStringSplitPattern(pString, pPattern)
  local Table = {}
  local fpat = "(.-)" .. pPattern
  local last_end = 1
  local s, e, cap = pString:find(fpat, 1)
  -- log.user(pString:match(fpat))
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

string_util.get_count_char_and_in_between_sub_strings = function(inputString, charToCount)
  local count = 0
  local prev = 0
  local t_res = {}

  for i = 1, #inputString do
    if string.sub(inputString, i, i) == charToCount then
      count = count + 1
      if i - prev < 2 then
        table.insert(t_res, "")
      else
        table.insert(t_res, inputString:sub(prev + 1, i - 1))
      end
      prev = i
    end
    if i == #inputString then
      if i - prev < 1 then -- this was `2` before.
        table.insert(t_res, "")
      else
        table.insert(t_res, inputString:sub(prev + 1, i))
      end
    end
  end
  return count, t_res
end

string_util.makeStringLength = function(inputString, maxLength, repl_str)
  repl_str = repl_str or " "

	if #inputString < maxLength then
		local numSpacesToAdd = maxLength - #inputString
		local spaces = string.rep(repl_str, numSpacesToAdd)
		return inputString .. spaces
	else
		return inputString:sub(0,maxLength)
	end
end

return string_util
