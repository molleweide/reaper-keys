local utils = require('command.utils')
local action_sequences = require('command.action_sequences')
local definitions = require('utils.definitions')
local getAction = require('utils.get_action')
local format = require('utils.format')
local log = require('utils.log')

---
---@param key_sequence string
---@param entries table
---@return table|string|nil
local function getActionKey(key_sequence, entries)
  local action_name = utils.getEntryForKeySequence(key_sequence, entries)
  if action_name and not utils.isFolder(action_name) and (not utils.checkIfActionHasOptionSet(action_name, 'registerAction') or utils.checkIfActionHasOptionSet(action_name, 'registerOptional')) then
    return action_name
  end

  local number_match, rest_of_key_sequence = utils.splitFirstMatch(key_sequence, '[1-9][0-9]*')
  if number_match then
    local num_prefix_entries = utils.filterEntries({"prefixRepetitionCount"}, entries)
    local action_key = getActionKey(rest_of_key_sequence, num_prefix_entries)
    if action_key then
      if type(action_key) ~= 'table' then action_key = {action_key} end
      action_key['prefixedRepetitions'] = tonumber(number_match)
      return action_key
    end
  end

  local start_of_key_sequence, possible_register = utils.splitLastKey(key_sequence)
  local reg_postfix_entries = utils.filterEntries({"registerAction"}, entries)
  local register_action_name = utils.getEntryForKeySequence(start_of_key_sequence, reg_postfix_entries)
  if register_action_name and not utils.isFolder(register_action_name) then
    local action_key = {register_action_name}
    action_key['register'] = possible_register
    return action_key
  end

  return nil
end

---
---@param key_sequence string
---@param action_type_entries table
---@return string|nil, table|nil, boolean
local function stripNextActionKeyInKeySequence(key_sequence, action_type_entries)
  if not action_type_entries then
    return nil, nil, false
  end

  -- log.debug("strip: " .. key_sequence .. " >>> " .. format.block(action_type_entries))

  local rest_of_key_sequence = ""
  local key_sequence_for_action_type = key_sequence
  while #key_sequence_for_action_type ~= 0 do
    local action_key = getActionKey(key_sequence_for_action_type, action_type_entries)
    if action_key then
      return rest_of_key_sequence, action_key, true
    end

    local last_key
    key_sequence_for_action_type, last_key = utils.splitLastKey(key_sequence_for_action_type)
    -- log.debug("STRIP: " .. key_sequence_for_action_type .. " " .. last_key)
    rest_of_key_sequence = last_key .. rest_of_key_sequence
  end

  return nil, nil, false
end

--- Builds the command table mapping of ACTIONS (action keys) to Action Sequence
--- function.
--- The ordering of ASF pairs in their respective modules can affect how commands
--- are found/built, so make sure to investigate the order of ASFs when debuggin.
---@param key_sequence
---@param action_sequence
---@param entries
---@return
local function buildCommandWithSequence(key_sequence, action_sequence, entries)
  local command = {
    action_sequence = {},
    action_keys = {},
  }

  local rest_of_key_sequence = key_sequence

  for _, action_type in pairs(action_sequence) do
    local action_key, found
    rest_of_key_sequence, action_key, found = stripNextActionKeyInKeySequence(rest_of_key_sequence, entries[action_type])
    log.user(rest_of_key_sequence, format.block( action_key ), found)
    if not found then
      return nil
    else
      table.insert(command.action_sequence, action_type)
      table.insert(command.action_keys, action_key)
    end
  end

  -- means we couldn't run through the whole KS
  if #rest_of_key_sequence > 0 then
    return nil
  end

  -- log.user(format.block(command))

  return command
end

--- Get possible action sequences AS (not ASFPs) from state.
--- Get possible key binds entries from context as one table
--- Loop act seq build command from seq
--- Return command
---
--- command: {
---   action_keys = {
---     {
---       "LeftGridDivision",
---       prefixedRepetitions = 2
---     }
---   },
---   action_sequence = {
---     "timeline_motion"
---   },
---   context = "main",
---   mode = "visual_timeline"
--- }
---@param state table
---@return table|nil command
local function buildCommand(state)
  local possible_sequences = action_sequences.getPossibleActionSequences(state['context'], state['mode'])
  local entries = definitions.getPossibleEntries(state['context'])

  -- log.user(format.block(possible_sequences))

  for _, action_sequence in pairs(possible_sequences) do
    local command = buildCommandWithSequence(state['key_sequence'], action_sequence, entries)
    if command then
      command['mode'] = state['mode']
      command['context'] = state['context']
      -- log.debug("COMMAND: " .. format.block(command))
      return command
    end
  end

  return nil
end

return buildCommand
