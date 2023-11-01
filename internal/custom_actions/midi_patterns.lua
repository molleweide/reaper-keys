local utils = require("custom_actions.utils")

local log = require("utils.log")
local format = require("utils.format")
local reaper_state = require("utils.reaper_state")
local s = require("utils.string")

local SHORTHAND_CASES = require("definitions.pattern_shorthands")
local PATTERN_PLACEHOLDER = "xx(xxx)"
local midi_insertion_data_default = {
  selected = false,
  muted = false,
  chan = 0,
  noSortIn = true,
}

-- local UNITS = {
--   ["16th"] = 0.125,
--   ["QN"] = 1,
-- }

local midi_patterns = {}

-- local function getMidiValidContext()
--   local ME = reaper.MIDIEditor_GetActive()
--   local take = reaper.MIDIEditor_GetTake(ME)
--
--   local retval = true
--   if not ME or (not take or not reaper.TakeIsMIDI(take)) then
--     retval = false
--   end
--   return retval, ME, take
-- end

local function randomBool()
  return math.floor(math.random() + 0.5) == 1
end

-- TODO: move to midi library and rename to midi.remove_notes({opts})
-- improve by adding a range from [60, 64]
-- range opt
-- note filter opt, eg notes outside of scale or predicate.

-- local function remove_note_row(take, t_midi_events, active_note_row)
--   for i = 1, t_midi_events[2] do
--     local note_idx = i - 1
--     local _, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, note_idx)
--     if pitch == active_note_row then
--       reaper.MIDI_DeleteNote(take, note_idx)
--     end
--   end
-- end

local function handle_multipliers(t_pattern_strings)
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
  return t_pat_multiplied
end

local function case_apply(cases, i, str, t_target)
  for pattern, value in pairs(cases) do
    if string.match(str, pattern) then
      if type(value) == "function" then
        value(t_target, i, str)
      else
        t_target[i] = value
      end
    end
  end
end

local function apply_shorthands(t_patterns, cases)
  for i, str in ipairs(t_patterns) do
    case_apply(cases, i, str, t_patterns)
  end
end

--
-- MODULE FUNCS BELOW
--

midi_patterns.insertPatternForCurrentBarAndNoteRow = function()
  local ret, ME, take = midi.getMidiValidContext()
  if not ret then
    return
  end

  local cursor_pos = reaper.GetCursorPosition()
  local t_midi_events = { reaper.MIDI_CountEvts(take) }
  local active_note_row = reaper.MIDIEditor_GetSetting_int(ME, "active_note_row")
  local t_pattern = {}
  local sixteen_note_len = 0.125
  local note_end_gap = 0.005
  local note_duration = sixteen_note_len - note_end_gap
  local retval, measures, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats(0, cursor_pos)

  midi.remove_notes(take, t_midi_events, active_note_row)

  -- log.user(">>>", cursor_pos, retval, measures, cml, fullbeats, cdenom)

  for i = 0, 15 do
    local note_start = i * sixteen_note_len
    table.insert(t_pattern, {
      flag = randomBool(),
      time_pos_start = note_start,
      time_pos_end = note_start + note_duration,
    })
  end

  log.user(format.block(t_pattern))

  for _, t_note in ipairs(t_pattern) do
    if t_note.flag then
      local ret = reaper.MIDI_InsertNote(
        take,
        midi_insertion_data_default.selected,
        midi_insertion_data_default.muted,
        reaper.MIDI_GetPPQPosFromProjTime(take, t_note.time_pos_start),
        reaper.MIDI_GetPPQPosFromProjTime(take, t_note.time_pos_end),
        midi_insertion_data_default.chan,
        active_note_row,
        80,
        midi_insertion_data_default.noSortIn
      )
    end
  end

  reaper.MIDI_Sort(take)
end

-- NOTE: PATTERN SPEC v1
--
--  -> `134C` first, third, and fourth beats should have randomized sixteenth notes
--
--  -> `13B` first and third beat should have random eighth notes
--
--        (default is to specify QN with digits)
--
--        (use delimiter to separate digits if above 10, eg. 9,10,11,60)
--
--        this could actually be quite powerful for inserting rhythms.
--
--        -> `.15,65,98,00(15)` use (.) to specify that digits symbolize which
--            eight note i am refering to and the chars coming after the digits
--            specify how the notes should be inserted/randomized. eg use 16th, 8th,
--            triplets or whatever notes for the beats.
--
--

