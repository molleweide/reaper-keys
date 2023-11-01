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
return lib_items
