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

local track_motions = {}

--
-- ZONE
--

track_motions.zone_next = function()
  local focused_track_objects, _ = lib_tr.get_focused_track_objects()
end
track_motions.zone_prev = function() end

track_motions.zone_first = function() end
track_motions.zone_last = function() end

--
-- GROUP
--

track_motions.group_next = function() end
track_motions.group_prev = function() end

--
-- MCAB M
--

track_motions.mcab_m_next = function() end
track_motions.mcab_m_prev = function() end
track_motions.mcab_m_first = function() end
track_motions.mcab_m_last = function() end
track_motions.mcab_mc_next = function() end
track_motions.mcab_mc_prev = function() end

--
-- MCAB A
--

track_motions.mcab_next_a = function() end
track_motions.mcab_prev_a = function() end

--
-- MCAB B
--

track_motions.mcab_b_next = function() end
track_motions.mcab_b_prev = function() end

--
-- MCAB T
--

track_motions.mcab_t_next = function() end
track_motions.mcab_t_prev = function() end

return track_motions
