local constants = {}

constants.midi_insertion_data_default = {
  selected = false,
  muted = false,
  chan = 0,
  noSortIn = true,
}

constants.t_chords = {
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
