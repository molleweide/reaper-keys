local musical_scales = {
  {
    name_long = "Major Scale",
    name_short = "Ionian",
    type = "diatonic",
    notes = {0, 2, 4, 5, 7, 9, 11}
  },
  {
    name_long = "Natural Minor Scale",
    name_short = "Aeolian",
    type = "diatonic",
    notes = {0, 2, 3, 5, 7, 8, 10}
  },
  {
    name_long = "Harmonic Minor Scale",
    name_short = "Harmonic Minor",
    type = "diatonic",
    notes = {0, 2, 3, 5, 7, 8, 11}
  },
  {
    name_long = "Melodic Minor Scale (Ascending)",
    name_short = "Melodic Minor Asc.",
    type = "diatonic",
    notes = {0, 2, 3, 5, 7, 9, 11}
  },
  {
    name_long = "Melodic Minor Scale (Descending)",
    name_short = "Melodic Minor Desc.",
    type = "diatonic",
    notes = {0, 2, 3, 5, 7, 8, 10}
  },
  {
    name_long = "Dorian Mode",
    name_short = "Dorian",
    type = "diatonic",
    notes = {0, 2, 3, 5, 7, 9, 10}
  },
  {
    name_long = "Phrygian Mode",
    name_short = "Phrygian",
    type = "diatonic",
    notes = {0, 1, 3, 5, 7, 8, 10}
  },
  {
    name_long = "Lydian Mode",
    name_short = "Lydian",
    type = "diatonic",
    notes = {0, 2, 4, 6, 7, 9, 11}
  },
  {
    name_long = "Mixolydian Mode",
    name_short = "Mixolydian",
    type = "diatonic",
    notes = {0, 2, 4, 5, 7, 9, 10}
  },
  {
    name_long = "Locrian Mode",
    name_short = "Locrian",
    type = "diatonic",
    notes = {0, 1, 3, 5, 6, 8, 10}
  },
  {
    name_long = "Pentatonic Major Scale",
    name_short = "Pentatonic Major",
    type = "pentatonic",
    notes = {0, 2, 4, 7, 9}
  },
  {
    name_long = "Pentatonic Minor Scale",
    name_short = "Pentatonic Minor",
    type = "pentatonic",
    notes = {0, 3, 5, 7, 10}
  },
  {
    name_long = "Blues Scale",
    name_short = "Blues",
    type = "pentatonic",
    notes = {0, 3, 5, 6, 7, 10}
  },
  {
    name_long = "Whole Tone Scale",
    name_short = "Whole Tone",
    type = "symmetrical",
    notes = {0, 2, 4, 6, 8, 10}
  },
  {
    name_long = "Chromatic Scale",
    name_short = "Chromatic",
    type = "chromatic",
    notes = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}
  },
  {
    name_long = "Hungarian Minor Scale",
    name_short = "Hungarian Minor",
    type = "diatonic",
    notes = {0, 2, 3, 6, 7, 8, 11}
  },
  {
    name_long = "Double Harmonic Scale",
    name_short = "Double Harmonic",
    type = "diatonic",
    notes = {0, 1, 4, 5, 7, 8, 11}
  },
  {
    name_long = "Phrygian Dominant Scale",
    name_short = "Phrygian Dominant",
    type = "diatonic",
    notes = {0, 1, 4, 5, 7, 9, 10}
  },
  {
    name_long = "Dorian ♯4 Scale",
    name_short = "Dorian ♯4",
    type = "diatonic",
    notes = {0, 2, 3, 6, 7, 9, 10}
  },
  {
    name_long = "Lydian Augmented Scale",
    name_short = "Lydian Augmented",
    type = "diatonic",
    notes = {0, 2, 4, 6, 8, 9, 11}
  },
  {
    name_long = "Lydian Dominant Scale",
    name_short = "Lydian Dominant",
    type = "diatonic",
    notes = {0, 2, 4, 6, 7, 9, 10}
  },
  {
    name_long = "Phrygian Major Scale",
    name_short = "Phrygian Major",
    type = "diatonic",
    notes = {0, 1, 4, 5, 7, 8, 10}
  },
  {
    name_long = "Enigmatic Scale",
    name_short = "Enigmatic",
    type = "symmetrical",
    notes = {0, 1, 4, 6, 8, 10, 11}
  },
  {
    name_long = "Altered Scale",
    name_short = "Altered",
    type = "diatonic",
    notes = {0, 1, 3, 4, 6, 8, 10}
  },
  {
    name_long = "Arabian Scale",
    name_short = "Arabian",
    type = "diatonic",
    notes = {0, 2, 4, 5, 6, 8, 10}
  },
  {
    name_long = "Byzantine Scale",
    name_short = "Byzantine",
    type = "diatonic",
    notes = {0, 1, 4, 5, 7, 8, 10}
  },
  {
    name_long = "Egyptian Scale",
    name_short = "Egyptian",
    type = "diatonic",
    notes = {0, 2, 5, 7, 10}
  },
  {
    name_long = "Hirajoshi Scale",
    name_short = "Hirajoshi",
    type = "pentatonic",
    notes = {0, 3, 4, 7, 8}
  },
  {
    name_long = "In Sen Scale",
    name_short = "In Sen",
    type = "pentatonic",
    notes = {0, 1, 5, 7, 10}
  },
  {
    name_long = "Istrian Scale",
    name_short = "Istrian",
    type = "diatonic",
    notes = {0, 1, 3, 4, 6, 7, 9}
  },
  {
    name_long = "Kumoi Scale",
    name_short = "Kumoi",
    type = "pentatonic",
    notes = {0, 2, 3, 7, 9}
  },
  {
    name_long = "Persian Scale",
    name_short = "Persian",
    type = "diatonic",
    notes = {0, 1, 4, 5, 6, 8, 11}
  },
  {
    name_long = "Phrygian Pentatonic Scale",
    name_short = "Phrygian Pentatonic",
    type = "pentatonic",
    notes = {0, 1, 3, 7, 8}
  },
  {
    name_long = "Prometheus Scale",
    name_short = "Prometheus",
    type = "diatonic",
    notes = {0, 2, 4, 6, 9, 10}
  },
  {
    name_long = "Takemitsu Scale",
    name_short = "Takemitsu",
    type = "pentatonic",
    notes = {0, 1, 5, 7, 8}
  },
  {
    name_long = "Chromatic Dorian Scale",
    name_short = "Chromatic Dorian",
    type = "chromatic",
    notes = {0, 2, 3, 5, 7, 9, 10}
  },
  {
    name_long = "Chromatic Mixolydian Scale",
    name_short = "Chromatic Mixolydian",
    type = "chromatic",
    notes = {0, 2, 4, 5, 7, 9, 10}
  },
  {
    name_long = "Chromatic Phrygian Scale",
    name_short = "Chromatic Phrygian",
    type = "chromatic",
    notes = {0, 1, 3, 5, 7, 8, 10}
  },
  {
    name_long = "Chromatic Lydian Scale",
    name_short = "Chromatic Lydian",
    type = "chromatic",
    notes = {0, 2, 4, 6, 7, 9, 11}
  },
  {
    name_long = "Chromatic Locrian Scale",
    name_short = "Chromatic Locrian",
    type = "chromatic",
    notes = {0, 1, 3, 4, 6, 8, 10}
  },
  {
    name_long = "Chromatic Blues Scale",
    name_short = "Chromatic Blues",
    type = "chromatic",
    notes = {0, 1, 3, 4, 5, 7, 8, 10, 11}
  },
  {
    name_long = "Chromatic Whole Tone Scale",
    name_short = "Chromatic Whole Tone",
    type = "chromatic",
    notes = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}
  }
  -- Add more scales here as needed
}

return musical_scales

