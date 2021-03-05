-- bindings in this file are prioritized over the default bindings
-- if you need help, check out the documentation https://gwatcha.github.io/reaper-keys/configuration/bindings.html
-- check out the ./defaults directory to see examples
return {
  global = {
    timeline_motion = {},
    timeline_operator = {},
    timeline_selector = {},
    visual_timeline_command = {},
    command = {}
  },
  main = {
    track_motion = {},
    visual_track_command = {
      ["<C-,>"] = { "+trkop", {
          ["d"] = "gCut",
          ["p"] = "gPut",
          ["y"] = "gYank",
      }}
    },
    track_selector = {},
    track_operator = {
      -- ["a"] = "ArmTracksWithMidiRouter",
    },
    timeline_operator = {},
    timeline_selector = {},
    timeline_motion = {},
    command = {
      -- ["aa"] = "ArmTracksWithMidiRouter", -- only works for command right now.
      ["zp"] = "ZoomProjectCustom",
      ["<C-,>"] = { "+cmd", {
          ["c"] = "LogWhatever",
          ["C"] = "CloseReaConsole",
          ["f"] = "FuzzyFx",
          ["l"] = "LogLastTouchFxParams",
          ["mq"] = "TrackInSet_MIDI_QMK",
          ["mg"] = "TrackInSet_MIDI_GRAND_ROLAND",
          ["mv"] = "TrackInSet_MIDI_VIRTUAL",
          ["md"] = "TrackInSet_MIDI_DEFAULT",
          ["R"] = "RepeatInsertTimeSelection",
          ["S"] = "SaveAllTracksAsTemplate",
          ["w"] = "ApplyConfigs",
      }}
    },
  },
  midi = {
    timeline_selector = {},
    timeline_operator = {},
    timeline_motion = {},
    command = {},
  },
}
