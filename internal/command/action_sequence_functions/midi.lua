local runner = require('command.runner')

return {
	midi_step = {
		{
			{ "midi_step_command" },
			function(midi_step_command)
				runner.runAction(midi_step_command)
			end,
		},
	},
}
