local s = require("utils.string")

local mnp = {}

-- TODO: move this also into a string parsing file.
--
-- ~ I need a way to specifically target chords / scale
-- ~ Add octave number to the initial pitch
mnp.parse_note_pool = function(note_pool_str)
  local root_pitch, note_pool_found
  local default_pitch = 60

  if note_pool_str == nil or note_pool_str == "" then
    return {
      root_pitch = default_pitch,
      note_pool = nil,
    }
  else
    local t_parsed_pool = s.split(note_pool_str, " ")

    -- log.user("t parsed pool:", format.block(t_parsed_pool))

    local parsed_pool

    if #t_parsed_pool == 1 then
      root_pitch = default_pitch
      parsed_pool = t_parsed_pool[1]
    elseif #t_parsed_pool > 1 then
      root_pitch = t_parsed_pool[1]
      parsed_pool = t_parsed_pool[2]
    end

    local all_note_pools = require("constants.all_note_pools")()
    local found_np = false

    for _, np in ipairs(all_note_pools) do
      if np.name_short:lower():match("^" .. parsed_pool) then
        note_pool_found = np
        found_np = true
      end
    end
  end

  if note_pool_found then
    for i, pitch in ipairs(note_pool_found.relative_intervals) do
      note_pool_found.relative_intervals[i] = pitch + default_pitch
    end
  end
  return {
    root_pitch = root_pitch,
    note_pool = note_pool_found,
  }
end

return mnp
