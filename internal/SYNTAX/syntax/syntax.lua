local log = require('utils.log')
local class_configs = require('SYNTAX.config.config').classes
local format = require('utils.format')
local log = require('utils.log')
local util = require('SYNTAX.lib.util')
local str_util = require('utils.string')

local syntax = {}

------------------------------------------------------------------------------------------

-- refactor
function getNameStringParts(tdx, trk_name)
  local dividers = {}
  local div_char = ':'
  local i = 0
  while true do
    i = string.find(trk_name, div_char, i+1)
    if i == nil then break end
    table.insert(dividers, i)
  end

  if #dividers ~= 2 then
    log.user("TrackNameError: "..tdx.." : 2 dividers are required.") -- format.vttError()
    return false
  end

  local prefix       = string.sub(trk_name, 1, dividers[1]-1)

  -- PREFIX ERROR
  if #prefix ~= 1 then
    log.user("TrackNameError: "..tdx.." : Prefix needs be length 1.") -- format.vttError()
    return false
  end

  -- OPTIONS ERROR
  local options_str = string.sub(trk_name, dividers[1]+1, dividers[2]-1)
  local options_obj = nil
  if #options_str > 0 then
    options_obj = createOptionsTable(tdx, options_str)
    if options_obj == false then
      return false
    end
  end

  -- NAME ERROR
  local name_str = string.sub(trk_name, dividers[2]+1, -1)
  local name_charset = '^[%a%d/_-]*$'
  if string.find(name_str, name_charset) == nil then
    log.user("TrackNameError: "..tdx.." : Name string `"..name_str.."`, has to be of `"..name_charset.."` .") -- format.vttError()
    return false
  end
  -- log.user('.........')
  return prefix, options_obj, name_str
end

function createOptionsTable(i, options_str)
  local options_arr = str_util.getStringSplitPattern(options_str,",")
  local OPTIONS = {}
  for i,s in pairs(options_arr) do
    local char_set = "^[%a]*=[%a%d]*$"
    -- log.user(s, string.find(s, char_set))
    if string.find(s, char_set) == nil then
      log.user("TrackNameError: "..i.." : Option `"..s.."` is incorrect.") -- format.vttError()
      return false
    end

    local eq = string.find(s, "=")
    -- table.insert(OPTIONS,{
    --   name = string.sub(s, 1, eq-1),
    --   value = string.sub(s, eq+1, -1),
    -- })
    OPTIONS[string.sub(s, 1, eq-1)] = string.sub(s, eq+1, -1)
  end
  return OPTIONS
end

-- -- mv to utils
-- function split(pString, pPattern)
--   local Table = {}  -- NOTE: use {n = 0} in Lua-5.0
--   local fpat = "(.-)" .. pPattern
--   local last_end = 1
--   local s, e, cap = pString:find(fpat, 1)
--   while s do
--     if s ~= 1 or cap ~= "" then
--       table.insert(Table,cap)
--     end
--     last_end = e+1
--     s, e, cap = pString:find(fpat, last_end)
--   end
--   if last_end <= #pString then
--     cap = pString:sub(last_end)
--     table.insert(Table, cap)
--   end
--   return Table
-- end

-- mv to virtual_track_table_interface.lua
function createTrackObj(guid, i, p, o, n) -- index; prefix; options; track name
  return {
    guid = guid,
    level = class_configs[p].treeProps.level,
    trackIndex = i, -- can only be used initially if tracks haven't been touched?!
    class = p,
    options = o, -- sub table
    name = n, -- the real tr name
    children = {},
  }
end

function verifyByComparing(tdx, pp, ne) -- prev / next entry
  -- if str_type == 'allowed' and validNext(ne, 'ZGMCABS', 'character not allowed') then return true end
  if pp == nil and  validNext(ne, 'Z',        tdx, 'first track needs to be of class Z')  then return true end
  -- same and conf.class.tree.repeatble??
  if pp == ne  and  validNext(ne, 'MABTS',     tdx, 'Only MABTS can come in sequence')      then return true end
  for i, c in pairs(class_configs) do
    if pp == c.prefix and  validNext(ne, c.treeProps.nxt, tdx, c.prefix .. ' needs to be followed by a ' .. c.treeProps.nxt ) then return true end
  end
  return false
