local log = require("utils.log")
local format = require("utils.format")
local str_util = require("utils.string")

local class_configs = require("definitions.syntax.config").classes
local sxu = require("syntax.utils")

local sx_tracks = {}

-- TODO: better error handling in general -> now there is some type mismatch
-- because I sometimes return bools/nil when funcs expect strings in the normal
-- case.

local function createOptionsTable(trk_idx, options_str)
  local options_arr = str_util.getStringSplitPattern(options_str, ",")
  local OPTIONS = {}
  for _, s in pairs(options_arr) do
    local char_set = "^[%a]*=[%a%d]*$"
    -- log.user(s, string.find(s, char_set))
    if string.find(s, char_set) == nil then
      log.user("TrackNameError: " .. trk_idx .. " : Option `" .. s .. "` is incorrect.") -- format.vttError()
      return false
    end
    local eq = string.find(s, "=")
    -- table.insert(OPTIONS,{
    --   name = string.sub(s, 1, eq-1),
    --   value = string.sub(s, eq+1, -1),
    -- })
    OPTIONS[string.sub(s, 1, eq - 1)] = string.sub(s, eq + 1, -1)
  end
  return OPTIONS
end

---
---@param tr_idx number
---@param trk_name string
---@return
local function getNameStringParts(tr_idx, trk_name)
  local dividers = {}
  local div_char = ":"
  local i = 0
  while true do
    i = string.find(trk_name, div_char, i + 1)
    if i == nil then
      break
    end
    table.insert(dividers, i)
  end

  if #dividers ~= 2 then
    log.user("TrackNameError: " .. tr_idx .. " : 2 dividers are required.") -- format.vttError()
    return false
  end

  local prefix = string.sub(trk_name, 1, dividers[1] - 1)

  -- PREFIX ERROR
  if #prefix ~= 1 then
    log.user("TrackNameError: " .. tr_idx .. " : Prefix needs be length 1.") -- format.vttError()
    return false
  end

  -- OPTIONS ERROR
  local options_str = string.sub(trk_name, dividers[1] + 1, dividers[2] - 1)
  local options_obj = nil
  if #options_str > 0 then
    options_obj = createOptionsTable(tr_idx, options_str)
    if options_obj == false then
      return false
    end
  end

  -- NAME ERROR
  local name_str = string.sub(trk_name, dividers[2] + 1, -1)
  local name_charset = "^[%a%d/_-]-%.?[%a%d/_-]-$"
  if string.find(name_str, name_charset) == nil then
    log.user(
      "TrackNameError: "
      .. tr_idx
      .. " : Name string `"
      .. name_str
      .. "`, has to be of `"
      .. name_charset
      .. "` ."
    ) -- format.vttError()
    return false
  end
  -- log.user('.........')
  return prefix, options_obj, name_str
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

---@param next_prefix string
---@param next_char_set string
---@param err_trk_idx number
---@param err_msg string
---@return boolean
local function validNext(next_prefix, next_char_set, err_trk_idx, err_msg)
  -- log.user('validNext: ' .. next_prefix, next_char_set)
  if str_util.strHasOneOfChars(next_prefix, next_char_set) then
    return true
  else
    log.user("TrackNameError: " .. err_trk_idx .. " : " .. err_msg .. ".") -- format.vttError()
    return false
  end
end

---
---@param tr_idx number
---@param prev_prefix string
---@param next_prefix boolean | string | nil
---@return boolean
local function verifyByComparing(tr_idx, prev_prefix, next_prefix) -- prev / next entry
  -- if str_type == 'allowed' and validNext(next_prefix, 'ZGMCABS', 'character not allowed') then return true end
  if prev_prefix == nil and validNext(next_prefix, "Z", tr_idx, "first track needs to be of class Z") then
    return true
  end

  -- same and conf.class.tree.repeatble??
  if prev_prefix == next_prefix and validNext(next_prefix, "MABTS", tr_idx, "Only MABTS can come in sequence") then
    return true
  end

  for _, c in pairs(class_configs) do
    if prev_prefix == c.prefix
        and validNext(
          next_prefix,
          c.treeProps.nxt,
          tr_idx,
          c.prefix .. " needs to be followed by a " .. c.treeProps.nxt
        )
    then
      return true
    end
  end
  return false
end

-- function matchSingleChar(str,char_set)
--   local s,e = string.find(str, "[".. char_set .."]")
--   -- log.user('matchSingleChar: ', string.find(str, "[".. char_set .."]"))
--   if s == 1 then return true end
-- end

sx_tracks.get_track_obj_for_idx = function(trIdx)
  local next_tr = reaper.GetTrack(0, trIdx)
  local guid = reaper.GetTrackGUID(next_tr)
  local _, track_name_raw = reaper.GetTrackName(next_tr)
  local next_prefix, next_options, next_track_name = getNameStringParts(trIdx, track_name_raw)

  -- FIX: type conversion, eg. of nr=3 should be tonumber() so that 3 is a num and not string

  return {
    tr = next_tr,
    guid = guid,
    level = class_configs[next_prefix].treeProps.level, -- revise later
    trackIndex = trIdx,
    class = next_prefix,
    options = next_options, -- sub table
    name = next_track_name, -- the real next_tr name
    name_components = str_util.getStringSplitPattern(next_track_name, "%."),
    name_raw = track_name_raw,
    children = {},
  }
