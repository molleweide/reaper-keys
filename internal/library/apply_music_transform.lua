local log = require("utils.log")
local format = require("utils.format")
local tl = require("library.timeline")
local containers = require("library.items")
local midi = require("library.midi")
local lib_tr = require("library.tracks")
local state_interface = require("state_machine.state_interface")
local tbl = require("utils.table")

-- TODO: CLI -> specify ranges manually?

local function shift_midi_events_in_time(t_midi_events, shift_amount)
  local res = {}

  for _, note in ipairs(t_midi_events) do
    local new_note = tbl.copy(note)

    -- FIX: I am not too fond of the naming here. midi note tl positions should
    -- be the same everywhere and regardless of context so that working with
    -- midi becomes more predictible.

    new_note.time_pos_start = new_note.time_pos_start + shift_amount
    new_note.time_pos_end = new_note.time_pos_end + shift_amount

    table.insert(res, new_note)
  end

  return res
end

-- TODO: move this to lib/items
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

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-- NOTE: Don't otimize the CLI now. I can be creative about that later,
-- and do some talking with chat gpt etc. but now it is just a matter
-- of getting the basics to work here so that I can start creating live
-- music shows. and I will be able to do that this week because now it
-- is going to be fucking done.
-- ithis week i will be done with everything that matters up until this system,
-- and so that I can then move on and start creating the beats.

-- TEST: LOOPING
--    default: beginning of measure
--    `l`      loop across range
--    -{N}     Start insertion N measures from the end of range.
--    n{N}     Insert every Nth measure.
--               Assumed `l`, so it will be auto-enabled

-- TEST: REGION CREATION
--    default: work in current region
--    r        make new region after current region, use same length as current
--    R        make new region before current region, use same length as current
--    +        duplicate/use-current region, AND build on top of it.

local function amt_parse_options(opts)
  opts.start_at_beginning_of_measure = true
  opts.loop_across_range = true
  opts.start_insertion_N_measures_from_the_end = 5
  opts.insert_every_Nth_measure = 2
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
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

  --
  -- GET MUSIC DATA FROM STRING
  --

  local ok, t_final_rendered_notes, ret_opts = midi.parse_and_render_midi_notes_block_from_string(opts.prompt_str)
  if not ok then
    return false
  end
  tbl.deep_extend(opts, ret_opts)

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
  -- 	log.user("track:", cs.name, cs.tr)
  -- end

  --
  -- COMPUTE TIMELINE RANGES
  --
  -- If regions exist then we prioritize those,
  -- else, if last command was motion/selector, we
  -- use their ranges.

  local target_ranges = {}
  if custom_targets.regions then
    -- for _, cs in ipairs(custom_targets.regions) do
    -- 	log.user("regions:", cs.name)
    -- end
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

  amt_parse_options(opts)

  --
  -- APPLY MUSIC TRANSFORM LOOP
  --

  for _, rng in ipairs(target_ranges) do
    local music_data_shifted_to_position = shift_midi_events_in_time(t_final_rendered_notes, rng[1])

    for _, trnode in ipairs(target_tracks) do
      local target_item = check_if_item_exists_or_create(trnode.tr, rng[1], rng[2])
      apply_music_transform_hooks(trnode, target_item, music_data_shifted_to_position)
    end
  end

  return true
end

return amt
