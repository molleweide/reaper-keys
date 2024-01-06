local log = require("utils.log")
local format = require("utils.format")
local runner = require("command.runner")
local midi = require("library.midi")
local midi_editor = require("library.midi_editor")

-- reaper.MIDIEditor_EnumTakes(ME, 0, editable_only)

return {
  normal = {
    {
      { "midi_operator", "midi_selector" },
      function(midi_operator, midi_selector)
        -- log.user("ASF MIDI (op, sel):", format.block(midi_operator), format.block(midi_selector))

        local ME_ACTIVE, ME = midi_editor.getMidiValidContext()
        if not ME_ACTIVE then
          log.debug("ME did not exist in ASF do `midi_operator/midi_selector`")
          return
        end
        local active_take = reaper.MIDIEditor_GetTake(ME.editor)
        midi.midi_take_filter_transform(active_take, {
          transform = {
            notes = { sel = false },
          },
        })
        midi_selector.meta.active_take = active_take
        midi_operator.meta.active_take = active_take
        runner.runAction(midi_selector)
        runner.runAction(midi_operator)
      end,
    },
    {
      { "midi_operator", "pitch_motion" },
      function(midi_operator, pitch_motion)
        log.user("ASF MIDI (op, pm):", format.block(midi_operator), format.block(pitch_motion))

        local ME_EXISTS, ME = midi_editor.getMidiValidContext()
        if not ME_EXISTS then
          log.debug("ME did not exist in ASF do `midi_operator/pitch_motion`")
          return
        end

        midi_operator.meta.start_row = reaper.MIDIEditor_GetSetting_int(ME.editor, "active_note_row")
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
