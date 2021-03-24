local log = require('utils.log')
local format = require('utils.format')


-- // MIDI HELPER VARIABLE
-- WAS_FILTERED = 1024;  // array for storing which notes are filtered
-- PASS_THRU_CC = 0;

local MODE = 0

-- TYPE_MASK=0xF0;
-- CHANNEL_MASK=0x0F;
-- //OMNI=0x00;
local NOTE_ON   = 0x90
local NOTE_OFF  = 0x80
local VEL       = 0x50 -- dec 80
-- //IN_GM=0x00;
-- //ORPHAN_KILL=0x00;
-- //ORPHAN_REMAP=0x01;
-- //OUT_AD=0x00;
-- //OUT_BFD=0x01;
-- //OUT_SD=0x02;

local midi = {}

-- for i=0, 127 do
--    midi['vkb_send_note_' .. i] = function() sendMidiNote(i) end
-- end
--
--  [1] = { val = function(note_start_index, range)
--          return note_start_index + range - 1 end} -- high thresh

function midi.sendMidiNote_B_3() sendMidiNote(47) end
function midi.sendMidiNote_As3() sendMidiNote(46) end
function midi.sendMidiNote_A_3() sendMidiNote(45) end
function midi.sendMidiNote_Gs3() sendMidiNote(44) end
function midi.sendMidiNote_G_3() sendMidiNote(43) end
function midi.sendMidiNote_Fs3() sendMidiNote(42) end
function midi.sendMidiNote_F_3() sendMidiNote(41) end
function midi.sendMidiNote_E_3() sendMidiNote(40) end
function midi.sendMidiNote_Ds3() sendMidiNote(39) end
function midi.sendMidiNote_D_3() sendMidiNote(38) end
function midi.sendMidiNote_Cs3() sendMidiNote(37) end
function midi.sendMidiNote_C_3() sendMidiNote(36) end


function midi.sendMidiNote_B_2() sendMidiNote(35) end
function midi.sendMidiNote_As2() sendMidiNote(34) end
function midi.sendMidiNote_A_2() sendMidiNote(33) end
function midi.sendMidiNote_Gs2() sendMidiNote(32) end
function midi.sendMidiNote_G_2() sendMidiNote(31) end
function midi.sendMidiNote_Fs2() sendMidiNote(30) end
function midi.sendMidiNote_F_2() sendMidiNote(29) end
function midi.sendMidiNote_E_2() sendMidiNote(28) end
function midi.sendMidiNote_Ds2() sendMidiNote(27) end
function midi.sendMidiNote_D_2() sendMidiNote(26) end
function midi.sendMidiNote_Cs2() sendMidiNote(25) end
function midi.sendMidiNote_C_2() sendMidiNote(24) end

function midi.sendMidiNote_B_1() sendMidiNote(23) end
function midi.sendMidiNote_As1() sendMidiNote(22) end
function midi.sendMidiNote_A_1() sendMidiNote(21) end
function midi.sendMidiNote_Gs1() sendMidiNote(20) end
function midi.sendMidiNote_G_1() sendMidiNote(19) end
function midi.sendMidiNote_Fs1() sendMidiNote(18) end
function midi.sendMidiNote_F_1() sendMidiNote(17) end
function midi.sendMidiNote_E_1() sendMidiNote(16) end
function midi.sendMidiNote_Ds1() sendMidiNote(15) end
function midi.sendMidiNote_D_1() sendMidiNote(14) end
function midi.sendMidiNote_Cs1() sendMidiNote(13) end
function midi.sendMidiNote_C_1() sendMidiNote(12) end


function midi.sendMidiNote_B_0() sendMidiNote(11) end
function midi.sendMidiNote_As0() sendMidiNote(10) end
function midi.sendMidiNote_A_0() sendMidiNote(9) end
function midi.sendMidiNote_Gs0() sendMidiNote(8) end
function midi.sendMidiNote_G_0() sendMidiNote(7) end
function midi.sendMidiNote_Fs0() sendMidiNote(6) end
function midi.sendMidiNote_F_0() sendMidiNote(5) end
function midi.sendMidiNote_E_0() sendMidiNote(4) end
function midi.sendMidiNote_Ds0() sendMidiNote(3) end
function midi.sendMidiNote_D_0() sendMidiNote(2) end
function midi.sendMidiNote_Cs0() sendMidiNote(1) end
function midi.sendMidiNote_C_0() sendMidiNote(0) end

--  TODO
--
--    how can I use key-release here??
--      write an issue > ask Mike about this

function sendMidiNote(note_num)
  reaper.StuffMIDIMessage( MODE,  NOTE_ON,  note_num,  VEL)
  -- wait()
  reaper.StuffMIDIMessage( MODE,  NOTE_OFF,  note_num,  VEL)
end

-- this string color makes it easier to read...
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

