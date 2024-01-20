-- local utils = require("custom_actions.utils")
local midi = require("library.midi")
local midi_editor = require("library.midi_editor")
local log = require("utils.log")
local format = require("utils.format")
local reaper_state = require("utils.reaper_state")
local s = require("utils.string")
local tl = require("library.timeline")

-- TODO: move this to `library/midi_patterns.lua`

local state_table_name = "midipatterns"

local NOTE_END_GAP = 0.005

local SHORTHAND_CASES = require("definitions.pattern_shorthands")

local PATTERN_SPEC = {
  user_input = {
    title = "pattern:",
    num_inputs = 1,
    placeholder = "xx(xxx)",
    input_field_width = "extrawidth=350",
    retvals_csv = "",
  },
  pattern_sep = " ", -- whitespace
  UNIT_MULTIPLIER = 0.5, -- quarter note
  UNIT_DIVIDER = 4, -- sixteenth note (0.125)
  special_symbols = {
    ["["] = { mult = 0.5 }, -- half
    ["]"] = { mult = 2 }, -- /2 *2
    ["("] = { mult = 2 / 3 }, -- tripple
    [")"] = { mult = 3 / 2 },
    ["{"] = { mult = 1 / 3 },
    ["}"] = { mult = 3 },
  },
}
PATTERN_SPEC.user_input.caption_csv =
string.format("%s,%s", PATTERN_SPEC.user_input.placeholder, PATTERN_SPEC.user_input.input_field_width)

local midi_patterns = {}

-- TODO: move to utils `time/transport/timeline`
local function get_beginning_of_measure()
  local _, msr = reaper.TimeMap2_timeToBeats(0, reaper.GetCursorPosition())
  local msr_start = reaper.TimeMap_GetMeasureInfo(0, msr)
  -- r.SetEditCurPos2(0, msr_start, 0, 0)
  return msr_start
end

local function randomBool()
  return math.floor(math.random() + 0.5) == 1
end

-- insert duplicates into `input_units` for each unit user wants repeated
local function apply_repeats(t_ps)
  local t_pattern_strings = t_ps.input_units

  local t_pat_multiplied = {}
  local idx_mult_start = 1
  local idx_at_mult = 1

  local function insert_once(is_last)
    local idx_stop = (not is_last and (idx_at_mult - 1)) or idx_at_mult
    for m = idx_mult_start, idx_stop do
      -- log.user(">> " .. t_pattern_strings[m])
      table.insert(t_pat_multiplied, t_pattern_strings[m])
    end
  end

  local function multiply(n)
    for _ = 1, n do
      insert_once()
    end
    idx_mult_start = idx_at_mult + 1
  end

  for i = 1, #t_pattern_strings do
    local substring = t_pattern_strings[i]
    idx_at_mult = i

    -- log.user(idx_mult_start, idx_at_mult, substring)

    -- if $N
    if string.match(substring, "^%$") then
      local secondChar = tonumber(substring:sub(2, 2))
      -- log.user(string.format("Multiplier for [%s] -----------", substring))

      multiply(secondChar)
    end
  end

  -- == 1 handles case where there is only one substring
  if idx_mult_start ~= idx_at_mult or idx_at_mult == 1 then
    insert_once(true)
  end

  t_ps.input_units = t_pat_multiplied
  return t_pat_multiplied
end

local function case_apply(cases, i, s_unit, t_target)
  for pattern, value in pairs(cases) do
    if string.match(s_unit, pattern) then
      if type(value) == "function" then
        value(t_target, i, s_unit)
      else
        t_target[i] = value
      end
    end
  end
end

-- replace `input_units` with their respective shorthand mapping
local function apply_shorthands(t_ps, cases)
  for i, s_unit in ipairs(t_ps.input_units) do
    case_apply(cases, i, s_unit, t_patterns)
  end
end

local function handle_if_special_char(t_ps)
  if string.match(t_ps.current_char, "[{%[%(%)%]}]") then
    for pattern_symbol, symbol_params in pairs(PATTERN_SPEC.special_symbols) do
      if t_ps.current_char == pattern_symbol then
        t_ps.current_unit.note_step = t_ps.current_unit.note_step * symbol_params.mult
      end
    end
    return true
  end
  return false
end

-- how can I pass the `opts` table down to here??
local function get_note_opts_for_char(pitch, t_ps)
  local note_end_full_length = t_ps.note_start + t_ps.current_unit.note_step

  local note_opts = {
    silent = true,
    time_pos_start = t_ps.note_start,
    time_pos_end_without_gap = note_end_full_length,
    time_pos_end = note_end_full_length - NOTE_END_GAP,
    note_step_length = t_ps.current_unit.note_step,
    pitch = pitch,
  }
  if string.match(t_ps.current_char, "[xk]") then
    note_opts.silent = false
  end
  if t_ps.current_char == "*" then
    note_opts.silent = randomBool()
  end
  return note_opts
end

local function make_midi_event_from_hit(t_midi_notes, t_midi_context, t_patterns_state)
  table.insert(t_midi_notes, get_note_opts_for_char(t_midi_context.note_row, t_patterns_state))
