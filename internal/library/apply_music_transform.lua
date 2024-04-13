local log = require("utils.log")
local format = require("utils.format")
local tl = require("library.timeline")
local containers = require("library.items")
local midi = require("library.midi")
local lib_tr = require("library.tracks")
local state_interface = require("state_machine.state_interface")
local tbl = require("utils.table")
local segments = require("library.segments")

local fb = format.block

-- FIX: truncate midi events that overflows range

-- TODO: CLI -> specify ranges manually?
--
-- `utils/cli.lua`

local function make_bool_flag(search_str, pat)
  local found = search_str:find(pat)
  -- log.user(search_str, pat, "->found:", found)
  return found and true or nil
end

local function make_int_flag(search_str, pat, default)
  local found = search_str:match(pat .. "(%d+)")
  return found and tonumber(found) or default
end

----

-- TODO: respect CLI prompt options
-- ~ preshift
-- ~ postshift
-- ~ every Nth
--
---Apply range shift and looping of musical data for a single range.
---@param opts any
---@param t_midi_events any
---@param current_range any
---@return table
local function shift_and_loop_data_to_range(opts, t_midi_events, current_range)
  local res = {}

  local range_len = current_range[2] - current_range[1]

  local loop_measures_len = opts.pattern.meta_data.num_measures_affected_length

  local num_loops = 1

  while range_len > loop_measures_len * num_loops do
    num_loops = num_loops + 1
  end

  log.user(
    "CHECK LOOP",
    format.block({
      range_len = range_len,
      loop_measures_len = loop_measures_len,
      num_loops = num_loops,
    })
  )

  -- num_loops = 1

  for i = 0, num_loops - 1, 1 do
    for _, note in ipairs(t_midi_events) do
      local new_note = tbl.copy(note)

      -- FIX: I am not too fond of the naming here. midi note tl positions should
      -- be the same everywhere and regardless of context so that working with
      -- midi becomes more predictible.

      local loop_shift = loop_measures_len * i

      new_note.time_pos_start = new_note.time_pos_start + current_range[1] + loop_shift
      new_note.time_pos_end = new_note.time_pos_end + current_range[1] + loop_shift

      table.insert(res, new_note)
    end
  end

  log.user("res", fb(res))

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

-- TEST: PATTERN START / LOOPING ----------------------------------------------
--    default: Beginning of measure
--    `l`      Loop across range
--    +{N}     Start inserting pattern N measures from left/start.
--    -{N}     Start insertion N measures from the end of range.
--    n{N}     Insert every Nth measure.
--               ?? Assumed `l`, so it will be auto-enabled
--               !! `l` is not required i think

-- TEST: REGION CREATION
--    default: Work in current region
--    r        Make new region after current region, use same length as current
--    R        Make new region before current region, use same length as current
--    #        Duplicate/use-current region, AND build on top of it.

local function amt_parse_options(opts)
  local cli_opts = opts.cli_options
  if not cli_opts then
    return
  end
  opts.configs = {}

  -- FIX: I can get rid of the `cli_opts` param to flag func by having the func
  -- return a new func that uses the cli_opts inside...

  -- PATTERN POSITION AND LOOPING

  -- Insert pattern at beginning of each supplied range
  opts.configs.start_at_beginning_of_range = true
  opts.configs.loop_across_range = make_bool_flag(cli_opts, "l")
  opts.configs.left_shift_number = make_int_flag(cli_opts, "%+")                         --cli_opts:match("%+(%d+)")
  opts.configs.start_insertion_N_measures_from_the_end = make_int_flag(cli_opts, "%-")   --cli_opts:match("%+(%d+)")
  opts.configs.stop_loop_N_measures_from_region_end = make_int_flag(cli_opts, "s")
  opts.configs.nth_measure_number = make_int_flag(cli_opts, "n")

  -- NEW REGION

  opts.configs.new_region_length_in_measures = make_int_flag(cli_opts, "n", 8)
  opts.configs.make_new_region_after = make_bool_flag(cli_opts, "r")
  opts.configs.make_new_region_before = make_bool_flag(cli_opts, "R")
  opts.configs.reuse_current_region = make_bool_flag(cli_opts, "#")

  log.user("PATTERN CLI OPTS:", format.block(opts.configs))
