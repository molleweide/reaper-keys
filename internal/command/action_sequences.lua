local format = require('utils.format')
local log = require('utils.log')

local action_sequences = {}

local action_sequence_definitions = {
  global = require('command.action_sequence_functions.global'),
  main = require('command.action_sequence_functions.main'),
  midi = require('command.action_sequence_functions.midi'),
}

--- Takes an array of tables and flattens them into one big table.
---@vararg table (how do I write this type name??)
---@return table
local function concatTables(...)
  local t = {}
  for n = 1,select("#",...) do
    local arg = select(n,...)
    if type(arg)=="table" then
      for _,v in ipairs(arg) do
        t[#t+1] = v
      end
    else
      t[#t+1] = arg
    end
  end
  return t
end

--- Takes action_sequence_functions tables, gets all combinations based on
--- context and mode and flattens the action function pair into a single table.
--- Eg.
--- {
---   ...,
---   ...,
---   {
---     { 'command' },
---     function(action) runner.runAction(action) end
---   },
---   {
---     { 'timeline_operator', 'timeline_selector' },
---     function(timeline_operator, timeline_selector)
---       local start_sel, end_sel = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
---        ...
---     end
---   },
---   {
---     { 'timeline_operator', 'timeline_motion' },
---     function() ... end,
---   }
---   ...,
---   ...,
--- }
---@param context string
---@param mode string
---@return table
local function getPossibleActionSequenceFunctionPairs(context, mode)
  local possible_sequence_function_pairs = concatTables(
    action_sequence_definitions[context][mode],
    action_sequence_definitions['global'][mode],
    action_sequence_definitions[context]['all_modes'],
    action_sequence_definitions['global']['all_modes']
  )
  return possible_sequence_function_pairs
end

--- Takes the flattened list of actions sequence function (ASF) pairs,
--- and returns all possible action sequences mapped into their own table.
---@param context string
---@param mode string
---@return table possible_action_sequences
function action_sequences.getPossibleActionSequences(context, mode)
  local action_sequence_function_pairs = getPossibleActionSequenceFunctionPairs(context, mode)

  -- TODO: use lib/refactor into `map` function??
  --
  -- filter out only AS from ARFPs
  local possible_action_sequences = {}
  for _, action_sequence_function_pair in ipairs(action_sequence_function_pairs) do
    local action_sequence = action_sequence_function_pair[1]
    table.insert(possible_action_sequences, action_sequence)
  end
  return possible_action_sequences
end

---
---@param seq1 table
---@param seq2 table
---@return boolean
local function checkIfActionSequencesAreEqual(seq1, seq2)
  if #seq1 ~= #seq2 then return false end
  for i=1,#seq1 do
    if seq1[i] ~= seq2[i] then
      return false
    end
  end

  return true
end

function action_sequences.getFunctionForCommand(command)
  local action_sequence_function_pairs = getPossibleActionSequenceFunctionPairs(command.context, command.mode)

  for _, action_sequence_function_pair in ipairs(action_sequence_function_pairs) do
    local action_sequence = action_sequence_function_pair[1]
    if checkIfActionSequencesAreEqual(command.action_sequence, action_sequence) then
      return action_sequence_function_pair[2]
    end
  end

  return nil
end

function action_sequences.getActionTypes()
  local action_types = {}
  local seen_types = {}
  for _,context_definitions in pairs(action_sequence_definitions) do
    for _,mode_definitions in pairs(context_definitions) do
      for _,action_sequence_function_pair in pairs(mode_definitions) do
        local action_sequence = action_sequence_function_pair[1]
        for _,action_type in pairs(action_sequence) do
          if not seen_types[action_type] then
            seen_types[action_type] = true
            table.insert(action_types, action_type)
          end
        end
      end
    end
  end

  table.sort(action_types)
  return action_types
end

return action_sequences
