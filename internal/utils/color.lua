local color = {}

color.hex2rgb = function(s16, set)
	s16 = s16:gsub("#", ""):gsub("0X", ""):gsub("0x", "")
	local b, g, r = reaper.ColorFromNative(tonumber(s16, 16))
	if set then
		if reaper.GetOS():match("Win") then
			gfx.set(r / 255, g / 255, b / 255)
		else
			gfx.set(b / 255, g / 255, r / 255)
		end
	end
	return r / 255, g / 255, b / 255
end

return color
