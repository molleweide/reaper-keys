local string_util = {}

-- FIX: what the fuck is this func doing?
function string_util.getStringSplitPattern(pString, pPattern)
  local Table = {}  -- NOTE: use {n = 0} in Lua-5.0
  local fpat = "(.-)" .. pPattern
  local last_end = 1
  local s, e, cap = pString:find(fpat, 1)
  while s do
    if s ~= 1 or cap ~= "" then
      table.insert(Table,cap)
    end
    last_end = e+1
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
string_util.strHasOneOfChars = function(str,char_set)
  local s,_ = string.find(str, "[".. char_set .."]")
  -- log.user('matchSingleChar: ', string.find(str, "[".. char_set .."]"))
  if s == 1 then return true end
end

string_util.split = function(str, sep)
    local parts = {}
    local pattern = string.format("([^%s]+)", sep)
    for part in string.gmatch(str, pattern) do
        table.insert(parts, part)
    end
    return parts
end

return string_util
