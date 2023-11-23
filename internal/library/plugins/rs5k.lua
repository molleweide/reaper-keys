local rs5k = {}

-- TODO: add nil checks for rs5k in each func
--

local plugin_name = "ReaSamplOmatic5000"

local function is_the_plugin()
end

rs5k.hasSampleLoaded = function(tobj)
  is_the_plugin()
  local ret, buf = reaper.TrackFX_GetNamedConfigParm(tobj.tr, fx_idx, "FILE0")
  return ret, buf
end

rs5k.updateSample = function(tobj, target_fx_idx, wav_file_path)
  is_the_plugin()
  reaper.TrackFX_SetNamedConfigParm(tobj.tr, target_fx_idx, "FILE0", wav_file_path)
  reaper.TrackFX_SetNamedConfigParm(tobj.tr, target_fx_idx, "DONE", "")
end

return rs5k
