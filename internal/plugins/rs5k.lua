local log = require("utils.log")
local format = require("utils.format")
local str_util = require("utils.string")
local lib_fx = require("library.fx")
local sx = require("SYNTAX.syntax.syntax")
local sx_utils = require("SYNTAX.lib.util")
-- local midi_editor = require("library.midi_editor")
local lib_tr = require("library.tracks")

local rs5k = {}

-- FIX: always pass opts table!!

-- TODO: add debug logs

-- FIX: create a dev func that outputs both the custom name and the raw plugin name.
-- >>> add this to dev log funcs, so that I can do this easilly
-- >>>>>> this can eventually turn into:
--     Create a funcion that iterates through all plugins, and checks if there
--     is already a plugin module for each plugin
--         - if NOT then create a plugin module from template
--         >>>> so that it becomes super easy to handle all possible plugins.
--         >>>>>> only do this with plugins that exist inside a project,
--         so that I dont create too many unused modules...

local plugin_name = "RS5K" -- "ReaSamplOmatic5000"

-- TODO: move the main part to `plugins/utils.lua` so that we can build out a
-- more detailed debug message and other utils involed in manipulating plugin
-- parameters.
local function is_the_plugin(track, fx_idx)
  -- utils.check_if_plugin_exists(track,fx)
  local _, name = reaper.TrackFX_GetFXName(track, fx_idx)
  if name:find(plugin_name) then
    return true
  else
    log.debug(string.format([[Track does not have plugin: %s]], plugin_name))
    return false
  end
end

rs5k.hasSampleLoaded = function(tobj, fx_idx)
  if is_the_plugin(tobj.tr, fx_idx) then
    local ret, buf = reaper.TrackFX_GetNamedConfigParm(tobj.tr, fx_idx, "FILE0")
    return ret, buf
  else
    log.debug(string.format([[xxxxxxxxx]], plugin_name))
  end
end

rs5k.updateSample = function(tobj, fx_idx, wav_file_path)
  if is_the_plugin(tobj.tr, fx_idx) then
    reaper.TrackFX_SetNamedConfigParm(tobj.tr, fx_idx, "FILE0", wav_file_path)
    reaper.TrackFX_SetNamedConfigParm(tobj.tr, fx_idx, "DONE", "")
  end
end

rs5k.randomize_sample = function(trk_obj, target_fx_idx)
  if is_the_plugin(track, target_fx_idx) then
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
      local g_obj, g_tr, _ =
      sx_utils.getParentGroupByTrIdx(sx.getVerifiedTree(track_objects_list), tobj.trackIndex)
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
        ]]   ,
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
end

return rs5k
