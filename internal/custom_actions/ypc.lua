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

-- todo: needs proper return codes, so that `CUT` can return if yank did not
-- succeed
---@param meta table | nil
---@param opts table | nil
ypc.yank = function(meta, opts)
  opts = opts or {}
  local t_foc_tr, vtt = libtr.get_focused_track_objects()
  -- todo: this function should go into ypc, since it is specifically prepping for ypc
  local t_single_track_data = libtr.get_single_track_data_for_yanking(t_foc_tr[1])
  require("utils.project_state").overwrite("ypc", "tracks", t_single_track_data)
  return t_foc_tr, vtt
end

ypc.put = function(meta, opts)
  opts = opts or {}
  local paste_data_exists, pd = project_state.get("ypc", "tracks")
  if not paste_data_exists then
    log.debug("YPC: paste data does not exist. Cannot paste nil...")
    return
  end
  local t_foc_tr, vtt = libtr.get_focused_track_objects()
  local np = t_foc_tr[1] -- node at position / first selected track in main
  if not opts.dry_run then
    reaper.InsertTrackAtIndex(np.trackIndex, false) -- should I add + 1 here?
    local state_insert = pd.state_chunk
    r.set_single_track_state_chunk(np.trackIndex, state_insert)
  end
  if np.group and np.group.options["m"] then
    r.node_takes_do(np.group, midi.shift_pitches_above_including, np.lanes.start, pd.lanes.range)
    r.node_insert_takes_do(np.group, pd.item_objs, midi.shift_insert_notes, np.lanes.start - pd.lanes.start)
  elseif np.channel_splitter then
    r.node_takes_do(np.channel_splitter, midi.shift_channels_above, sxu.get_split_index(np), 1)
    r.node_insert_takes_do(np.group, pd.item_objs, midi.insert_notes_force_chan, sxu.get_split_index(np))
  else
    r.node_insert_takes_do(np.trackIndex, pd.item_objs, midi.insert_notes_force_chan, 0)
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
    r.node_iter_items_and_xtake(target_tobj.group, function(item, take, take_is_midi)
      midi.delete_notes_in_pitch_range(take, target_tobj.lanes.start, target_tobj.lanes._end)
      midi.shift_pitches_above_including(take, target_tobj.lanes._end + 1, -target_tobj.lanes.range)
    end)
  elseif target_tobj.channel_splitter then
    r.node_iter_items_and_xtake(target_tobj.channel_splitter, function(item, take, take_is_midi)
      midi.delete_notes_for_channel(take, sxu.get_split_index(target_tobj))
      midi.shift_channels_above(take, sxu.get_split_index(target_tobj), -1)
    end)
  end
  if not opts.dry_run then
    r.delete_node(target_tobj)
  end
end

ypc.insertTrackAbove = function(meta, opts)
  -- reaper.InsertTrackAtIndex(insertion_idx, false)
end

ypc.insertTrackBelow = function(meta, opts)
  -- reaper.InsertTrackAtIndex(insertion_idx, false)
end

return ypc
