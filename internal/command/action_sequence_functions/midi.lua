local runner = require("command.runner")

return {
  normal = {
    midi_operator = {
      {
        { "timeline_operator", "timeline_selector" },
        function(timeline_operator, timeline_selector) end,
      },
      {
        { "timeline_operator", "timeline_motion" },
        function(timeline_operator, timeline_motion) end,
      },
      { { "timeline_motion" }, function(timeline_motion) end },
    },
  },
  midi_step = {
    {
      { "midi_step_command" },
      function(midi_step_command)
        runner.runAction(midi_step_command)
      end,
    },
  },
}
