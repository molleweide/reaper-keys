local utils = {}

function utils.jWriteVstData(file_name, t)
	-- Write extended vst usage data
	local sContent = ""

	for i, l in ipairs(t) do -- this prolly doesn't have to write 0 ratings as that is the default...
		if not l.action then -- for now don't store action ratings
			sContent = sContent .. l.name .. "," .. l.rating .. "\n"
		end
	end

	local file = io.open(file_name, "w")
	file:write(sContent)
	file:close()
end

function utils.jReadVstData(file_name)
	-- Reads extended vst usage data
	local vstData = {}
	-- if the file doesnt exist create it
	if not io.open(file_name, "r") then
		local file = io.open(file_name, "w")
		file:close()
	end
	for line in io.lines(file_name) do
		local vstName = line:match("(.+),.-")
		local vstRating = line:match(".+,(.+)")
		vstData[vstName] = { rating = vstRating }
	end
	return vstData
end

function utils.jReadJsfxIniGetValuesFromString(st)
	local doubleQuotedP1, doubleQuotedP2 = st:match('^"(.-)" (.+)')
	local singleQuotedP1, singleQuotedP2 = st:match("^'(.-)' (.+)")
	local noQuotedP1, noQuotedP2 = st:match("^(.-) (.+)")

	local result1 = doubleQuotedP1 or singleQuotedP1 or noQuotedP1
	local nameLineP2 = doubleQuotedP2 or singleQuotedP2 or noQuotedP2

	if result1 then
		local doubleQuotedP2 = nameLineP2:match('^"(.-)"')
		local singleQuotedP2 = nameLineP2:match("^'(.-)'")
		local noQuotedP2 = nameLineP2:match("^(.+)")

		local result2 = doubleQuotedP2 or singleQuotedP2 or noQuotedP2
		if result1 and result2 then
			-- msg(result1 .. " :: " .. result2)
			return result1, result2
		end
	end
	-- else
	-- msg("UNKNOWN: " .. st)
	return false
end

function utils.jReadJsfxIni(ini_file_name, tRatingsData)
	local i = 0
	local tResult = {}

	if not reaper.file_exists(ini_file_name) then
		msg("Ini file does not exist: " .. ini_file_name)
		msg("Try opening the Reaper default FX browser once to have this file automatically generated.")
		return tResult
	end

	for line in io.lines(ini_file_name) do
		-- local versionLine = line:match("^VERSION.*")
		local nameLine = line:match("^NAME (.+)$")
		-- local revLine = line:match("^REV (.+)$")

		if nameLine then
			-- msg("NAME: " .. nameLine)
			local fxName, fxDesc = utils.jReadJsfxIniGetValuesFromString(nameLine)
			if fxName then -- succes, add!
				local sName = "jsfx: " .. fxName -- add to make different from vst's with same name
				fxDesc = fxDesc:gsub("^JS: ", "") -- remove "JS: " from description
				local iRating = utils._getRating(tRatingsData, sName)
				tResult[#tResult + 1] = {
					name = sName,
					desc = fxDesc,
					filename = fxName,
					jsfx = true,
					rating = iRating,
				}
			end
		end
	end
	return tResult
end

function utils._getRating(tRatingsData, sName)
	if tRatingsData[sName] then
		return math.floor(tRatingsData[sName].rating)
	else
		return 0
	end
end

function utils._nameOnBlacklist(tBlacklist, name)
	for _, skipName in ipairs(tBlacklist) do
		if (name):find(skipName) then
			return true
		end
	end
	return false
end

function utils.jReadVstIni(ini_file_name, tRatingsData)
	local i = 0
	local tResult = {} -- the resulting table with VST's in it
	local tLookup = {} -- a reversed table where tLookup["vst name"] = index in tResult (for checking if this fx already exists)

	if not reaper.file_exists(ini_file_name) then
		msg("Ini file does not exist: " .. ini_file_name)
		return tResult
	end

	for line in io.lines(ini_file_name) do
		-- Safety checking the first line
		if i == 0 then
			if line ~= "[vstcache]" then
				msg("VST ini file looks different than expected, not loading VST's, file: " .. ini_file_name)
				return false
			end
		else
			local sName = line:match(".-,.-,(.+)") or false
			local sTypePart = line:match("(.+)=.+")

			if sName and sName ~= "<SHELL>" then
				local skip = utils._nameOnBlacklist(pluginsData.PLUGIN_BLACKLIST, sName .. sTypePart)
				-- for _, skipName in ipairs(pluginsData.PLUGIN_BLACKLIST) do
				-- 	if (sName..sTypePart):find(skipName) then
				-- 		skip = true
				-- 		break
				-- 	end
				-- end

				if not skip then
					-- Get rating
					local iRating = utils._getRating(tRatingsData, sName)

					local bInstrument = nil
					if line:find(".+!!!VSTi") then
						bInstrument = true
						-- sName = sName:sub(1,-8)
					end

					local bDll = nil
					local bVst3 = nil
					local bVst = nil
					if sTypePart:find("dll") then
						bDll = true
					elseif sTypePart:find("vst3") then
						bVst3 = true
					elseif sTypePart:find("vst$") or sTypePart:find("vst.") then
						bVst = true
					end

					local desc = utils._removeVstiString(sName)

					if not tLookup[sName] then
						table.insert(tResult, {
							name = sName,
							desc = desc,
							line = i,
							instrument = bInstrument,
							dll = bDll,
							vst3 = bVst3,
							vst = bVst,
							rating = iRating,
						})
						tLookup[sName] = #tResult
					elseif bDll then -- also found dll version
						tResult[tLookup[sName]].dll = true
					elseif bVst3 then -- also found vst3 version
						tResult[tLookup[sName]].vst3 = true
					elseif bVst then -- also found vst version (mac)
						tResult[tLookup[sName]].vst = true
					end
				end
			end
		end
		i = i + 1
	end

	return tResult
