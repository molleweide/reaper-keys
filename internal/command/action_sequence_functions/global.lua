local runner = require('command.runner')
local log = require('utils.log')
local state_interface = require('state_machine.state_interface')
local config = require('definitions.config')

-- TEST:  1. set a temporary state if buildCommand(new_state) returns true
--            build_state
--            pre_exec_state.
--            >>> this would allow me to access the state inside of the action
--            instead which would be simplest.
--            BUT
--            why do I need temp state?
--              why cant i just update the state incrementally?
--        ~
--        ~
--        2. pass state down directly to action:
--          replace all ASF func args with vararg. Then I'd know that 1 is always
--          state, and remaining args are always the actions expected in the same order
--          as the sequence table defines.
--
-- asf(...)
-- state = select(1, ...)

local function invalidSequenceCall(...)
  log.error("An action action_sequence without a command function was called.")
  log.trace(debug.traceback())
end

--- NOTE: Table containing { action_sequence <-> action_function } (ASFPs) pairs
--        The [ action sequence ] should be handled in the way of the [ action function ]
return {
  all_modes = {
    {
      { 'command' },
      function(action)
        runner.runAction(action)
      end
    },
  },
  normal = {
    {
      { 'timeline_operator', 'timeline_selector' },
      function(timeline_operator, timeline_selector)
        local start_sel, end_sel = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
        runner.runAction(timeline_selector)
        runner.runAction(timeline_operator)

        if type(timeline_operator) ~= 'table' or not timeline_operator['setTimeSelection'] then
          reaper.GetSet_LoopTimeRange(true, false, start_sel, end_sel, false)
        end
      end
    },
    {
      { 'timeline_operator', 'timeline_motion' },
      function(timeline_operator, timeline_motion)

        local start_sel, end_sel = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)

        -- NOTE: create temporary selection that will be used later when applying
        -- the operator.
        -- instead of passing positions to the operator, the operator gets the positions
        -- from the temporary selection which is then set back.
        runner.makeSelectionFromTimelineMotion(timeline_motion, 1)

        runner.runAction(timeline_operator)

        -- reset temp selection
        if type(timeline_operator) ~= 'table' or not timeline_operator['setTimeSelection'] then
          reaper.GetSet_LoopTimeRange(true, false, start_sel, end_sel, false)
        end
      end
    },
    {
      { 'timeline_motion' },
      function(timeline_motion)
        runner.runAction(timeline_motion)
      end
    },
  },
  visual_timeline = {
    {
      { 'visual_timeline_command' },
      function(visual_timeline_command)
        runner.runAction(visual_timeline_command)
      end
    },
    {
      { 'timeline_operator' },
      function(timeline_operator)
        runner.runAction(timeline_operator)
        state_interface.setModeToNormal()
        if not config['persist_visual_timeline_selection'] then
          runner.runAction("ClearTimeSelection")
        end
      end
    },
    {
      { 'timeline_selector' },
      function(timeline_selector)
        runner.runAction(timeline_selector)
      end
    },
    {
      { 'timeline_motion' },
      function(timeline_motion)
        local args = {timeline_motion}
        local move_function = runner.runAction
        runner.extendTimelineSelection(move_function, args)
      end
    },
  },
  vkb = {
    {
      { 'vkb_command' },
      function(action)
        runner.runAction(action)
      end
    },
  },
}
