-- dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")
local log = require("utils.log")
local format = require("utils.format")
local RS_TrObj = require("SYNTAX.lib.track_obj")
local class_conf = require("SYNTAX.config.config").classes

local reaper_utils = require("custom_actions.utils")
local util = require("SYNTAX.lib.util") -- rename to sxutil
-- local fx_util = require('SYNTAX.lib.fx_util')
local fx_util = require("library.fx")

-- module variables
local div = "_"

local fx = {}

local function checkOldFxHasDiv(old_fx_name)
  -- local old_has_div = false
  if type(old_fx_name) == "string" then
    if old_fx_name:match("_A_") then
      -- old_has_div = true
      return true
    end
  end
  return false
end

--- @return string old_tr_name, string old_rsfx_str
local function getRSFXStrAndTrackName(old_has_div, old_fx_name)
  local old_tr_name, old_rsfx_str
  if old_has_div then
    old_tr_name = old_fx_name:sub(0, old_fx_name:find(div) - 1)
    old_rsfx_str = old_fx_name:sub(old_fx_name:find(div), -1)
    -- return old_fx_name:sub(0, old_fx_name:find(div) - 1), old_fx_name:sub(old_fx_name:find(div), -1)
  else
    -- return "xxx", "xxx"
    old_tr_name = "xxx"
    old_rsfx_str = old_fx_name -- a bit hacky
  end
  return old_tr_name, old_rsfx_str
end

local function getPrevDataForFx(opts_global)
  -- log.user("guid tr", type(opts_global.trk_obj.guid), format.block(opts_global.trk_obj.guid))

  local old_fx_name = fx_util.getSetTrackFxNameByFxChainIndex({
    guid_tr = opts_global.trk_obj.guid,
    idx_fx = opts_global.new_fx_chain_idx,
    is_rec_fx = false,
  })

  -- log.user("##chob/old_fx_name: " .. opts_global.trk_obj.name .. " | " .. tostring(old_fx_name))
  local old_has_div = checkOldFxHasDiv(old_fx_name)
  local old_tr_name, old_rsfx_str = getRSFXStrAndTrackName(old_has_div, old_fx_name)
  return old_has_div, old_tr_name, old_rsfx_str
end

-- local function get_matches(opts)
-- 	local tr_name_match = false
-- 	local rsfx_str_match = false
--
-- 	if old_tr_name == opts.track_obj.name then
-- 		tr_name_match = true
-- 	end
-- 	if old_rsfx_str == new_rsfx_str then
-- 		rsfx_str_match = true
-- 	end
-- 	return tr_name_match, rsfx_str_match
-- end

local function rsfxHandleCode(opts_g, opts_rs)
  if opts_rs.t_rsfx.code ~= nil then
    if opts_rs.old_has_div then
      -- check if there is a match is rsfx string

      if not opts_rs.rsfx_str_match then -- missmatch
        fx_util.replaceFxAtIndex(opts_g.trk_obj.guid, opts_rs.t_rsfx.search_str, opts_g.new_fx_chain_idx) -- after existing
      end
    else -- prev not pre, but still pre syntax > insert at end of pre ( ?????? )
      log.user(
        "INSERT FX @ "
        .. opts_g.trk_obj.guid
        .. " > "
        .. opts_rs.t_rsfx.search_str
        .. " #"
        .. opts_g.new_fx_chain_idx
      )
      fx_util.insertFxAtIndex(opts_g.trk_obj.guid, opts_rs.t_rsfx.search_str, opts_g.new_fx_chain_idx) -- after existing
    end

    -- NOTE: what is this used for???
    rs_fx_pre_count = opts_g.new_fx_chain_idx + 1
  else
    if opts_rs.old_has_div then
      fx_util.removeFxAtIndex(opts_g.trk_obj.guid, opts_g.new_fx_chain_idx)
    end
  end -- A, then B,C
end

local function rsfxUdateFxName(opts_g, opts_rs)
  if not opts_rs.tr_name_match or not opts_rs.rsfx_str_match then -- update name
    fx_util.getSetTrackFxNameByFxChainIndex(
      opts_g.trk_obj.guid,
      opts_g.new_fx_chain_idx,
      false,
      opts_rs.new_fx_name
    ) -- update fxc name
  end
end

-- 1. first we handle standard FX parameters
-- 2. update named config paramteres, if any.
local function rsfxUdateFxParams(i1, opts_g, opts_rs)
  -- first handle regular fx params

  -- TODO: nil check

  for k, rsfx_parm in pairs(opts_rs.t_rsfx.fx_params) do
    -- TODO: create guid api for this
    reaper.TrackFX_SetParam(
      opts_g.tr,
      opts_g.new_fx_chain_idx,
      k,
      -- compute/call get param value
      rsfx_parm.val(opts_g.proll_start_idx, opts_g.tr_range, i1)
    )
  end

  -- NAMED CONFIG PARAMS
  -- eg. this is where samples are being assigned to RS5Ks
  if type(opts_rs.t_rsfx.named_config_params) == "function" then
    opts_rs.t_rsfx.named_config_params(opts_g, opts_rs.t_rsfx)
  end
end