end

-----------------

function sx_tracks.get_list_of_track_objects()
  local t_track_objects = {}
  local prev_prefix = nil -- prev class

  for trIdx = 0, reaper.CountTracks(0) - 1 do
    local next_track_obj = sx_tracks.get_track_obj_for_idx(trIdx)

    if verifyByComparing(trIdx, prev_prefix, next_track_obj.class) and next_track_obj.class ~= false then
      table.insert(t_track_objects, next_track_obj)
      prev_prefix = next_track_obj.class
    else
      break
    end
  end
  -- log.user('VTT_LEN_POST: ' .. reaper.CountTracks(0))
  return t_track_objects
end

-- create / popelate tree based on syntax.
-- >> This function should be recursive and be merged into.
--    I think that should work actually.
sx_tracks.make_tree = function(t_trk_objs)
  local vtt = {
    track_list = t_trk_objs,
    groups = {},
    -- midi_tracks = {}
    -- audio_tracks = {},
    -- buss_tracks = {},
    -- text_tracks = {},
    channel_splitters = {},
    -- splitt
  }
  local prev_zone = nil
  local prev_group = nil
  local prev_mcab = nil
  local prev_lvl4_obj = nil
  local prev_track_obj = nil

  -- TODO: i should also map each child to child.parent = zone/group/C/...

  -- TODO: each if conditional block should be refactored into a single
  -- function that makes it easier to visualize what is going on here.

  local function tree_process_trk_obj(trk_obj, check_curr_cls) end

  -- TODO: assign surrounding context info to trk_objs.
  -- Eg. assign Z and G to each MCABS.

  for i, trk_obj in ipairs(t_trk_objs) do
    -- LEVEL 1 | Z ------------------------------------------------------------
    if trk_obj.level == 1 then
      -- log.user(i)

      if str_util.strHasOneOfChars(trk_obj.class, "Z") then
        if prev_zone ~= nil then
          prev_zone.lastTrackIndex = trk_obj.trackIndex - 1
        end
        if prev_group ~= nil then
          prev_group.lastTrackIndex = trk_obj.trackIndex - 1
        end
        vtt[#vtt + 1] = trk_obj
        prev_zone = trk_obj -- put below and rename > prev_lvl1_obj = trk_obj
      end
    end

    -- LEVEL 2 | G ------------------------------------------------------------
    if trk_obj.level == 2 then
      if str_util.strHasOneOfChars(trk_obj.class, "G") then
        if prev_group ~= nil and prev_track_obj.class ~= "Z" then
          prev_group.lastTrackIndex = trk_obj.trackIndex - 1
        end
        prev_zone.children[#prev_zone.children + 1] = trk_obj
        prev_group = trk_obj
        trk_obj.zone = prev_zone
        table.insert(vtt.groups, trk_obj)
      end
    end

    -- LEVEL 3 | MCABT --------------------------------------------------------
    if trk_obj.level == 3 then
      if str_util.strHasOneOfChars(trk_obj.class, "MCABT") then
        prev_group.children[#prev_group.children + 1] = trk_obj
        trk_obj.zone = prev_zone
        trk_obj.group = prev_group
        prev_mcab = trk_obj
        if trk_obj.class == "C" then
          table.insert(vtt.channel_splitters, trk_obj)
        end
      end
    end

    -- level 4 | S ------------------------------------------------------------
    if trk_obj.level == 4 then
      if str_util.strHasOneOfChars(trk_obj.class, "S") then
        trk_obj.zone = prev_zone
        trk_obj.group = prev_group
        trk_obj.channel_splitter = prev_mcab
        prev_mcab.children[#prev_mcab.children + 1] = trk_obj
      end
      prev_lvl4_obj = trk_obj
    end

    --------
    prev_track_obj = trk_obj -- keep ref of prev track obj
  end
  return vtt
end

-- Recursively flatten vtt tree.
--
-- The `make_tree` func assigns a lot of useful metadata to each track object.
-- Therefore, it can be useful to get a flattened list again of all track objs
-- for use in eg. picker results, so that I can filter by class etc. ZGMCABS.
sx_tracks.tree_make_flat = function(t_trk_objs)
  local flat_list = {}

  local function make_flat(t)
    for _, v in pairs(t) do
      table.insert(flat_list, v)
      if v.children then
        make_flat(v.children)
      end
    end
  end

  make_flat(t_trk_objs)
end

sx_tracks.getVerifiedTree = function(sx_list)
  local vtt = sx_list and sx_tracks.make_tree(sx_list) or sx_tracks.make_tree(sx_tracks.get_list_of_track_objects())
  sxu.DRUMKITS_extend_with_context(vtt)
  return vtt
end

sx_tracks.trackHasOption = function(trk_obj, opt)
  if trk_obj.options ~= nil then
    if trk_obj.options[opt] ~= nil then
      return true
    else
      log.user("TrackOptionError: " .. trk_obj.trackIndex .. " : Track does not have option: `" .. opt .. "`.") -- add group name to this err msg
      return false
    end
  else
    -- log.user("TrackOptionError: "..trk_obj.trackIndex.." : Track does not have any options.") -- add group name to this err msg
    return false
  end
end

return sx_tracks
