local lib_items = {}

--
-- NOTE: this will serve a basis for doing more complex operations to handle
-- media items.
--

lib_items.get_items_in_track_objects = function(t_track_objects)
	local t_all_items = {}
	for _, trk_obj in pairs(t_track_objects) do
		local num_items = reaper.GetTrackNumMediaItems(trk_obj.tr)
		if num_items > 0 then
			-- first_item = reaper.GetTrackMediaItem(track, 0)
			-- first_item_sel = reaper.IsMediaItemSelected(first_item)

			for i = 0, num_items - 1 do
				local item = reaper.GetTrackMediaItem(trk_obj.tr, i)
				local item_cur_take = reaper.GetTake(item, 0)
				local take_name = reaper.GetTakeName(item_cur_take)
				table.insert(t_all_items, {
					parent_track_id = guid,
					item_idx = reaper.GetMediaItemInfo_Value(item, "IP_ITEMNUMBER"),
					name = take_name,
				})
			end
		end
		return t_all_items
	end
end

-- NOTE: reaper.GetMediaItemInfo_Value( item, parmname )
--
-- Get media item numerical-value attributes.
-- B_MUTE : bool * : muted (item solo overrides). setting this value will clear C_MUTE_SOLO.
-- B_MUTE_ACTUAL : bool * : muted (ignores solo). setting this value will not affect C_MUTE_SOLO.
-- C_LANEPLAYS : char * : in fixed lane tracks, 0=this item lane does not play, 1=this item lane plays exclusively, 2=this item lane plays and other lanes also play (read-only)
-- C_MUTE_SOLO : char * : solo override (-1=soloed, 0=no override, 1=unsoloed). note that this API does not automatically unsolo other items when soloing (nor clear the unsolos when clearing the last soloed item), it must be done by the caller via action or via this API.
-- B_LOOPSRC : bool * : loop source
-- B_ALLTAKESPLAY : bool * : all takes play
-- B_UISEL : bool * : selected in arrange view
-- C_BEATATTACHMODE : char * : item timebase, -1=track or project default, 1=beats (position, length, rate), 2=beats (position only). for auto-stretch timebase: C_BEATATTACHMODE=1, C_AUTOSTRETCH=1
-- C_AUTOSTRETCH: : char * : auto-stretch at project tempo changes, 1=enabled, requires C_BEATATTACHMODE=1
-- C_LOCK : char * : locked, &1=locked
-- D_VOL : double * : item volume, 0=-inf, 0.5=-6dB, 1=+0dB, 2=+6dB, etc
-- D_POSITION : double * : item position in seconds
-- D_LENGTH : double * : item length in seconds
-- D_SNAPOFFSET : double * : item snap offset in seconds
-- D_FADEINLEN : double * : item manual fadein length in seconds
-- D_FADEOUTLEN : double * : item manual fadeout length in seconds
-- D_FADEINDIR : double * : item fadein curvature, -1..1
-- D_FADEOUTDIR : double * : item fadeout curvature, -1..1
-- D_FADEINLEN_AUTO : double * : item auto-fadein length in seconds, -1=no auto-fadein
-- D_FADEOUTLEN_AUTO : double * : item auto-fadeout length in seconds, -1=no auto-fadeout
-- C_FADEINSHAPE : int * : fadein shape, 0..6, 0=linear
-- C_FADEOUTSHAPE : int * : fadeout shape, 0..6, 0=linear
-- I_GROUPID : int * : group ID, 0=no group
-- I_LASTY : int * : Y-position (relative to top of track) in pixels (read-only)
-- I_LASTH : int * : height in pixels (read-only)
-- I_CUSTOMCOLOR : int * : custom color, OS dependent color|0x1000000 (i.e. ColorToNative(r,g,b)|0x1000000). If you do not |0x1000000, then it will not be used, but will store the color
-- I_CURTAKE : int * : active take number
-- IP_ITEMNUMBER : int : item number on this track (read-only, returns the item number directly)
-- F_FREEMODE_Y : float * : free item positioning or fixed lane Y-position. 0=top of track, 1.0=bottom of track
-- F_FREEMODE_H : float * : free item positioning or fixed lane height. 0.5=half the track height, 1.0=full track height
-- I_FIXEDLANE : int * : fixed lane of item (fine to call with setNewValue, but returned value is read-only)
-- B_FIXEDLANE_HIDDEN : bool * : true if displaying only one fixed lane and this item is in a different lane (read-only)
-- P_TRACK : MediaTrack * : (read-only)

