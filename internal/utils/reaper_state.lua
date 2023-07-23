local log = require('utils.log')
local format = require('utils.format')
local serpent = require('serpent')

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

local reaper_state = {}

local namespace = "reaper_keys"

function reaper_state.delete(table_name)
  reaper.DeleteExtState(namespace, table_name, true)
end

function reaper_state.set(table_name, lua_table)
  local lua_table_string = serpent.dump(lua_table, { comment = false })
  reaper.SetExtState(namespace, table_name, lua_table_string, true)
end

function reaper_state.get(table_name)
  local string_value = reaper.GetExtState(namespace, table_name)
  if string_value then
    local ok, ext_value = serpent.load(string_value)
    if not ok or not ext_value or not type(ext_value) == 'table' then
      return nil
    end

    if type(ext_value) ~= 'table' then
      return nil
    end

    return ext_value
  end

  return nil
end

function reaper_state.append(name, key, new_data)
  local all_data = reaper_state.get(name)
  if all_data[key] then
    table.insert(all_data[key], new_data)
  else
    all_data[key] = {new_data}
  end
  reaper_state.set(name, all_data)
end

function reaper_state.setKeys(table_name, new_data)
  local saved_table = reaper_state.get(table_name)
  if not saved_table then
    saved_table = {}
  end

  for key,value in pairs(new_data) do
    saved_table[key] = value
  end
  reaper_state.set(table_name, saved_table)
end

function reaper_state.getKey(table_name, key)
  local saved_table = reaper_state.get(table_name)
  if not saved_table then
    return nil
  end
  return saved_table[key]
end

function reaper_state.clearJustOpenedFlag()
  local is_open = reaper.GetExtState(namespace, "reaper_started")
  if is_open == "open" then
    return false
  end

  reaper.SetExtState(namespace, "reaper_started", "open", false)
  return true
end

return reaper_state
