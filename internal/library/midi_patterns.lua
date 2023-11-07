-- local utils = require("custom_actions.utils")
local midi = require("library.midi")
local log = require("utils.log")
local format = require("utils.format")
local reaper_state = require("utils.reaper_state")
local s = require("utils.string")

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
	local _, msr = r.TimeMap2_timeToBeats(0, r.GetCursorPosition())
	local msr_start = r.TimeMap_GetMeasureInfo(0, msr)
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

-- how can I pass the `opts` table down to here??
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
	if t_ps.char == "*" then
		note_opts.silent = randomBool()
	end
	return note_opts
end

local function make_midi_event_from_hit(t_midi_notes, t_midi_context, t_patterns_state)
	table.insert(t_midi_notes, get_note_opts_for_char(t_midi_context.note_row, t_patterns_state))
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

--
-- MAIN FUNCTION
--

-- FIX: this `insertPatternForCurrentBarAndNoteRow` can be made by just passing
-- an opts table to the actions in `defaults/actions`.
-- I could use `*` char to symbolize random hit or pause

midi_patterns.insertPatternForCurrentBarAndNoteRow = function()
	local ret, _, _, midi_ctx = midi.getMidiValidContext()
	if not ret then
		return
	end

	local t_pattern = {}
	local sixteen_note_len = 0.125
	local note_duration = sixteen_note_len - NOTE_END_GAP
	-- local retval, measures, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats(0, cursor_pos)

	midi.remove_notes(midi_ctx.take, midi_ctx.events, midi_ctx.note_row)

	-- log.user(">>>", cursor_pos, retval, measures, cml, fullbeats, cdenom)
	local beginning_msr = get_beginning_of_measure()

	for i = 0, 15 do
		local note_start = beginning_msr + i * sixteen_note_len
		table.insert(t_pattern, {
			flag = randomBool(),
			time_pos_start = note_start,
			time_pos_end = note_start + note_duration,
		})
	end

	log.user(format.block(t_pattern))

	midi.insert_notes({
		take = midi_ctx.take,
		notes = t_pattern,
	})
end

-- TODO: use cursor position or start from current measure
-- FIX: rename to `createNewPatternAndInsert`
--       or someting better more generalized
-- TODO:
-- ~ somehow randomize hits x/o
--
-- -- if unit has hard consonant chars, then make a hit (ie. silent = false)
-- so hard consonants are hits, and smooth vowels are pauses or silen. this
-- hopefully makes it ergonomic to program hits.
--
-- TODO: how can user specify how long notes should be?
-- Eg. for drum lanes, then the duration of each midi event can be
-- very short
-- BUT with synths, then I might want more control over note lengths

midi_patterns.insertPatternFromString = function(meta, opts)
	local ret, _, _, t_midi_context = midi.getMidiValidContext()
	if not ret then
		return
	end

	-- local midi_patterns_state = reaper_state.get(state_table_name)
	-- -- log.user("PREV PATTERN:", format.block(midi_patterns_state))

	local t_midi_notes = {}
	local str_pat_input = opts.pattern or nil

	if not str_pat_input then
		_, str_pat_input = reaper.GetUserInputs(PATTERN_SPEC.user_input)
	end

	-- maybe rename it to command state as a more general term so that this pattern
	-- could be reused in other of my custom action commands.
	local t_patterns_state = {
		input_units = s.split(str_pat_input, PATTERN_SPEC.pattern_sep),
		note_start = opts.start_at_measure and get_beginning_of_measure() or t_midi_context.cursor_pos,
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