-- Concatenate the full name string to be used in fx chain
--
--
local function getSingleRSFXName(child_obj, new_fx_chain_idx, RSFX_IDX, ridx, rsfx)
  local name_str = rsfx.code .. div .. new_fx_chain_idx .. div .. rsfx.rsfx_name .. div .. ridx
  name_str = child_obj.name .. div .. name_str

  local new_rsfx_str = name_str:sub(name_str:find(div), -1)

  return name_str, new_rsfx_str
end

local function computeSyntaxLength(child_obj, RSFX_LIST)
  local fx_tot = 0
  local tr_range = 1
  for i = 0, #RSFX_LIST do
    if RSFX_LIST[i].spawnByRange and RS_TrObj.trackHasOption(child_obj, "nr") then
      tr_range = child_obj.options.nr
      for r = 0, tr_range - 1 do
        fx_tot = fx_tot + 1
      end
    else
      fx_tot = fx_tot + 1
    end
  end
  return fx_tot
end

local function handleFXChainSyntaxPostFx(opts_global)
  if 0 < opts_global.old_fx_chain_count - opts_global.new_fx_chain_idx then
    for _ = opts_global.new_fx_chain_idx, opts_global.old_fx_chain_count - 1 do
      local ofxn =
      fx_util.getSetTrackFxNameByFxChainIndex(opts_global.trk_obj.guid, opts_global.new_fx_chain_idx, false)
      local old_has_div = checkOldFxHasDiv(ofxn)
      if old_has_div then
        fx_util.removeFxAtIndex(opts_global.trk_obj.guid, opts_global.new_fx_chain_idx) -- don't increment index if we remove
        -- log.user('rm excess pre')
      else
        opts_global.new_fx_chain_idx = opts_global.new_fx_chain_idx + 1
      end
    end
  end
end

function fx.applyConfFxToChildObj(child_obj, proll_start_idx, opt_type) -- change to drum_map_note_start
  local tr, _ = reaper_utils.getTrackByGUID(child_obj.guid)
  if tr == nil or child_obj == nil then
    return
  end

  -- NOTE: I put together a table of all
  local opts_global = {
    tr = tr,
    tr_range = RS_TrObj.trackHasOption(child_obj, "nr") and child_obj.options.nr or 1,
    trk_obj = child_obj,
    proll_start_idx = proll_start_idx,
    opt_type = opt_type,
    new_fx_chain_idx = 0,
    old_fx_chain_count = reaper.TrackFX_GetCount(tr),
  }

  local RSFX_LIST = class_conf[child_obj.class].fx_syntax[opt_type]

  -- each syntax table component
  for RSFX_IDX = 0, #RSFX_LIST do
    -- TODO: attach this table as sub table of opts_g
    local opts_rsfx_idx = {
      spawn_num = (RS_TrObj.trackHasOption(child_obj, "nr") and RSFX_LIST[RSFX_IDX].spawnByRange)
          and child_obj.options.nr
          or 1,
      t_rsfx = RSFX_LIST[RSFX_IDX],
    }

    for i1 = 0, opts_rsfx_idx.spawn_num - 1 do -- syntax spawn num =============================
      -- TODO: put this into opts_rsfx_idx.old_data
      local old_has_div, old_tr_name, old_rsfx_str = getPrevDataForFx(opts_global)

      -- TODO: reduce paramaters to opts table
      local new_fx_name, new_rsfx_str =
      getSingleRSFXName(child_obj, opts_global.new_fx_chain_idx, RSFX_IDX, i1, RSFX_LIST[RSFX_IDX])

      opts_rsfx_idx.old_has_div = old_has_div
      opts_rsfx_idx.new_fx_name = new_fx_name
      opts_rsfx_idx.tr_name_match = old_tr_name == child_obj.name and true or false
      opts_rsfx_idx.rsfx_str_match = old_rsfx_str == new_rsfx_str and true or false

      -- log.user(
      --   "\n\n - fx info -----------------------------\n"
      --   .. "opts_global.tr_range: "
      --   .. opts_global.tr_range
      --   .. "\n"
      --   .. "old has div"
      --   .. tostring(old_has_div)
      --   .. "\n"
      --   .. "old/new tr name: \t"
      --   .. old_tr_name
      --   .. " => "
      --   .. child_obj.name
      --   .. "\n"
      --   -- 'new_pre_fx_count' .. new_pre_fx_count .. '\n' ..
      --   .. "rsfx_str old/new: \t"
      --   .. tostring(old_rsfx_str)
      --   .. " => "
      --   .. new_rsfx_str
      --   .. "\n"
      --   .. "match name/rsfx: \t"
      --   .. tostring(opts_rsfx_idx.tr_name_match)
      --   .. " | "
      --   .. tostring(opts_rsfx_idx.rsfx_str_match)
      --   .. "\n"
      -- )

      rsfxHandleCode(opts_global, opts_rsfx_idx)
      rsfxUdateFxName(opts_global, opts_rsfx_idx)
      rsfxUdateFxParams(i1, opts_global, opts_rsfx_idx)

      opts_global.new_fx_chain_idx = opts_global.new_fx_chain_idx + 1
    end -- FX
  end -- RSFX_LIST

  handleFXChainSyntaxPostFx(opts_global)

  -- log.user('new fx chain count: ' .. opts_global.new_fx_chain_idx .. '\n\n\n')

  return true
end

return fx
