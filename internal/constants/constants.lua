local constants = {}

constants.midi_insertion_data_default = {
  selected = false,
  muted = false,
  chan = 0,
  noSortIn = true,
}

-- look at my old pitch machine theory table and reuse it here.
constants.t_chords = {
  -- basic intervals

  -- triads
  {
    "major",
    { 1, 5, 8 },
  },
  {
    "minor",
    { 1, 4, 8 },
  },
}

return constants
