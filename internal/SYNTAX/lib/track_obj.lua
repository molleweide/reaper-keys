local format = require('utils.format')
local log = require('utils.log')

local track_obj_funcs = {}


function track_obj_funcs.trackHasOption(trk_obj, opt)
  if trk_obj.options ~= nil then
    if trk_obj.options[opt] ~= nil then
      return true
    else
      log.user("TrackOptionError: "..trk_obj.trackIndex.." : Track does not have option: `" .. opt .."`.") -- add group name to this err msg
      return false
    end
  else
    -- log.user("TrackOptionError: "..trk_obj.trackIndex.." : Track does not have any options.") -- add group name to this err msg
    return false
  end
end

return track_obj_funcs
