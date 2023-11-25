local ru = require("custom_actions.utils")
local fx_util = require("library.fx")
local format = require("utils.format")
local log = require("utils.log")
local syntax = require("SYNTAX.syntax.syntax")
local ypc = require("SYNTAX.lib.ypc")
local syntax_utils = require("SYNTAX.lib.util")
local apply_funcs = require("SYNTAX.syntax.util")
local config = require("SYNTAX.config.config")
local rk_config = require("definitions.config")

local actions = {}

function actions.applyConfigs()
	log.clear()

	local tracks_list = syntax.get_list_of_track_objects()
	local vtt = syntax.getVerifiedTree(tracks_list)

	-- apply basic defaults
	for _, sx_obj in pairs(tracks_list) do

	  -- apply track ui props
		syntax_utils.setClassTrackInfo(config.classes, sx_obj)

    -- apply routing
		local routing = config.classes[sx_obj.class].routing -- (sx_obj)

    log.user(sx_obj.name, type(routing), routing)


		if routing then
			if type(routing) == "function" then
				routing(sx_obj)
			elseif type(routing) == "table" then
				for routing_opt_key, routing_func in pairs(routing) do
				  log.user(routing_opt_key, routing_func)
					if syntax_utils.trackObjHasOption(sx_obj, routing_opt_key) then
					  log.user("apply lanes for:", sx_obj.name)
						routing_func(sx_obj)
					end
				end
			end
		end
	end

	-- -- setup drum lanes
	-- for _, gobj in pairs(vtt.groups) do
	-- 	local count_w_range = rk_config.drum_lanes_low_note_start
	-- 	local opt_m_children = {}
	-- 	for _, mcab_obj in pairs(gobj.children) do
	-- 		opt_m_children = apply_funcs.prepareMidiTracksForLaneMapping(gobj, mcab_obj, opt_m_children)
	-- 	end
	-- 	apply_funcs.applyMappedOptMChildren(gobj, opt_m_children, count_w_range)
	-- end
end

function actions.gyank()
	ypc.customGroupYpc("yank")
end

function actions.gcut()
	ypc.customGroupYpc("cut")
	actions.applyConfigs()
end

function actions.gput()
	ypc.customGroupYpc("put")
	actions.applyConfigs()
end

function actions.sidechainToGhostKick()
	log.clear()
	apply_funcs.applyKeydFxToSelTrks(
		true, -- tr_filt_hook
		"SC_GHOST_KICK", -- fx_gui_name
		"ReaComp (Cockos)", -- fx_search_str
		{
			[0] = 0.25, -- thres
			[1] = 0.06, -- ratio
			[8] = (1 / 1084) * 2, -- aux
		},
		"(ghostkick)$[0|2]" -- route_str | recieve from name match tr
	)
end

function actions.log_vtt()
	local tracks_list = syntax.get_list_of_track_objects()
	local vtt = syntax.getVerifiedTree(tracks_list)

	for _, sx_obj in pairs(vtt.groups) do
		log.user(sx_obj.trackIndex, sx_obj.name, sx_obj.zone.name, #sx_obj.children)
	end

	-- for _, sx_obj in pairs(tracks_list) do
	--   if sx_obj.class == "M" then
	--     -- if class_conf[sx_obj].default_routing then
	--     log.user(sx_obj.trackIndex, sx_obj.name, sx_obj.zone.name, sx_obj.group.name)
	--   end
	-- end

	-- -- log.user(format.block(syntax.getVerifiedTree()))
	-- for i, LVL1_obj in pairs(vtt) do ------------------------------ lvl 1 ------------
	--   for j, LVL2_obj in pairs(LVL1_obj.children) do ------------- lvl 2 ------------
	--     for k, LVL3_obj in pairs(LVL2_obj.children) do ----------- lvl 3 ------------
	--       log.user(LVL3_obj.trackIndex, LVL3_obj.name, LVL3_obj.zone.name)
	--     end
	--   end
	-- end
end

return actions
