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
	-- Get music data from string
	local ok, t_final_rendered_notes = midi.parse_and_render_midi_notes_block_from_string(main_input_str)
	if not ok then
		return false
	end

	local custom_targets = opts.targets or {}

	if custom_targets.tracks then
	end

	if custom_targets.regions then
	end

	local cursor_info = tl.get_cursor_info()


	for _, trnode in ipairs(t_sel_trks) do
		local target_item = check_if_item_exists_or_create(trnode.tr, cursor_info.msr.start, cursor_info.msr._end)
		apply_music_transform_hooks(trnode, target_item, t_final_rendered_notes)
	end

	return true
end

return amt
