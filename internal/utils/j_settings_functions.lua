--[[
@author n0ne
@version 0.7.1
@noindex
--]]

local sf = require("utils.j_string_functions")

local settings_funcs = {}

---
---@param file_name
---@return
function settings_funcs.jSettingsReadFromFile(file_name)
	-- Reads variables from a ini style text file
	local f = io.open(file_name, "r")
	if not f then
		msg("No settingsfile found: " .. file_name)
		return false
	end

	local sContent = f:read("*all")
	f:close()

	return settings_funcs.jSettingsRead(sContent)
end

---
---@param file_name
---@param inSection
---@param inName
---@param inValue
---@param bSectionOptional
function settings_funcs.jSettingsWriteToFile(file_name, inSection, inName, inValue, bSectionOptional)
	local bSectionOptional = bSectionOptional or false

	local f = io.open(file_name, "r")
	if not f then
		msg("No settingsfile found: " .. file_name)
		return false
	end

	local sContent = f:read("*all")
	f = io.open(file_name, "w")
	sContent = settings_funcs.jSettingsWriteKey(sContent, inSection, inName, inValue, bSectionOptional)
	f:write(sContent)
	f:close()
end

---
---@param file_name
---@param tKeys
---@param bSectionOptional
function settings_funcs.jSettingsWriteToFileMultiple(file_name, tKeys, bSectionOptional)
	local bSectionOptional = bSectionOptional or false

	local f = io.open(file_name, "r")
	if not f then
		msg("No settingsfile found: " .. file_name)
		return false
	end

	local sContent = f:read("*all")
	f = io.open(file_name, "w")
	for _, v in pairs(tKeys) do
		sContent = settings_funcs.jSettingsWriteKey(sContent, v[1], v[2], v[3], bSectionOptional)
	end
	f:write(sContent)
	f:close()
end

---
---@param str
---@return
function settings_funcs.jSettingsRead(str)
    -- Reads variables from a ini style string
	-- Format for text file is: varname=value
	-- Comments can be made with ; or // (can be inline too)
    -- Every varname will we a TABLE in the returned table, this way one variable can have multiple values
	local settingsData = {}

	for line in str:gmatch("[^\r\n]+") do
		local lineClean = settings_funcs._jSettingsRemoveComments(line)
		local name, value, section = settings_funcs._jSettingsLineProcess(lineClean)
		if name then
			value = settings_funcs._jSettingsReadProcessValue(value)
			-- msg("Var: " .. name .. ": " .. tostring(value))
			if settingsData[name] then
				settingsData[name][#settingsData[name]+1] = value
			else
				settingsData[name] = {value}
			end
		elseif section then
			-- Can do something with section name here
			-- msg("Section: " .. section)
		else
			-- Comments/empty/unrecognized
			-- msg ("Skipped: " .. tostring(line))
		end
	end

	-- tablePrint(settingsData)
	return settingsData
end

---
---@param inLine
---@return
function settings_funcs._jSettingsRemoveComments(inLine)
	local lineClean = sf.jStringExplode(inLine, ";")[1]
	lineClean = sf.jStringExplode(lineClean, "//")[1] -- First version used // for comments
	return lineClean
end

---
---@param inLine
---@return
function settings_funcs._jSettingsLineProcess(inLine)
	local name = inLine:match("(.+)=(.-)")
	local value = inLine:match(".+=(.+)")
	if name then
		return name, value, nil
	end
	-- else
	local section = inLine:match("%[(.+)%]")

	return name, value, section
end

---
---@param str
---@param inSection
---@param inName
---@param inValue
---@param bSectionOptional
---@return
function settings_funcs.jSettingsWriteKey(str, inSection, inName, inValue, bSectionOptional)
	local bSectionOptional = bSectionOptional or false
	local newStr = ""
	local currentSection = false
	local bSucces = false

	inSection = tostring(inSection)
	inName = tostring(inName)
	inValue = tostring(inValue)

	for line in str:gmatch("[^\r\n]+") do

		local lineClean = settings_funcs._jSettingsRemoveComments(line)
		local name, value, section = settings_funcs._jSettingsLineProcess(lineClean)
		if section then
			if currentSection == inSection and not bSucces then
				-- We were the section we're looking for and now changing: key was not present, create...
				-- msg("creating new key")
				newStr = newStr .. inName .. "=" .. inValue .. "\n"
				bSucces = true
			end
			currentSection = section
		elseif name == inName then
			if currentSection == inSection or bSectionOptional then
				-- msg("found our key: " .. name .. "=" .. value .. " [" .. tostring(currentSection) .. "]")
				line = inName .. "=" .. inValue
				bSucces = true
			end
		end

		newStr = newStr .. line .. "\n"
	end

	if not bSucces and bSectionOptional then
		-- Neither the key nor section was found, but section is optional (backwards compatibility issue) so create at end of file
		newStr = newStr .. inName .. "=" .. inValue .. "\n"
		bSucces = true
	end
	if not bSucces then
		msg("Could not update ini value, prolly section does not exist. "  .. inName .. "=" .. inValue .. " [" .. inSection .. "]")
	end

	return newStr, bSucces
end

---
---@param file_name
---@param default_file
---@param content
function settings_funcs.jSettingsCreate(file_name, default_file, content)
	local default_file = default_file or false
    local content = content or ""

    if not io.open(file_name, "r") then
		local file = io.open(file_name, "w")
		if default_file then
			local file_to_read = io.open(default_file, "r")
			if not file_to_read then
				msg("jSettingsCreate(): Default file sepcified but could not open: " .. default_file)
				return false
			end
			content = file_to_read:read("a")
		end

		file:write(content)
		file:close()
		return true -- New file created
	else
		return false -- settingsfile already exists
    end
end

---
---@param value
---@return
function settings_funcs._jSettingsReadProcessValue(value)
	value = sf.jStringTrim(value)
    if value == "true" then
        value = true
    elseif value == "false" then
		value = false
	elseif sf.jStringIsInt(value) then
		value = math.tointeger(value)
    end

    return value
end

---
---@param t
---@param name
---@param typeCheck
function settings_funcs.jSettingsGet(t, name, typeCheck)

	local value = t[name]
	if value == nil then
		msg("jSettingsGet(): Trying to read an empty setting: " .. name)
		return nil
	end


	if typeCheck == "table" then
		if type(value) ~= typeCheck then
			msg("jSettingsGet(): setting type does not match for: " .. name .. ". Wanted: " .. typeCheck .. ", got: " .. type(value))
		end
		return value
	else
		local v = value[1]
		-- msg(tostring(v) .. " : " .. tostring(tonumber(v)))
		if typeCheck == "number" and tonumber(v) then
			return v
		elseif type(v) ~= typeCheck then
			msg("jSettingsGet(): setting type does not match for: " .. name .. ". Wanted: " .. typeCheck .. ", got: " .. type(v))
		end
		return v
	end
end

function settings_funcs._joinSettingsTables(t1, t2)
	local tResult = {}
	for k, v in ipairs(t1) do
		tResult[k] = { v, t2[k] }
	end
	return tResult
end

return settings_funcs
