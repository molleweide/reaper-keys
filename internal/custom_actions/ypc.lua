local log = require("utils.log")
local format = require("utils.format")

local cu = require("custom_actions.utils")
local r = require("utils.reaper")
local project_state = require("utils.project_state")

local libtr = require("library.tracks")
local midi = require("library.midi")
local libit = require("library.items")

local sxa = require("syntax.actions")
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

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-- refactor into which module
--
-- defaults to return everything
--
-- TODO: collect item/take fx_chain??
--
--
local function prepare_item_data_objs_for_yanking(tobj)
  local t_item_data_objs_for_yanking
  if sxu.trackObjHasOption(tobj.group, "m") then
    -- filter out correct midi lane range data from lane master
    log.user("prep item objs for yank: opt M")
    t_item_data_objs_for_yanking = libit.single_track_filter_transform_items(tobj.group, {
      filter = {
        info = {},
        data = {
          midi = {
            -- pitch -> filter range
            notes = { pitch = { { sxu.get_drum_lane_indices(tobj.group, tobj) } } },
          },
        },
      },
    })
  elseif tobj.class == "S" then
    -- filter out correct midi chan data on split master
    log.user("prep item objs for yank: S")
    t_item_data_objs_for_yanking = libit.single_track_filter_transform_items(tobj.channel_splitter, {
      {
        info = {},
        data = {
          midi = {
            notes = {
              -- pass function that filters single channel
              chan = function(note)
                return note.ch == tbl.findIndexOf(tobj.channel_splitter.children, tobj.guid, "guid")
              end,
            },
          },
        },
      },
    })
  else -- MC
    log.user("prep item objs for yank: standard MC")
    t_item_data_objs_for_yanking = libit.single_track_filter_transform_items(
      tobj,
      --
      -- TODO: if I want all info then i should just pass it as a "info" string
      -- in the filter table so that filter = { "info", "midi"}, will get
      -- everything
      --
      { filter = { info = {}, data = { midi = {} } } }-- get all midi
    )
  end
  return t_item_data_objs_for_yanking
end

-- todo: handle routes ?? i think this should be done via state chunk
-- todo: refactor first part into `get_track_data({
--    filter =
--       ~ track name and meta
--       ~ track info/params
--       ~ item data
--       ~ routes
-- })`
--
--
-- This functions get all info pertaining to a track that should be yanked.
-- Since data and track is separated with drum lanes this requires a custom
-- function that collects track info and then takes the data from the correct
-- source track container.
--
-- TODO: migrate this func into custom/ypc.lua

local function get_single_track_data_for_yanking(tobj)
  log.user(string.format("yank foc tr: %s (t), %s (g)", tobj.name, tobj.group and tobj.group.name or "!g"))

  -- move all information pertaining to putting together the track object to
  --

  local copied_from_type = "regular"

  -- if tobj.group and tobj.group.options["m"] then
  if sxu.trackObjHasOption(tobj.group, "m") then
    copied_from_type = "drumkit"
  elseif tobj.channel_splitter then
    copied_from_type = "splitter"
  end

  local tr = r.getTrackByGUID(tobj.guid)

  local track_data = {
    copied_from_type = copied_from_type,
    class = tobj.class,
    lanes = tobj.lanes and tobj.lanes,
    name = tobj.name,
    name_components = tobj.name_components,
    track_name_raw = tobj.name_raw,
    track_options = tobj.options,
    prev_idx = tobj.trackIndex,
    track_info = libtr.get_track_info_params(tobj.tr), --attach this inside of syntax.tracks instead.
    item_objs = prepare_item_data_objs_for_yanking(tobj),
    state_chunk = r.get_single_track_state_chunk(tr),
    -- fx_chain_state = fxu.get_single_tracks_fx_state_chunk(tobj.tr),
    routes = {},
  }
  return track_data
end

---- module funcs
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-- todo: needs proper return codes, so that `CUT` can return if yank did not
-- succeed
---@param meta table | nil
---@param opts table | nil
ypc.yank = function(meta, opts)
  opts = opts or {}
  local t_foc_tr, vtt = libtr.get_focused_track_objects()
  -- todo: this function should go into ypc, since it is specifically prepping for ypc
  --
  --

  local t_single_track_data = get_single_track_data_for_yanking(t_foc_tr[1])
  require("utils.project_state").overwrite("ypc", "tracks", t_single_track_data)
  return t_foc_tr, vtt
end

-- todo: the issue is that i have to collect all of the pitches and batch delet
-- them and then insert new events, because otherwise the order of notes gets fucked.
-- which is not good. but it makes for a funny effect tho.

ypc.put = function(meta, opts)
  opts = opts or {}
  local paste_data_exists, pd = project_state.get("ypc", "tracks")
  if not paste_data_exists then
    log.debug("YPC: paste data does not exist. Cannot paste nil...")
    return
  end
  local t_foc_tr, vtt = libtr.get_focused_track_objects()
  local np = t_foc_tr[1] -- node at position / first selected track in main
  local insertion_idx = np.trackIndex + 1 -- put below.. not above.

  -- put new track
  if not opts.dry_run then
    reaper.InsertTrackAtIndex(insertion_idx, false) -- should I add + 1 here?

    -- TODO: is this necessary?
    -- r.set_single_track_state_chunk(insertion_idx, pd.state_chunk)

    function recall_track(idx)
      local tr = reaper.GetTrack(0, idx)
      local _, str = reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", pd.track_name_raw, 1)

      -- TODO: why isn't the correct color applied?

      -- TODO: move this into route lib.
      reaper.SetMediaTrackInfo_Value(tr, 'B_MAINSEND', 0)
    end

    recall_track(insertion_idx)
  end

  -- put data

  if sxu.trackObjHasOption(np.group, "m") then
    log.debug("ypc put: drumkit")
    -- why do I need to add 1 here?
    r.node_takes_do(np.group, midi.shift_pitches_above_including, np.lanes.start + 1, pd.lanes.range)

    -- `pd` is the data node version of an item. this means that I could actually just send the pd
    -- table, so that these calls get a little tighter.
    r.node_insert_takes_do(np.group, pd.item_objs, midi.shift_insert_notes, np.lanes.start - pd.lanes.start)
  elseif np.channel_splitter then
    log.debug("ypc put: splitter")
    r.node_takes_do(np.channel_splitter, midi.shift_channels_above, sxu.get_split_index(np), 1)
    r.node_insert_takes_do(np.group, pd.item_objs, midi.insert_notes_force_chan, sxu.get_split_index(np))
  else
    log.debug("ypc put: regular")
    -- r.node_insert_takes_do(insertion_idx, pd.item_objs, midi.insert_notes_force_chan, 0)
  end
  sxa.applyConfigs()
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
    -- since this func is always for iterating and filtering items/takes in a node.
    -- in some of this midi funcs, why do I even pass the item/takes - shouldn't
    -- this be passed under the hood according to the filters i have specified.
    -- so instead i might pass an opts table instead and use the libit filter_transform
    -- func instead.
    r.node_iter_items_and_xtake(target_tobj.group, function(item, take, take_is_midi)
      midi.delete_notes_in_pitch_range(take, target_tobj.lanes.start + 1, target_tobj.lanes._end + 1)
      midi.shift_pitches_above_including(take, target_tobj.lanes._end + 2, -target_tobj.lanes.range)
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

  sxa.applyConfigs()
end

ypc.insertTrackAbove = function(meta, opts)
  -- reaper.InsertTrackAtIndex(insertion_idx, false)
end

ypc.insertTrackBelow = function(meta, opts)
  -- reaper.InsertTrackAtIndex(insertion_idx, false)
end

return ypc
