local log = require("utils.log")
local format = require("utils.format")

local r = reaper

local command_id_toggle_me_expl = 50124

----

local function me_open()
	r.Main_OnCommand(command_id_toggle_me_expl, 1)
end

local function me_close()
	r.Main_OnCommand(command_id_toggle_me_expl, 0)
end

-----

local media_explorer = {}


media_explorer.toggle = function()
	local state = r.GetToggleCommandState(command_id_toggle_me_expl)

	if state == 0 then
		me_open()
	else
		me_close()
	end
end

return media_explorer

-- -- @description Open folder with media item active take source media
-- -- @version 1.0
-- -- @author me2beats
-- -- @changelog
-- --  + init
--
-- local r = reaper
--
-- r.Undo_BeginBlock()
--
-- local it = r.GetSelectedMediaItem(0,0)
-- if not it then return end
-- local tk = r.GetActiveTake(it)
-- if not tk then return end
-- local src = r.GetMediaItemTake_Source(tk)
-- if not src then return end
-- local src_fn = r.GetMediaSourceFileName(src, '')
--
-- r.OpenMediaExplorer(src_fn, 0)
--
-- r.Undo_EndBlock('Open media in Media Explorer', 2)
--
--
--
-- -- @description Close Media Explorer
-- -- @version 1.1
-- -- @author me2beats
-- -- @changelog
-- --  + init
--
-- local r = reaper
--
-- local undo_name = 'Close Media Explorer'
--
-- function ToggleActionOnOff(id,on,undo_name,undo_flag)
--
--   local state = r.GetToggleCommandState(id)
--   if on == 1 and state == 0 or on == 0 and state ~= 0 then
--     r.Undo_BeginBlock()
--     r.Main_OnCommand(id,0)
--     r.Undo_EndBlock(undo_name, undo_flag)
--   end
-- end
--
-- ToggleActionOnOff(50124,0,undo_name,2) -- Media explorer: Show/hide media explorer
--
--
--
-- -- @description Auto open folder with media item active take source media
-- -- @version 1.0
-- -- @author me2beats
-- -- @changelog
-- --  + init
--
-- local r = reaper
--
-- function auto_browse_sel_item(it)
--   local tk = r.GetActiveTake(it)
--   if not tk then return end
--   if r.TakeIsMIDI(tk) then return end
--   local src = r.GetMediaItemTake_Source(tk)
--   if not src then return end
--   local src_fn = r.GetMediaSourceFileName(src, '')
--
--   r.OpenMediaExplorer(src_fn, 0)
-- end
--
-- function main()
--   local ch_count = r.GetProjectStateChangeCount(0)
--
--   if not last_ch_count or last_ch_count ~= ch_count then
--
--     local it = r.GetSelectedMediaItem(0,0)
--     if it then
--       local guid,proj_str = r.BR_GetMediaItemGUID(it), tostring(r.EnumProjects(-1, ''))
--
--       local ext_sec, ext_key,ext_key1 = 'me2beats_auto_browse', 'last_sel', 'last_proj'
--       local old_guid = r.GetExtState(ext_sec, ext_key)
--       local old_proj = r.GetExtState(ext_sec, ext_key1)
--       if old_guid ~= guid or old_proj ~= proj_str then
-- --      if old_guid ~= guid then
--         auto_browse_sel_item(it)
--         r.SetExtState(ext_sec, ext_key, guid, 0)
--         r.SetExtState(ext_sec, ext_key1, proj_str, 0)
--       end
--     end
--
--   end
--
--   last_ch_count = ch_count
--   r.defer(main)
-- end
--
-- -----------------------------------------------
--
-- function SetButtonON()
--   r.SetToggleCommandState( sec, cmd, 1 ) -- Set ON
--   r.RefreshToolbar2( sec, cmd )
--   main()
-- end
--
-- -----------------------------------------------
--
-- function SetButtonOFF()
--   r.SetToggleCommandState( sec, cmd, 0 ) -- Set OFF
--   r.RefreshToolbar2( sec, cmd )
-- end
--
-- -----------------------------------------------
--
--
-- _, _, sec, cmd = r.get_action_context()
-- SetButtonON()
-- r.atexit(SetButtonOFF)
--
-- --[[
--    * ReaScript Name: Open and Close Media Explorer when item is inserted
--    * Lua script for Cockos REAPER
--    * Author: MPL
--    * Author URI: http://forum.cockos.com/member.php?u=70694
--    * Licence: GPL v3
--    * Version: 1.0
--   ]]
--
--
-- function run()
--   is_me_open = reaper.GetToggleCommandState(50124)
--   count_items0 = reaper.CountMediaItems(0)
--   if count_items0 ~= count_items or is_me_open == 0
--     then reaper.Main_OnCommand(50124, 0) reaper.atexit()
--     else reaper.defer(run)
--   end
-- end
--
-- count_items = reaper.CountMediaItems(0)
-- is_me_open = reaper.GetToggleCommandState(50124)
-- if is_me_open == 0 then reaper.Main_OnCommand(50124, 0) end -- open MediaExplorer
-- run()
