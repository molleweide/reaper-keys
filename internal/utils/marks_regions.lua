local marks = {}

marks.get_marks_and_regions = function(isrgn)
		local t_results = {}
		local ret, num_markers, num_regions = reaper.CountProjectMarkers(0)
		local num_total = num_markers + num_regions
		if num_regions > 0 then
			local i = 0
			while i < num_total do
				local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3(0, i)
				local t_prepare = {
					isrgn = isrgn,
					pos = pos,
					rgnend = rgnend,
					name = name,
					mark_region_idx = markrgnindexnumber,
					color = color,
				}
				if isrgn then
					table.insert(t_results, t_results)
				else
					table.insert(t_results, t_results)
				end
				i = i + 1
			end
		else
			log.user("Project has no regions!")
		end
		return t_results
	end

return marks
