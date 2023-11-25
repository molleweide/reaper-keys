-- dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")
local log = require("utils.log")
local format = require("utils.format")
local class_conf = require("definitions.syntax.config").classes

local reaper_utils = require("custom_actions.utils")
local fx_util = require("library.fx")

local sx_tracks = require("SYNTAX.tracks")

-- module variables
local div = "_" -- move to constants, or syntax config?

local fx = {}

-- local function compute_syntax_name_string_length(child_obj, T_TRACK_CLASS_FX_SX)
--   local fx_tot = 0
--   local tr_range = 1
--   for i = 0, #T_TRACK_CLASS_FX_SX do
--     if T_TRACK_CLASS_FX_SX[i].spawnByRange and sx_tracks.trackHasOption(child_obj, "nr") then
--       tr_range = child_obj.options.nr
--       for _ = 0, tr_range - 1 do
--         fx_tot = fx_tot + 1
--       end
--     else
--       fx_tot = fx_tot + 1
--     end
--   end
--   return fx_tot
-- end

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

local function getPrevDataForFx(state)
  -- log.user("guid tr", type(state.trk_obj.guid), format.block(state.trk_obj.guid))

  local old_fx_name = fx_util.getSetTrackFxNameByFxChainIndex({
    guid_tr = state.trk_obj.guid,
    idx_fx = state.new_fx_chain_idx,
    is_rec_fx = false,
  })

  -- log.user("##chob/old_fx_name: " .. state.trk_obj.name .. " | " .. tostring(old_fx_name))
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

-- handle_UI_name_prefix??
local function handle_ui_name_code(state, sx_fx_opts, sx_fx_state)
  if sx_fx_opts.t_sx_current_fx.code ~= nil then
    if sx_fx_state.old_has_div then
      -- check if there is a match is rsfx string

      if not sx_fx_state.rsfx_str_match then -- missmatch
        fx_util.replaceFxAtIndex(
          state.trk_obj.guid,
          sx_fx_state.t_sx_current_fx.search_str,
          state.new_fx_chain_idx
        ) -- after existing
      end
    else -- prev not pre, but still pre syntax > insert at end of pre ( ?????? )
      log.user(
        "INSERT FX @ "
        .. state.trk_obj.guid
        .. " > "
        .. sx_fx_opts.t_sx_current_fx.search_str
        .. " #"
        .. state.new_fx_chain_idx
      )
      fx_util.insertFxAtIndex(state.trk_obj.guid, sx_fx_opts.t_sx_current_fx.search_str, state.new_fx_chain_idx) -- after existing
    end

    -- NOTE: what is this used for???
    rs_fx_pre_count = state.new_fx_chain_idx + 1
  else
    if sx_fx_state.old_has_div then
      fx_util.removeFxAtIndex(state.trk_obj.guid, state.new_fx_chain_idx)
    end
  end -- A, then B,C
end

local function update_ui_fx_name(state, sx_fx_state)
  if not sx_fx_state.tr_name_match or not sx_fx_state.rsfx_str_match then -- update name
    fx_util.getSetTrackFxNameByFxChainIndex(
      state.trk_obj.guid,
      state.new_fx_chain_idx,
      false,
      sx_fx_state.new_fx_name
    ) -- update fxc name
  end
end

-- 1. first we handle standard FX parameters
-- 2. update named config paramteres, if any.
local function handle_fx_params(spawn_idx, state, sx_fx_opts)
  if #sx_fx_opts.t_sx_current_fx.fx_params > 0 then
    for pidx, parameter_func in pairs(sx_fx_opts.t_sx_current_fx.fx_params) do
      reaper.TrackFX_SetParam(
        state.trk_obj.tr,
        state.new_fx_chain_idx,
        pidx,
        parameter_func(state.proll_start_idx, state.tr_range, spawn_idx)
      )
    end
  end
  if type(sx_fx_opts.t_sx_current_fx.named_config_params) == "function" then
    sx_fx_opts.t_sx_current_fx.named_config_params(state, sx_fx_opts.t_sx_current_fx)
  end
