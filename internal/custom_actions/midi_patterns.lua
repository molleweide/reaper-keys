local utils = require("custom_actions.utils")
local midi = require("library.midi")

local log = require("utils.log")
local format = require("utils.format")
local reaper_state = require("utils.reaper_state")
local s = require("utils.string")

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
	UNIT_DIVIDER = 4, -- sixteenth note
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

-- insert duplicates into `input_units` for each unit user wants repeated
local function apple_repeats(t_ps)
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

--
-- MODULE FUNCS BELOW
--

-- TODO: should i redo this action by reusing `midi_patterns.insertPatternFromString`

midi_patterns.insertPatternForCurrentBarAndNoteRow = function()
	local ret, ME, take = midi.getMidiValidContext()
	if not ret then
		return
	end

	-- move these three into the midi context function
	local cursor_pos = reaper.GetCursorPosition()
	local t_midi_events = { reaper.MIDI_CountEvts(take) }
	local active_note_row = reaper.MIDIEditor_GetSetting_int(ME, "active_note_row")

	local t_pattern = {}
	local sixteen_note_len = 0.125
	local note_duration = sixteen_note_len - NOTE_END_GAP
	-- local retval, measures, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats(0, cursor_pos)

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

	midi.insert_notes({
		take = take,
		notes = t_pattern,
	})

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
-- TODO: use custom jGui input here instead, rather than the reaper
-- GetUserInput, since it doesn't seem to be possible to customize the reaper
-- input that easilly.

local function update_closure_level(t_unit, pattern, mult)
	if t_unit.current_unit.char == pattern then
		t_unit.current_unit.note_step = t_unit.current_unit.note_step * mult
	end
end

local function handle_if_special_char(t_ps)
	if string.match(t_ps.char, "[{%[%(%)%]}]") then
		for pattern_symbol, symbol_params in pairs(PATTERN_SPEC.special_symbols) do
			if t_ps.char == pattern_symbol then
				t_ps.current_unit.note_step = t_ps.current_unit.note_step * symbol_params.mult
			end
		end
		return true
	end
	return false
end

local function make_midi_event_from_hit(t_midi_notes, t_midi_context, t_patterns_state)
	table.insert(t_midi_notes, get_note_opts_for_char(t_midi_context.note_row, t_patterns_state))
end

-- if unit has hard consonant chars, then make a hit (ie. silent = false)
-- so hard consonants are hits, and smooth vowels are pauses or silen. this
-- hopefully makes it ergonomic to program hits.
--
-- TODO: how can user specify how long notes should be?
-- Eg. for drum lanes, then the duration of each midi event can be
-- very short
-- BUT with synths, then I might want more control over note lengths
--
local function get_note_opts_for_char(pitch, t_ps)
	local note_opts = {
		silent = true,
		time_pos_start = t_ps.note_start,
		time_pos_end = t_ps.note_start + (t_ps.current_unit.note_step - NOTE_END_GAP),
		note_step_length = t_ps.current_unit.note_step,
		pitch = pitch,
	}
	if string.match(t_ps.char, "[xk]") then
		note_opts.silent = false
	end
	return note_opts
end

local function get_unit_multipliers(unit)
	local capture_mul = unit:match("(N),M$")
	local capture_div = unit:match("N,(M)$")
	return capture_mul or PATTERN_SPEC.UNIT_MULTIPLIER, capture_div or PATTERN_SPEC.UNIT_DIVIDER
end

local function get_prepare_unit_params(unit)
	local multiplier, divider = get_unit_multipliers(unit)
	return {
		note_step = multiplier / divider,
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

-- TODO: use cursor position or start from current measure

midi_patterns.insertPatternFromString = function()
	local ret, _, _, t_midi_context = midi.getMidiValidContext()
	if not ret then
		return
	end

	-- local midi_patterns_state = reaper_state.get(state_table_name)
	-- -- log.user("PREV PATTERN:", format.block(midi_patterns_state))

	local t_midi_notes = {}

	local _, str_pat_input = reaper.GetUserInputs(PATTERN_SPEC.user_input)

	-- maybe rename it to command state as a more general term so that this pattern
	-- could be reused in other of my custom action commands.
	local t_patterns_state = {
		input_units = s.split(str_pat_input, PATTERN_SPEC.pattern_sep),
		note_start = t_midi_context.cursor_pos,
	}

	apple_repeats(t_patterns_state)
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
			]])
		end
	end

	midi.remove_notes(t_midi_context.take, t_midi_context.events, t_midi_context.note_row)
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
