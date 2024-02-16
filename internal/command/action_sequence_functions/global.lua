local log = require("utils.log")
local format = require("utils.format")
local runner = require("command.runner")
local log = require("utils.log")
local state_interface = require("state_machine.state_interface")
local config = require("definitions.config")

local function invalidSequenceCall(...)
	log.error("An action action_sequence without a command function was called.")
	log.trace(debug.traceback())
end

local function save_timeline_sel()
	local start_sel, end_sel = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
	return start_sel, end_sel
end

local function restore_timeline_sel(timeline_operator, start_sel, end_sel)
	if type(timeline_operator) ~= "table" or not timeline_operator["setTimeSelection"] then
		reaper.GetSet_LoopTimeRange(true, false, start_sel, end_sel, false)
	end
end

local function save_timeline_sel_to_state()
	local start_sel, end_sel = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
	state_interface.set_timeline_motion_range({ start_sel, end_sel })
end


--- NOTE: Table containing { action_sequence <-> action_function } (ASFPs) pairs
--        The [ action sequence ] should be handled in the way of the [ action function ]
return {
	all_modes = {
		{
			{ "command" },
			function(action)
				-- log.user("ASF:", format.block(action))
				runner.runAction(action)
			end,
		},
	},
	normal = {
		{
			{ "timeline_operator", "timeline_selector" },
			function(timeline_operator, timeline_selector)
				-- local start_sel, end_sel = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
				local start_sel, end_sel = save_timeline_sel()
				runner.runAction(timeline_selector)
				save_timeline_sel_to_state()
				runner.runAction(timeline_operator)
				restore_timeline_sel(timeline_operator, start_sel, end_sel)
			end,
		},
		{
			{ "timeline_operator", "timeline_motion" },
			function(timeline_operator, timeline_motion)
				-- log.user("ASF:", format.block(timeline_operator), format.block(timeline_motion))
				local start_sel, end_sel = save_timeline_sel()

				local start, _end = runner.makeSelectionFromTimelineMotion(timeline_motion, 1)

				timeline_operator.meta.start_pos = start
				timeline_operator.meta.end_pos = _end
				runner.runAction(timeline_operator)

				restore_timeline_sel(timeline_operator, start_sel, end_sel)
			end,
		},
		{
			{ "timeline_motion" },
			function(timeline_motion)
				runner.runAction(timeline_motion)
			end,
		},
	},
	visual_timeline = {
		{
			{ "visual_timeline_command" },
			function(visual_timeline_command)
				runner.runAction(visual_timeline_command)
			end,
		},
		{
			{ "timeline_operator" },
			function(timeline_operator)
				runner.runAction(timeline_operator)
				state_interface.setModeToNormal()
				if not config["persist_visual_timeline_selection"] then
					runner.runAction("ClearTimeSelection")
				end
			end,
		},
		{
			{ "timeline_selector" },
			function(timeline_selector)
				runner.runAction(timeline_selector)
			end,
		},
		{
			{ "timeline_motion" },
			function(timeline_motion)
				local args = { timeline_motion }
				local move_function = runner.runAction
				runner.extendTimelineSelection(move_function, args)
			end,
		},
	},
	vkb = {
		{
			{ "vkb_command" },
			function(action)
				runner.runAction(action)
			end,
		},
	},
}
