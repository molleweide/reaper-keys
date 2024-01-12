local log = require("utils.log")
local constants = require("state_machine.constants")

local state_events = {}

-- state has already been copied so
state_events.on_mode_enter = function(state)
	log.user("[state_events.on_mode_enter]:", state.mode)
	if state.mode == "midi_step" then
		state.midi_step_state = constants.reset_state["midi_step_state"]
	log.user("::reset midi step state table::")
	end
end

state_events.on_mode_exit = function(old_mode, state)
	log.user("[state_events.on_mode_exit]:", old_mode)
	if old_mode == "midi_step" then
		-- look at state and get the GUIDs for armed midi tracks to unarm.
	end
end

return state_events
