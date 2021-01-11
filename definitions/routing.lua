-- default values when creating routes
return {
  default_params = {
    ["k"] = 0, -- k = category    : int,      is <0 for receives, 0=sends, >0 for hardware outputs
    ["i"] = 0, -- i = send_idx    : int
    ["m"] = 0, -- m = B_MUTE      : bool
    ["f"] = 0, -- f = B_PHASE     : bool,     true to flip phase
    ["M"] = 0, -- M = B_MONO      : bool
    ["v"] = 0, -- v = D_VOL       : double,   1.0 = +0dB etc
    ["p"] = 0, -- p = D_PAN       : double,   -1..+1
    ["P"] = 0, -- P = D_PANLAW    : double,   1.0=+0.0db, 0.5=-6dB, -1.0 = projdef etc
    ["s"] = 0, -- s = I_SENDMODE  : int,      0=post-fader, 1=pre-fx, 2=post-fx (deprecated), 3=post-fx
    ["a"] = 0, -- a = I_AUTOMODE  : int :     auto mode (-1=use track automode, 0=trim/off, 1=read, 2=touch, 3=write, 4=latch)
    ["c"] = 0, -- c = I_SRCCHAN   : int,      index,&1024=mono, -1 for none
    ["C"] = 0, -- C = I_DSTCHAN   : int,      index, &1024=mono, otherwise stereo pair, hwout:&512=rearoute
    ["I"] = 0, -- I = I_MIDIFLAGS : int,      low 5 bits=source channel 0=all, 1-16, next 5 bits=dest channel, 0=orig, 1-16=chanSee CreateTrackSend, RemoveTrackSend, GetTrackNumSends.
  }
}
