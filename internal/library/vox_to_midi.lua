local ru = require('custom_actions.utils')
local fx = require('library.fx')
local log = require("utils.log")
local format = require("utils.format")

-- TODO: This should be moved to `custom_actions`

local vox2midi = {}

-- bind this to <leader>ms
vox2midi.setDrumTrigMIDIOutFromCurrentNote = function()
	local me = reaper.MIDIEditor_GetActive()
	local active_row = reaper.MIDIEditor_GetSetting_int(me, "active_note_row")

	-- FIX: temporary hard coded index -> find by name string later
	local drum_vox_src = 13
	local drum_vox_trk = reaper.GetTrack(0, drum_vox_src)
	local drum_vox_guid = ru.getGUIDByTrack(drum_vox_trk)
	local audio_to_drum_trig_idx = 0

	-- FIX: hard coded drum trigger index
	fx.setParamForFxAtIndex(drum_vox_guid, audio_to_drum_trig_idx, 5, active_row, false)
end

return vox2midi
