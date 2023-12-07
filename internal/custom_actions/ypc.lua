local log = require("utils.log")
local format = require("utils.format")

local cu = require("custom_actions.utils")
local r = require("utils.reaper")

local project_state = require("utils.project_state")

local libtr = require("library.tracks")
local midi = require("library.midi")

local sx_tracks = require("syntax.tracks")
local sxu = require("syntax.utils")

--
--
-- THIS MODULE CREATES ACTIONS FOR MANAGING MIDI NODES
--
--

-- NOTE:
-- how should i structure this.
-- Should I move ypc functions for tracks into lib/tracks.

-- FIX: C routing does not work > need to fix lib/route bug

-- TRACK EDITING YPC | only applies to MCABS tracks??
--
-- ypc functions only work on a single track for the moment.
--
-- NOTE: make sure to only use one track at a time.
--
-- TODO: enforce so that you only can copy certain classes together.

local ypc = {}

-- local USE_NATIVE_YPC = false
--
-- -- locals
--
-- local function native_copy_tracks(nop)
--   if nop then
--     return
--   end
--   reaper.Main_OnCommandEx(40210, 1, 0) -- copy tracks
-- end
--
-- local function native_paste_tracks(nop)
--   if nop then
--     return
--   end
--   numeric_id = reaper.NamedCommandLookup("_SWS_AWPASTE")
--   if numeric_id == 0 then
--     log.error("Could not find action in reaper or action list for: " .. id)
--     return false
--   end
--   reaper.Main_OnCommand(numeric_id, 0) -- paste tracks
-- end
--
-- local function native_cut_tracks(nop)
--   if nop then
--     return
--   end
--   reaper.Main_OnCommandEx(40210, 1, 0) -- copy tracks
--   reaper.Main_OnCommandEx(40005, 1, 0) -- remove tracks
--   reaper.Main_OnCommandEx(40505, 1, 0) -- select last touched track
-- end

local function debug_ypc(type, tobj_pos)
  log.debug(string.format(
    [[
---------------------------------
  YPC -> %s
  track name = %s
        idx  = %s
  group name = %s
---------------------------------
  ]] ,
    type,

    tobj_pos.name,
    tobj_pos.trackIdx,
    tobj_pos.group and tobj_pos.group.name
  ))

  -- for _, g in ipairs(vtt.groups) do
  --   if g.mc_drums and g.name == "DKIT2" then
  --     for _, c in ipairs(g.mc_drums) do
  --       log.debug(c.name, format.block(c.lanes))
  --     end
  --   end
  -- end
end

---- module funcs

--
-- YANK
--

-- FIX: needs proper return codes, so that `CUT` can return if yank did not
-- succeed
--
-- FIX: remove libtr and use cu.getTrackPosition()
--
---@param meta table | nil
---@param opts table | nil
ypc.yank = function(meta, opts)
  opts = opts or {}
  local t_foc_tr, vtt = libtr.get_focused_track_objects()
  debug_ypc("yank", t_foc_tr[1], vtt)
  -- TODO: this function should go into ypc, since it is specifically prepping for ypc
  local t_single_track_data = libtr.get_single_track_data_for_yanking(t_foc_tr[1])
  require("utils.project_state").overwrite("ypc", "tracks", t_single_track_data)
  return t_foc_tr, vtt
end

