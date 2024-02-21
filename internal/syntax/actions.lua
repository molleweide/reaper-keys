local ru = require("custom_actions.utils")
local fx_util = require("library.fx")
local format = require("utils.format")
local log = require("utils.log")
local sx_tracks = require("syntax.tracks")
-- local ypc = require("syntax.lib.ypc")
local sxu = require("syntax.utils")
local sx_configs = require("definitions.syntax.config")
local rk_config = require("definitions.config")

local r = require("utils.reaper")

-- TODO: move this file to under `custom_actions`

local trr = require("library.routing")

local actions = {}

-- TODO: split up each section into a util function for running a specific
-- set of configs so that I can control exactly what should be updated
-- after eg. YPC

actions.apply_everything= function()
  actions.apply_node_info()
  actions.apply_node_routing()
end

-- TODO: pass single node and only apply config to it.

function actions.applyConfigs(sx_node_single)
  -- log.clear()

  local tracks_list = sx_tracks.get_list_of_track_objects()
  -- move this as an opt into `get_list_of_track_objects`
  -- return vtt as optional.
  local vtt = sx_tracks.getVerifiedTree(tracks_list)

  -- NOTE: apply configs to tracks list if NOT a specific node is passed

  for _, sx_obj in pairs(tracks_list) do
    --
    -- APPLY TRACK UI PROPS / INFO PARAMS
    --
    sxu.setClassTrackInfo(sx_configs.classes, sx_obj)

    --
    -- ROUTING
    --

    local routing = sx_configs.classes[sx_obj.class].routing -- (sx_obj)
    -- log.user(sx_obj.name, type(routing), routing)
    if routing then
      if type(routing) == "function" then
        routing(sx_obj)
      elseif type(routing) == "table" then
        for routing_opt_key, routing_func in pairs(routing) do
          -- log.user(routing_opt_key, routing_func)
          if sxu.trackObjHasOption(sx_obj, routing_opt_key) then
            -- log.user("apply lanes for:", sx_obj.name)
            routing_func(sx_obj)
          end
        end
      end
    end
  end

  --
  -- SORT TRACKS BY NAME
  --

  -- NOTE: this requires efficient midi-shifting of drum lanes midi channel
  -- swapping, for this to work properly

  -- boolean reaper.ReorderSelectedTracks(integer beforeTrackIdx, integer makePrevFolder)
  -- Moves all selected tracks to immediately above track specified by index beforeTrackIdx, returns false if no tracks were selected. makePrevFolder=0 for normal, 1 = as child of track preceding track specified by beforeTrackIdx, 2 = if track preceding track specified by beforeTrackIdx is last track in folder, extend folder

  for i, cobj in ipairs(vtt.channel_splitters) do
    -- sort ch split children
  end

  for i, gobj in ipairs(vtt.groups) do
    -- sort group children
    -- move CS as a whole
  end

  -- sort groups within zones??
  -- sort zones within project??
  -- >>>> i should do both of these just because I will want to be able to
  -- swap the positioning of track objects.

  -- EXAMPLE OF SORTING/REORDERING TRACKS
  --
  --   -- collect selected tracks
  --     tr_t = {}
  --     local cnt_seltr = CountSelectedTracks(0)
  --     if cnt_seltr == 0 then return end
  --     local tr = GetSelectedTrack(0,0)
  --     local insert_id = CSurf_TrackToID( tr, false )
  --
  --     for i =1, cnt_seltr do
  --       local tr = GetSelectedTrack(0,i-1)
  --       tr_t[#tr_t+1] = {GUID = GetTrackGUID( tr ),
  --                       col = GetMediaTrackInfo_Value(tr, 'I_CUSTOMCOLOR')}
  --     end
  --   -- sort by col
  --     table.sort(tr_t, function(a,b) return a.col<b.col end )
  --
  --   for i = 1, #tr_t do
  --     local tr = BR_GetMediaTrackByGUID( 0, tr_t[i].GUID )
  --     SetOnlyTrackSelected( tr )
  --     ReorderSelectedTracks(insert_id, 0)
  --   end

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

