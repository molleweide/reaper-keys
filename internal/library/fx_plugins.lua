local log = require("utils.log")
local format = require("utils.format")
local fu = require("utils.fzf")
local tf = require("utils.j_tables")
local data_loaders = require("pickers.data.load_plugins_data")
local str_util = require("utils.string")
local lib_fx = require("library.fx")
local sx = require("SYNTAX.syntax.syntax")
local sx_utils = require("SYNTAX.lib.util")
local midi_editor = require("library.midi_editor")

local cust_util = require("custom_actions.utils")

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
  local target_trk_objects = {}
  local track_objects_list = syntax.get_list_of_track_objects()

  -- collect target tracks
  if trk_obj then
    table.insert(target_trk_objects, trk_obj)
  else
    local ME_ACTIVE, ME = midi_editor.getMidiValidContext(hwnd)
    if ME_ACTIVE then

      -- find track corresponding to actively editing midi item.
      -- >> randomize
    else
      local t_sel_trk_indices = cust_util.getSelectedTrackIndices()
      for _, tidx in ipairs(t_sel_trk_indices) do
        -- these should map 1:1 with track_objects_list
        table.insert(target_trk_objects, track_objects_list[tidx])
      end
    end
  end

  -- TODO: for each selected track do...

  for _, tobj in pairs(target_trk_objects) do
    -- rename this func to getParentGroupByTrObj and only pass track obj.
    local g_obj, g_tr, _ = sx_utils.getParentGroupByTrIdx(sx.getVerifiedTree(track_objects_list), tobj.trackIndex)
    local t_fx_by_name = lib_fx.getFxIndexByName(tobj.guid_tr, "ReaSamplomatic")

    -- check that we are working with a midi drum track
    if sx_utils.trackObjHasOption(g_obj, "m") and #t_fx_by_name > 0 then
      local target_fx_idx = t_fx_by_name[1].idx
      local utils_io = require("utils.fs")
      local numbers = require("utils.numbers")
      local t_track_name_parts = str_util.getStringSplitPattern(tobj.name, "%.")
      local t_matched_wav_files = utils_io.findWavFilesWithNameX(t_track_name_parts[1])

      if #t_matched_wav_files > 0 then
        -- maybe both of these funcs should go into one `rs5k.updateSample()`
        reaper.TrackFX_SetNamedConfigParm(
          tobj.tr,
          target_fx_idx,
          "FILE0",
          t_matched_wav_files[numbers.getRandomIndexInRange(1, #t_matched_wav_files)]
        )
        reaper.TrackFX_SetNamedConfigParm(tobj.tr, target_fx_idx, "DONE", "")
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
  end
end

return plugins
