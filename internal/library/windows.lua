local windows = {}

-- TODO: move the HEX value into a constants table
windows.get_main_tcp_size = function()
	local ret, tcp_width, tcp_height =
		reaper.JS_Window_GetClientSize(reaper.JS_Window_FindChildByID(reaper.GetMainHwnd(), 0x3E8))
	return ret, tcp_width, tcp_height
end

return windows
