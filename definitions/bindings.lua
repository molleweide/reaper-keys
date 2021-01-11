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
    },
    timeline_operator = {},
    timeline_selector = {},
    timeline_motion = {},
    command = {
      ["<C-,>"] = { "+cmd", {
          ["c"] = "LogWhatever",
          ["C"] = "CloseReaConsole",
          ["f"] = "FuzzyFx",
          ["w"] = "ApplyConfigs",
          ["R"] = "RepeatInsertTimeSelection",
          ["S"] = "SaveAllTracksAsTemplate"
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
