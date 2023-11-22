local log = require("utils.log")
local format = require("utils.format")
local fu = require("utils.fzf")
local tf = require("utils.j_tables")
local data_loaders = require("pickers.data.load_plugins_data")
local str_util = require("utils.string")
local lib_fx = require("library.fx")
local sx = require("SYNTAX.syntax.syntax")
local sx_utils = require("SYNTAX.lib.util")

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

plugins.randomize_rs5k_sample = function(trk_obj)
  local track_objects_list = syntax.get_list_of_track_objects()

  if not trk_obj then
    -- if ME active then

    -- find track corresponding to actively editing midi item.
    -- >> randomize

    -- else

    -- TODO: determine which select tracks
    -- 1. get selected track indices
    -- 2. for each track object proceed...

    -- end
  end

  -- TODO: for each selected track do...

  local g_obj, g_tr, _ = sx_utils.getParentGroupByTrIdx(sx.getVerifiedTree(track_objects_list), track_obj.trackIndex)
  local t_fx_by_name = lib_fx.getFxIndexByName(trk_obj.guid_tr, "ReaSamplomatic")

  if not t_fx_by_name or #t_fx_by_name == 0 then
    log.debug(string.format([[ [plugins.randomize_rs5k_...]: %s has no RS5K to load with samples..]], trk_obj.name))
    return
  end

  local target_fx_idx = t_fx_by_name[1].idx

  -- check that we are working with a midi drum track
  if sx_utils.trackObjHasOption(g_obj, "m") then -- drum lanes
    local utils_io = require("utils.fs")
    local numbers = require("utils.numbers")
    local t_track_name_parts = str_util.getStringSplitPattern(trk_obj.name, "%.")
    local t_matched_wav_files = utils_io.findWavFilesWithNameX(t_track_name_parts[1])

    if #t_matched_wav_files > 0 then
      reaper.TrackFX_SetNamedConfigParm(
        trk_obj.tr,
        target_fx_idx,
        "FILE0",
        t_matched_wav_files[numbers.getRandomIndexInRange(1, #t_matched_wav_files)]
      )
      reaper.TrackFX_SetNamedConfigParm(trk_obj.tr, target_fx_idx, "DONE", "")
    else
      log.debug(string.format(
        [[
        [plugins.randomize_rs5k_sample_for_select_tracks_sampler]: No WAV samples
        where found for track (%s) with search string (%s)
        ]],
        trk_obj.name,
        t_track_name_parts[1]
      ))
    end
  end -- if sx has opt 'm'
end

return plugins
