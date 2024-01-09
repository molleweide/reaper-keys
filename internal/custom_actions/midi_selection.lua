local log = require("utils.log")
local format = require("utils.format")

local midi = require("library.midi")

local ms = {}

-- midi operator -> pitch_motion
--   ranges will be passed to the operator, in order to make the selection.
--
--
ms.selectNoteRows = function(meta, opts)
  -- if meta.start_row and meta.end_row then
  --   midi.midi_take_filter_transform(meta.active_take, {
  --     filter = { notes = { pitch = { { meta.start_row, meta.end_row } } } },
  --     transform = {
  --       notes = { sel = true },
  --     },
  --   })
  -- end
end

ms.innerActiveTake = function(meta, opts)
  midi.midi_take_filter_transform(meta.active_take, {
    transform = {
      notes = { sel = true }, -- this would select all notes in take
    },
  })
end

ms.rowAndAbove = function(meta, opts)
  -- log.user("Midi Above | meta:", format.block(meta), "opts:", format.block(opts))
  local row = reaper.MIDIEditor_GetSetting_int(meta.ME.editor, "active_note_row")

  midi.midi_take_filter_transform(meta.active_take, {
    filter = {
      notes = {
        pitch = function(note)
          return row <= note.pitch
        end,
      },
    },
    transform = { notes = { sel = true } },
  })

  -- midi.midi_take_filter_transform(meta.active_take, {
  --   transform = {
  --     notes = { sel = true }, -- this would select all notes in take
  --   },
  -- })
end

ms.rowAndBelow = function(meta, opts)
  -- log.user("Midi Below | meta:", format.block(meta), "opts:", format.block(opts))
  local row = reaper.MIDIEditor_GetSetting_int(meta.ME.editor, "active_note_row")
  midi.midi_take_filter_transform(meta.active_take, {
    filter = {
      notes = {
        pitch = function(note)
          return note.pitch <= row
        end,
      },
    },
    transform = { notes = { sel = true } },
  })
end
return ms
