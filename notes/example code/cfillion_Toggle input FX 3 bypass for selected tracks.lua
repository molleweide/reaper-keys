local UNDO_STATE_FX = 2 -- track/master fx

local name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local fxIndex = tonumber(name:match("FX (%d+)"))

if fxIndex then
  fxIndex = 0x1000000 + (fxIndex - 1)
else
  error('could not extract slot from filename')
end

reaper.Undo_BeginBlock()

  -- tobble fx
  -- reaper.TrackFX_SetEnabled(track, fxIndex, not reaper.TrackFX_GetEnabled(track, fxIndex))

reaper.Undo_EndBlock(name, UNDO_STATE_FX)
