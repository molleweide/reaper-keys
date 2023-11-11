local fu = require("utils.fzf")
local sf = require("utils.j_string_functions")

local COLOR_VST = jColor:new({ 0.6, 0.6, 0.6, 1 })
local COLOR_VSTI = jColor:new({ 0.8, 0.8, 0.5, 1 })
local COLOR_FXCHAIN = jColor:new({ 0.5, 0.5, 0.8, 1 })
local COLOR_TEMPLATE = jColor:new({ 0.5, 0.7, 0.5, 1 })
local COLOR_JSFX = jColor:new({ 0.7, 0.5, 0.5, 1 })
local COLOR_AU = jColor:new({ 0.5, 0.5, 0.7, 1 })
local COLOR_AUI = jColor:new({ 0.5, 0.7, 0.7, 1 })
local COLOR_ACTION = jColor:new({ 0.8, 0.5, 0.5, 1 })

local function _makeColorsCatagory(ResultsEntryControl, ResultsEntryInfo, color)
	ResultsEntryControl.colors_label = {}
	ResultsEntryControl.colors_label.normal = color
	ResultsEntryControl.colors_label.hover = color:lighter(0.2)
	-- ResultsEntryControl.colors_label.hover = jColor:new("white")
	ResultsEntryInfo.colors_label = color
end

-- TODO: SCROLL_RESULTS needs to be accessed via args

local function entry_maker(tButtons, tResults)
	for i, cIds in ipairs(tButtons) do
		local ResultsEntryControl = cIds[1]
		local ResultsEntryInfo = cIds[2]
		local iStart = fu._round(i + SCROLL_RESULTS)
		local highlights = sf.jStringExplode(textBox.value, " ")

		local showing
		if iStart <= #tResults then
			showing = iStart
		else
			showing = #tResults
		end
		LABEL_STATS.label = "(" .. showing .. "/" .. #tResults .. ")"

		if tResults and iStart <= #tResults then
			local fx = tResults[iStart]
			ResultsEntryControl.label = fx.desc
			ResultsEntryControl.visible = true
			ResultsEntryInfo.visible = true
			ResultsEntryControl.highlight = highlights

			local tTypes = {}
			if fx.instrument then
				if fx.vst3 then
					tTypes[#tTypes + 1] = "VST3i"
				elseif fx.dll or fx.vst then
					tTypes[#tTypes + 1] = "VSTi"
				end
				_makeColorsCatagory(ResultsEntryControl, ResultsEntryInfo, COLOR_VSTI)
			else
				if fx.vst3 then
					tTypes[#tTypes + 1] = "VST3"
				end
				if fx.dll then
					tTypes[#tTypes + 1] = "VST"
				end
				if fx.vst then
					tTypes[#tTypes + 1] = "VST"
				end
				_makeColorsCatagory(ResultsEntryControl, ResultsEntryInfo, COLOR_VST)
			end

			if fx.tracktemplate then
				tTypes[#tTypes + 1] = "TEMP"
				_makeColorsCatagory(ResultsEntryControl, ResultsEntryInfo, COLOR_TEMPLATE)
			end

			if fx.fxchain then
				tTypes[#tTypes + 1] = "FXCHAIN"
				_makeColorsCatagory(ResultsEntryControl, ResultsEntryInfo, COLOR_FXCHAIN)
			end

			if fx.jsfx then
				tTypes[#tTypes + 1] = "JSFX"
				_makeColorsCatagory(ResultsEntryControl, ResultsEntryInfo, COLOR_JSFX)
			end

			if fx.action then
				tTypes[#tTypes + 1] = "ACTION"
				_makeColorsCatagory(ResultsEntryControl, ResultsEntryInfo, COLOR_ACTION)
			end

			if fx.au then
				tTypes[#tTypes + 1] = "AU"
				_makeColorsCatagory(ResultsEntryControl, ResultsEntryInfo, COLOR_AU)
			end

			if fx.aui then
				tTypes[#tTypes + 1] = "AUi"
				_makeColorsCatagory(ResultsEntryControl, ResultsEntryInfo, COLOR_AUI)
			end

			local sTypes = ""
			for _, sT in ipairs(tTypes) do
				sTypes = sTypes .. " " .. sT
			end

			ResultsEntryInfo.label = sTypes --.. "\n" .. fx.rating
		else
			ResultsEntryControl.visible = false
			ResultsEntryInfo.visible = false
		end
	end
end

return entry_maker
