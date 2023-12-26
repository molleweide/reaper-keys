local cfg = require("definitions.config")
local samplerNoteBass = cfg.drum_lanes_low_note_start -- 48
local log = require("utils.log")
local format = require("utils.format")

---- mv >>> util file
function midiNumToNormalized(num)
	-- normalized values are used in, eg. RS5K for setting note values...
	return num * 1 / 128
end

-- ========================================================================

return {
	prefix = "M",
	treeProps = { -- rename > tree_syntax
		level = 3,
		nxt = "ZGMCABT",
		rep = true,
	},
	trackProps = {
		trackHeight = { attrString = "I_HEIGHTOVERRIDE", attrVal = 20 },
		trackColor = { attrString = "I_CUSTOMCOLOR", val = 122 },
	},
	routing = function(trk_obj)
		local trr = require("library.routing")
		local rc = require("definitions.routing")
		local has_sends = trr.trackHasSends(trk_obj.guid, rc.flags.CAT_SEND)
		if not has_sends then
			if trk_obj.zone.name == "DRUMS_ZONE" then
				trr.updateState("(SUM_DRUMS)#[0|0]", trk_obj.guid)
			elseif trk_obj.zone.name == "MUSIC_ZONE" then
				trr.updateState("(SUM_MUSIC)#[0|0]", trk_obj.guid)
			elseif trk_obj.zone.name == "FX_ZONE" then
				trr.updateState("(SUM_FX)#[0|0]", trk_obj.guid)
			elseif trk_obj.zone.name == "VOCALS_ZONE" then
			else
				trr.updateState("(MIX_BUSS)#[0|0]", trk_obj.guid)
			end
		end
	end,
	fx_syntax = { -- class M syntax

		-- todo: add fx sequence for regular synth tracks
		default = {},

		m = {
			[0] = { -- only integer keys are used when computing table #length
				-- fx_type = 'JS: ',
				code = "A", -- pre fx
				rsfx_name = "NoteFlt", -- rename >
				search_str = "midi_note_filter",
				fx_params = {
					[0] = function(note_start_index, range)
						return note_start_index
					end, -- now thresh
					[1] = function(note_start_index, range)
						return note_start_index + range - 1
					end, -- high thresh
				},
			},
			-- NOTE: what does `code` mean here?
			[1] = {
				-- fx_type = 'JS: ',
				code = "A",
				rsfx_name = "NoteTrans",
				search_str = "midi_transpose",
				fx_params = {
					[0] = function(note_start_index, range)
						return samplerNoteBass - note_start_index
					end, -- note shift // transpore note
				},
			},
			[2] = {
				-- fx_type = 'VST: ',
				code = "A",
				spawnByRange = true, -- M has option 'nr'
				rsfx_name = "RS5K",
				search_str = "ReaSamplOmatic5000",

				-- NOTE: each param is applied by a param_apply_func.
				fx_params = {
					[3] = function(note_start_index, range, r)
						return midiNumToNormalized(samplerNoteBass + r)
					end, -- note range start
					[4] = function(note_start_index, range, r)
						return midiNumToNormalized(samplerNoteBass + r)
					end, -- note range end
				},
				named_config_params = function(state, t_rsfx)
					local constants = require("constants.constants")
					local rs5k = require("plugins.rs5k")
					log.debug(
						string.format(
							[[CLASS_M [named_config_params] # %s > %s / %s (%s)]],
							state.trk_obj.trackIndex,
							state.trk_obj.name,
							state.new_fx_chain_idx,
							t_rsfx.rsfx_name
						)
					)

					local _, buf = rs5k.hasSampleLoaded(state.trk_obj, state.new_fx_chain_idx)
					log.user(
						">>>>>>",
						state.trk_obj.name .. ":",
						retval,
						-- buf,
						" | ",
						type(buf),
						buf == "",
						buf:find(constants.patterns.extension_wav)
					)

					if
						(
							cfg.syntax.samplers.load_random_sample_if_empty
							and buf == "" --:find(constants.patterns.extension_wav) == nil
						) or cfg.syntax.samplers.always_reload_random_sample
					then
						rs5k.updateSample(state.trk_obj, state.new_fx_chain_idx)
					else
						return
					end
				end,
			},
		}, -- m
	},
}
