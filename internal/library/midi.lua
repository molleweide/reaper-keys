local log = require('utils.log')
local format = require('utils.format')


-- // MIDI HELPER VARIABLE
-- WAS_FILTERED = 1024;  // array for storing which notes are filtered
-- PASS_THRU_CC = 0;

local MODE = 0

-- TYPE_MASK=0xF0;
-- CHANNEL_MASK=0x0F;
-- //OMNI=0x00;
local NOTE_ON   = 0x90;
local NOTE_OFF  = 0x80;
-- //IN_GM=0x00;
-- //ORPHAN_KILL=0x00;
-- //ORPHAN_REMAP=0x01;
-- //OUT_AD=0x00;
-- //OUT_BFD=0x01;
-- //OUT_SD=0x02;

local midi = {}

function midi.sendMidiNote_C3() sendMidiNote(51) end
function midi.sendMidiNote_C3() sendMidiNote(50) end
function midi.sendMidiNote_C3() sendMidiNote(49) end
function midi.sendMidiNote_C3() sendMidiNote(48) end


-- todo
--
--    how can I use key-release here??
--
--      write an issue > ask Mike about this
function sendMidiNote(int)
  reaper.StuffMIDIMessage( MODE,  NOTE_ON,  msg2,  msg3)
  -- wait()
  reaper.StuffMIDIMessage( MODE,  NOTE_OFF,  msg2,  msg3)
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

