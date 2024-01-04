local log = require("utils.log")
local format = require("utils.format")
local runner = require("command.runner")

return {
  normal = {
    {
      -- BUG: Function is not called if used with prefix repetition count.
      { "midi_operator", "pitch_motion" },
      function(midi_operator, pitch_motion)
        local midi_editor = require("library.midi_editor")
        log.user(format.block(midi_operator), format.block(pitch_motion))

        -- log.user("meta = ", format.block(meta), "opts = ", format.block(opts))
        local ME_EXISTS, ME = midi_editor.getMidiValidContext()
        if not ME_EXISTS then
          log.debug("ME did not exist in `")
          return
        end
        -- local start, _end = runner.getPitchRangeFromPitchMotion(pitch, 1)
        local start_row = reaper.MIDIEditor_GetSetting_int(ME.editor, "active_note_row")
        runner.runAction(pitch_motion)
        local end_row = reaper.MIDIEditor_GetSetting_int(ME.editor, "active_note_row")

        log.user("MIDI MOTION: range = ", start_row, end_row)

        -- runner.runAction(midi_operator)
      end,
    },
    {
      { "pitch_motion" },
      function(pitch_motion)
        runner.runAction(pitch_motion)
      end,
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
