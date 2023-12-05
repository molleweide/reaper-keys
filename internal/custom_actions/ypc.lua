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
  sxu.DRUMKITS_extend_with_context(vtt)

  -- for _, g in ipairs(vtt.groups) do
  --   if g.mc_drums and g.name == "DKIT2" then
  --     for _, c in ipairs(g.mc_drums) do
  --       log.debug(c.name, format.block(c.lanes))
  --     end
  --   end
  -- end

  debug_ypc("yank", t_foc_tr[1])

  -- TODO: this function should go into ypc, since it is specifically prepping for ypc
  local t_single_track_data = libtr.get_single_track_data_for_yanking(t_foc_tr[1])

  require("utils.project_state").overwrite("ypc", "tracks", t_single_track_data)
  return t_foc_tr, vtt
end

ypc.put = function(meta, opts)
  opts = opts or {}
  local exists, t_paste_data = project_state.get("ypc", "tracks")
  if not exists then
    log.debug("YPC: paste data does not exist. Cannot paste nil...")
    return
  end
  if t_paste_data then
    for k, v in pairs(t_paste_data) do
      log.user("PUT: data to paste keys:", k)
    end
  end

  -- log.user(format.block(t_paste_data.item_objs))
  local t_foc_tr, vtt = libtr.get_focused_track_objects()
  sxu.DRUMKITS_extend_with_context(vtt)
  local tobj_pos = t_foc_tr[1]

  -- insert new track
  if not opts.dry_run then
    reaper.InsertTrackAtIndex(insert_new_track_at_idx, false)
    local state_insert = t_paste_data.state_chunk
    r.set_single_track_state_chunk(insert_new_track_at_idx, state_insert)
  end

  -- shift data if necessary
  if tobj_pos.group and tobj_pos.group.options["m"] then
    local tr, item_count = r.get_track_and_item_count_for_node(tobj_pos.group)
    for i = 0, item_count - 1 do -- does parent_item_cnt need to be stored????
      local item = reaper.GetTrackMediaItem(tr, i)
      local take = reaper.GetMediaItemTake(item, 0) -- active take?
      midi.shift_pitches_above_including(take, tobj_pos.lanes.start, t_paste_data.lanes.range)
    end
    -- todo: insert data and set channel == split_chan_num
    for i = 0, #t_paste_data.item_objs - 1 do -- does parent_item_cnt need to be stored????
      -- todo: insert data and set channel == split_chan_num
    end
    -- log.user(format.block(t_drum_master_item_objs))
  elseif tobj_pos.channel_splitter then
    local tr, item_count = r.get_track_and_item_count_for_node(tobj_pos.channel_splitter)
    for i = 0, item_count - 1 do -- does parent_item_cnt need to be stored????
      local item = reaper.GetTrackMediaItem(tr, i)
      local take = reaper.GetMediaItemTake(item, 0) -- active take?
      midi.shift_channels_for_channels_below(take, sxu.get_split_index(tobj_pos), 1)
    end
    -- todo: insert data and set channel == split_chan_num
    for i = 0, t_paste_data.item_objs - 1 do -- does parent_item_cnt need to be stored????
      -- todo: insert data and set channel == split_chan_num
    end
  else
    local tr = reaper.GetTrack(0, insert_new_track_at_idx)
    local item_count = reaper.CountTrackMediaItems(tr)
    -- todo: just insert the data.
    for i = 0, t_paste_data.item_objs - 1 do -- does parent_item_cnt need to be stored????
      -- todo: insert data and set channel == split_chan_num
    end
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
  if target_tobj.group.mc_drums then
    local tr, item_count = r.get_track_and_item_count_for_node(target_tobj.group)
    for i = 0, item_count - 1 do -- does parent_item_cnt need to be stored????
      local item = reaper.GetTrackMediaItem(tr, i)
      local take = reaper.GetMediaItemTake(item, 0) -- active take?
      midi.delete_notes_in_pitch_range(take, target_tobj.lanes.start, target_tobj.lanes._end)
      midi.shift_pitches_above_including(take, target_tobj.lanes._end + 1, -target_tobj.lanes.range)
    end
  elseif target_tobj.channel_splitter then
    local tr, item_count = r.get_track_and_item_count_for_node(target_tobj.channel_splitter)
    for i = 0, item_count - 1 do -- does parent_item_cnt need to be stored????
      local item = reaper.GetTrackMediaItem(tr, i)
      local take = reaper.GetMediaItemTake(item, 0) -- active take?
      midi.delete_notes_for_channel(take, sxu.get_split_index(target_tobj))
      midi.shift_channels_for_channels_below(take, sxu.get_split_index(target_tobj), -1)
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
