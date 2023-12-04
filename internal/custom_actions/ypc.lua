local log = require("utils.log")
local format = require("utils.format")

local cu = require("custom_actions.utils")
local r = require("utils.reaper")

local project_state = require("utils.project_state")

local libtr = require("library.tracks")

local sx_tracks = require("syntax.tracks")
local sxu = require("syntax.utils")

-- FIX: C routing does not work > need to fix lib/route bug

-- TRACK EDITING YPC | only applies to MCABS tracks??
--
-- ypc functions only work on a single track for the moment.
--
-- NOTE: make sure to only use one track at a time.

local ypc = {}

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

local function debug_ypc(type, tobj_pos)
	log.debug(string.format(
		[[
---------------------------------
  YPC -> %s
  track name = %s
        idx  = %s
  group name = %s
---------------------------------
  ]],
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

	debug_ypc("yank", t_foc_tr[1])

	-- TODO: this function should go into ypc, since it is specifically prepping for ypc
	local t_single_track_data = libtr.get_single_track_data_for_yanking(t_foc_tr[1])

	require("utils.project_state").overwrite("ypc", "tracks", t_single_track_data)
	return t_foc_tr, vtt
end

--
-- PUT
--

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

	-- FIX: redo focused track here so that it returns more of a "context" that
	-- can be used when managing tracks.
	-- >> It already does return selection and vtt, so I could just use the selection
	-- objects...
	--
	local vtt_pre = sx_tracks.getVerifiedTree() -- make this an opt param in get_focused_track_objects

	local insert_new_track_at_idx = cu.getTrackPosition() + 1
	local tobj_pos = vtt_pre.track_list[insert_new_track_at_idx]
	local operating_on_drum_kit = tobj_pos.group and tobj_pos.group.options["m"]

	--
	-- PUT: VARIABLES
	--

	local put_type
	local parent_obj
	local midi_transform_target_track
	local midi_transform_target_track_item_count

	-- drum kit vars
	local shift_pitches_starting_from
	local pitch_shift_amount
	local pname_sel_track
	local preceding_drum_obj
	local preceding_drum_range = {}
	-- splitter vars
	-- regular put vars

	if operating_on_drum_kit then
		put_type = "drumkit"
		parent_obj = tobj_pos.group
		preceding_drum_range = { sxu.get_drum_lane_indices(tobj_pos.group, sxu.get_prev_drum(tobj_pos)) }
		shift_pitches_starting_from = preceding_drum_range[2] + 1
		pitch_shift_amount = tonumber(t_paste_data.track_options and t_paste_data.track_options.nr or 1)
		midi_transform_target_track = r.getTrackByGUID(tobj_pos.group.guid)
		pname_sel_track = reaper.GetTrackMIDINoteNameEx(0, midi_transform_target_track, shift_pitches_starting_from, 0)
	--
	elseif tobj_pos.channel_splitter then
		put_type = "splitter"
		-- todo...
		parent_obj = tobj_pos.channel_splitter
		midi_transform_target_track = r.getTrackByGUID(tobj_pos.channel_splitter.guid)
	else
		put_type = "regular"
	end

	midi_transform_target_track_item_count = reaper.CountTrackMediaItems(midi_transform_target_track)

	-- TODO: migrate this into debug_ypc
	log.debug(string.format(
		[[---------------------------------
  YPC -> PUT (type: %s)
  ::SELECTED TRACK IN MAIN::
         name = %s
         class = %s
         idx = %s (GUI idx = %s)
         prollname = %s
  ::INSERTION DATA INFO::
         rstart = %s
         rend = %s (this is the value we have to shift up to in order to make place for insertion data)
         pitch_shift_amount = %s
  ::PARENT OBJECT INFO::
         name = %s
         class = %s
         opt.m = %s
  ::PRECEDING DRUM TRACK INFO::
        name = %s
        preceding range_start = %s
        preceding_range_end = %s
  ---------------------------------
    ]],
		--tr@pos
		put_type,
		tobj_pos.name,
		tobj_pos.class,
		tobj_pos.trackIndex,
		tobj_pos.trackIndex + 1,
		pname_sel_track,

		-- preceding_range_end + 1,
		shift_pitches_starting_from,
		shift_pitches_starting_from + pitch_shift_amount - 1,
		pitch_shift_amount > 0 and "+" .. tostring(pitch_shift_amount) or pitch_shift_amount,

		-- parent
		parent_obj and parent_obj.name,
		parent_obj and parent_obj.class,
		parent_obj and parent_obj.options["m"],
		-- drums preceeding
		preceding_drum_obj.name,
		preceding_drum_range[1],
		preceding_drum_range[2]
	))
	--
	-- PUT: NEW TRACK -------------------------------------------------------
	--

	-- TODO: ensure new state exists above under variables?
	--
	if not opts.dry_run then
		reaper.InsertTrackAtIndex(insert_new_track_at_idx, false)
		local state_insert = t_paste_data.state_chunk
		r.set_single_track_state_chunk(insert_new_track_at_idx, state_insert)

		if put_type == "regular" then
			midi_transform_target_track = reaper.GetTrack(0, insert_new_track_at_idx)
		end
	end

	--
	-- PUT: MIDI -------------------------------------------------------
	--

	-- shift data if necessary
	if put_type == "drumkit" then
		for i = 0, midi_transform_target_track_item_count - 1 do -- does parent_item_cnt need to be stored????
			local item = reaper.GetTrackMediaItem(midi_transform_target_track, i)
			local take = reaper.GetMediaItemTake(item, 0) -- active take?
			require("library.midi").midi_take_filter_transform(take, {
				dry_run = true,
				filter = {
					notes = {
						pitch = function(note)
							return shift_pitches_starting_from <= note.pitch
						end,
					},
				},
				transform = { notes = { pitch = pitch_shift_amount } },
			})
		end
	-- log.user(format.block(t_drum_master_item_objs))
	elseif put_type == "splitter" then
	elseif put_type == "regular" then
	else
		log.debug("PUT: something went wrong...")
	end
end

--
-- CUT -------------------------------------------------------
--

ypc.cut = function(meta, opts)
	opts = opts or {}
	local t_foc_tr, _ = ypc.yank() -- pass track to yank
	local target_tobj = t_foc_tr[1]

	if not target_tobj then
		log.debug("YPC CUT: yanking did not suceed - aborting...")
		return
	end

	local cut_type, parent_obj
	local operating_on_drum_kit = target_tobj.group and target_tobj.group.options["m"]

	--
	local drum_tr_range_num
	local range_start, range_end
	local shift_value
	local pname
	local pname_shift

	--
	local midi_data_collect_track
	local midi_data_collect_track_item_count

	--
	-- CUT: VARIABLES
	--

	if operating_on_drum_kit then
		cut_type = "drumkit"
		parent_obj = target_tobj.group
		drum_tr_range_num = target_tobj.options and target_tobj.options["nr"] or 1
		range_start, range_end = sxu.get_drum_lane_indices(target_tobj.group, target_tobj)
		shift_value = range_end - range_start + 1
		midi_data_collect_track = r.getTrackByGUID(target_tobj.group.guid)

		pname = reaper.GetTrackMIDINoteNameEx(0, midi_data_collect_track, range_start, 0)
		pname_shift = reaper.GetTrackMIDINoteNameEx(0, midi_data_collect_track, range_end + 1, 0)
	elseif target_tobj.channel_splitter then
		cut_type = "splitter"
		parent_obj = target_tobj.channel_splitter
		midi_data_collect_track = r.getTrackByGUID(target_tobj.channel_splitter.guid)
	else
		cut_type = "regular"
		parent_obj = target_tobj.channel_splitter
		midi_data_collect_track = r.getTrackByGUID(target_tobj.guid)
	end

	midi_data_collect_track_item_count = reaper.CountTrackMediaItems(midi_data_collect_track)

	-- TODO: migrate this into debug_ypc
	log.debug(
		string.format(
			[[---------------------------------
  YPC -> CUT (type: %s)
  ::FOCUS TRACK TO CUT::
         name = %s
         class = %s
         idx = %s (GUI idx = %s)
         range = %s
         range start = %s; range end = %s
  ::PARENT OBJ::
         name = %s
         class = %s
         opt.m = %s
  :::::::::::::
  proll  name = %s (@ shift_pitches_above_note_row)
         name_shift = %s
  shift  value = %s
  ---------------------------------
    ]],
			cut_type,
			target_tobj.name,
			target_tobj.class,
			target_tobj.trackIndex,
			target_tobj.trackIndex + 1,
			drum_tr_range_num,
			range_start,
			range_end,
			parent_obj and parent_obj.name,
			parent_obj and parent_obj.class,
			parent_obj and parent_obj.options["m"],
			pname,
			pname_shift,
			-shift_value
		)
	)

	local cut_track
	if cut_type == "drumkit" or cut_type == "channel_splitter" then
		cut_track = midi_data_collect_track
	else
		cut_track = r.getTrackByGUID(target_tobj.guid)
	end

	--
	-- CUT: ACT
	--

	if cut_type == "drumkit" then
		for i = 0, midi_data_collect_track_item_count - 1 do -- does parent_item_cnt need to be stored????
			local item = reaper.GetTrackMediaItem(midi_data_collect_track, i)
			local take = reaper.GetMediaItemTake(item, 0) -- active take?
			-- delete notes inside range
			require("library.midi").midi_take_filter_transform(take, {
				remove = {
					notes = { pitch = { { range_start, range_end } } },
				},
				dry_run = true,
			})
			-- shift notes
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
	elseif cut_type == "splitter" then
		log.debug("CUT data from channel splitter master")
	-- shift existing
	elseif cut_type == "regular" then
		log.debug("CUT: something went wrong")
	end

	if not opts.dry_run then
		reaper.DeleteTrack(cut_track)
	end
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
