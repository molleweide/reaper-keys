# ROUTING

1. walk through string
2. extract all letters

```lua

--  `s15mf`
--
--  order of input
--
--  CATEGORY
--
--  SEND_IDX
--        k = category    : int,      is <0 for receives, 0=sends, >0 for hardware outputs
--        i = send_index  : int

--        m = B_MUTE      : bool
--        f = B_PHASE     : bool,     true to flip phase
--        M = B_MONO      : bool
--        v = D_VOL       : double,   1.0 = +0dB etc
--        p = D_PAN       : double,   -1..+1
--        P = D_PANLAW    : double,   1.0=+0.0db, 0.5=-6dB, -1.0 = projdef etc
--        s = I_SENDMODE  : int,      0=post-fader, 1=pre-fx, 2=post-fx (deprecated), 3=post-fx
--        a = I_AUTOMODE  : int :     auto mode (-1=use track automode, 0=trim/off, 1=read, 2=touch, 3=write, 4=latch)
--        c = I_SRCCHAN   : int,      index,&1024=mono, -1 for none
--        C = I_DSTCHAN   : int,      index, &1024=mono, otherwise stereo pair, hwout:&512=rearoute
--        I = I_MIDIFLAGS : int,      low 5 bits=source channel 0=all, 1-16, next 5 bits=dest channel, 0=orig, 1-16=chanSee CreateTrackSend, RemoveTrackSend, GetTrackNumSends.
--

-- boolean reaper.SetTrackSendInfo_Value(tr, int categ, int sidx, str pname, num newval)
```
