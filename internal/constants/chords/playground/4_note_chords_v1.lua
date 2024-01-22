local four_note_chords = {
  { name_long = "Major Seventh", name_short = "Maj7", type = "seventh", notes = { 0, 4, 7, 11 } },
  { name_long = "Dominant Seventh", name_short = "7", type = "seventh", notes = { 0, 4, 7, 10 } },
  { name_long = "Minor Seventh", name_short = "m7", type = "seventh", notes = { 0, 3, 7, 10 } },
  { name_long = "Diminished Seventh", name_short = "dim7", type = "seventh", notes = { 0, 3, 6, 9 } },
  { name_long = "Augmented Major Seventh", name_short = "Maj7#5", type = "seventh", notes = { 0, 4, 8, 11 } },
  { name_long = "Augmented Seventh", name_short = "7#5", type = "seventh", notes = { 0, 4, 8, 10 } },
  { name_long = "Major Sixth", name_short = "6", type = "sixth", notes = { 0, 4, 7, 9 } },
  { name_long = "Minor Sixth", name_short = "m6", type = "sixth", notes = { 0, 3, 7, 9 } },
  { name_long = "Major Ninth", name_short = "Maj9", type = "ninth", notes = { 0, 4, 7, 11, 14 } },
  { name_long = "Dominant Ninth", name_short = "9", type = "ninth", notes = { 0, 4, 7, 10, 14 } },
  { name_long = "Minor Ninth", name_short = "m9", type = "ninth", notes = { 0, 3, 7, 10, 14 } },
  { name_long = "Major Ninth Sharp Eleven", name_short = "Maj9#11", type = "ninth", notes = { 0, 4, 7, 11, 18 } },
  { name_long = "Dominant Ninth Sharp Eleven", name_short = "9#11", type = "ninth", notes = { 0, 4, 7, 10, 18 } },
  { name_long = "Minor Ninth Sharp Eleven", name_short = "m9#11", type = "ninth", notes = { 0, 3, 7, 10, 18 } },
  { name_long = "Major Seventh Sharp Nine", name_short = "Maj7#9", type = "seventh", notes = { 0, 4, 7, 11, 15 } },
  { name_long = "Dominant Seventh Sharp Nine", name_short = "7#9", type = "seventh", notes = { 0, 4, 7, 10, 15 } },
  { name_long = "Minor Seventh Sharp Nine", name_short = "m7#9", type = "seventh", notes = { 0, 3, 7, 10, 15 } },
  -- Add more chords here as needed
}

local common_four_note_chords = {
  {
    name_long = "Major Seventh Chord",
    name_short = "Maj7",
    type = "seventh",
    number_of_notes = 4,
    notes = { 0, 4, 7, 11 },
  },
  {
    name_long = "Dominant Seventh Chord",
    name_short = "7",
    type = "seventh",
    number_of_notes = 4,
    notes = { 0, 4, 7, 10 },
  },
  {
    name_long = "Minor Seventh Chord",
    name_short = "m7",
    type = "seventh",
    number_of_notes = 4,
    notes = { 0, 3, 7, 10 },
  },
  {
    name_long = "Minor Major Seventh Chord",
    name_short = "mMaj7",
    type = "seventh",
    number_of_notes = 4,
    notes = { 0, 3, 7, 11 },
  },
  {
    name_long = "Diminished Seventh Chord",
    name_short = "dim7",
    type = "seventh",
    number_of_notes = 4,
    notes = { 0, 3, 6, 9 },
  },
  {
    name_long = "Half-Diminished Seventh Chord",
    name_short = "m7♭5",
    type = "seventh",
    number_of_notes = 4,
    notes = { 0, 3, 6, 10 },
  },
  {
    name_long = "Major Sixth Chord",
    name_short = "6",
    type = "sixth",
    number_of_notes = 4,
    notes = { 0, 4, 7, 9 },
  },
  {
    name_long = "Minor Sixth Chord",
    name_short = "m6",
    type = "sixth",
    number_of_notes = 4,
    notes = { 0, 3, 7, 9 },
  },
  {
    name_long = "Dominant Seventh Suspended Fourth Chord",
    name_short = "7sus4",
    type = "seventh",
    number_of_notes = 4,
    notes = { 0, 5, 7, 10 },
  },
  {
    name_long = "Major Seventh Suspended Fourth Chord",
    name_short = "Maj7sus4",
    type = "seventh",
    number_of_notes = 4,
    notes = { 0, 5, 7, 11 },
  },
  -- Add more chords here as needed
}


---------------------------------

