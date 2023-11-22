
local rs5k = {}

rs5k.hasSampleLoaded = function ()

end

rs5k.updateSample = function ()

        reaper.TrackFX_SetNamedConfigParm(
          tobj.tr,
          target_fx_idx,
          "FILE0",
          t_matched_wav_files[numbers.getRandomIndexInRange(1, #t_matched_wav_files)]
        )
        reaper.TrackFX_SetNamedConfigParm(tobj.tr, target_fx_idx, "DONE", "")
end

return rs5k
