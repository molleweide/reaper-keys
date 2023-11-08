local tl = {}


-- default to cursor, but I can also pass a numb

tl.get_cursor_info = function(time)
	-- convert a time into beats.
	-- if measures is non-NULL, measures will be set to the measure count, return value will be beats since measure.
	-- if cml is non-NULL, will be set to current measure length in beats (i.e. time signature numerator)
	-- if fullbeats is non-NULL, and measures is non-NULL, fullbeats will get the full beat count (same value returned if measures is NULL).
	-- if cdenom is non-NULL, will be set to the current time signature denominator.
	local _, measures, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats(0, reaper.GetCursorPosition())

	-- Get the QN position and time signature information for the start of a
	-- measure. Return the time in seconds of the measure start.
	local msr_start_time, qn_start, qn_end, timesig_num, timesig_denom = reaper.TimeMap_GetMeasureInfo(0, measures)
	return {
		msr_num = measures, -- measures up until cursor
		cml = cml,
		fullbeats = fullbeats,
		cdenom = cdenom,
		msr = {
			start = msr_start_time,
			_end = reaper.TimeMap2_beatsToTime(0, 0, measures + 1),
			qn_start = qn_start,
			qn_end = qn_end,
			timesig_num = timesig_num,
			timesig_denom = timesig_denom,
		},
	}
end

return tl
