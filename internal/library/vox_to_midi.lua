local ru = require("custom_actions.utils")
local tr = require("utils.track")
local fx = require("library.fx")
local log = require("utils.log")
local format = require("utils.format")

-- TODO: This should be moved to `custom_actions`

local vox2midi = {}


--- Updates a parameter in the drum trigger src track based on the currently
--- selected note row, so that one can control the output pitch of the midi
--- trigger note.
vox2midi.setDrumTrigMIDIOutFromCurrentNote = function()
	local me = reaper.MIDIEditor_GetActive()
	local active_row = reaper.MIDIEditor_GetSetting_int(me, "active_note_row")
	local match_vox_src = tr.getMatchedTrackGUIDs("vox2DrumsTrigSrc")
	if match_vox_src then
		local fx_by_name = fx.getFxIndexByName(match_vox_src[1].guid, "JS: Audio To MIDI Drum Trigger")
		if fx_by_name then
			fx.setParamForFxAtIndex(match_vox_src[1].guid, fx_by_name[1].idx, 5, active_row, false)
		end
	end
end

return vox2midi
