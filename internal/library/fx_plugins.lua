local log = require("utils.log")
local format = require("utils.format")
local fu = require("utils.fzf")
local tf = require("utils.j_tables")
local data_loaders = require("pickers.data.load_plugins_data")
local str_util = require("utils.string")
local lib_fx = require("library.fx")
local sx = require("SYNTAX.syntax.syntax")
local sx_utils = require("SYNTAX.lib.util")
-- local midi_editor = require("library.midi_editor")
local lib_tr = require("library.tracks")

local plugins = {}

plugins.get_all_plugins_data = function()
  local results = {}
  local tRatingData = fu.jReadVstData(pluginsData.DATA_INI_FILE)
  results = fu.jReadVstIni(pluginsData.VST_INI_FILE, tRatingData)
  local tTemplates = fu.getTemplates(pluginsData.TEMPLATE_SUB_DIRS, pluginsData.TEMPLATE_ROOT_DIR, tRatingData)
  results = tf.jTablesGlue(tTemplates, results)
  local tFXChains = fu.getFXChains(pluginsData.FXCHAIN_SUB_DIRS, pluginsData.FXCHAIN_ROOT_DIR, tRatingData)
  results = tf.jTablesGlue(tFXChains, results)
  local tJsfx = fu.jReadJsfxIni(pluginsData.JSFX_INI_FILE, tRatingData)
  results = tf.jTablesGlue(tJsfx, results)
  if pluginsData.LOAD_AU then
    local tAu = fu.jReadAuIni(pluginsData.AU_INI_FILE, tRatingData)
    results = tf.jTablesGlue(tAu, results)
  end
  if pluginsData.LOAD_ACTIONS then
    local tActions = data_loaders.jGetActions()
    results = tf.jTablesGlue(tActions, results)
  end
  -- msg(os.clock() - time)
  -- table.sort(results, sortByRating)
  return results
end

plugins.randomize_rs5k_sample = function(trk_obj, target_fx_idx)
  local utils_io = require("utils.fs")
  local numbers = require("utils.numbers")
  local rs5k = require("library.plugins.rs5k")
  -- if we pass a track object, then this should override get focused tracks

  local target_trk_objects, track_objects_list = lib_tr.get_focused_track_objects(trk_obj)

  -- TODO: for each selected track do...

  for _, tobj in pairs(target_trk_objects) do
    -- rename this func to getParentGroupByTrObj and only pass track obj.
    --
    -- TODO: this might actually exist >> if we come from `applySyntax` then
    -- the tree will already exist and could be passed as an argument??
    -- This could be refactored later so that this can become a very flexible
    -- base for updating FX on focused track(s).
    local g_obj, g_tr, _ = sx_utils.getParentGroupByTrIdx(sx.getVerifiedTree(track_objects_list), tobj.trackIndex)
    local fx_idx
    if target_fx_idx then
      fx_idx = target_fx_idx
    else
      local t_fx_by_name = lib_fx.getFxIndexByName(tobj.guid_tr, "ReaSamplomatic")
      if t_fx_by_name then
        fx_idx = t_fx_by_name[1].idx
      else
        goto continue
      end
    end

    -- check that we are working with a midi drum track
    if fx_idx and sx_utils.trackObjHasOption(g_obj, "m") then
      -- TODO: the split table should be assigned to each track in SX
      local t_track_name_parts = str_util.getStringSplitPattern(tobj.name, "%.")
      local t_matched_wav_files = utils_io.findWavFilesWithNameX(t_track_name_parts[1])

      if #t_matched_wav_files > 0 then
        -- maybe both of these funcs should go into one `rs5k.updateSample()`
        local p_wav_file = t_matched_wav_files[numbers.getRandomIndexInRange(1, #t_matched_wav_files)]

        -- TODO: the check for `if rs5k` should be moved into this function so that
        -- the plugins API has an internal nil check and returns false..
        rs5k.updateSample(tobj, fx_idx, p_wav_file)
      else
        log.debug(string.format(
          [[
        [plugins.randomize_rs5k_sample_for_select_tracks_sampler]: No WAV samples
        where found for track (%s) with search string (%s)
        ]] ,
          tobj.name,
          t_track_name_parts[1]
        ))
      end
    else
      log.debug(
        string.format([[ [plugins.randomize_rs5k_...]: %s has no RS5K to load with samples..]], tobj.name)
      )
    end
    ::continue::
  end
end

return plugins
