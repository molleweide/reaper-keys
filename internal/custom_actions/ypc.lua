local log = require("utils.log")
local format = require("utils.format")

local cu = require("custom_actions.utils")
local r = require("utils.reaper")

local project_state = require("utils.project_state")

local sx_tracks = require("syntax.tracks")
local sxu = require("syntax.utils")

-- FIX: C routing does not work > need to fix lib/route bug

-- TRACK EDITING YPC | only applies to MCABS tracks??
--
-- ypc functions only work on a single track for the moment.
--
-- NOTE: make sure to only use one track at a time.

local ypc = {}

-- ultrashall api has state chunk functions for storing and
-- loading FX Chains
--
-- HACK: hold up!!!!!
-- when copy / pasting tracks couldn't i just store the track state chunk???

-- TODO: enforce so that you only can copy certain classes together.

local USE_NATIVE_YPC = false

-- locals

local function native_copy_tracks(nop)
  if nop then
    return
  end
  reaper.Main_OnCommandEx(40210, 1, 0) -- copy tracks
end

local function native_paste_tracks(nop)
  if nop then
    return
  end
  numeric_id = reaper.NamedCommandLookup("_SWS_AWPASTE")
  if numeric_id == 0 then
    log.error("Could not find action in reaper or action list for: " .. id)
    return false
  end
  reaper.Main_OnCommand(numeric_id, 0) -- paste tracks
end

local function native_cut_tracks(nop)
  if nop then
    return
  end
  reaper.Main_OnCommandEx(40210, 1, 0) -- copy tracks
  reaper.Main_OnCommandEx(40005, 1, 0) -- remove tracks
  reaper.Main_OnCommandEx(40505, 1, 0) -- select last touched track
end

---- module funcs

--
-- YANK
--

-- FIX: needs proper return codes, so that `CUT` can return if yank did not
-- succeed
--
---@param meta table | nil
---@param opts table | nil
ypc.yank = function(meta, opts)
  -- FIX: remove libtr and use cu.getTrackPosition()
  local libtr = require("library.tracks")
  local t_foc_tr, t_tobj_list = libtr.get_focused_track_objects()
  sx_tracks.getVerifiedTree(t_tobj_list) -- make this an opt param in get_focused_track_objects

  log.user("TARGET TOBJ OPTIONS", format.block(t_foc_tr[1].options))

  local t_single_track_data = libtr.get_single_track_data_for_yanking(t_foc_tr[1])

  -- log.user(format.block(t_single_track_data.item_objs))
  -- log.user(format.block(t_single_track_data.state_chunk))

  -- for k, v in pairs(t_single_track_data) do
  -- 	log.user("yank", k, format.block(v))
  -- end

  -- need to store

  -- Note: Need to store data in both cases since the source data can come from a
  -- different track source

  require("utils.project_state").overwrite("ypc", "tracks", t_single_track_data)
  return t_foc_tr[1], t_tobj_list
end

--
-- PUT
--

