local chords = {
  two = require("constants.chords.two_note"),
  three = require("constants.chords.three_note"),
  four = require("constants.chords.four_note"),
  -- five = require("constants.chords.five_note"),
  -- six = require("constants.chords.six_note"),
  -- seven = require("constants.chords.seven_note"),
}

return function()
  local res = {}

  for _, chord_list in pairs(chords) do
    for _, chord in ipairs(chord_list) do
      table.insert(res, chord)
    end
  end

  return res
end
