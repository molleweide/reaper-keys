
local note_pools = {
  two = require("constants.chords.two_note"),
  three = require("constants.chords.three_note"),
  four = require("constants.chords.four_note"),
  scales = require("constants.scales.scales")
  -- five = require("constants.note_pools.five_note"),
  -- six = require("constants.note_pools.six_note"),
  -- seven = require("constants.note_pools.seven_note"),
}

return function()
  local res = {}

  for _, pool_list in pairs(note_pools) do
    for _, note_pool in ipairs(pool_list) do
      table.insert(res, note_pool)
    end
  end

  return res
end
