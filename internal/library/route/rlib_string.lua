local ru = require("custom_actions.utils")
local log = require("utils.log")
local format = require("utils.format")
local str_util = require("utils.string")
local midi_util = require("utils.midi")
local r = require("utils.reaper")
local rc = require("definitions.routing")

local rlib_targets = require("library.route.rlib_targets")

-- FIX: rename `t_route_opts` to `t_route_opts`

local rlib_string = {}

-- TODO: this should go into the config file
local USER_INPUT_TARGETS_DIV = "|"

function extract_route_secondary_param(str, key)
  -- TODO: i have to document this pattern better
  --
  --
  -- NOTE: pattern looking for:
  -- 1. Either of these first `!?`
  -- 2. Target `character`, eg. "a"
  -- 3. num ?dot ?num ?num ?num ?num
  --
  local pattern = "!?" .. key .. "%d?%.?%d?%d?%d?%d?" -- very generic pattern

  local s, e = string.find(str, pattern)
  local mv_offset = 1
  local retval = false
  local matched_value
  local prefix

  if s ~= nil and e ~= nil then
    retval = true
    local sub_pattern = string.sub(str, s, e)
    prefix = string.sub(sub_pattern, 0, 1)
    if prefix == "!" then
      mv_offset = 2
    end
    matched_value = string.sub(str, s + mv_offset, e)
  end

  return retval, matched_value, prefix
end

--- Extract information about which data channels to target, ie. audio/midi
---@param str
---@param bracket_type
---@param sep
---@param allowed_range_low
---@param allowed_range_high
---@return
function extract_channel_info(str, bracket_type, sep, allowed_range_low, allowed_range_high)
  local dataBracket, str = str_util.extract_string_inside_brackets(str, bracket_type)
  local bSrc, bDst
  if dataBracket ~= nil then
    local dataBracketSplit = str_util.getStringSplitPattern(dataBracket, sep)
    for d = 1, #dataBracketSplit do
      local D = tonumber(dataBracketSplit[d])
      if D < allowed_range_low or D > allowed_range_high then
        D = 0
      end
      if d == 1 then
        if D ~= nil then
          bDst = D
        else
          bDst = 0
        end
      end
      if d == 2 then
        bSrc = bDst
        if D ~= nil then
          bDst = D
        else
          bDst = 0
        end
        break
      end
    end
  end
  return str, bSrc, bDst
end

--- Tries to extract a requested route config secondary param.
--- Defaults are assigned if pattern not found.
---@param t_route_opts table
---@param str string
---@param key string
---@param primary number
---@return table, string
function extract_secondary_param_mappings(t_route_opts, str, key, primary)
  local ret, val, pre = extract_route_secondary_param(str, key)
  -- log.user(key, ret, val, pre)

  --
  -- UPDATE ROUTE CONFIG
  --

  -- FIX: since t_route_opts.default_params holds everything i just
  -- need to access the

  -- exists or PRIMARY
  if ret or primary ~= nil then
    if primary ~= nil then
      val = primary
    else
      val = tonumber(val)
    end

    if ret and val == nil then
      val = t_route_opts.default_params[key].param_value
    end

    t_route_opts.new_params[key] = {
      description = t_route_opts.default_params[key].description,
      param_name = t_route_opts.default_params[key].param_name,
      param_value = val,
    }

    -- exists and prefix
    if ret and pre == "!" then
      t_route_opts.new_params[key].param_value = t_route_opts.default_params[key].disable_value
    end
  end

  return t_route_opts, str
end

rlib_string.ensure_src_dst_nodes = function(t_route_opts, str, src_tr_data, dst_tr_data)
  local ret
  ret, src_tr_data, dst_tr_data, str = str_util.extract_parenthesis(str) -- extractParenthesisTargets(str)
  -- Ensure source nodes
  if src_tr_data ~= nil then
    local src_tr_split = str_util.getStringSplitPattern(src_tr_data, USER_INPUT_TARGETS_DIV)
    ret, t_route_opts = rlib_targets.setRouteTargetGuids(t_route_opts, "src_guids", src_tr_split)
  elseif r.isSel() then
    -- defaults to setting selected tracks as `sources` to pull from if no
    -- src targets found in input string

    -- t_route_opts.src_from_selection = true
    -- if t_route_opts.category == 0 then
    t_route_opts["src_guids"] = r.getSelectedTracksGUIDs()
    -- end
  end

  -- Ensure dest nodes.
  if dst_tr_data ~= nil then
    local dst_tr_split = str_util.getStringSplitPattern(dst_tr_data, USER_INPUT_TARGETS_DIV)
    ret, t_route_opts = rlib_targets.setRouteTargetGuids(t_route_opts, "dst_guids", dst_tr_split)
  end
  return ret
end

-- NOTE: Order of operations:
-- 1. extract src/dest parenthesis
-- 2. extract channel info from {}/[]
-- 3. extract other (secondary) parameter mappings
--
--- Extracts route parameters from the config string
---@param t_route_opts
---@param str
---@return
function rlib_string.extractParamsFromString(t_route_opts, str)
  -- find first literal hyphen
  if str:find("%-") then
    t_route_opts.remove_routes = true
    t_route_opts.remove_both = true
  end

  -- find any # literal
  if str:find("%#") then
    t_route_opts.category = 0
    t_route_opts.remove_both = false
  end

  -- find any dollar literal
  if str:find("%$") then
    t_route_opts.category = -1 -- ???
    t_route_opts.remove_both = false
  end

  local ret, src_tr_data, dst_tr_data, str = str_util.extract_parenthesis(str) -- extractParenthesisTargets(str)
  rlib_string.ensure_src_dst_nodes(t_route_opts, str, src_tr_data, dst_tr_data)

  -- what is b ??
  local str, bSrc, bDst = extract_channel_info(str, "[]", t_route_opts.meta.channel_data_separator, 0, 6)
  local str, cSrc, cDst = extract_channel_info(str, "{}", t_route_opts.meta.channel_data_separator, 0, 16)

  t_route_opts, str = extract_secondary_param_mappings(t_route_opts, str, "a", bSrc)
  t_route_opts, str = extract_secondary_param_mappings(t_route_opts, str, "d", bDst)
  t_route_opts, str = extract_secondary_param_mappings(
    t_route_opts,
    str,
    "m",
    (cSrc and cDst) and midi_util.create_send_flags(cSrc, cDst)
  )

  -- NOTE: what is the purpose of this? To force overwrite?!
  ret, val, pre = extract_route_secondary_param(str, "u")
  if ret then
    t_route_opts.overwrite = true
  end

  return true, t_route_opts
end

return rlib_string
