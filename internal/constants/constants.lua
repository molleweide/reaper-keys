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

-- look at my old pitch machine theory table and reuse it here.
-- NOTE: this should go into a defunintions/chords instead.
constants.t_chords = {
	-- basic intervals

	-- triads
	{
		"major",
		{ 1, 5, 8 },
	},
	{
		"minor",
		{ 1, 4, 8 },
	},
}

constants.patterns = {
 extension_wav = "%.[wW][aA][vV]$"
}

return constants
