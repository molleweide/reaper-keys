local log = require("utils.log")
local format = require("utils.format")
local runner = require("command.runner")

return {
  normal = {
    {
      { "midi_operator", "midi_selector" },
      function(midi_operator, midi_selector)

        -- local start_sel, end_sel = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
        runner.runAction(midi_selector)
        runner.runAction(midi_operator)
        --
        -- if type(timeline_operator) ~= "table" or not timeline_operator["setTimeSelection"] then
        --   reaper.GetSet_LoopTimeRange(true, false, start_sel, end_sel, false)
        -- end
      end,
    },
    {
      { "midi_operator", "pitch_motion" },
      function(midi_operator, pitch_motion)
        local midi_editor = require("library.midi_editor")
        -- log.user(format.block(midi_operator), format.block(pitch_motion))

        local ME_EXISTS, ME = midi_editor.getMidiValidContext()
        if not ME_EXISTS then
          log.debug("ME did not exist in `")
          return
        end

        midi_operator.meta.start_row =reaper.MIDIEditor_GetSetting_int(ME.editor, "active_note_row")
        runner.runAction(pitch_motion)
        midi_operator.meta.end_row = reaper.MIDIEditor_GetSetting_int(ME.editor, "active_note_row")
        runner.runAction(midi_operator)
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
