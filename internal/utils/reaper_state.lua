local log = require("utils.log")
local format = require("utils.format")
local serpent = require("serpent")

-- todo: merge `saved.lua`

-- NOTE: Reaper state uses `ExtState` to manage data.
--  AVAILABLE APIS:
--
--    reaper.DeleteExtState(string section, string key, boolean persist)
--        Delete the extended state value for a specific section and key. persist=true means the value should remain deleted the next time REAPER is opened. See SetExtState, GetExtState, HasExtState.
--
--    boolean retval, optional string key, optional string val = reaper.EnumProjExtState(ReaProject proj, string extname, integer idx)
--        Enumerate the data stored with the project for a specific extname. Returns false when there is no more data. See SetProjExtState, GetProjExtState.
--
--    string reaper.GetExtState(string section, string key)
--        Get the extended state value for a specific section and key. See SetExtState, DeleteExtState, HasExtState.
--
--    integer retval, string val = reaper.GetProjExtState(ReaProject proj, string extname, string key)
--        Get the value previously associated with this extname and key, the last time the project was saved. See SetProjExtState, EnumProjExtState.
--
--    boolean reaper.HasExtState(string section, string key)
--        Returns true if there exists an extended state value for a specific section and key. See SetExtState, GetExtState, DeleteExtState.
--
--    reaper.SetExtState(string section, string key, string value, boolean persist)
--        Set the extended state value for a specific section and key. persist=true means the value should be stored and reloaded the next time REAPER is opened. See GetExtState, DeleteExtState, HasExtState.
--
--    integer reaper.SetProjExtState(ReaProject proj, string extname, string key, string value)
--        Save a key/value pair for a specific extension, to be restored the next time this specific project is loaded. Typically extname will be the name of a reascript or extension section. If key is NULL or "", all extended data for that extname will be deleted. If val is NULL or "", the data previously associated with that key will be deleted. Returns the size of the state for this extname. See GetProjExtState, EnumProjExtState.
--
-------------------------------------------------------------------------------
-- EXT STATE EXPLANATION IN REAPER KEYS
--
-- [REAPER API NAME / REAPER KEYS NAME]
--
-- --
--
-- [ section / namespace ]      eg. reaper_keys,
--
--   Everything using reaper state is assigning data to the `reaper_keys`
--   table in ext state. Reaper keys has its own namespace so that other
--   3rd party scripts won't accidentally override anything for us.
--
-- --
--
-- [ key/table_name ]      eg. macros, feedback (gui), midipatterns
--
--   The `table_name` param is the name of the table where I want to store
--   some specific information.
--
-------------------------------------------------------------------------------
--
-- get / set
--
-- Handles reaper-keys tables
--
-- append / setKeys / getKeys
--
-- Handles data within each reaper-keys table.
--
-------------------------------------------------------------------------------

--
-- REAPER STATE API
--

local reaper_state = {}

local namespace = "reaper_keys"

function reaper_state.delete(table_name)
	reaper.DeleteExtState(namespace, table_name, true)
end

--- Set / overwrite a reaper-keys table.
---@param table_name table
---@param lua_table table
function reaper_state.set(table_name, lua_table)
	local lua_table_string = serpent.dump(lua_table, { comment = false })
	reaper.SetExtState(namespace, table_name, lua_table_string, true)
end

function reaper_state.overwriteAll(name, data)
	reaper_state.set(name, data)
end

--- Get a reaper-keys table by name.
---@param table_name table
---@return nil
function reaper_state.get(table_name)
	local string_value = reaper.GetExtState(namespace, table_name)
	if string_value then
		local ok, ext_value = serpent.load(string_value)
		if not ok or not ext_value or not type(ext_value) == "table" then
			return nil
		end

		if type(ext_value) ~= "table" then
			return nil
		end

		return ext_value
	end

	return nil
end

--
-- CREATE / UPDATE
--

function reaper_state.overwrite(table_name, key, new_data)
	local data = reaper_state.get(table_name)
	data[key] = new_data
	reaper_state.overwriteAll(table_name, data)
end

--- Append or set a specific key in a reaper-keys table.
--- Eg. reaper_state.append('macros', state['macro_register'], command)
---@param table_name table
---@param key string
---@param new_data any
function reaper_state.append(table_name, key, new_data)
	local all_data = reaper_state.get(table_name)
	if all_data[key] then
		table.insert(all_data[key], new_data)
	else
		all_data[key] = { new_data }
	end
	-- reaper_state.set(table_name, all_data)
	reaper_state.overwriteAll(table_name, all_data)
end

--- Update a reaper-keys table by a list of keys from a table.
--- Eg. reaper_state.setKeys("feedback", {open = false})
---@param table_name table
---@param new_data any
function reaper_state.setKeys(table_name, new_data)
	local saved_table = reaper_state.get(table_name)
	if not saved_table then
		saved_table = {}
	end

	for key, value in pairs(new_data) do
		saved_table[key] = value
	end
	reaper_state.set(table_name, saved_table)
end

--
-- READ
--

--- Get a key from a reaper-keys table.
--- Eg. reaper_state.getKey('macros', register)
---@param table_name table
---@param key string
---@return any
function reaper_state.getKey(table_name, key)
	local saved_table = reaper_state.get(table_name)
	if not saved_table then
		return nil
	end
	return saved_table[key]
end

--
-- DELETE
--

--- Delete a key in a reaper-keys table, by setting it to nil, which forces
--- reapers internal clean up.
---@param table_name string
---@param key string
function reaper_state.delete_key(table_name, key)
	local data = reaper_state.get(table_name)
	data[key] = nil
	reaper_state.overwriteAll(table_name, data)
end

--
-- HANDLE SPECIAL CASES
--

function reaper_state.clearJustOpenedFlag()
	local is_open = reaper.GetExtState(namespace, "reaper_started")
	if is_open == "open" then
		return false
	end

	reaper.SetExtState(namespace, "reaper_started", "open", false)
	return true
end

return reaper_state
