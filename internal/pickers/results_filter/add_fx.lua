local function findVst(vstTable, sPattern, iMaxResults, iInstance, find_plain)
	iInstance = iInstance or false
	find_plain = find_plain or true
	iMaxResults = iMaxResults or false

	local tResult = {}
	local iCount = 0

	if type(iInstance) == "number" and iInstance <= 0 then
		jError("findVst(), instance <= 0. First instance is 1! iInstance: " .. tostring(iInstance), J_ERROR_ERROR)
		return false
	end

	-- NOTE; this for loop basically first makes a comparison with the plugin
	-- string names, and then it does some

	for i, t in ipairs(vstTable) do
		local bMatch = true
		-- Look for every word in the string
		for token in string.gmatch(sPattern, "[^%s]+") do
			-- local name = t.name
			-- local name = _makeFxNameSearchable(t.name)
			local name = t.desc -- no longer search in name but in description

			token = token:lower()

			if token == "@fx" or token == "@vst" then
				if not t.dll and not t.vst and not t.vst3 then
					bMatch = false
					break
				end
			elseif token == "@temp" then
				if not t.tracktemplate then
					bMatch = false
					break
				end
			elseif token == "@chain" then
				if not t.fxchain then
					bMatch = false
					break
				end
			elseif token == "@vst3" then
				if not t.vst3 then
					bMatch = false
					break
				end
			elseif token == "@i" then
				if not t.instrument then
					bMatch = false
					break
				end
			elseif token == "@js" then
				if not t.jsfx then
					bMatch = false
					break
				end
			elseif token == "@a" then
				if not t.action then
					bMatch = false
					break
				end
			elseif token:match("^@.*") then -- prevents when you start typing a tag that all the search results disappear
				bMatch = true
			-- elseif not name:lower():find(token:lower(), 1, find_plain) then
			-- 	bMatch = false
			-- 	break
			else
				token = token:gsub("\\@", "@") -- replace escaped '@'
				bMatch = name:lower():find(token:lower(), 1, find_plain)
				if not bMatch then
					break
				end
			end
		end

		if bMatch then
			iCount = iCount + 1
			if iInstance == false then
				t.id = i -- keep track of position in main table
				tResult[#tResult + 1] = t
				if iMaxResults ~= false then
					if #tResult >= iMaxResults then -- check if we already have enough results
						return tResult
					end
				end
			elseif iInstance == iCount then
				return t
			end
		end
	end

	if not iInstance then
		-- return table
		if #tResult == 0 then
			return {} -- Used to return false but should be empty table
		else
			return tResult
		end
	else
		-- instance not found
		return false
	end
end

return findVst
