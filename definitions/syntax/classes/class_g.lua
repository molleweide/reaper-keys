return {
  prefix = "G",
  treeProps = { level = 2, nxt = "MCABT", rep = false, cont = true },
  trackProps = {
    trackHeight = { attrString = "I_HEIGHTOVERRIDE", attrVal = 50 },
    trackColor = { attrString = "I_CUSTOMCOLOR", val = 122 },
  },
  options = {
    -- m = ?, -- mapped drum gobj
  },
  routing = {

    m = function(gobj, rk_config)
      rk_config = rk_config or require("definitions.config")
      local log = require("utils.log")
      local sxu = require("sx.utils")
      local sx_tracks = require("sx.tracks")
      local trr = require("library.routing")

      log.user("!!!!")

      local opt_m_children = {}
      for _, mcab_obj in pairs(gobj.children) do
        if sxu.strHasOneOfChars(mcab_obj.class, "MC") and sxu.trackObjHasOption(gobj, "m") then
          trr.updateState("-#", gobj.guid) -- remove all sends
          opt_m_children[#opt_m_children + 1] = mcab_obj -- collect m_opt_obj for reverse looping later
        end
      end

      local lane_idx = rk_config.drum_lanes_low_note_start

      for k = 1, #opt_m_children do
        local rev_idx = #opt_m_children + 1 - k -- reverse idx !!!
        local child_obj = opt_m_children[rev_idx]

        trr.updateState("#{0|0}", gobj.guid, child_obj.guid)

        require("sx.fx").track_apply_fx_configs(child_obj, lane_idx, "m")

        -- set piano roll
        if lane_idx > 127 then
          log.user(
            string.format(
              "TrackOptionError: %s : Note range for group (%s) exceedes 127.",
              child_obj.trackIndex,
              gobj.name
            )
          )
          return false
        end
        for i = 0, 127 do
          reaper.SetTrackMIDINoteNameEx(0, gobj.tr, lane_idx + i, 0, "")
        end

        local has_opt_nr = sx_tracks.trackHasOption(child_obj, "nr")

        if has_opt_nr then
          for i = 0, child_obj.options.nr - 1 do
            reaper.SetTrackMIDINoteNameEx(
              0,
              gobj.tr,
              lane_idx + i,
              0,
              i == 0 and child_obj.name or rk_config.symbPianoRollRange
            )
          end
        else
          reaper.SetTrackMIDINoteNameEx(0, gobj.tr, lane_idx, 0, child_obj.name)
        end
        lane_idx = has_opt_nr and (lane_idx + child_obj.options.nr) or (lane_idx + 1)
      end
    end,
  },
}
