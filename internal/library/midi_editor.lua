local log = require("utils.log")
local format = require("utils.format")

-- TODO: delete this file... unused...

local midi_editor = {}

-- Get settings from a MIDI editor. setting_desc can be:
-- snap_enabled: returns 0 or 1
-- active_note_row: returns 0-127
-- last_clicked_cc_lane: returns 0-127=CC, 0x100|(0-31)=14-bit CC, 0x200=velocity, 0x201=pitch, 0x202=program, 0x203=channel pressure, 0x204=bank/program select, 0x205=text, 0x206=sysex, 0x207=off velocity, 0x208=notation events, 0x210=media item lane
-- default_note_vel: returns 0-127
-- default_note_chan: returns 0-15
-- default_note_len: returns default length in MIDI ticks
-- scale_enabled: returns 0-1
-- scale_root: returns 0-12 (0=C)
-- list_cnt: if viewing list view, returns event count
-- if setting_desc is unsupported, the function returns -1.

midi_editor.get_note_row = function()
	local me = reaper.MIDIEditor_GetActive()
	local active_row = reaper.MIDIEditor_GetSetting_int(me, "active_note_row")
	return active_row
end

return midi_editor

-- TODO: create module api to get all things necessary quick and easy

-- get current_note_row
--
-- etc...
