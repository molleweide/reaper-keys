local log = require("utils.log")
local format = require("utils.format")

local fu = require("utils.fzf")

return function(self, i)
		-- todo: i should prolly remove the undo points since
		-- those are handled by RK

		log.user("SELECT FX: ", i)

		if not self.t_search_results then
			return false
		end -- results is empty

		local fx = self.t_search_results[i]

		if not fx then
			return false
		end -- no such result

		self.t_results_data[fx.id].rating = self.t_results_data[fx.id].rating + 1

		reaper.Undo_BeginBlock2(J_PROJECT_DATA:getId())

		if fx.tracktemplate then
			-- This is a template, insert it
			reaper.Main_openProject(fu._jPath(fx.path .. fx.filename))
		elseif fx.fxchain then
			if not GUI.kb.control() then -- Control not held, insert on tracks
				-- Adds an FXCHAIN to a track. If there are no FX on the track an empty chain will be created first
				local selectedTracks = J_PROJECT_DATA:selectedTracks(0, 0, true)
				local bCreatedChain = false

				for _, t in pairs(selectedTracks) do
					if t.fxcount == 0 then
						J_PROJECT_DATA:unselectAllTracks()
						t.selected = 1
						jCreateTrackChainForSelectedTracks()
						bCreatedChain = true
					end
				end

				for _, t in pairs(selectedTracks) do
					if bCreatedChain then
						t.selected = 1
					end
					local numFxBefore = t.fxcount
					jFxChainAdd(t, fu.jReadFxChainFromFile(fu._jPath(fx.path .. fx.filename)))
					if pluginsData.FXCHAIN_FLOAT_WINDOWS then
						for iFX = numFxBefore, t.fxcount - 1 do
							t:getFx(iFX):show(3)
						end
					end
				end

				if pluginsData.TRACK_SHOW_FLAG == 1 and not pluginsData.FXCHAIN_FLOAT_WINDOWS then -- added for people using the fxchain window so the fx will show
					local focusTrack = selectedTracks[1]
					if focusTrack then
						focusTrack:getFx(focusTrack.fxcount - 1):show(pluginsData.TRACK_SHOW_FLAG)
					end
				end

				-- LEAVE THIS FOR FUTURE !!!!!!!!!!
				-- else -- control held, try to add chain to items
				-- reaper.ClearConsole()
				-- for i in J_PROJECT_DATA:selectedItems() do
				-- 	local take = i:getActiveTake()
				-- 	local chunk = i:getStateChunk()
				-- 	local takeNumber = math.tointeger(take.number)
				-- 	-- msg(chunk)
				-- 	-- msg("---")

				-- 	msg(math.tointeger( takeNumber))
				-- 	local fxChunk = ultraschall.GetFXStateChunk(chunk, takeNumber)
				-- 	msg(fxChunk)
				-- 	msg("after: ")
				-- 	local fxString = fu.jReadFxChainFromFile(fx.path .. fx.filename)
				-- 	if not fxChunk then
				-- 		-- No fx yet, create chunk:
				-- 		msg("create new chunk...")
				-- 		fxChunk = " <TAKEFX\n" .. fxString .. "\n  >"
				-- 		takeNumber = 0
				-- 	else
				-- 		fxChunk =  fxChunk:gsub(">$", '') -- remove closing ">"
				-- 		fxChunk = fxChunk .. "\n" .. fxString .. "\n>"
				-- 	end
				-- 	msg("fxChunk:")
				-- 	msg(fxChunk)
				-- 	msg("Chunk:")
				-- 	msg(chunk)
				-- 	local r, newChunk = ultraschall.SetFXStateChunk(chunk, fxChunk, takeNumber)
				-- 	-- msg(newChunk)
				-- 	-- i:setStateChunk(newChunk)

				-- end
			end
		elseif fx.action then
			-- NOTE: this is how I can call regular actions from a fuzzy list.
			-- This could also be used in combination with RK sequences and fuzzy
			-- search next step to take

			reaper.Main_OnCommandEx(fx.command, 1, 0)
		-- msg(fx.command)
		-- msg(fx.name)
		else
			-- this is a vst or a jsfx
			local typeInfo = ""
			if self.t_results_data[fx.id].vst3 and pluginsData.PREFER_VST3 then -- prefer VST3 where available
				typeInfo = "VST3:"
			end

			local fxString = ""
			if fx.jsfx then
				fxString = fx.filename
			elseif fx.au then
				fxString = fx.filename
			elseif fx.aui then
				fxString = fx.filename
			else
				fxString = typeInfo .. fu._removeVstiString(self.t_results_data[fx.id].name)
			end
			if not GUI.kb.control() then -- Control not held, insert on tracks
				for t in J_PROJECT_DATA:selectedTracks() do
					local r = t:addFx(fxString)
					if r then
						r:show(pluginsData.TRACK_SHOW_FLAG)
					end
				end
			else -- Control held, insert on items
				for i in J_PROJECT_DATA:selectedItems() do
					local take = i:getActiveTake()
					local r = take:addFx(fxString)
					if r >= 0 then
						reaper.TakeFX_Show(take:getReaperTake(), r, pluginsData.ITEM_SHOW_FLAG) -- show FX
					end
				end
			end
		end
		reaper.Undo_EndBlock2(J_PROJECT_DATA:getId(), "FAST FX FINDER: Add Fx", 0)

		UPDATE_RATINGS = true
		return true
	end
