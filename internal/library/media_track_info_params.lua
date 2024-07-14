local track_info = {}

-- NOTE: If I want:
-- the value of all params then i just call the function to obtain all track info
-- params of type.
-- I could even have a fltr.track_info helper to make it possible to more easilly
-- manage these types of values. And then I won't have to think about it more
-- in the future because this will be good enough to handle all cases.

-- TEST: Each info entry could have a function attached which handles something
-- about how you set the value.

local T_TRACK_INFO_PARAMS = {
  B_MUTE = { type = "bool", name = "B_MUTE" },
  B_PHASE = { type = "bool", name = "B_PHASE" },
  B_RECMON_IN_EFFECT = {
    type = "bool",
    read_only = true,
    name = "B_RECMON_IN_EFFECT",
    description = "record monitoring in effect (current audio-thread playback state, read-only)",
  },
  IP_TRACKNUMBER = {
    type = "number",
    read_only = true,
    name = "IP_TRACKNUMBER",
    description = "track number 1-based, 0=not found, -1=master track (read-only, returns the int directly)",
  },
  I_SOLO = {
    type = "int",
    name = "I_SOLO",
    min = 0,
    max = 6,
    description = "soloed, 0=not soloed, 1=soloed, 2=soloed in place, 5=safe soloed, 6=safe soloed in place",
  },
  B_SOLO_DEFEAT = {
    type = "bool",
    name = "B_SOLO_DEFEAT",
    description = "when set, if anything else is soloed and this track is not muted, this track acts soloed",
  },
  I_FXEN = { type = "int", name = "I_FXEN", description = "fx enabled, 0=bypassed, !0=fx active" },
  I_RECARM = {
    type = "int",
    name = "I_RECARM",
    description = "record armed, 0=not record armed, 1=record armed",
  },
  I_RECINPUT = {
    type = "int",
    name = "I_RECINPUT",
    description = [[
            record input, <0=no input. if 4096 set, input is MIDI and low 5
            bits represent channel (0=all, 1-16=only chan), next 6 bits
            represent physical input (63=all, 62=VKB). If 4096 is not set, low
            10 bits (0..1023) are input start channel (ReaRoute/Loopback start
            at 512). If 2048 is set, input is multichannel input (using track
            channel count), or if 1024 is set, input is stereo input, otherwise
            input is mono.
            ]],
  },
  I_RECMODE = {
    type = "int",
    name = "I_RECMODE",
    description =
    "record mode, 0=input, 1=stereo out, 2=none, 3=stereo out w/latency compensation, 4=midi output, 5=mono out, 6=mono out w/ latency compensation, 7=midi overdub, 8=midi replace",
  },
  I_RECMODE_FLAGS = {
    type = "int",
    name = "I_RECMODE_FLAGS",
    description = "record mode flags, &3=output recording mode (0=post fader, 1=pre-fx, 2=post-fx/pre-fader)",
  },

  I_RECMON = {
    type = "int",
    name = "I_RECMON",
    description = "record monitoring, 0=off, 1=normal, 2=not when playing (tape style)",
  },
  I_RECMONITEMS = {
    type = "int",
    name = "I_RECMONITEMS",
    description = "monitor items while recording, 0=off, 1=on",
  },
  B_AUTO_RECARM = {
    type = "bool",
    name = "B_AUTO_RECARM",
    description = [[
            automatically set record arm when selected (does not immediately
            affect recarm state, script should set directly if desired)
            ]],
  },
  I_VUMODE = {
    type = "int",
    name = "I_VUMODE",
    description = [[
            track vu mode, &1:disabled, &30==0:stereo peaks,
            &30==2:multichannel peaks, &30==4:stereo RMS, &30==8:combined RMS,
            &30==12:LUFS-M, &30==16:LUFS-S (readout=max), &30==20:LUFS-S
            (readout=current), &32:LUFS calculation on channels 1+2 only
        ]],
  },
  I_AUTOMODE = {
    type = "int",
    name = "I_AUTOMODE",
    description = "track automation mode, 0=trim/off, 1=read, 2=touch, 3=write, 4=latch",
  },
  I_NCHAN = { type = "int", name = "I_NCHAN", description = "Number of track channels, 2-128, even numbers only" },
  I_SELECTED = { type = "int", name = "I_SELECTED", description = "track selected, 0=unselected, 1=selected" },
  I_WNDH = {
    type = "int",
    read_only = true,
    name = "I_WNDH",
    description = "current TCP window height in pixels including envelopes (read-only)",
  },
  I_TCPH = {
    type = "int",
    read_only = true,
    name = "I_TCPH",
    description = "current TCP window height in pixels not including envelopes (read-only)",
  },
  I_TCPY = {
    type = "int",
    read_only = true,
    name = "I_TCPY",
    description = "current TCP window Y-position in pixels relative to top of arrange view (read-only)",
  },
  I_MCPX = {
    type = "int",
    read_only = true,
    name = "I_MCPX",
    description = "current MCP X-position in pixels relative to mixer container (read-only)",
  },
  I_MCPY = {
    type = "int",
    name = "I_MCPY",
    description = "current MCP Y-position in pixels relative to mixer container (read-only)",
  },
  I_MCPW = {
    type = "int",
    read_only = true,
    name = "I_MCPW",
    description = "current MCP width in pixels (read-only)",
  },
  I_MCPH = {
    type = "int",
    read_only = true,
    name = "I_MCPH",
    description = "current MCP height in pixels (read-only)",
  },
  I_FOLDERDEPTH = {
    type = "int",
    name = "I_FOLDERDEPTH",
    description = [[folder depth change, 0=normal, 1=track is a folder
            parent, -1=track is the last in the innermost folder, -2=track is
            the last in the innermost and next-innermost folders, etc]],
  },
  I_FOLDERCOMPACT = {
    type = "int",
    name = "I_FOLDERCOMPACT",
    description = "folder collapsed state (only valid on folders), 0=normal, 1=collapsed, 2=fully collapsed",
  },
  I_MIDIHWOUT = {
    type = "int",
    name = "I_MIDIHWOUT",
    description =
    "track midi hardware output index, <0=disabled, low 5 bits are which channels (0=all, 1-16), next 5 bits are output device index (0-31)",
  },
  I_PERFFLAGS = {
    type = "int",
    name = "I_PERFFLAGS",
    description = "track performance flags, &1=no media buffering, &2=no anticipative FX",
  },
  I_CUSTOMCOLOR = {
    type = "int",
    name = "I_CUSTOMCOLOR",
    description = [[custom color, OS dependent color|0x1000000 (i.e.
            ColorToNative(r,g,b)|0x1000000). If you do not |0x1000000, then it
            will not be used, but will store the color]],
  },
  I_HEIGHTOVERRIDE = {
    type = "int",
    name = "I_HEIGHTOVERRIDE",
    description = "custom height override for TCP window, 0 for none, otherwise size in pixels",
  },
  I_SPACER = {
    type = "int",
    name = "I_SPACER",
    description = [[1=TCP track spacer above this trackB_HEIGHTLOCK :
            bool * : track height lock (must set I_HEIGHTOVERRIDE before
            locking)]],
  },
  D_VOL = {
    type = "double",
    name = "D_VOL",
    unit = "dB",
    description = "trim volume of track, 0=-inf, 0.5=-6dB, 1=+0dB, 2=+6dB, etc",
  },
  D_PAN = { type = "double", name = "D_PAN", description = "trim pan of track, -1..1" },
  D_WIDTH = { type = "double", name = "D_WIDTH", description = "width of track, -1..1" },
  D_DUALPANL = {
    type = "double",
    name = "D_DUALPANL",
    description = "dualpan position 1, -1..1, only if I_PANMODE==6",
  },
  D_DUALPANR = {
    type = "double",
    name = "D_DUALPANR",
    description = "dualpan position 2, -1..1, only if I_PANMODE==6",
  },
  I_PANMODE = {
    type = "int",
    name = "I_PANMODE",
    description = "pan mode, 0=classic 3.x, 3=new balance, 5=stereo pan, 6=dual pan",
  },
  D_PANLAW = {
    type = "double",
    name = "D_PANLAW",
    description =
    "pan law of track, <0=project default, 0.5=-6dB, 0.707..=-3dB, 1=+0dB, 1.414..=-3dB with gain compensation, 2=-6dB with gain compensation, etc",
  },
  I_PANLAW_FLAGS = {
    type = "int",
    name = "I_PANLAW_FLAGS",
    description =
    "pan law flags, 0=sine taper, 1=hybrid taper with deprecated behavior when gain compensation enabled, 2=linear taper, 3=hybrid taper",
  },
  P_ENV = {
    type = "TrackEnvelope *",
    read_only = true,
    name = "P_ENV",
    description = "(read-only) chunkname can be <VOLENV, <PANENV, etc; GUID is the stringified envelope GUID.",
  },
  B_SHOWINMIXER = {
    type = "bool",
    name = "B_SHOWINMIXER",
    description = "track control panel visible in mixer (do not use on master track)",
  },
  B_SHOWINTCP = {
    type = "bool",
    name = "B_SHOWINTCP",
    description = "track control panel visible in arrange view (do not use on master track)",
  },
  B_MAINSEND = { type = "bool", name = "B_MAINSEND", description = "track sends audio to parent" },
  C_MAINSEND_OFFS = {
    type = "char",
    name = "C_MAINSEND_OFFS",
    description = "channel offset of track send to parent",
  },
  C_MAINSEND_NCH = {
    type = "char",
    name = "C_MAINSEND_NCH",
    description = "channel count of track send to parent (0=use all child track channels, 1=use one channel only)",
  },
  I_FREEMODE = {
    type = "int",
    name = "I_FREEMODE",
    description =
    "1=track free item positioning enabled, 2=track fixed lanes enabled (call UpdateTimeline() after changing)",
  },
  I_NUMFIXEDLANES = {
    type = "int",
    read_only = true,
    name = "I_NUMFIXEDLANES",
    description = "number of track fixed lanes (fine to call with setNewValue, but returned value is read-only)",
  },
  C_LANESCOLLAPSED = {
    type = "char",
    name = "C_LANESCOLLAPSED",
    description =
    "fixed lane collapse state (1=lanes collapsed, 2=track displays as non-fixed-lanes but hidden lanes exist)",
  },
  C_LANEPLAYS = {
    type = "char",
    read_only = true,
    name = "C_LANEPLAYS",
    description =
    "in fixed lane tracks, 0=lane N does not play, 1=lane N plays exclusively, 2=lane N plays and other lanes also play (fine to call with setNewValue, but returned value is read-only)",
  },
  C_BEATATTACHMODE = {
    type = "char",
    name = "C_BEATATTACHMODE",
    description = [[
            track timebase, -1=project default, 0=time, 1=beats (position,
            length, rate), 2=beats (position only)
            ]],
  },
  F_MCP_FXSEND_SCALE = {
    type = "float",
    name = "F_MCP_FXSEND_SCALE",
    description = "scale of fx+send area in MCP (0=minimum allowed, 1=maximum allowed)",
  },
  F_MCP_FXPARM_SCALE = {
    type = "float",
    name = "F_MCP_FXPARM_SCALE",
    description = "scale of fx parameter area in MCP (0=minimum allowed, 1=maximum allowed)",
  },
  F_MCP_SENDRGN_SCALE = {
    type = "float",
    name = "F_MCP_SENDRGN_SCALE",
    description = "scale of send area as proportion of the fx+send total area (0=minimum allowed, 1=maximum allowed)",
  },
  F_TCP_FXPARM_SCALE = {
    type = "float",
    name = "F_TCP_FXPARM_SCALE",
    description = "scale of TCP parameter area when TCP FX are embedded (0=min allowed, default, 1=max allowed)",
  },
  I_PLAY_OFFSET_FLAG = {
    type = "int",
    name = "I_PLAY_OFFSET_FLAG",
    description = [[
            track media playback offset state, &1=bypassed, &2=offset value is
            measured in samples (otherwise measured in seconds)
            ]],
  },
  D_PLAY_OFFSET = {
    type = "double",
    name = "D_PLAY_OFFSET",
    description = "track media playback offset, units depend on I_PLAY_OFFSET_FLAG",
  },
  -- P_PARTRACK : MediaTrack * : parent track (read-only)
  -- P_PARTRACK = reaper.GetMediaTrackInfo_Value(track, "P_PARTRACK"),
  -- P_PROJECT : ReaProject * : parent project (read-only)
  -- P_PROJECT = reaper.GetMediaTrackInfo_Value(track, "P_PROJECT"),
}

track_info.get_track_info_params = function()
  return T_TRACK_INFO_PARAMS
end

-- TODO: I need to attach the meta data so that I can easilly handle all entries.

track_info.get_array = function(to)
  local res = {}
  for _, v in pairs(T_TRACK_INFO_PARAMS) do
    v.value = reaper.GetMediaTrackInfo_Value(to.tr, v.name)
    v._meta = {
      type = "info_param",
      cat = "track",
    }
    table.insert(res, v)
  end
  return res
end

return track_info