end

local function concat_full_UI_fx_name_string(state, ridx, rsfx)
  local name_str = rsfx.code .. div .. state.new_fx_chain_idx .. div .. rsfx.rsfx_name .. div .. ridx
  name_str = state.trk_obj.name .. div .. name_str
  local new_rsfx_str = name_str:sub(name_str:find(div), -1)
  return name_str, new_rsfx_str
end

local function handle_syntax_fx_chain_post_fx(state)
  if 0 < state.old_fx_chain_count - state.new_fx_chain_idx then
    for _ = state.new_fx_chain_idx, state.old_fx_chain_count - 1 do
      local ofxn =
      fx_util.getSetTrackFxNameByFxChainIndex(state.trk_obj.guid, state.new_fx_chain_idx, false)
      local old_has_div = checkOldFxHasDiv(ofxn)
      if old_has_div then
        fx_util.removeFxAtIndex(state.trk_obj.guid, state.new_fx_chain_idx) -- don't increment index if we remove
        -- log.user('rm excess pre')
      else
        state.new_fx_chain_idx = state.new_fx_chain_idx + 1
      end
    end
  end
end

local function sx_get_prepare_single_fx_state(state, spawn_idx, sxfx_opts)
  local old_has_div, old_tr_name, old_rsfx_str = getPrevDataForFx(state)
  local new_fx_name, new_rsfx_str = concat_full_UI_fx_name_string(state, spawn_idx, sxfx_opts.t_sx_current_fx)
  return {
    old_has_div = old_has_div,
    new_fx_name = new_fx_name,
    tr_name_match = old_tr_name == state.trk_obj.name and true or false,
    rsfx_str_match = old_rsfx_str == new_rsfx_str and true or false,
  }
end

local function apply_single_effect(state, sxfx_opts)
  for spawn_idx = 0, sxfx_opts.spawn_num - 1 do -- syntax spawn num =============================
    local sx_fx_state = sx_get_prepare_single_fx_state(state, spawn_idx, sxfx_opts)
    handle_ui_name_code(state, sxfx_opts, sx_fx_state)
    update_ui_fx_name(state, sx_fx_state)
    handle_fx_params(spawn_idx, state, sxfx_opts)
    state.new_fx_chain_idx = state.new_fx_chain_idx + 1
  end
end

-- apply fx syntax to track
function fx.track_apply_fx_configs(child_obj, proll_start_idx, opt_type) -- change to drum_map_note_start
  local tr, _ = reaper_utils.getTrackByGUID(child_obj.guid)
  if tr == nil or child_obj == nil then
    return
  end

  child_obj.tr = tr

  -- TODO: reattach track to child object and only use the track_obj moving forward

  -- TODO: refactor the attachement of range to track object into the initial
  -- parsing of the syntax track list.

  -- NOTE: I put together a table of all
  local state = {
    tr = tr, -- move into trk_obj
    tr_range = sx_tracks.trackHasOption(child_obj, "nr") and child_obj.options.nr or 1, -- move into trk_obj
    trk_obj = child_obj,
    proll_start_idx = proll_start_idx,
    opt_type = opt_type, -- move into trk_obj
    new_fx_chain_idx = 0,
    old_fx_chain_count = reaper.TrackFX_GetCount(tr),
  }

  local T_TRACK_CLASS_FX_SX = class_conf[child_obj.class].fx_syntax[opt_type]
  for sxfx_idx = 0, #T_TRACK_CLASS_FX_SX do
    apply_single_effect(state, {
      spawn_num = (sx_tracks.trackHasOption(child_obj, "nr") and T_TRACK_CLASS_FX_SX[sxfx_idx].spawnByRange)
          and child_obj.options.nr
          or 1,
      t_sx_current_fx = T_TRACK_CLASS_FX_SX[sxfx_idx],
    })
  end -- T_TRACK_CLASS_FX_SX

  handle_syntax_fx_chain_post_fx(state)

  -- log.user('new fx chain count: ' .. state.new_fx_chain_idx .. '\n\n\n')

  return true
end

return fx
