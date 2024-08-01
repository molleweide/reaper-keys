local constants = {}

constants.midi_note_defaults = {
  selected = false,
  muted = false,
  chan = 0,
  velocity = 80,
  noSortIn = true,
  pitch = 60,
}

constants.midi_helpers = {
  -- WAS_FILTERED = 1024;  // array for storing which notes are filtered
  -- PASS_THRU_CC = 0;
  MODE = 0,
  -- TYPE_MASK=0xF0;
  -- CHANNEL_MASK=0x0F;
  -- //OMNI=0x00;
  NOTE_ON = 0x90,
  NOTE_OFF = 0x80,
  VEL = 0x50, -- dec 80
  -- //IN_GM=0x00;
  -- //ORPHAN_KILL=0x00;
  -- //ORPHAN_REMAP=0x01;
  -- //OUT_AD=0x00;
  -- //OUT_BFD=0x01;
  -- //OUT_SD=0x02;
}

-- -- look at my old pitch machine theory table and reuse it here.
-- -- NOTE: this should go into a defunintions/chords instead.
-- constants.t_chords = {
-- 	-- basic intervals
-- 	{
-- 		"minor second",
-- 		{ 1, 5, 8 },
-- 	},
-- 	{
-- 		"minor second",
-- 		{ 1, 5, 8 },
-- 	},
--
-- 	{
-- 		"minor second",
-- 		{ 1, 5, 8 },
-- 	},
--
-- 	{
-- 		"minor second",
-- 		{ 1, 5, 8 },
-- 	},
--
-- 	{
-- 		"minor second",
-- 		{ 1, 5, 8 },
-- 	},
--
-- 	{
-- 		"minor second",
-- 		{ 1, 5, 8 },
-- 	},
--
--
-- 	-- triads
-- 	{
-- 		"major",
-- 		{ 1, 5, 8 },
-- 	},
-- 	{
-- 		"minor",
-- 		{ 1, 4, 8 },
-- 	},
-- }

constants.patterns = {
  extension_wav = "%.[wW][aA][vV]$"
}


-- "<VOLENV") )
-- "<PANENV") )
-- "<VOLENV2")
-- "<PANENV2")
-- "<WIDTHENV")
-- "<WIDTHENV2"
-- "<VOLENV3")
-- "<MUTEENV")

constants.BUILTIN_ENVELOPES = {
  volume = {
    id             = 0,
    name           = "volume",
    name_formatted = "Volume",
    search_string
                   = "<VOLENV2"
  },
  volume_pre_fx = {
    id = 1,
    name = "volume_pre_fx",
    name_formatted = "Volume (Pre-FX)",
    search_string = "<VOLENV"
  },
  pan = { id = 2, name = "Pan", search_string = "<PANENV2" },
  pan_pre_fx = { id = 3, name = "Pan (Pre-FX)", search_string = "<PANENV" },
  width = {
    id = 4,
    name = "width",
    name_formatted = "Width",
    search_string =
    "<WIDTHENV2"
  },
  width_pre_fx = { id = 5, name = "width_pre_fx", name_formatted = "Width (Pre-FX)", search_string = "<WIDTHENV" },
  mute = { id = 6, name = "mute", name_formatted = "Mute", search_string = "<MUTEENV" },
  -- pitch = { id = 7, name = "Pitch", search_string = "<PANENV" },
  -- playrate = { id = 8, name = "Playrate", search_string = "<PANENV" },
  -- tempo_map = { id = 9, name = "Tempo map", search_string = "<PANENV" },
  -- parameter = { id = 10, name = "Parameter", search_string = "<PANENV" },
}


constants.CC_CONSTANTS = {
  type = {
    ---       bits of the data byte ): Note Off = 8; Note On = 9; Aftertouch = 10; CC = 11;
    ---       Program Change = 12; Channel Pressure = 13; Pitch Vend = 14; text = 15.
    --     note_off = ,
    -- note_on = ,
    cc = 176, -- 176
    pitch = 224,
    -- pitch =
  },
}

constants.CC_SHAPES = {
  square = { id = 0 },
  linear = { id = 1 },
  slow_start_end = { id = 2 },
  fast_start = { id = 3 },
  fast_end = { id = 4 },
  bezier = { id = 5 }
}



return constants