end

local function get_unit_multipliers(unit)
  local n, m = unit:match("^.-(%d+),(%d+)$")
  -- log.user("BOTH:", n, m)
  if not (n and m) then
    local _, _, n_cap1, n_cap2 = unit:find("([^,]-)(%d+)$")
    local _, _, m_cap1 = unit:find(".-,(%d+)$")
    -- log.user("N:", n_cap2)
    -- log.user("M:", m_cap1)
    n = n_cap2
    m = m_cap1
  end

  local mul = n and tonumber(n) / 2
  local div = m and tonumber(m)
  -- log.user("BOTH // mul =", mul, "div =", div, ">>", (mul and div) and mul / div)
  return mul or PATTERN_SPEC.UNIT_MULTIPLIER, div or PATTERN_SPEC.UNIT_DIVIDER
end

local function get_prepare_unit_params(unit)
  local multiplier, divider = get_unit_multipliers(unit)
  local note_step = multiplier / divider
  log.user(string.format(
    [[
	mul = %s
	div = %s
	note_step = %s
	]]  ,
    multiplier,
    divider,
    note_step
  ))
  return {
    note_step = note_step,
    multiplier = multiplier,
    divider = divider,
    note_hit_idx = 1, -- unused...
    unit_subtract_len = multiplier,
  }
end

local function increment(t_ps)
  t_ps.note_start = t_ps.note_start + t_ps.current_unit.note_step
  t_ps.current_unit.unit_subtract_len = t_ps.current_unit.unit_subtract_len - t_ps.current_unit.note_step
end

--
-- MAIN FUNCTION
--

-- special chars:
--    *   = random hit or silent
--    N   =
--    M   =
--    ()  =
--    {}  =
--    []  =

-- TODO: use fzf picker and store pattern history
-- only store patterns when the function is called from a picker/user_input.
-- Note when I call this function in other actions that also pass pattern strings.

midi_patterns.insertPatternFromString = function(meta, opts)
  opts = opts or {}
  local ret, t_midi_context = midi_editor.getMidiValidContext()
  if not ret then
    return
  end

  -- local midi_patterns_state = reaper_state.get(state_table_name)
  -- -- log.user("PREV PATTERN:", format.block(midi_patterns_state))

  local t_midi_notes = {}
  local str_pat_input = opts.pattern or nil

  if not str_pat_input then
    _, str_pat_input = reaper.GetUserInputs(
      PATTERN_SPEC.user_input.title,
      PATTERN_SPEC.user_input.num_inputs,
      PATTERN_SPEC.user_input.caption_csv,
      PATTERN_SPEC.user_input.retvals_csv
    )
  end

  -- maybe rename it to command state as a more general term so that this pattern
  -- could be reused in other of my custom action commands.
  local t_patterns_state = {
    input_units = s.split(str_pat_input, PATTERN_SPEC.pattern_sep),
    -- This value is incremented for each note added to the pattern.
    note_start = opts.start_at_measure and (tl.get_cursor_info()).msr.start or t_midi_context.cursor_pos,
  }

  apply_repeats(t_patterns_state)
  apply_shorthands(t_patterns_state, SHORTHAND_CASES)

  for _, unit in pairs(t_patterns_state.input_units) do
    t_patterns_state.current_unit = get_prepare_unit_params(unit)

    -- todo: i need to filter out escape stuff, eg. \n, and \t...
    for char in unit:gmatch(".") do
      t_patterns_state.current_char = char
      if not handle_if_special_char(t_patterns_state) then
        make_midi_event_from_hit(t_midi_notes, t_midi_context, t_patterns_state)
        increment(t_patterns_state)
      end
    end

    if t_patterns_state.current_unit.unit_subtract_len > 0 then
      log.debug([[
			unit_subtract_len > 0
			-> User input unit did not make even time according to multiplier,
			but this is fine, just know that you did not...
			]]  )
    end
  end

  log.debug("t pattern state", format.block(t_patterns_state), format.block(t_midi_notes))

  local pattern_start_ppq = reaper.MIDI_GetPPQPosFromProjTime(t_midi_context.take, t_midi_notes[1].time_pos_start)
  local pattern_end_ppq =
  reaper.MIDI_GetPPQPosFromProjTime(t_midi_context.take, t_midi_notes[#t_midi_notes].time_pos_end_without_gap)

  midi.midi_take_filter_transform(t_midi_context.take, {
    remove = {
      notes = {
        pitch = function(note)
          return note.pitch == t_midi_context.note_row
              and (pattern_start_ppq <= note.ppq_s and note.ppq_e <= pattern_end_ppq)
        end,
      },
    },
  })

  midi.insert_notes({
    take = t_midi_context.take,
    notes = t_midi_notes,
  })
  reaper_state.set(state_table_name, { prev_pattern_string = str_pat_input })
end

midi_patterns.editPrevPatternAndInsert = function() end

midi_patterns.repeatPrevPatternFromCurrentMeasure = function() end

midi_patterns.repeatPrevPatternFromCursor = function() end

return midi_patterns
