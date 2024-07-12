local T_MEDIA_ITEM_TAKE_INFO_PARAMS = {
  -- reaper.GetMediaItemTakeInfo_Value( take, parmname )
  --
  -- Get media item take numerical-value attributes.
  -- D_STARTOFFS : double * : start offset in source media, in seconds
  D_VOL = {
    type = "double",
    name = "D_VOL",
    description = "take volume, 0=-inf, 0.5=-6dB, 1=+0dB, 2=+6dB, etc, negative if take polarity is flipped",
  },
  -- D_PAN : double * : take pan, -1..1
  -- D_PANLAW : double * : take pan law, -1=default, 0.5=-6dB, 1.0=+0dB, etc
  -- D_PLAYRATE : double * : take playback rate, 0.5=half speed, 1=normal, 2=double speed, etc
  -- D_PITCH : double * : take pitch adjustment in semitones, -12=one octave down, 0=normal, +12=one octave up, etc
  -- B_PPITCH : bool * : preserve pitch when changing playback rate
  -- I_LASTY : int * : Y-position (relative to top of track) in pixels (read-only)
  -- I_LASTH : int * : height in pixels (read-only)
  -- I_CHANMODE : int * : channel mode, 0=normal, 1=reverse stereo, 2=downmix, 3=left, 4=right
  -- I_PITCHMODE : int * : pitch shifter mode, -1=projext default, otherwise high 2 bytes=shifter, low 2 bytes=parameter
  -- I_CUSTOMCOLOR : int * : custom color, OS dependent color|0x1000000 (i.e. ColorToNative(r,g,b)|0x1000000). If you do not |0x1000000, then it will not be used, but will store the color
  -- IP_TAKENUMBER : int : take number (read-only, returns the take number directly)
  -- P_TRACK : pointer to MediaTrack (read-only)
  -- P_ITEM : pointer to MediaItem (read-only)
  -- P_SOURCE : PCM_source *. Note that if setting this, you should first retrieve the old source, set the new, THEN delete the old.
}

local M = {}
-- only data / no ref
M.get_take_info = function(take) end

M.get_array = function(take)
  local res = {}
  for _, v in pairs(T_MEDIA_ITEM_TAKE_INFO_PARAMS) do
    v.value = reaper.GetMediaItemTakeInfo_Value(take, v.name)
    table.insert(res, v)
  end
  return res
end

return M