end

---Compute the regions for which we should inject data.
---1. If picked regions exist
---2. Check if selector command
---3. Check if visual timeline is set
---4. Check if "motion"
---@param custom_targets any
---@return table
local function compute_target_timeline_ranges(custom_targets)
  local target_ranges = {}
  -- 1. selected regions
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
    -- 2. operator & motion
    if state_interface.last_command_has("timeline_operator") then
      local tl_range = state_interface.getKey("last_set_timeline_range")
      table.insert(target_ranges, tl_range)
    else
      -- 3. cursor position
      local cursor_info = tl.get_cursor_info()
      table.insert(target_ranges, {
        cursor_info.msr.start,
        cursor_info.msr._end,
      })
    end
  end
  return target_ranges
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-- WARN: hooks cannot transform notes in time so that the pattern becomes longer
-- than expected.
--
---Apply user configured hooks
---@param trnode any
---@param target_item any
---@param midi_data any
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

--- Takes a set of tracks and musical patterns and applies this midi data
--- the target tracks at specified timeline ranges. It allows one to operate
--- on a macro level by injecting musical data algorhitmically.
---@param opts any
---@return boolean
amt.apply_patterns_to_sel_tracks = function(opts)
  opts = opts or {}
  local custom_targets = opts.targets or {}

  --
  -- GET MUSIC DATA FROM STRING
  --
  --

  local ok, t_final_rendered_notes, ret_opts = midi.parse_and_render_midi_notes_block_from_string(opts.prompt_str)
  if not ok then
    return false
  end
  tbl.deep_extend(opts, ret_opts)

  log.user("opts", format.block(opts))

  log.user("final notes", format.block(t_final_rendered_notes))
  --
  -- COMPUTE TARGET TRACKS
  --
  -- depending on whether or not target tracks are specified in the string prompt
  -- we have to have a smart chain for computing default tracks to target if
  -- none are specified.

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

  -- handle create new regions
  local rd
  if custom_targets.regions and opts.add_new_region_opts then
    log.user("APPLY MUSIC: ADDING NEW REGIONS")
    -- TODO: Reverse loop inject the new regions, and overwrite the custom_targets.regions
    -- variable so the new region will be used for compute_target_timeline_ranges
    -- below
    rd = segments.compute_new_regions_data_for_insertion(opts.add_new_region_opts, custom_targets.regions)


  end

  local target_ranges = compute_target_timeline_ranges(custom_targets)

  amt_parse_options(opts)

  --
  -- APPLY MUSIC TRANSFORM LOOP
  --
  -- NOTE: In the case of [rR#], how do I handle if multiple regions or
  -- ranges are passed into AMT?
  -- SOLUTION: ->>> Assume, that only one region/range is passed and work
  -- as if everything will workout - Handle issues along the way.

  -- FIX: I should reverse loop insert data, so that ranges don't fall
  -- out of sync after first insertion of a new region/section.

  for _, t_target_range in ipairs(target_ranges) do
    -- note: Everything from here on, can depend on the cli options so I have
    -- to implement them one by one.

    --
    -- (A). FOR EACH TARGET RANGE
    --
    -- The rhythm events are shifted from zero-based to each target range,
    -- including if running @ cursor.

    local music_data_shifted_to_position =
        shift_and_loop_data_to_range(opts, t_final_rendered_notes, t_target_range)

    -- log.user("music_data_shifted_to_position", format.block(music_data_shifted_to_position))


    for _, trnode in ipairs(target_tracks) do
      log.user("?")
      local target_item = check_if_item_exists_or_create(trnode.tr, t_target_range[1], t_target_range[2])
      apply_music_transform_hooks(trnode, target_item, music_data_shifted_to_position)
    end
  end

  return true
end

return amt