-- NOTE: reaper.GetMediaItemTakeInfo_Value( take, parmname )
--
-- Get media item take numerical-value attributes.
-- D_STARTOFFS : double * : start offset in source media, in seconds
-- D_VOL : double * : take volume, 0=-inf, 0.5=-6dB, 1=+0dB, 2=+6dB, etc, negative if take polarity is flipped
-- D_PAN : double * : take pan, -1..1
-- D_PANLAW : double * : take pan law, -1=default, 0.5=-6dB, 1.0=+0dB, etc
-- D_PLAYRATE : double * : take playback rate, 0.5=half speed, 1=normal, 2=double speed, etc
-- D_PITCH : double * : take pitch adjustment in semitones, -12=one octave down, 0=normal, +12=one octave up, etc
-- B_PPITCH : bool * : preserve pitch when changing playback rate
-- I_LASTY : int * : Y-position (relative to top of track) in pixels (read-only)
-- I_LASTH : int * : height in pixels (read-only)
-- I_CHANMODE : int * : channel mode, 0=normal, 1=reverse stereo, 2=downmix, 3=left, 4=right
-- I_PITCHMODE : int * : pitch shifter mode, -1=projext default, otherwise high 2 bytes=shifter, low 2 bytes=parameter
-- I_CUSTOMCOLOR : int * : custom color, OS dependent color|0x1000000 (i.e. ColorToNative(r,g,b)|0x1000000). If you do not |0x1000000, then it will not be used, but will store the color
-- IP_TAKENUMBER : int : take number (read-only, returns the take number directly)
-- P_TRACK : pointer to MediaTrack (read-only)
-- P_ITEM : pointer to MediaItem (read-only)
-- P_SOURCE : PCM_source *. Note that if setting this, you should first retrieve the old source, set the new, THEN delete the old.

-- NOTE: reaper.GetTakeName( take )
--
-- returns NULL if the take is not valid

-- NOTE: retval, stringNeedBig = reaper.GetSetMediaItemTakeInfo_String( tk, parmname, stringNeedBig, setNewValue )
--
-- Gets/sets a take attribute string:
-- P_NAME : char * : take name
-- P_EXT:xyz : char * : extension-specific persistent data
-- GUID : GUID * : 16-byte GUID, can query or update. If using a _String() function, GUID is a string {xyz-...}.

-- -- Get name of take
-- take_name = reaper.GetTakeName(reaper.GetActiveTake(reaper.GetSelectedMediaItem(0, i)))

-- new_take_name[i] = take_name .. "_" .. tostring(count)

-- -- Get active take
-- active_take = reaper.GetActiveTake(reaper.GetSelectedMediaItem(0, i))

-- -- Apply new name
-- reaper.GetSetMediaItemTakeInfo_String(active_take, 'P_NAME', new_take_name[i], true)

lib_items.get_item_info = function(tr, i)
	local item = reaper.GetTrackMediaItem(tr, i)
	local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
	local item_end = item_start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
	return {
		ref = item,
		start = item_start,
		_end = item_end,
	}
end

lib_items.get_items_in_range = function(track, range_start, range_end)
	local item_cnt = reaper.GetTrackNumMediaItems(track)
	local items_found = {}
	for i = 0, item_cnt - 1 do
		local item_info = lib_items.get_item_info(track, i)
		if item_info.start >= range_start and item_info._end <= range_end then
			table.insert(items_found, item_info)
		end
	end
	return #items_found > 0 and items_found or false
end

lib_items.unselect_items = function(t_indices)
	if not t_indices then
		local csi = reaper.CountSelectedMediaItems(0)
		if csi > 0 then
			for i = 0, csi - 1 do
				reaper.SetMediaItemSelected(reaper.GetSelectedMediaItem(0, i), false)
				reaper.UpdateArrange()
			end
		end
	else
		-- TODO:...
		-- for k, v in pairs(t) do
		--
		-- end
	end
end

return lib_items
