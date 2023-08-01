local ru = require("custom_actions.utils")
local tr = require("utils.track")
local fx = require("library.fx")
local log = require("utils.log")
local format = require("utils.format")

-- TODO: This should be moved to `custom_actions`

local vox2midi = {}

vox2midi.setDrumTrigMIDIOutFromCurrentNote = function()
	local me = reaper.MIDIEditor_GetActive()
	local active_row = reaper.MIDIEditor_GetSetting_int(me, "active_note_row")

	local match_vox_src = tr.getMatchedTrackGUIDs("vox2DrumsTrigSrc")

	if match_vox_src then
		local audio_to_drum_trig_idx = 2
		local fx_by_name = fx.getFxIndexByName(match_vox_src[1].guid, "JS: Audio To MIDI Drum Trigger")
		log.info(">>>>> ", format.block(fx_by_name))

		fx.setParamForFxAtIndex(match_vox_src[1].guid, audio_to_drum_trig_idx, 5, active_row, false)
	end
end

return vox2midi
