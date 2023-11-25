local log = require("utils.log")
local format = require("utils.format")
local str_util = require("utils.string")
local lib_fx = require("library.fx")
local sx = require("syntax.tracks")
local sxlu = require("syntax.utils")
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


-- TODO: move the main part to `plugins/utils.lua` so that we can build out a
-- more detailed debug message and other utils involed in manipulating plugin
-- parameters.
local function is_the_plugin(track, fx_idx)
  -- utils.check_if_plugin_exists(track,fx)
  local _, name = reaper.TrackFX_GetFXName(track, fx_idx)
  if name:find(rs5k.PLUGIN_NAME) then
    return true
  else
    log.debug(string.format([[Track does not have plugin: %s]], rs5k.PLUGIN_NAME))
    return false
  end
end

rs5k.PLUGIN_NAME = "RS5K" -- "ReaSamplOmatic5000"

rs5k.hasSampleLoaded = function(tobj, fx_idx)
  if is_the_plugin(tobj.tr, fx_idx) then
    local ret, buf = reaper.TrackFX_GetNamedConfigParm(tobj.tr, fx_idx, "FILE0")
    return ret, buf
  else
    log.debug(string.format([[xxxxxxxxx]], rs5k.PLUGIN_NAME))
  end
end

-- if there is no wav_file supplied, then tries to update the sampler randomly
-- based on its track name
rs5k.updateSample = function(tobj, fx_idx, wav_file_path)
  if is_the_plugin(tobj.tr, fx_idx) then


    if not wav_file_path then
      local utils_io = require("utils.fs")
      local numbers = require("utils.math")
      local t_matched_wav_files = utils_io.findWavFilesWithNameX(tobj.name_components[1])

      if #t_matched_wav_files > 0 then
        -- log.user("??")
        wav_file_path = t_matched_wav_files[numbers.getRandomIndexInRange(1, #t_matched_wav_files)]
      else
        -- todo: refactor this into a nice plugins util debug message func
        log.debug(string.format(
          [[
        [plugins.randomize_rs5k_sample_for_select_tracks_sampler]: No WAV samples
        where found for track (%s) with search string (%s)
        ]] ,
          tobj.name,
          tobj.name_components[1]
        ))
        return
      end
    end

    log.user(tobj.name, tobj.name_components[1], ">>> wav:", wav_file_path )

    reaper.TrackFX_SetNamedConfigParm(tobj.tr, fx_idx, "FILE0", wav_file_path)
    reaper.TrackFX_SetNamedConfigParm(tobj.tr, fx_idx, "DONE", "")
  end
end

return rs5k