ypc.put = function(meta, opts)
  opts = opts or {}
  local exists, pdata = project_state.get("ypc", "tracks")
  if not exists then
    log.debug("YPC: paste data does not exist. Cannot paste nil...")
    return
  end
  local t_foc_tr, vtt = libtr.get_focused_track_objects()
  local npos = t_foc_tr[1]
  local insert_new_track_at_idx = npos.trackIndex
  local new_tr

  -- insert new track
  if not opts.dry_run then
    -- NOTE: i will probably have to + 1 here, since I have been assuming insertion
    -- after the tobj at pos.
    reaper.InsertTrackAtIndex(insert_new_track_at_idx, false)
    local state_insert = pdata.state_chunk
    r.set_single_track_state_chunk(insert_new_track_at_idx, state_insert)
    new_tr = reaper.GetTrack(0, insert_new_track_at_idx)
  end

  -- NOTE: it seems that this could be refactored into one single statement,
  -- where I use the correct midi func call based on type.
  if npos.group and npos.group.options["m"] then
    r.node_takes_do(npos.group, midi.shift_pitches_above_including, npos.lanes.start, pdata.lanes.range)
    -- local tr, item_count = r.get_track_and_item_count_for_node(npos.group)
    -- for i = 0, item_count - 1 do -- does parent_item_cnt need to be stored????
    --   local _, take = r.get_item_and_first_take(tr, i)
    --   midi.shift_pitches_above_including(take, npos.lanes.start, pdata.lanes.range)
    -- end

    r.node_insert_takes_do(
      npos.group,
      pdata.item_objs,
      midi.shift_insert_notes,
      npos.lanes.start - pdata.lanes.start
    )
    -- for _, item_data in ipairs(pdata.item_objs) do
    --   local _, take = r.get_create_item_from_node(npos.group, item_data)
    --   midi.shift_insert_notes(take, item_data, npos.lanes.start - pdata.lanes.start)
    -- end
  elseif npos.channel_splitter then
    r.node_takes_do(npos.channel_splitter, midi.shift_channels_above, sxu.get_split_index(npos), 1)
    -- local tr, item_count = r.get_track_and_item_count_for_node(npos.channel_splitter)
    -- for i = 0, item_count - 1 do -- does parent_item_cnt need to be stored????
    --   local _, take = r.get_item_and_first_take(tr, i)
    --   midi.shift_channels_above(take, sxu.get_split_index(npos), 1)
    -- end
    r.node_insert_takes_do(npos.group, pdata.item_objs, midi.insert_notes_force_chan, sxu.get_split_index(npos))
    -- for _, item_data in ipairs(pdata.item_objs) do
    --   local _, take = r.get_create_item_from_node(npos.channel_splitter, item_data)
    --   midi.insert_notes_force_chan(take, sxu.get_split_index(npos), item_data)
    -- end
  else
    r.node_insert_takes_do(new_tr, pdata.item_objs, midi.insert_notes_force_chan, 0)
    -- for _, item_data in ipairs(pdata.item_objs) do
    --   local _, take = r.get_create_item_from_node(new_tr, item_data)
    --   midi.insert_notes_force_chan(take, 0, item_data)
    -- end
  end
end

ypc.cut = function(meta, opts)
  opts = opts or {}
  local t_foc_tr, _ = ypc.yank() -- pass track to yank
  local target_tobj = t_foc_tr[1]
  if not target_tobj then
    log.debug("YPC CUT: yanking did not suceed - aborting...")
    return
  end

  -- TODO: these for loops could also be done as transform of
  -- single_track_filter_transform_items
  --
  if target_tobj.group.mc_drums then
    local tr, item_count = r.get_track_and_item_count_for_node(target_tobj.group)
    for i = 0, item_count - 1 do -- does parent_item_cnt need to be stored????
      local _, take = r.get_item_and_first_take(tr, i)
      midi.delete_notes_in_pitch_range(take, target_tobj.lanes.start, target_tobj.lanes._end)
      midi.shift_pitches_above_including(take, target_tobj.lanes._end + 1, -target_tobj.lanes.range)
    end
  elseif target_tobj.channel_splitter then
    local tr, item_count = r.get_track_and_item_count_for_node(target_tobj.channel_splitter)
    for i = 0, item_count - 1 do
      local _, take = r.get_item_and_first_take(tr, i)
      midi.delete_notes_for_channel(take, sxu.get_split_index(target_tobj))
      midi.shift_channels_above(take, sxu.get_split_index(target_tobj), -1)
    end
  end
  if not opts.dry_run then
    reaper.DeleteTrack(r.getTrackByGUID(target_tobj.guid))
  end
end

ypc.insertTrackAbove = function(meta, opts)
  reaper.InsertTrackAtIndex(insertion_idx, false)
end

ypc.insertTrackBelow = function(meta, opts)
  reaper.InsertTrackAtIndex(insertion_idx, false)
end

return ypc
