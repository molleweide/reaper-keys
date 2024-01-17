local triads = {
  {
    name_long = "Major",
    name_short = "Maj",
    type = "Triad",
    notes = {0, 4, 7}
  },
  {
    name_long = "Minor",
    name_short = "Min",
    type = "Triad",
    notes = {0, 3, 7}
  },
  {
    name_long = "Diminished",
    name_short = "Dim",
    type = "Triad",
    notes = {0, 3, 6}
  },
  {
    name_long = "Augmented",
    name_short = "Aug",
    type = "Triad",
    notes = {0, 4, 8}
  },
  {
    name_long = "Sus2",
    name_short = "Sus2",
    type = "Triad",
    notes = {0, 2, 7}
  },
  {
    name_long = "Sus4",
    name_short = "Sus4",
    type = "Triad",
    notes = {0, 5, 7}
  }
}

-- Print the table for all possible triads
for _, triad in ipairs(triads) do
  print("Triad Name (Long): " .. triad.name_long)
  print("Triad Name (Short): " .. triad.name_short)
  print("Triad Type: " .. triad.type)
  print("Triad Notes: " .. table.concat(triad.notes, ", "))
  print("\n")
end
