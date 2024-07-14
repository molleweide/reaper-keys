local T_MEDIA_ITEM_TAKE_INFO_PARAMS = {
  D_STARTOFFS = {
    type = "double",
    name = "D_STARTOFFS",
    description = [[double * : start offset in source media, in seconds]],
  },
  D_VOL = {
    type = "double",
    name = "D_VOL",
    description = "take volume, 0=-inf, 0.5=-6dB, 1=+0dB, 2=+6dB, etc, negative if take polarity is flipped",
  },
  D_PAN = {
    type = "double",
    name = "D_PAN",
    description = "double * : take pan, -1..1",
  },
  D_PANLAW = {
    type = "double",
    name = "D_PANLAW",
    description = [[double * : take pan law, -1=default, 0.5=-6dB, 1.0=+0dB, etc]],
  },
  D_PLAYRATE = {
    type = "double",
    name = "D_PLAYRATE",
    description = "double * : take playback rate, 0.5=half speed, 1=normal, 2=double speed, etc",
  },
  D_PITCH = {
    type = "double",
    name = "D_PITCH",
    description = "double * : take pitch adjustment in semitones, -12=one octave down, 0=normal, +12=one octave up, etc",
  },
  B_PPITCH = {
    type = "bool",
    name = "B_PPITCH",
    description = "bool * : preserve pitch when changing playback rate",
  },
  I_LASTY = {
    type = "int",
    name = "I_LASTY",
    description = "int * : Y-position (relative to top of track) in pixels (read-only)",
    read_only = true,
  },
  I_LASTH = {
    type = "int",
    name = "I_LASTH",
    description = "int * : height in pixels (read-only)",
    read_only = true,
  },
  I_CHANMODE = {
    type = "int",
    name = "I_CHANMODE",
    description = "int * : channel mode, 0=normal, 1=reverse stereo, 2=downmix, 3=left, 4=right",
  },
  I_PITCHMODE = {
    type = "int",
    name = "I_PITCHMODE",
    description = "int * : pitch shifter mode, -1=projext default, otherwise high 2 bytes=shifter, low 2 bytes=parameter",
  },
  I_CUSTOMCOLOR = {
    type = "int",
    name = "I_CUSTOMCOLOR",
    description =
    [[int * : custom color, OS dependent color|0x1000000 (i.e. ColorToNative(r,g,b)|0x1000000). If you do not |0x1000000, then it will not be used, but will store the color]],
  },
  IP_TAKENUMBER = {
    type = "int",
    name = "IP_TAKENUMBER",
    description = "int : take number (read-only, returns the take number directly)",
    read_only = true,
  },
  P_TRACK = {
    type = "pointer",
    name = "P_TRACK",
    description = "pointer to MediaTrack (read-only)",
    read_only = true,
  },
  P_ITEM = {
    type = "pointer",
    name = "P_ITEM",
    description = "pointer to MediaItem (read-only)",
    read_only = true,
  },
  P_SOURCE = {
    type = "pcm_source",
    name = "PCM_source",
    description = [[PCM_source *. Note that if setting this, you should first
    retrieve the old source, set the new, THEN delete the old.]],
  },
}

local M = {}
-- only data / no ref
M.get_take_info = function(take) end

M.get_array = function(take)
  local res = {}
  for _, v in pairs(T_MEDIA_ITEM_TAKE_INFO_PARAMS) do
    local value = reaper.GetMediaItemTakeInfo_Value(take, v.name)

    if type(value) == "userdata" then
      value = "<userdata>"
    end

    v.value = value
    v._meta = {
      type = "info_param",
      cat = "take",
    }
    table.insert(res, v)
  end
  return res
end

return M
