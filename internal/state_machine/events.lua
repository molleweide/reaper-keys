local log = require("utils.log")
local format = require("utils.format")

local midi_editor = require("library.midi_editor")
local r = require("utils.reaper")

local constants = require("state_machine.constants")

local state_events = {}

-- state has already been copied so
state_events.on_mode_enter = function(state)
	log.user("[state_events.on_mode_enter]:", state.mode)

	if state.mode == "midi_step" then
		state.midi_step_state = constants.reset_state["midi_step_state"]

		local ok, ME = midi_editor.getMidiValidContext()

		state.midi_step_state.guids_track_active = ME.track_guid

		r.track_record_arm_enable(ME.track)

		log.debug(format.block(ME))

		log.user("::reset midi step state table::")
	end
end

state_events.on_mode_exit = function(old_mode, state)
	log.user("[state_events.on_mode_exit]:", old_mode)
	if old_mode == "midi_step" then
		-- look at state and get the GUIDs for armed midi tracks to unarm.
		local ok, ME = midi_editor.getMidiValidContext()
		log.debug("track to un arm:", state.midi_step_state.guids_track_active)

		r.track_record_arm_disable(r.getTrackByGUID(ME.track_guid))
		state.midi_step_state.guids_track_active = nil
	end
end

return state_events
