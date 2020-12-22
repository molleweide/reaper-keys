# class syntax

str class.next
str class.possible_children
int class.level
bool class.repeat
bool class.cont ???
table trackInfoSettings
table fx_syntax

```

-- refactor into general fx / util settings file??
local samplerNoteBass = 48

---- mv >>> util file
function midiNumToNormalized(num)
  -- normalized values are used in, eg. RS5K for setting note values...
  return num * 1/128
end

-- ========================================================================

return {
  prefix = 'C',
  treeProps = { -- classTreeAttrs
    depth = 3,
      nxt = 'S',
        rep = false, cont = true, possible_children = 'S',
  },
  trackProps = {
    trackHeight = { attrString = "I_HEIGHTOVERRIDE", attrVal = 30, },
    trackColor = { attrString = "I_CUSTOMCOLOR", val = 122, }
  },
  fx_syntax = { -- class M syntax
    default = {},
    m = {
      prefix = 'A',
      [0] = {
        -- fx_type = 'JS: ',
        code = 'A',
        rsfx_name = "NoteFlt", -- rename >
        search_str = "midi_note_filter",
        fx_params = {
          [0] = { val = function(note_start_index, range) return note_start_index end }, -- now thresh
          [1] = { val = function(note_start_index, range) return note_start_index + range - 1 end} -- high thresh
        }
      },
      [1] = {
        -- fx_type = 'JS: ',
        code = 'A',
        rsfx_name = "NoteTrans",
        search_str = "midi_transpose",
        fx_params = {
          [0] = {  val = function(note_start_index, range) return samplerNoteBass - note_start_index end } -- note shift // transpore note
        }
      },
      [2] = {
        -- fx_type = 'VST: ',
        code = 'A',
        spawnByRange = true, -- M has option 'nr'
        rsfx_name = "RS5K",
        search_str = "ReaSamplOmatic5000",
        fx_params = {
          [3] = { val = function(note_start_index, range, r) return midiNumToNormalized(samplerNoteBass + r) end }, -- note range start
          [4] = { val = function(note_start_index, range, r) return midiNumToNormalized(samplerNoteBass + r) end } -- note range end
        }
      }
    } -- m
  }
}

```
