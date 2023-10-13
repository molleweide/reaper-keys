local log = require("utils.log")
local format = require("utils.format")

local reaper_state = require("utils.reaper_state")

local s = require("utils.string")

local PATTERN_PLACEHOLDER = "xo(xo) a b"

-- TODO: handle case of single substring
--
--    if # = 1

local SHORTHAND_CASES = {
  ["A"] = function(t, idx, val_in)
    t[idx] = "matched regex. compute something based on:" .. val_in
  end,
  ["a"] = "xoxo",
  -- quarter note beats
  ["q4"] = "xxxx4", -- four QN hits, which in the end should
  ["2q"] = "xoxo4", -- four QN hits, which in the end should
  ["q2"] = "oxox4", -- four QN hits, which in the end should
  ["32"] = "xxx2,3",
  -- test
  ["b"] = "xx(xxx)",
  ["c"] = "x[xx](xox)",
  ["d"] = "xxx2,3", -- 2-
}

local UNITS = {
  ["16th"] = 0.125,
  ["QN"] = 1,
}

local midi_patterns = {}

local function getMidiValidContext()
  local ME = reaper.MIDIEditor_GetActive()
  local take = reaper.MIDIEditor_GetTake(ME)

  local retval = true
  if not ME or (not take or not reaper.TakeIsMIDI(take)) then
    retval = false
  end
  return retval, ME, take
end

local function randomBool()
  return math.floor(math.random() + 0.5) == 1
end

midi_patterns.insertPatternForCurrentBarAndNoteRow = function()
  local ret, ME, take = getMidiValidContext()
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

  local insertion_data = {
    selected = false,
    muted = false,
    chan = 0,
    noSortIn = true,
  }

  for i = 1, t_midi_events[2] do
    local note_idx = i - 1
    local _, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, note_idx)

    -- local note_time = reaper.MIDI_GetProjTimeFromPPQPos(take, startppqpos)
    -- local retval, measures, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats(0, reaper.GetCursorPosition())
    -- log.user("note ppq time:", note_time)
    -- log.user("chan", chan)

    if pitch == active_note_row then
      -- reaper.MIDI_SetNote(take, note_idx, true, muted, startppqpos, endppqpos, chan, pitch, vel, true)
      reaper.MIDI_DeleteNote(take, note_idx)
      -- else
      -- 	-- reaper.MIDI_SetNote(take, note_idx, false, muted, startppqpos, endppqpos, chan, pitch, vel, true)
    end
  end

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
        insertion_data.selected,
        insertion_data.muted,
        reaper.MIDI_GetPPQPosFromProjTime(take, t_note.time_pos_start),
        reaper.MIDI_GetPPQPosFromProjTime(take, t_note.time_pos_end),
        insertion_data.chan,
        active_note_row,
        80,
        insertion_data.noSortIn
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
-- 1. whitespace separated elemets `a $4 xoox oxox xoox xoxo`
-- 2. a chunk starting with special char, eg $4. will multiply preceeding
-- 3. xk == hit
-- 4. o == no hit
-- 5.
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
midi_patterns.insertPatternFromString = function()
  local midi_patterns_state = reaper_state.get(state_table_name)

  log.user("PREV PATTERN:", format.block(midi_patterns_state))

  local user_input_opts = {
    -- todo:...
  }

  local input_placeholder = PATTERN_PLACEHOLDER

  local input_field_width = "extrawidth=350"
  local caption_csv = string.format("%s,%s", input_placeholder, input_field_width)
  local retvals_csv = ""

  -- pattern options
  local pattern_opts = {
    -- todo...
  }

  local pattern_sep = " " -- whitespace

  local _, str_pat_input = reaper.GetUserInputs("pattern:", 1, input_placeholder, caption_csv, retvals_csv)

  local t_pattern_strings = s.split(str_pat_input, pattern_sep)

  -- log.user("PATTERN STRING:", format.block(t_pattern_strings))

  --
  -- HANDLE MULTIPLIERS
  --

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

  if idx_mult_start ~= idx_at_mult then
    insert_once(true)
  end

  -- log.user(idx_mult_start, idx_at_mult, format.block(t_pat_multiplied))

  --
  -- SHORTHAND SWITCH TRANSFORMER
  --

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

  for i, str in ipairs(t_pat_multiplied) do
    case_apply(SHORTHAND_CASES, i, str, t_pat_multiplied)
  end

  -- TODO: 3. render the final table of rhythm chunks
  --    parse the raw rhythm units:
  --    xoxo {xxo} xoxo xooo
  --
  --    and create

  local t_final_midi_notes = {}

  local unit_multiplier = 1
  local unit_divider = 4

  local found = true

  for _, unit in pairs(t_pat_multiplied) do
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
    for i = 1, #unit do
      local char = unit:sub(i, i)
      local found_special = false

      if char == "(" then
        par_level = par_level + 1
      elseif char == ")" then
        par_level = par_level - 1
      end

      if char == "{" then
        cur_level = cur_level + 1
      elseif char == "}" then
        cur_level = cur_level - 1
      end

      if char == "[" then
        brack_level = brack_level + 1
      elseif char == "]" then
        brack_level = brack_level - 1
      end

      log.user(par_level, cur_level, brack_level, "char:", char)

      if string.match(char, "[{%[%(%)%]}]") then
        goto continue
      end

      -- TODO: now how should i handle ({[]}) here now???


        ::continue::
    end


    -- TODO: check balanced {([])} levels here??

    local pattern_parens = "%((.-)%)"
    local pattern_curly = "{(.-)}"
    local pattern_brackets = "%[(.-)%]"

    -- local extractedString = string.match(unit, pattern)
    local paren_start, paren_finish, paren_capturedString = string.find(unit, pattern_parens)
    local curly_start, curly_finish, curly_capturedString = string.find(unit, pattern_curly)
    local brackets_start, brackets_finish, brackets_capturedString = string.find(unit, pattern_brackets)

    log.user("parens:", paren_start, paren_finish, paren_capturedString)

    -- NOTE: I can gmatch to capture balanced {([])}
    --
    -- local input = "aa(x(sd))"
    -- local outermostCapturedString = ""
    -- for capturedString in input:gmatch("%b()") do
    -- 	outermostCapturedString = capturedString
    -- end

    -- TODO: for each note subtrack from the
    unit_subtract_len = unit_subtract_len - 666

    -- if `o` then ignore and step forward

    -- create
    -- table.insert(t_final_midi_notes, {
    -- 	time_pos_start = note_start,
    -- 	time_pos_end = note_start + note_duration,
    -- })
    --

    if unit_subtract_len > 0 then
      -- not enough notes for this unit
      -- fill remaining somehow
      log.user("unit_subtract_len > 0")
    end

    log.user("")
  end

  --  4. insert notes

  -- todo: parse each QN instance
  --
  -- ~ each delimited segment could describe something that is longer than
  --   a QN - truncate info so that only QNs length blocks are used.

  -- TODO: last repeat $5
  --   handle repetition of pattern.
  --   eg. ooxx 4$ -> repeat ooxx four times

  reaper_state.set(state_table_name, { prev_pattern_string = str_pat_input })
end

midi_patterns.editPrevPatternAndInsert = function() end

midi_patterns.repeatPrevPatternFromCurrentMeasure = function() end

midi_patterns.repeatPrevPatternFromCursor = function() end

return midi_patterns
