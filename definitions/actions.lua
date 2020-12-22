-- if you need to define a new action for use in reaper keys, do so here
-- if you need help check out the documentation https://gwatcha.github.io/reaper-keys/configuration/actions.html
-- see ./defaults/actions.lua for examples, as well as actions you can call

-- provides functions which are specific to reaper-keys, such as macros
-- search for 'lib' in the default actions file to see examples
local lib = require('library')
-- provides custom functions which make use of the reaper api
-- search for 'custom' in the default actions file to see examples

local syntax = require('SYNTAX.syntax_actions')

-- local reaper_syntax = require('reaper_syntax')

-- naming conventions:
-- a noun implies an action which selects the noun, or a movement to it's position
-- simple verbs are usually operators, such as 'change'
-- longer verbs are usually commands

return {
  FuzzyFx = "_RSd7bf7022d92114682d354e90dbe8aef580a5ef5c",
  -- ApplyConfigs = "_RSa338711f729b0a270b849a2a119fd485212279b0", -- syntax.applyConfigs,
  ApplyConfigs = syntax.applyConfigs,
  -- gCut = "_RS7903a906bc188e96b41a1dba76c401faec0bbd07", -- syntax.customGroupYpc("put")
  -- gPut = "_RSa4785ef14e17a4412c460da932d4930ac2ec1378",
  -- gYank = "_RSa451c4c6c528944724f431978115cb7bc73479cd",
  gCut = syntax.gcut,
  gPut = syntax.gput,
  gYank = syntax.gyank,
}