-- move to other file?
local function applyKeydFxToSelTrks(fn_filt, fx_gui_name, fx_search_str, fx_params, route_str)
  local t_sel = ru.getSelectedTracksGUIDs()
  for i, t_tr in pairs(t_sel) do
    local passed_filter = false
    if fn_filt or fn_filt() then
      passed_filter = true
    end
    if passed_filter and not fx_util.trackHasFxChainString(t_tr.guid, fx_gui_name, false) then
      local fx_idx = fx_util.insertFxToLastIdxAndGuiRename(t_tr.guid, fx_search_str, fx_gui_name)
      fx_util.setFxParamsFromTable(t_tr.guid, fx_idx, fx_params)
    end
  end
  trr.updateState(route_str)
end

function actions.sidechainToGhostKick()
  log.clear()
  applyKeydFxToSelTrks(
    true, -- tr_filt_hook
    "SC_GHOST_KICK", -- fx_gui_name
    "ReaComp (Cockos)", -- fx_search_str
    {
      [0] = 0.25, -- thres
      [1] = 0.06, -- ratio
      [8] = (1 / 1084) * 2, -- aux
    },
    "(ghostkick)$[0|2]"-- route_str | recieve from name match tr
  )
end

function actions.log_vtt()
  local tracks_list = sx_tracks.get_list_of_track_objects()
  local vtt = sx_tracks.getVerifiedTree(tracks_list)

  for _, sx_obj in pairs(vtt.groups) do
    log.user(sx_obj.trackIndex, sx_obj.name, sx_obj.zone.name, #sx_obj.children)
  end

  -- for _, sx_obj in pairs(tracks_list) do
  --   if sx_obj.class == "M" then
  --     -- if class_conf[sx_obj].default_routing then
  --     log.user(sx_obj.trackIndex, sx_obj.name, sx_obj.zone.name, sx_obj.group.name)
  --   end
  -- end

  -- -- log.user(format.block(sx_tracks.getVerifiedTree()))
  -- for i, LVL1_obj in pairs(vtt) do ------------------------------ lvl 1 ------------
  --   for j, LVL2_obj in pairs(LVL1_obj.children) do ------------- lvl 2 ------------
  --     for k, LVL3_obj in pairs(LVL2_obj.children) do ----------- lvl 3 ------------
  --       log.user(LVL3_obj.trackIndex, LVL3_obj.name, LVL3_obj.zone.name)
  --     end
  --   end
  -- end
end

local function comp_nodes(a, b)
  return a.name > b.name
end

actions.sort_group_children = function()
  local vtt = sx_tracks.getVerifiedTree(tracks_list)

  local function sort_channel_splitter_children(c, ridx)
    table.sort(c.children, comp_nodes)
    for i = #c.children, 1, -1 do
      local c_child = c.children[i]
      if c_child.class == "S" then
        sxu.select_node(c_child)
        reaper.ReorderSelectedTracks(ridx, 0)
      end
    end
  end

  -- sort groups
  for gi, g in ipairs(vtt.groups) do
    table.sort(g.children, comp_nodes)

    local reorder_at_idx = gi ~= #vtt.groups and vtt.groups[gi + 1].trackIndex or reaper.CountTracks(0)

    local mc_idx = 0

    -- SORT TRACKS AND COLLECT MIDI DATA

    for i = #g.children, 1, -1 do
      local g_child = g.children[i]

      -- FIX: if drumkit...
      --           assign drum data to children
      --      elseif splitter
      --           also assign split midi data.
      --

      -- mark each node with its lane indices for later
      g_child.lane_indices = { sxu.get_drum_lane_indices(g, g_child) }
      -- g_child.lane_midi_data = get the track midi data for this lane.

      if g_child.class == "M" or g_child.class == "C" then
        if g_child.class == "C" then
          sort_channel_splitter_children(g_child, reorder_at_idx)
        end
        sxu.select_node(g_child) -- must not forget to also move the C node itself
        reaper.ReorderSelectedTracks(reorder_at_idx, 0)
        mc_idx = mc_idx + 1
      end
    end

    -- DELETE ALL MIDI DATA FOR DRUM LANES AND SPLITTERS

    -- INSERT SORTED MIDI LANES AND SPLIT MIDI AGAIN

  end
end

return actions