end

function validNext(next_string, next_char_set, err_trk_idx, err_msg)
  -- log.user('validNext: ' .. next_string, next_char_set)
  if util.strHasOneOfChars(next_string, next_char_set) then return true
  else
    log.user("TrackNameError: "..err_trk_idx.." : "..err_msg..".") -- format.vttError()
    return false
  end
end

-- function matchSingleChar(str,char_set)
--   local s,e = string.find(str, "[".. char_set .."]")
--   -- log.user('matchSingleChar: ', string.find(str, "[".. char_set .."]"))
--   if s == 1 then return true end
-- end

-----------------

local vtt = {}
local prev_zone = nil
local prev_group = nil
local prev_mcab = nil
local prev_lvl4_obj = nil
local prev_track_obj = nil

function syntax.getVerifiedTree()
  local next_prefix = nil
  local prev_prefix = nil

  -- log.user('VTT_LEN_PRE: ' .. reaper.CountTracks(0))

  for i=0, reaper.CountTracks(0) - 1 do
    local tr = reaper.GetTrack(0, i)
    local _, track_name_raw = reaper.GetTrackName(tr)
    local next_prefix, next_options, next_track_name = getNameStringParts(i, track_name_raw)
    local guid = reaper.GetTrackGUID(tr)

    -- syntax.verify
    if verifyByComparing(i, prev_prefix, next_prefix) and next_prefix ~= false then
      local next_track_obj = createTrackObj(guid, i, next_prefix, next_options, next_track_name) -- <<<<<<<< TODO
      -- log.user('!!!')
      vttInsertTrack(next_track_obj)

      prev_prefix = next_prefix
    else
      break
    end

  end
  -- log.user('VTT_LEN_POST: ' .. reaper.CountTracks(0))
  -- log.user(format.virtualTrackTable(vtt))
  -- actions.applyMappingsAndOptions(vtt)
  return vtt
end

-- create / popelate tree based on syntax.
function vttInsertTrack(trk_obj)
  --> todo
  ---------------------------------------------------------
  --
  --  This function should be recursive and be merged into.
  --  I think that should work actually.
  --
  ---------------------------------------------------------

  -- log.user('@@')

  -- LEVEL 1 | Z ------------------------------------------------------------
  if trk_obj.level == 1 then -- if level 1
    if util.strHasOneOfChars(trk_obj.class,'Z') then
      if prev_zone  ~= nil then prev_zone.lastTrackIndex  = trk_obj.trackIndex - 1 end
      if prev_group ~= nil then prev_group.lastTrackIndex = trk_obj.trackIndex - 1 end
      vtt[#vtt+1] = trk_obj
      prev_zone = trk_obj -- put below and rename > prev_lvl1_obj = trk_obj
    end
  end
  -- LEVEL 2 | G ------------------------------------------------------------
  if trk_obj.level == 2 then -- if level 2
    if util.strHasOneOfChars(trk_obj.class,'G') then
      if prev_group ~= nil and prev_track_obj.class ~= 'Z' then prev_group.lastTrackIndex = trk_obj.trackIndex - 1 end
      prev_zone.children[#prev_zone.children+1] = trk_obj
      prev_group = trk_obj
    end
  end
  -- LEVEL 3 | MCABT --------------------------------------------------------
  if trk_obj.level == 3 then
    if util.strHasOneOfChars(trk_obj.class,'MCABT') then
      prev_group.children[#prev_group.children+1] = trk_obj
      prev_mcab = trk_obj
    end
  end
  -- level 4 | S ------------------------------------------------------------
  if trk_obj.level == 4 then
    if util.strHasOneOfChars(trk_obj.class,'S') then
      prev_mcab.children[#prev_mcab.children+1] = trk_obj
    end
    prev_lvl4_obj = trk_obj
  end
  prev_track_obj = trk_obj -- keep ref of prev track obj
end

-----------------
-----------------

return syntax