local four_note_chords = {
  {
    name_long = "Major Seventh Chord",
    name_short = "Maj7",
    type = "seventh",
    number_of_notes = 4,
    notes = {0, 4, 7, 11}
  },
  {
    name_long = "Dominant Seventh Chord",
    name_short = "7",
    type = "seventh",
    number_of_notes = 4,
    notes = {0, 4, 7, 10}
  },
  {
    name_long = "Minor Seventh Chord",
    name_short = "m7",
    type = "seventh",
    number_of_notes = 4,
    notes = {0, 3, 7, 10}
  },
  {
    name_long = "Minor Major Seventh Chord",
    name_short = "mMaj7",
    type = "seventh",
    number_of_notes = 4,
    notes = {0, 3, 7, 11}
  },
  {
    name_long = "Diminished Seventh Chord",
    name_short = "dim7",
    type = "seventh",
    number_of_notes = 4,
    notes = {0, 3, 6, 9}
  },
  {
    name_long = "Half-Diminished Seventh Chord",
    name_short = "m7♭5",
    type = "seventh",
    number_of_notes = 4,
    notes = {0, 3, 6, 10}
  },
  {
    name_long = "Major Sixth Chord",
    name_short = "6",
    type = "sixth",
    number_of_notes = 4,
    notes = {0, 4, 7, 9}
  },
  {
    name_long = "Minor Sixth Chord",
    name_short = "m6",
    type = "sixth",
    number_of_notes = 4,
    notes = {0, 3, 7, 9}
  },
  {
    name_long = "Dominant Seventh Suspended Fourth Chord",
    name_short = "7sus4",
    type = "seventh",
    number_of_notes = 4,
    notes = {0, 5, 7, 10}
  },
  {
    name_long = "Major Seventh Suspended Fourth Chord",
    name_short = "Maj7sus4",
    type = "seventh",
    number_of_notes = 4,
    notes = {0, 5, 7, 11}
  },
  {
    name_long = "Minor Seventh Sharp Five Chord",
    name_short = "m7♯5",
    type = "seventh",
    number_of_notes = 4,
    notes = {0, 3, 8, 10}
  },
  {
    name_long = "Minor Seventh Flat Five Chord",
    name_short = "m7♭5",
    type = "seventh",
    number_of_notes = 4,
    notes = {0, 3, 6, 10}
  },
  {
    name_long = "Major Seventh Sharp Five Chord",
    name_short = "Maj7♯5",
    type = "seventh",
    number_of_notes = 4,
    notes = {0, 4, 8, 11}
  },
  {
    name_long = "Minor Major Sixth Chord",
    name_short = "mMaj6",
    type = "sixth",
    number_of_notes = 4,
    notes = {0, 3, 7, 9}
  },
  {
    name_long = "Dominant Ninth Chord",
    name_short = "9",
    type = "ninth",
    number_of_notes = 4,
    notes = {0, 4, 7, 10}
  },
  {
    name_long = "Major Ninth Chord",
    name_short = "Maj9",
    type = "ninth",
    number_of_notes = 4,
    notes = {0, 4, 7, 11}
  },
  {
    name_long = "Minor Ninth Chord",
    name_short = "m9",
    type = "ninth",
    number_of_notes = 4,
    notes = {0, 3, 7, 10}
  },
  {
    name_long = "Dominant Ninth Sharp Eleven Chord",
    name_short = "9♯11",
    type = "ninth",
    number_of_notes = 4,
    notes = {0, 4, 7, 10, 6}
  },
  {
    name_long = "Major Ninth Sharp Eleven Chord",
    name_short = "Maj9♯11",
    type = "ninth",
    number_of_notes = 4,
    notes = {0, 4, 7, 11, 6}
  },
  {
    name_long = "Minor Ninth Sharp Eleven Chord",
    name_short = "m9♯11",
    type = "ninth",
    number_of_notes = 4,
    notes = {0, 3, 7, 10, 6}
  },
  {
    name_long = "Dominant Ninth Flat Thirteenth Chord",
    name_short = "9♭13",
    type = "ninth",
    number_of_notes = 4,
    notes = {0, 4, 7, 10, 8}
  },
  {
    name_long = "Major Ninth Flat Thirteenth Chord",
    name_short = "Maj9♭13",
    type = "ninth",
    number_of_notes = 4,
    notes = {0, 4, 7, 11, 8}
  },
  {
    name_long = "Minor Ninth Flat Thirteenth Chord",
    name_short = "m9♭13",
    type = "ninth",
    number_of_notes = 4,
    notes = {0, 3, 7, 10, 8}
  },
  {
    name_long = "Dominant Ninth Sharp Fifth Chord",
    name_short = "9♯5",
    type = "ninth",
    number_of_notes = 4,
    notes = {0, 4, 8, 10}
  },
  {
    name_long = "Major Ninth Sharp Fifth Chord",
    name_short = "Maj9♯5",
    type = "ninth",
    number_of_notes = 4,
    notes = {0, 4, 8, 11}
  },
  {
    name_long = "Minor Ninth Sharp Fifth Chord",
    name_short = "m9♯5",
    type = "ninth",
    number_of_notes = 4,
    notes = {0, 3, 8, 10}
  },
  {
    name_long = "Dominant Ninth Sharp Five Sharp Eleven Chord",
    name_short = "9♯5♯11",
    type = "ninth",
    number_of_notes = 4,
    notes = {0, 4, 8, 10, 6}
  },
  {
    name_long = "Major Ninth Sharp Five Sharp Eleven Chord",
    name_short = "Maj9♯5♯11",
    type = "ninth",
    number_of_notes = 4,
    notes = {0, 4, 8, 11, 6}
  },
  {
    name_long = "Minor Ninth Sharp Five Sharp Eleven Chord",
    name_short = "m9♯5♯11",
    type = "ninth",
    number_of_notes = 4,
    notes = {0, 3, 8, 10, 6}
  }
}

return four_note_chords

