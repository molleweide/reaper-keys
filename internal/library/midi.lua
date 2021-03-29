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

function midi.sendMidiNote_71() sendMidiNote(61) end
function midi.sendMidiNote_70() sendMidiNote(70) end
function midi.sendMidiNote_69() sendMidiNote(69) end
function midi.sendMidiNote_68() sendMidiNote(68) end
function midi.sendMidiNote_67() sendMidiNote(67) end
function midi.sendMidiNote_66() sendMidiNote(66) end
function midi.sendMidiNote_65() sendMidiNote(65) end
function midi.sendMidiNote_64() sendMidiNote(64) end
function midi.sendMidiNote_63() sendMidiNote(63) end
function midi.sendMidiNote_62() sendMidiNote(62) end
function midi.sendMidiNote_61() sendMidiNote(61) end
function midi.sendMidiNote_60() sendMidiNote(60) end

function midi.sendMidiNote_59() sendMidiNote(59) end
function midi.sendMidiNote_58() sendMidiNote(58) end
function midi.sendMidiNote_57() sendMidiNote(57) end
function midi.sendMidiNote_56() sendMidiNote(56) end
function midi.sendMidiNote_55() sendMidiNote(55) end
function midi.sendMidiNote_54() sendMidiNote(54) end
function midi.sendMidiNote_53() sendMidiNote(53) end
function midi.sendMidiNote_52() sendMidiNote(52) end
function midi.sendMidiNote_51() sendMidiNote(51) end
function midi.sendMidiNote_50() sendMidiNote(50) end
function midi.sendMidiNote_49() sendMidiNote(49) end
function midi.sendMidiNote_48() sendMidiNote(48) end

function midi.sendMidiNote_47() sendMidiNote(47) end
function midi.sendMidiNote_46() sendMidiNote(46) end
function midi.sendMidiNote_45() sendMidiNote(45) end
function midi.sendMidiNote_44() sendMidiNote(44) end
function midi.sendMidiNote_43() sendMidiNote(43) end
function midi.sendMidiNote_42() sendMidiNote(42) end
function midi.sendMidiNote_41() sendMidiNote(41) end
function midi.sendMidiNote_40() sendMidiNote(40) end
function midi.sendMidiNote_39() sendMidiNote(39) end
function midi.sendMidiNote_38() sendMidiNote(38) end
function midi.sendMidiNote_37() sendMidiNote(37) end
function midi.sendMidiNote_36() sendMidiNote(36) end

function midi.sendMidiNote_35() sendMidiNote(35) end
function midi.sendMidiNote_34() sendMidiNote(34) end
function midi.sendMidiNote_33() sendMidiNote(33) end
function midi.sendMidiNote_32() sendMidiNote(32) end
function midi.sendMidiNote_31() sendMidiNote(31) end
function midi.sendMidiNote_30() sendMidiNote(30) end
function midi.sendMidiNote_29() sendMidiNote(29) end
function midi.sendMidiNote_28() sendMidiNote(28) end
function midi.sendMidiNote_27() sendMidiNote(27) end
function midi.sendMidiNote_26() sendMidiNote(26) end
function midi.sendMidiNote_25() sendMidiNote(25) end
function midi.sendMidiNote_24() sendMidiNote(24) end

function midi.sendMidiNote_23() sendMidiNote(23) end
function midi.sendMidiNote_22() sendMidiNote(22) end
function midi.sendMidiNote_21() sendMidiNote(21) end
function midi.sendMidiNote_20() sendMidiNote(20) end
function midi.sendMidiNote_19() sendMidiNote(19) end
function midi.sendMidiNote_18() sendMidiNote(18) end
function midi.sendMidiNote_17() sendMidiNote(17) end
function midi.sendMidiNote_16() sendMidiNote(16) end
function midi.sendMidiNote_15() sendMidiNote(15) end
function midi.sendMidiNote_14() sendMidiNote(14) end
function midi.sendMidiNote_13() sendMidiNote(13) end
function midi.sendMidiNote_12() sendMidiNote(12) end

function midi.sendMidiNote_11() sendMidiNote(11) end
function midi.sendMidiNote_10() sendMidiNote(10) end
function midi.sendMidiNote_09() sendMidiNote(9) end
function midi.sendMidiNote_08() sendMidiNote(8) end
function midi.sendMidiNote_07() sendMidiNote(7) end
function midi.sendMidiNote_06() sendMidiNote(6) end
function midi.sendMidiNote_05() sendMidiNote(5) end
function midi.sendMidiNote_04() sendMidiNote(4) end
function midi.sendMidiNote_03() sendMidiNote(3) end
function midi.sendMidiNote_02() sendMidiNote(2) end
function midi.sendMidiNote_01() sendMidiNote(1) end
function midi.sendMidiNote_00() sendMidiNote(0) end

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

