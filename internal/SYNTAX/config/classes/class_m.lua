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
          -- local _, file = reaper.TrackFX_GetNamedConfigParm(opts_g.tr, opts_g.new_fx_chain_idx, "FILE0")

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

          local utils_io = require("utils.io")

          local function getSubstringBeforePeriod(str)
            local substring = string.match(str, "^(.-)%.") -- The pattern captures characters until the first period.
            return substring
          end

          local searchName = getSubstringBeforePeriod( opts_g.trk_obj.name )

          local matchingFiles = utils_io.findWavFilesWithNameX(searchName)

          -- TODO: get random sample file index
          local function getRandomIndexInRange(minIndex, maxIndex)
            -- Calculate the random floating-point number between 0 and 1
            local randomFloat = math.random()

            -- Calculate the random index within the specified range
            local rangeSize = maxIndex - minIndex + 1
            local randomIndex = math.floor(randomFloat * rangeSize) + minIndex

            return randomIndex
          end

          if #matchingFiles > 0 then
            reaper.TrackFX_SetNamedConfigParm(
              opts_g.tr,
              opts_g.new_fx_chain_idx,
              "FILE0",
              matchingFiles[getRandomIndexInRange(1, #matchingFiles)]
            )
            reaper.TrackFX_SetNamedConfigParm(opts_g.tr, opts_g.new_fx_chain_idx, "DONE", "")
          end
        end,
      },
    }, -- m
  },
}
