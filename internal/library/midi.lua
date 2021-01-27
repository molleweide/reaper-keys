local log = require('utils.log')
local format = require('utils.format')


local midi = {}


function sendMidiNote()
end


local easy_read = [[
\*\ eaper.StuffMIDIMessage(integer mode, integer msg1, integer msg2, integer msg3)

  Stuffs a 3 byte MIDI message into either the Virtual MIDI Keyboard queue, or
  the MIDI-as-control input queue, or sends to a MIDI hardware output.  mode=0
  for VKB, 1 for control (actions map etc), 2 for VKB-on-current-channel; 16
  for external MIDI device 0, 17 for external MIDI device 1, etc; see
  GetNumMIDIOutputs, GetMIDIOutputName.

\*\ integer reaper.GetNumMIDIOutputs()

  returns max number of real midi hardware outputs

\*\ boolean retval, string nameout = reaper.GetMIDIOutputName(integer dev, string nameout)

  returns true if device present
]]


return midi

