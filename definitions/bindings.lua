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
    visual_track_command = {},
    track_selector = {},
    track_operator = {},
    timeline_operator = {},
    timeline_selector = {},
    timeline_motion = {},
    command = {
      ["<C-,>"] = { "+fx", {
          ["c"] = "Log", -- custom function test logger
          ["C"] = "CloseConsole", -- how can I close the console with a key command??
          ["f"] = "FuzzyFx",
          -- ["a"] = "ApplyTrackSyntax",
          ["w"] = "WriteTrackTable"
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