-- NOTE: PATTERN SPEC V2
--
--
-- 1. whitespace separated units `a $4 xoox oxox xoox xoxo`
-- 2. a unit starting with special char, eg $4. will multiply preceeding
-- 3. xk == hit
-- 4. o == no hit
-- 5. [] make note length in half
-- 6. { } divide note length by four again
-- 7. () note length becomes two over three
-- 8. [(***)] achieve tripple in unit divider position
--
--  unit := represents a time block, based on musical time divisions
--
--  unit can be a short hand
--
--  unit is transformed into time division atoms
--
--      eg. 1 QN of sixteenth notes (xoxo)
--          2 QN of 6 tripplets 1/12
--          .5 QN of 2 16th
--          .5 QN of 4 32
--          3 QN of ???
--          4 QN of ???
--
--          a = 1 QN of (xoxo)
--          b = .5 QN of (xo)
--          c do .25 QN of one 16th note (x)
--
--  -> NOTE: DEFAULT UNIT LENGTH = 1 QN, default atom divider is 16th note
--
--  xoxo    is 4 sixtenth notes
--
--  xx(xxx)     would be two notes and a tripplet in the current unit
--              default is 1QN and 16th notes so this is [ xx(xxx) ]
--
--  x[xo](xox)     unit=1QN atom(x/o)=16
--                  1 QN = [ x x:split x2:triple ]
--                  ie. one sixteenth
--                      two 32th notes
--                      three 24th notes
--                      == one full QN
--
--  [xx]x(xxx)
--
-- NOTE: VARIABLE QN
-- it is up to the user to make sure that the final length is correct when
-- everything adds up
--
--    >>> NOTE: last number sets unit multiplier
--
--    >>> NOTE: divider = 16
--
--    >>>>>>>>> so the last two chars determine if there is a custom timing
--    parsing.
--
-- -- TWO QUARTER NOTES
--
--  xxxx2
--
--  xxx2
--
--  xoxoxo2,6     becomes six notes over two QN, (including three pauses)
--  alt. xoxoxo2+  or (=)
--
--  xxx2,3        becomes tree notes over two
--  alt. xxx2-
--
--
--  x{[xx]xx}(xxx)
--  [(***)]  {***}
--
--
--  -- how to do 3/2 triplets?
--
--  -- TODO: shuffle parameter
--
--  [] = atom splitter
--  () = two atoms
--
-- -> SHORTHANDS:
--
--  a = 1/4
--  b = 1/8
--  c = 1/16 notes
--
--  eg. a $4 -> insert 4 QNs of quarter notes
--      b $2 -> insert 2 QN of consecutive 16th notes
--      c $8 -> insert 8 QNs of 1/8 notes
--
--  . (period) -> empty QN
--
--  ..       -> two empty quarter notes
--
--  .3     -> three empty QNs -> (oooo oooo oooo)
--
--  ^     -> fill rest of measure with empty QNs
--             eg. if you have very large meter eg 11/4 then [ . a ^ x5 ]
--             would create a pattern of length 11 QNs
--
--
--  -> SPECIFY EXPLICIT PATTERNS:
--
--    xoxx oxoo xkxo xkoo
--
--    x,k  = hit
--    o    = no hit
--
--    should a single o == oooo
--    and single x == xooo
--
--    () use () to indicate triples
--
--
--  xx(xxx)    -> (xxx) indicates a triplet 24th note
--
--  [xx]    -> [] indicates 32th notes
--
--  QUESTION: I need a syntax for creating patterns that extend over multiple
--  quarter notes, eg. 3/2 three notes over two.
--      And then even go further and allow for writing {xxooxx} and have this
--      be six notes over two
--
--  {}#
--
--
--  +(N)/-N    -> use to alternate note rows up or down, eg if you want
--                 get the feel of alternating hands
--                 x x x...
--                  x x
--
--  LAST CHUNK
--
--  xN or $N    -> to indicate number of repetitons of pattern
--
--  !      -> don't extend midi item if pattern overflows take end point.
local state_table_name = "midipatterns"

-- FIX: rename to `createNewPatternAndInsert`
--
--
-- NOTE: leader m i
--    is the keybind for this action
--
--
-- TODO: leader m i -> insert pattern at cursor position
--       leader m I -> insert beginning of measure
--       .....      -> beginning of take??
--
--
-- TODO: leade m R -> replace selected note with pattern
--        requires only one note to be selected???
--
-- TODO: replace all selected notes with pattern??
--
-- TODO: use custom jGui input here instead, rather than the reaper
-- GetUserInput, since it doesn't seem to be possible to customize the reaper
-- input that easilly.

