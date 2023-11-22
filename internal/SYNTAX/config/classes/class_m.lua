local samplerNoteBass = 48
local log = require("utils.log")

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
          [0] = {
            val = function(note_start_index, range)
              return note_start_index
            end,
          }, -- now thresh
          [1] = {
            val = function(note_start_index, range)
              return note_start_index + range - 1
            end,
          }, -- high thresh
        },
      },
      -- NOTE: what does `code` mean here?
      [1] = {
        -- fx_type = 'JS: ',
        code = "A",
        rsfx_name = "NoteTrans",
        search_str = "midi_transpose",
        fx_params = {
          [0] = {
            val = function(note_start_index, range)
              return samplerNoteBass - note_start_index
            end,
          }, -- note shift // transpore note
        },
      },
      [2] = {
        -- fx_type = 'VST: ',
        code = "A",
        spawnByRange = true, -- M has option 'nr'
        rsfx_name = "RS5K",
        search_str = "ReaSamplOmatic5000",
        fx_params = {
          [3] = {
            val = function(note_start_index, range, r)
              return midiNumToNormalized(samplerNoteBass + r)
            end,
          }, -- note range start
          [4] = {
            val = function(note_start_index, range, r)
              return midiNumToNormalized(samplerNoteBass + r)
            end,
          }, -- note range end
        },
        named_config_params = function(opts_g, t_rsfx)
          local str_util = require("utils.string")
          local rk_config = require("definitions.config")
          local constants = require("constants.constants")

          -- log.user(
          -- 	opts_g.trk_obj.trackIndex
          -- 		.. " > "
          -- 		.. opts_g.trk_obj.name
          -- 		.. " / "
          -- 		.. opts_g.new_fx_chain_idx
          -- 		.. "("
          -- 		.. t_rsfx.rsfx_name
          -- 		.. ") : "
          -- 	-- .. file
          -- )

          local _, buf = reaper.TrackFX_GetNamedConfigParm(opts_g.tr, opts_g.new_fx_chain_idx, "FILE0")
          -- log.user(opts_g.trk_obj.name .. ":", retval, buf, type(buf), buf == "", buf:find(wav_ext_pattern))

          if (
              not rk_config.syntax.samplers.load_random_sample_if_empty
                  and buf:find(constants.patterns) ~= nil
              ) or not rk_config.syntax.samplers.always_reload_random_sample
          then
            return
          end

          -- log.user(opts_g.trk_obj.name .. " does not have samples. Fixing..")

          local utils_io = require("utils.fs")
          local numbers = require("utils.numbers")
          local t_track_name_parts = str_util.getStringSplitPattern(opts_g.trk_obj, "%.")
          local t_matched_wav_files = utils_io.findWavFilesWithNameX(t_track_name_parts[1])

          if #t_matched_wav_files > 0 then
            reaper.TrackFX_SetNamedConfigParm(
              opts_g.tr,
              opts_g.new_fx_chain_idx,
              "FILE0",
              t_matched_wav_files[numbers.getRandomIndexInRange(1, #t_matched_wav_files)]
            )
            reaper.TrackFX_SetNamedConfigParm(opts_g.tr, opts_g.new_fx_chain_idx, "DONE", "")
          else
            log.debug(string.format(
              [[
            [Class_m]:No WAV samples where found for track (%s) with search string (%s)
            ]] ,
              opts_g.trk_obj.name,
              t_track_name_parts[1]
            ))
          end
          -- end
        end,
      },
    }, -- m
  },
}
