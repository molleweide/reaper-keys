local reaper_state = require("utils.reaper_state")
local log = require("utils.log")
local constants = require("state_machine.constants")
local events = require("state_machine.events")
local utils = require("command.utils")

-- NOTE: This file hosts global reaper state pertaining to

local state_interface = {}
local state_table_name = "state"

-- map state to state key
function state_interface.set(state)
	reaper_state.set(state_table_name, state)
end

-- get state, update key, reset state
--
-- TODO: use ... varargs
-- In `setKey` use vararg and assume the last arg is the value to be set,
-- so that I can set keys at variable depth.
--
function state_interface.setKey(key, value)
	local state = state_interface.get()
	state[key] = value
	state_interface.set(state)
end

-- get state and return key
function state_interface.getKey(key)
	local state = state_interface.get()

	-- dynamically add new keys ( during dev )
	local val = state[key]
	if val == nil then
		-- log.user("getKey " .. key .. " = nil")
		local default_val = constants.reset_state[key]
		state_interface.setKey(key, default_val)
		return default_val
	else
		-- log.user("getKey " .. key .. " exists")
		return val
	end

	-- return state[key]
end

-- get state; return reset state if err
function state_interface.get()
	local state = reaper_state.get(state_table_name)
	if not state then
		log.info("Could not read state data. Returning reset state.")
		state = constants["reset_state"]
	end
	return state
end

function state_interface.toggleKey(key)
	local old_val = state_interface.getKey(key)
	if type(old_val) == "boolean" then
	  local new_val = not old_val
		state_interface.setKey(key, new_val)
		return true, new_val
	else
		log.trace("[state_interface]: Cannot toggle non-boolean key.")
		return false
	end
end

-- TODO: annotate below functions

-- FIXME reduntant functions ?????

function state_interface.getLastSearchedTrackNameAndDirection()
	local state = state_interface.get()
	return state["last_searched_track_name"], state["last_track_name_search_direction_was_forward"]
end

function state_interface.setLastSearchedTrackNameAndDirection(name, forward)
	local new_state = state_interface.get()
	new_state["last_searched_track_name"] = name
	new_state["last_track_name_search_direction_was_forward"] = forward
	state_interface.set(new_state)
end

function state_interface.checkIfConsistentState(state)
	local current_state = state_interface.get()
	for k, value in pairs(current_state) do
		if k == "last_command" then
			if not utils.checkIfCommandsAreEqual(state.last_command, current_state.last_command) then
				return false
			end
		elseif value ~= state[k] then
			return false
		end
	end
	return true
end

function state_interface.setVisualTrackPivotIndex(visual_track_pivot_i)
	local state = state_interface.get()
	state["visual_track_pivot_i"] = visual_track_pivot_i
	state_interface.set(state)
end

function state_interface.getVisualTrackPivotIndex()
	local state = state_interface.get()
	local visual_track_pivot_i = state["visual_track_pivot_i"]
	return visual_track_pivot_i
end

function state_interface.setTimelineSelectionSide(left_or_right)
	local state = state_interface.get()
	state["timeline_selection_side"] = left_or_right
	state_interface.set(state)
end

function state_interface.getTimelineSelectionSide()
	local state = state_interface.get()
	return state["timeline_selection_side"]
end

function state_interface.getMode()
	local state = state_interface.get()
	return state.mode
end

function state_interface.set_timeline_motion_range(t_range)
	local state = state_interface.get()
	state["last_set_timeline_range"] = t_range
	state_interface.set(state)
end

-- TODO: attach `prev_mode` variable to RK state table and set it to nil as
-- default
function state_interface.setMode(mode)
	log.user("[state_interface.setMode] START =================")
	local state = state_interface.get()
	local old_mode = state.mode
	state.mode = mode
	events.on_mode_exit(old_mode, state)
	events.on_mode_enter(state)
	state_interface.set(state)
	log.user("[state_interface.setMode] END ===================")
end

-- why is there a need for this additional function to set normal mode, when
-- one already exists in lib.state?
function state_interface.setModeToNormal()
	local state = state_interface.get()
	state["key_sequence"] = ""
	state["context"] = "main"
	state["mode"] = "normal"
	state["timeline_selection_side"] = "left"
	state_interface.set(state)
end

state_interface.getContext = function()
	local state = state_interface.get()
	return state.context
end

state_interface.last_command_has = function(asf_type)
	local last_command = state_interface.getKey("last_command")
	for _, elem in ipairs(last_command.action_sequence) do
	  if elem:match(asf_type) then
	    return true
	  end
	end
end

return state_interface