local function update_closure_level(char, open, close, level_var)
  if char == open then
    level_var = level_var + 1
  elseif char == close then
    level_var = level_var - 1
  end
end

midi_patterns.insertPatternFromString = function()
  local ret, ME, take = midi.getMidiValidContext()
  if not ret then
    return
  end
  local t_midi_events = { reaper.MIDI_CountEvts(take) }
  local active_note_row = reaper.MIDIEditor_GetSetting_int(ME, "active_note_row")

  -- local midi_patterns_state = reaper_state.get(state_table_name)
  -- -- log.user("PREV PATTERN:", format.block(midi_patterns_state))

  -- TODO: send http request to nvim and prompt nvim for string input,
  --       and send the string back to reaper via OSC
  -- 1. play around with neovim http server
  -- 2. prompt for nui.input on event.
  -- 3. send data back to reaper over OSC

  local input_placeholder = PATTERN_PLACEHOLDER
  local input_field_width = "extrawidth=350"
  local caption_csv = string.format("%s,%s", input_placeholder, input_field_width)
  local retvals_csv = ""
  local pattern_sep = " " -- whitespace

  local _, str_pat_input = reaper.GetUserInputs("pattern:", 1, input_placeholder, caption_csv, retvals_csv)

  local t_pattern_strings = s.split(str_pat_input, pattern_sep)
  local t_pat_multiplied = handle_multipliers(t_pattern_strings)

  apply_shorthands(t_pat_multiplied, SHORTHAND_CASES)

  --
  -- 3. render the final table of midi notes
  --

  local t_final_midi_notes = {}

  local unit_multiplier = 0.5 -- default time unit, a QN I believe
  local unit_divider = 4

  local found = true
  local note_start = 0

  for _, unit in pairs(t_pat_multiplied) do


    -- TODO: handle custom unit multipliers and dividers
    if string.match(unit, "pattern") then
      unit_multiplier = 99
    end
    if string.match(unit, "pattern") then
      unit_divider = 99
    end
    local unit_subtract_len = unit_multiplier


    log.user(unit_multiplier, unit_divider, "UNIT: [" .. unit .. "]")

    -- TODO: extract [], (), {}

    local par_level = 0
    local cur_level = 0
    local brack_level = 0


    local note_hit_idx = 1

    --
    -- for each unit, parse xx(x[xx{x{x}}]) into actual timing events
    --

    for i = 1, #unit do
      local char = unit:sub(i, i)
      update_closure_level(char, "(", ")", par_level)
      update_closure_level(char, "{", "}", cur_level)
      update_closure_level(char, "[", "]", brack_level)

      log.user(par_level, cur_level, brack_level, "char:", char)

      -- NOTE: i believe this just ignores {([])} for now so that I can start
      -- to work on just basic conversion of xko into time evts
      if string.match(char, "[{%[%(%)%]}]") then
        goto continue
      end

      -- TODO: update the mult and divider
      -- AND hit modulators {([])}

      -- 0.25 by default
      local note_step = unit_multiplier / unit_divider

      if par_level == 1 then
        note_step = (note_step * 2) / 3
      end


      local note_end_gap = 0.005
      local note_duration = note_step - note_end_gap

      -- TODO: handle both `x` and `k` for `hit`, ergonomic with alternating
      -- fingers in qwerty...
      if string.match(char, "[xk]") then
        table.insert(t_final_midi_notes, {
          char = char,
          time_pos_start = note_start,
          time_pos_end = note_start + note_duration,
        })
      end

      -- set vars for next round
      note_start = note_start + note_step
      unit_subtract_len = unit_subtract_len - note_step
      ::continue::
    end

    log.user("time even???: ", unit_subtract_len)

    -- if `o` then ignore and step forward

    if unit_subtract_len > 0 then
      -- not enough notes for this unit
      -- fill remaining somehow
      log.user("unit_subtract_len > 0")
    end

    log.user("")
  end
  log.user(format.block(t_final_midi_notes))

  midi.remove_notes(take, t_midi_events, active_note_row)
  midi.insert_notes(take, {
    notes = t_final_midi_notes,
    output_note = active_note_row
  })
  reaper_state.set(state_table_name, { prev_pattern_string = str_pat_input })
end

midi_patterns.editPrevPatternAndInsert = function() end

midi_patterns.repeatPrevPatternFromCurrentMeasure = function() end

midi_patterns.repeatPrevPatternFromCursor = function() end

return midi_patterns
