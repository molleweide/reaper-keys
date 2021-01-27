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
      ["zp"] = "ZoomProject",
      ["<C-,>"] = { "+cmd", {
          ["c"] = "LogWhatever",
          ["C"] = "CloseReaConsole",
          ["f"] = "FuzzyFx",
          ["mq"] = "TrackInputSet_QMK",
          ["mg"] = "TrackInputSet_GRAND_ROLAND",
          ["mv"] = "TrackInputSet_VIRTUAL",
          ["R"] = "RepeatInsertTimeSelection",
          ["S"] = "SaveAllTracksAsTemplate",
          ["w"] = "ApplyConfigs",
          ["x"] = "AddTrackRoute"
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