end

---
---@param ini_file_name
---@param tRatingsData
---@return
function utils.jReadAuIni(ini_file_name, tRatingsData)
	local tResult = {}

	if not reaper.file_exists(ini_file_name) then
		msg("Ini file does not exist: " .. ini_file_name)
		return tResult
	end

	local i = 1
	for line in io.lines(ini_file_name) do
		if i == 1 and line ~= "[auplugins]" then
			msg("First line of AU ini file does not match, not loading Audio Units.")
			return {}
		else
			-- local versionLine = line:match("^VERSION.*")
			local vendor, name, instrument = line:match("^(.-): (.+)=(.+)$")
			-- local revLine = line:match("^REV (.+)$")
			local au = instrument == "<!inst>"
			local aui = instrument == "<inst>"
			if vendor and name and instrument then
				local sName = "au: " .. name -- add to make different from vst's with same name
				local fxDesc = name .. " (" .. vendor .. ")"
				local iRating = utils._getRating(tRatingsData, sName)
				tResult[#tResult + 1] = {
					name = sName,
					desc = fxDesc,
					filename = vendor .. ": " .. name,
					au = au,
					aui = aui,
					rating = iRating,
				}
			end
		end

		i = i + 1
	end
	return tResult
end

--- Get track templates
---@param tDirs
---@param sRootDir
---@param tRatingsData
---@return
function utils.getTemplates(tDirs, sRootDir, tRatingsData)
	local tResult = {}
	for i, v in ipairs(tDirs) do
		tResult = getFilesRecursive(sRootDir .. "/" .. v[1], not v[2], tResult)
	end

	-- return tResult
	local tTemplatesData = {}
	local count = 1
	for i, v in ipairs(tResult) do
		if utils._jIsTemplate(v[1]) then
			local sName = v[1] .. " (" .. v[2]:gsub(sRootDir, "") .. ")"
			-- Get rating
			local iRating = utils._getRating(tRatingsData, sName)
			-- local iRating = 0
			-- if tRatingsData[sName] then
			-- 	iRating = math.floor(tRatingsData[sName].rating)
			-- end
			local desc = sName:gsub(".RTrackTemplate", "")
			tTemplatesData[count] = {
				name = sName,
				desc = desc,
				filename = v[1],
				path = v[2],
				tracktemplate = true,
				rating = iRating,
			}
			count = count + 1
		end
	end
	return tTemplatesData
end

--- Is track template?
---@param filename
---@return
function utils._jIsTemplate(filename)
	return filename:lower():find("%.rtracktemplate$")
end

--- Is FX chain?
---@param filename
---@return
function utils._jIsFxChain(filename)
	return filename:lower():find("%.rfxchain$")
end

--- Get FX chain
---@param tDirs
---@param sRootDir
---@param tRatingsData
---@return
function utils.getFXChains(tDirs, sRootDir, tRatingsData)
	local tResult = {}
	for i, v in ipairs(tDirs) do
		tResult = getFilesRecursive(sRootDir .. "/" .. v[1], not v[2], tResult)
	end
	-- return tResult
	local tFXChainData = {}
	local count = 1
	for i, v in ipairs(tResult) do
		if utils._jIsFxChain(v[1]) then
			local sName = v[1] .. " (" .. v[2]:gsub(sRootDir, "") .. ")"
			-- Get rating
			local iRating = 0
			if tRatingsData[sName] then
				iRating = math.floor(tRatingsData[sName].rating)
			end
			local desc = sName:gsub(".RfxChain", "")
			tFXChainData[count] = {
				name = sName,
				desc = desc,
				filename = v[1],
				path = v[2],
				fxchain = true,
				rating = iRating,
			}
			count = count + 1
		end
	end
	return tFXChainData
end

function utils._round(inValue)
	return math.floor(inValue + 0.5)
end

function utils._removeVstiString(s)
	return s:gsub("!!!VSTi", "")
end

function utils._jPath(p)
	if reaper.GetOS() == "Win32" or reaper.GetOS() == "Win64" then
		local r = p:gsub("/", "\\"):gsub("\\+", "\\")
		return r
	else
		local r = p:gsub("\\", "/"):gsub("/+", "/")
		return r
	end
end

return utils
