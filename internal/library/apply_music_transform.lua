local log = require("utils.log")
local format = require("utils.format")
local tl = require("library.timeline")
local containers = require("library.items")
local midi = require("library.midi")
local lib_tr = require("library.tracks")
local state_interface = require("state_machine.state_interface")

local function check_if_item_exists_or_create(track, check_start_pos, check_end_pos)
	local items_found = containers.get_track_items_that_span_cursor_pos(track, check_start_pos, check_end_pos)
	local target_item
	if items_found then
		target_item = items_found[1].ref
	else
		target_item = containers.create_new_item(true, track, check_start_pos, check_end_pos)
	end
	return target_item
end

local function apply_music_transform_hooks(trnode, target_item, midi_data)
	local group_hooks = require("definitions.midi_apply_hooks").groups
	for hook_name, fn in pairs(group_hooks) do
		if trnode.group.name:lower():match(hook_name) then
			log.user("BASS HOOK")
			midi_data = fn(midi_data)
		end
	end
	midi.insert_notes({
		item = target_item,
		notes = midi_data,
	})
end

local amt = {}

amt.apply_patterns_to_sel_tracks = function(opts)
	opts = opts or {}
	local custom_targets = opts.targets or {}

	local last_command = state_interface.getKey("last_command")

	-- log.user("last_command:", format.block(last_command))

	--
	-- GET MUSIC DATA FROM STRING
	--
	-- TODO: add good defaults if not string is provided
	--

	local ok, t_final_rendered_notes = midi.parse_and_render_midi_notes_block_from_string(opts.prompt_str)
	if not ok then
		return false
	end

	--
	-- COMPUTE TARGET TRACKS
	--

	local target_tracks
	if custom_targets.tracks then
		target_tracks = custom_targets.tracks
	else
		local focused_track_objects, _, context = lib_tr.get_focused_track_objects()
		target_tracks = focused_track_objects
	end

	-- -- log.user("apply music:", #target_tracks)
	-- for _, cs in ipairs(target_tracks) do
	-- 	log.user(cs.name)
	-- end

	--
	-- COMPUTE TIMELINE RANGES
	--
	-- If regions exist then we prioritize those,
	-- else, if last command was motion/selector, we
	-- use their ranges.
	--
	-- TODO: one should also be able to specify in the prompt_str itself
	-- the positions themselves on a custom basis.
	--
	local target_ranges = {}
	if custom_targets.regions then
		for _, reg in ipairs(custom_targets.regions) do
			table.insert(target_ranges, {
				reg.pos,
				reg.rgnend,
			})
		end
	else
		if state_interface.last_command_has("timeline_operator") then
			local tl_range = state_interface.getKey("last_set_timeline_range")
			table.insert(target_ranges, tl_range)
		else
			local cursor_info = tl.get_cursor_info()
			table.insert(target_ranges, {
				cursor_info.msr.start,
				cursor_info.msr._end,
			})
		end
	end

	log.user("APPLY MUSIC RANGES:", format.block(target_ranges))

	--
	-- APPLY MUSIC TRANSFORM LOOP
	--

	-- 1. for each track node
	-- 2. for each region

	-- for _, trnode in ipairs(target_tracks) do
	-- 	local target_item = check_if_item_exists_or_create(trnode.tr, cursor_info.msr.start, cursor_info.msr._end)
	-- 	apply_music_transform_hooks(trnode, target_item, t_final_rendered_notes)
	-- end

	return true
end

return amt
