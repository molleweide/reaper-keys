
-- local config = require("definitions.config")
local log = require("utils.log")
local format = require("utils.format")
-- local ru = require("custom_actions.utils")
-- local fx = require("library.fx")
local lib_tr = require("library.tracks")
-- local io = require("definitions.io")
-- local project_state = require("utils.project_state")
-- local tu = require("utils.table")
-- local state_interface = require("state_machine.state_interface")
local syntax = require("SYNTAX.tracks")

local tl_op = {}


-- NOTE: just like with [ chord -> timeline ] the tl motion is
-- computed first and then the range is passed to the operator,
-- so the operator is the picker prompt. and then it is
-- passed the meta command, and this means that we are looking at state
-- in order to determine if operator command, and so we might as well
-- just do the checking in the function itself instead of passing the
-- meta opt as an annoying prop that we need to handle all the way down
-- the call chain.
--
--
tl_op.apply_patterns_across_tracks = function()

  -- TODO: Assign timeline motion to state


end


return tl_op

