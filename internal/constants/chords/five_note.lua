--
-- FIX: zero-based
--
return {
  --
  -- BASIC INTERVALS
  --
  {
    "minor second",
    type = "interval",
    { 1, 2 },
  },
  {
    "major second",
    type = "interval",
    { 1, 3 },
  },
  {
    "minor third",
    type = "interval",
    { 1, 4 },
  },
  {
    "major third",
    type = "interval",
    { 1, 5 },
  },
  {
    "perfect fourth",
    type = "interval",
    { 1, 6 },
  },
  {
    "tritone",
    type = "interval",
    { 1, 7 },
  },
  {
    "perfect fifth",
    type = "interval",
    { 1, 8 },
  },
  {
    "minor sixth",
    type = "interval",
    { 1, 9 },
  },
  {
    "major sixth",
    type = "interval",
    { 1, 10 },
  },
  {
    "minor seventh m7",
    type = "interval",
    { 1, 11 },
  },
  {
    "major seventh M7",
    type = "interval",
    { 1, 12 },
  },
  {
    "perfect octave P8",
    type = "interval",
    { 1, 13 },
  },
  {
    "minor ninth | m9",
    type = "interval",
    { 1, 14 },
  },
  {
    "major ninth | M9",
    type = "interval",
    { 1, 15 },
  },
  {
    "minor tenth | m10",
    type = "interval",
    { 1, 15 },
  },
  {
    "major tenth | M10",
    type = "interval",
    { 1, 15 },
  },
  {
    "perfect eleventh | 11",
    type = "interval",
    { 1, 16 },
  },
  {
    "flat twelvth | b12",
    type = "interval",
    { 1, 17 },
  },
  {
    "perfect twelvth | 12",
    type = "interval",
    { 1, 18 },
  },
  {
    "minor 13",
    type = "interval",
    { 1, 19 },
  },
  {
    "major 13",
    type = "interval",
    { 1, 20 },
  },

  --
  -- TRIADS
  --

  {
    "major",
    type = "triad",
    { 1, 5, 8 },
  },
  {
    "minor",
    type = "triad",
    { 1, 4, 8 },
  },
  {
    "sus2",
    type = "triad",
    { 1, 4, 8 },
  },
  {
    "add9",
    type = "triad",
    { 1, 4, 8 },
  },
  {
    "sus4",
    type = "triad",
    { 1, 4, 8 },
  },
  {
    "dim",
    type = "triad",
    { 1, 4, 8 },
  },
  {
    "minor",
    type = "triad",
    { 1, 4, 8 },
  },
  {
    "minor",
    type = "triad",
    { 1, 4, 8 },
  },
  {
    "minor",
    type = "triad",
    { 1, 4, 8 },
  },
  {
    "quartal | Q", -- double fourths
    type = "triad",
    { 1, 4, 8 },
  },
  {
    "quartal | Q-", -- tritone + fourth
    type = "triad",
    { 1, 4, 8 },
  },
  {
    "quartal | Q+", -- fourth + tritone.
    type = "triad",
    { 1, 4, 8 },
  },

  --
  -- FOUR NOTE CHORDS
  --

  {
    "maj7",
    type = "triad",
    { 1, 4, 8 },
  },

  {
    "min7",
    type = "triad",
    { 1, 4, 8 },
  },

  {
    "m7b5",
    type = "triad",
    { 1, 4, 8 },
  },

  {
    "m7sus4",
    type = "triad",
    { 1, 4, 8 },
  },

  --
  -- FIVE NOTE CHORDS
  --

  {
    "maj9",
    type = "triad",
    { 1, 4, 8 },
  },

  {
    "minor 9th | m9",
    type = "triad",
    { 1, 4, 8 },
  },

  {
    "minor 7 add 4",
    type = "triad",
    { 1, 4, 8 },
  },

  {
    "minor 7 add 13",
    type = "triad",
    { 1, 4, 8 },
  },

}