ypc.put = function(meta, opts)
  local exists, t_data_track_to_paste = project_state.get("ypc", "tracks")
  if not exists then
    log.debug("YPC: paste data does not exist. Cannot paste nil...")
    return
  end
  if t_data_track_to_paste then
    for k, v in pairs(t_data_track_to_paste) do
      log.user("PUT: data to paste keys:", k)
    end
  end

  local vtt_pre = sx_tracks.getVerifiedTree() -- make this an opt param in get_focused_track_objects

  local insert_new_track_at_idx = cu.getTrackPosition() + 1

  local tobj_at_pos = vtt_pre.track_list[insert_new_track_at_idx]

  -- DEBUG LOGGING

  log.debug(
    string.format(
      [[ YPC PUT TOBJ @ POS
    name = %s
    class = %s
    idx = %s
    group name = %s
    ]] ,
      tobj_at_pos.name,
      tobj_at_pos.class,
      tobj_at_pos.trackIndex,
      tobj_at_pos.group and tobj_at_pos.group.options["m"]
    )
  )

  local operating_on_drum_kit = tobj_at_pos.group and tobj_at_pos.group.options["m"]

  --
  -- INSERT NEW TRACK AND SET STATE CHUNK
  --

  -- log.user(">>>",t_data_track_to_paste.state_chunk)
  -- reaper.InsertTrackAtIndex( insert_new_track_at_idx, false )
  -- r.set_single_track_state_chunk(insert_new_track_at_idx, state)

  --
  -- INSERT APPLY DATA
  --

  if operating_on_drum_kit then
    log.debug("YPC PUT / shift & insert data into drum kit master")
    -- log.user(paste_obj_range, type(paste_obj_range))
    local shift_pitches_above_note_row =
    sxu.get_note_row_after_drum_before_idx(tobj_at_pos.group, insert_new_track_at_idx)
    local paste_obj_range = t_data_track_to_paste.track_options and t_data_track_to_paste.track_options.nr or 1
    local range_num = tonumber(paste_obj_range)
    local shift_pitches_starting_from = shift_pitches_above_note_row + 1

    log.user("range of interest", shift_pitches_above_note_row, shift_pitches_above_note_row + range_num - 1)
    local tr = require("custom_actions.utils").getTrackByGUID(tobj_at_pos.group.guid)
    local item_count = reaper.CountTrackMediaItems(tr)
    local pname = reaper.GetTrackMIDINoteNameEx(0, tr, shift_pitches_starting_from, 0)

    log.user("PNAME:", pname)

    for i = 0, item_count - 1 do -- does parent_item_cnt need to be stored????
      local item = reaper.GetTrackMediaItem(tr, i)
      local take = reaper.GetMediaItemTake(item, 0) -- active take?
      require("library.midi").midi_take_filter_transform(take, {
        filter = {
          notes = {
            pitch = function(note)
              return shift_pitches_starting_from <= note.pitch
            end,
          },
        },
        transform = { notes = { pitch = range_num } },
      })
    end

    -- log.user(format.block(t_drum_master_item_objs))
  elseif tobj_at_pos.channel_splitter then
    log.debug("ypc.put / shift & insert data into channel splitter master")
  else
    log.debug("ypc.put / insert data into standard MC track")
  end
end

--
-- CUT
--

ypc.cut = function(meta, opts)
  local target_tobj, t_sx_tobj_list = ypc.yank() -- pass track to yank
  if not target_tobj then
    log.debug("YPC CUT: yanking did not suceed - aborting...")
    return
  end
  -- log.user(target_tobj.name, target_tobj.trackIndex, target_tobj.options.nr)

  local operating_on_drum_kit = target_tobj.group and target_tobj.group.options["m"]

  if operating_on_drum_kit then
    log.debug("CUT data from drum kit master")
    local range_start, range_end = sxu.get_drum_lane_indices_from_child_track_obj(target_tobj.group, target_tobj)
    local shift_value = range_end - range_start + 1
    log.user("CUT range:", range_start, range_end, "shiftval =", -shift_value)

    local tr = require("custom_actions.utils").getTrackByGUID(target_tobj.group.guid)
    local item_count = reaper.CountTrackMediaItems(tr)
    local pname = reaper.GetTrackMIDINoteNameEx(0, tr, range_start, 0)
    local pname_shift = reaper.GetTrackMIDINoteNameEx(0, tr, range_end + 1, 0)
    log.user("PNAME:", pname, pname_shift)

    for i = 0, item_count - 1 do -- does parent_item_cnt need to be stored????
      local item = reaper.GetTrackMediaItem(tr, i)
      local take = reaper.GetMediaItemTake(item, 0) -- active take?
      -- delete notes inside range
      -- shift notes
      require("library.midi").midi_take_filter_transform(take, {
        remove = {
          notes = { pitch = { { range_start, range_end } } },
        },
      })
      require("library.midi").midi_take_filter_transform(take, {
        filter = {
          notes = {
            pitch = function(note)
              return range_end + 1 <= note.pitch
            end,
          },
        },
        transform = { notes = { pitch = -shift_value } },
      })
    end
  elseif target_tobj.channel_splitter then
    log.debug("CUT data from channel splitter master")
    -- shift existing
  end

  -- reaper.DeleteTrack(tr)
end

--
-- INSERT NEW TRACK
--

ypc.insertTrackAbove = function(meta, opts)
  reaper.InsertTrackAtIndex(insertion_idx, false)
end

ypc.insertTrackBelow = function(meta, opts)
  reaper.InsertTrackAtIndex(insertion_idx, false)
end

return ypc
