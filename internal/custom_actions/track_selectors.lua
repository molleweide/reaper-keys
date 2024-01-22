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

local track_selectors = {}

--
-- ZONE
--

track_selectors.zone_inner = function()
  local focused_track_objects, _ = lib_tr.get_focused_track_objects()
end
track_selectors.zone_outer = function() end
--
-- GROUP
--

--
-- GROUP
--

track_selectors.group_inner = function() end
track_selectors.group_outer = function() end

track_selectors.group_inner_mcab_m = function() end
track_selectors.group_inner_mcab_mc = function() end
track_selectors.group_inner_mcab_a = function() end
track_selectors.group_inner_mcab_b = function() end

--
-- MCAB C
--

-- selects the whole C
track_selectors.mcab_c_outer = function() end
track_selectors.mcab_c_inner = function() end

return track_selectors
