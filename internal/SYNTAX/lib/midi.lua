local log = require('utils.log')
local fxConfigs = require('SYNTAX.config.config').fxConfigs
local trackObj = require('SYNTAX.lib.track_obj')
local symbPianoRollRange = '#' -- mv to config

local midi = {}

-- lane mapping /////////////////////////////

function midi.updatePianoRoll(grp_obj,child_obj, count_w_range)
  if count_w_range > 127 then
    log.user("TrackOptionError: "..child_obj.trackIndex.." : Note range for group (" ..  grp_obj.name .. ") exceedes 127.") -- add group name to this err msg
    return false
  end

  -- set piano roll
  local group_track = reaper.GetTrack(0,grp_obj.trackIndex)

  for i=0, 127 do
    reaper.SetTrackMIDINoteNameEx( 0, group_track, count_w_range + i,0,'')
  end

  -- reset
  if not trackObj.trackHasOption(child_obj, 'nr') then
    reaper.SetTrackMIDINoteNameEx( 0, group_track, count_w_range, 0, child_obj.name)
  else
    for i=0, child_obj.options.nr - 1 do
      if i == 0 then
        local retval = reaper.SetTrackMIDINoteNameEx( 0, group_track, count_w_range + i, 0, child_obj.name)
      else
        local retval = reaper.SetTrackMIDINoteNameEx( 0, group_track, count_w_range + i, 0, symbPianoRollRange)
      end

    end
  end

  -- increment range
  if not trackObj.trackHasOption(child_obj, 'nr') then
    count_w_range = count_w_range + 1
  else
    count_w_range = count_w_range + child_obj.options.nr
  end
  return count_w_range
end

return midi
