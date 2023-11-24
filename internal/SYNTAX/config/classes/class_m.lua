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
          local cfg = require("definitions.config")
          local constants = require("constants.constants")
          local rs5k = require("library.plugins.rs5k")

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

          -- reaper.TrackFX_GetNamedConfigParm(opts_g.tr, opts_g.new_fx_chain_idx, "FILE0")
          local _, buf = rs5k.hasSampleLoaded(opts_g.trk_obj, opts_g.new_fx_chain_idx)

          -- log.user(opts_g.trk_obj.name .. ":", retval, buf, type(buf), buf == "", buf:find(wav_ext_pattern))

          if (
              cfg.syntax.samplers.load_random_sample_if_empty
                  and buf:find(constants.patterns.extension_wav) == nil
              ) or cfg.syntax.samplers.always_reload_random_sample
          then
            rs5k.randomize_sample(opts_g.trk_obj, opts_g.new_fx_chain_idx)
          else
            return
          end
        end,
      },
    }, -- m
  },
}
