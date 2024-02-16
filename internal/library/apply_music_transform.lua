local log = require("utils.log")
local format = require("utils.format")
local tl = require("library.timeline")
local containers = require("library.items")
local midi = require("library.midi")

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

amt.apply_patterns_to_sel_tracks = function(opts, t_sel_trks, main_input_str)
	local custom_targets = opts.targets or {}
	local target_tracks, target_ranges

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

	if custom_targets.tracks then
		target_tracks = custom_targets.tracks
	else
		local focused_track_objects, _, context = lib_tr.get_focused_track_objects()
		target_tracks = focused_track_objects
	end

	--
	-- COMPUTE TIMELINE RANGES
	--

	-- TODO: log ranges etc.

	if custom_targets.regions then
		-- TODO: extract ranges and put in target_ranges table?
		target_regions = custom_targets.regions
	else
		-- TODO: get range from timeline OR motion/selection
		local cursor_info = tl.get_cursor_info()
	end

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
