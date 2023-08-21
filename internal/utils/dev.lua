local dev = {}

function prepareGetFocusedFX()
	local retval, tracknumber, itemnumber, fxnumber = reaper.GetFocusedFX()

	-- no fx window
	if retval == 0 then
		reaper.MB("No FX has focus...", "Nothing to list, sorry!", 0)
		return reaper.defer(function() end)
	end

	local track = reaper.CSurf_TrackFromID(tracknumber, false)
	reaper.ClearConsole()

	return retval, tracknumber, itemnumber, fxnumber, track
end

-- TODO
--
--    add input fx
--
--    also show the source-file-name
--      so that one can easilly search add new fx.
--

-- log all fx params of last touched fx
function dev.logLastTouchedFxParams()
	local retval, tracknumber, itemnumber, fxnumber, track = prepareGetFocusedFX()
	if retval ~= 0 then
		-- track FX
		if retval == 1 then
			local parm_cnt = reaper.TrackFX_GetNumParams(track, fxnumber)
			local _, name = reaper.TrackFX_GetFXName(track, fxnumber, "")
			reaper.ShowConsoleMsg("\n" .. name .. " parameter id numbers\n\n")
			for i = 0, parm_cnt - 1 do
				local retval, buf = reaper.TrackFX_GetParamName(track, fxnumber, i, "")
				reaper.ShowConsoleMsg(i .. ": " .. buf .. "\n")
			end

		-- item FX
		elseif retval == 2 then
			local fxid = fxnumber >> 16 -- (FX Number)
			local takeid = fxnumber & 0xFFFF -- (Take Index)
			local item = reaper.GetMediaItem(0, itemnumber)
			local take = reaper.GetMediaItemTake(item, takeid)
			local parm_cnt = reaper.TakeFX_GetNumParams(take, fxid)
			local _, name = reaper.TakeFX_GetFXName(take, fxid, "")
			reaper.ShowConsoleMsg("\n" .. name .. " parameter id numbers\n\n")
			for i = 0, parm_cnt - 1 do
				local retval, buf = reaper.TakeFX_GetParamName(take, fxid, i, "")
				reaper.ShowConsoleMsg(i .. ": " .. buf .. "\n")
			end
		end
		reaper.defer(function() end)
	end
end

function dev.logLastTouchedFxParamDetails()
	retval, tracknumber, fxnumber, paramnumber = reaper.GetLastTouchedFX()
	if retval then
		tr = reaper.CSurf_TrackFromID(tracknumber, false)
		retval, fxname = reaper.TrackFX_GetFXName(tr, fxnumber, "")
		retval, parname = reaper.TrackFX_GetParamName(tr, fxnumber, paramnumber, "")
		val = reaper.TrackFX_GetParamNormalized(tr, fxnumber, paramnumber)
		retval, valf = reaper.TrackFX_GetFormattedParamValue(tr, fxnumber, paramnumber, "")
		retval, trname = reaper.GetTrackName(tr, "")
		reaper.ClearConsole()
		reaper.ShowConsoleMsg(
			trname
				.. "\nfx#"
				.. (fxnumber + 1)
				.. " - "
				.. fxname
				.. "\nparameter#"
				.. (paramnumber + 1)
				.. " - "
				.. parname
				.. "\nvalue: "
				.. val
				.. "\nFormatted value: "
				.. valf
		)
	end
end

function dev.logPaths() end

function dev.logLastTouchedFxNamedConfigParams()
	local retval, tracknumber, itemnumber, fxnumber, track = prepareGetFocusedFX()
	local _, trname = reaper.GetTrackName(track, "")

	local buf_vst_chunk, buf_pdc

	if retval ~= 0 then
		-- track FX
		if retval == 1 then
			retval, buf_vst_chunk = reaper.TrackFX_GetNamedConfigParm(track, fxnumber, "vst_chunk")

			retval, buf_pdc = reaper.TrackFX_GetNamedConfigParm(track, fxnumber, "pdc")

			-- local retval, b_type = TrackFX_GetNamedConfigParm(tr, fx, "BANDTYPE" .. i - 1)

			reaper.ClearConsole()
			reaper.ShowConsoleMsg(
				"Dev log named config parms @ tr:"
					.. trname
					.. "\n"
					.. "vst_chunk:\n\t"
					.. buf_vst_chunk
					.. " - "
					-- .. fxname
					.. "\n"
					.. "pdc:"
					.. buf_pdc
				.. "\n\n"
				-- .. " - "
				-- .. parname
				-- .. "\nvalue: "
				-- .. val
				-- .. "\nFormatted value: "
				-- .. valf
			)

		-- item FX
		elseif retval == 2 then
		end
	end
end

return dev
