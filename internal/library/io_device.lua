local reaper_utils = require('custom_actions.utils')
local log = require('utils.log')
local format = require('utils.format')

io_device = {}

--  REAPER STARTUP
--
--    on start up look for midi devices / audio devices and
--    enable the ones I prefer

function setMidiInForSingleTrack(tr, chan, dev_name)
  if not tr then return end
  if not chan then chan = 0 end
  if not dev_name then dev_name = 'Virtual Midi Keyboard' end -- config.default_midi_device

  -- log.user('\n\nMIDI DEVICE SET: ' .. dev_name .. '\n')
  for i = 0, 64 do
    local retval, nameout = reaper.GetMIDIInputName( i, '' )
    -- if nameout ~= '' then log.user('\t'..nameout) end
    if nameout:lower():match(dev_name:lower()) then dev_id = i end
  end

  if not dev_id then
    -- log.user('device not found')
    return
  end
  val = 4096+ chan + ( dev_id << 5  )

  --  I_RECINPUT : int * : record input,
  --
  --      <0=no input.
  --
  --      if 4096 set,
  --        input is MIDI and low 5 bits represent channel (0=all, 1-16=only chan),
  --        next 6 bits represent physical input (63=all, 62=VKB).
  --
  --      If 4096 is not set,
  --        low 10 bits (0..1023) are input start channel (ReaRoute/Loopback start at 512).
  --
  --      If 2048 is set,
  --        input is multichannel input (using track channel count),
  --
  --      or if 1024 is set,
  --        input is stereo input, otherwise input is mono.
  reaper.SetMediaTrackInfo_Value( tr, 'I_RECINPUT',val)
end

function setMidiInMultSel(dev_name)
  for i = 1, reaper.CountSelectedTracks(0) do
    local tr = reaper.GetSelectedTrack(0,i-1)
    setMidiInForSingleTrack( tr, channel, dev_name )
  end
end

function io_device.setInputTo_MIDI_DEFAULT() setMidiInMultSel() end

-- move these funcs to config >> ./personal/io_devices.lua ???
function io_device.setInputTo_MIDI_VIRTUAL() setMidiInMultSel('Virtual Midi Keyboard') end

function io_device.setInputTo_MIDI_QMK() setMidiInMultSel('Ergodox EZ') end

--[[
--  todo
--
--    whenever I use a new piano >> add to list of pianos? maybe good idea
--]]
function io_device.setInputTo_MIDI_GRAND_ROLAND() setMidiInMultSel('- port 1') end

return io_device
