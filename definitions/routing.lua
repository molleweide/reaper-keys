-- default values when creating routes
return {
  default_params = {

    -- required
    ["d"] = 0, -- dstTrIdx    : int

    ["k"] = 0, -- category    : int,      is <0 for receives, 0=sends, >0 for hardware outputs
    ["i"] = 0, -- send_idx    : int
    ["m"] = 0, -- B_MUTE      : bool
    ["f"] = 0, -- B_PHASE     : bool,     true to flip phase
    ["M"] = 0, -- B_MONO      : bool
    ["v"] = 0, -- D_VOL       : double,   1.0 = +0dB etc
    ["p"] = 0, -- D_PAN       : double,   -1..+1
    ["P"] = 0, -- D_PANLAW    : double,   1.0=+0.0db, 0.5=-6dB, -1.0 = projdef etc
    ["s"] = 0, -- I_SENDMODE  : int,      0=post-fader, 1=pre-fx, 2=post-fx (deprecated), 3=post-fx
    ["a"] = 0, -- I_AUTOMODE  : int :     auto mode (-1=use track automode, 0=trim/off, 1=read, 2=touch, 3=write, 4=latch)
    ["c"] = 0, -- I_SRCCHAN   : int,      index,&1024=mono, -1 for none
    ["C"] = 0, -- I_DSTCHAN   : int,      index, &1024=mono, otherwise stereo pair, hwout:&512=rearoute
    ["I"] = 0, -- I_MIDIFLAGS : int,      low 5 bits=source channel 0=all, 1-16, next 5 bits=dest channel, 0=orig, 1-16=chanSee CreateTrackSend, RemoveTrackSend, GetTrackNumSends.
  }
}

-- boolean reaper.SetTrackSendInfo_Value(MediaTrack tr, integer category, integer sendidx, string parmname, number newvalue)
--
-- Set send/receive/hardware output numerical-value attributes, return true on success.
-- category is <0 for receives, 0=sends, >0 for hardware outputs
-- parameter names:
-- B_MUTE : bool *
-- B_PHASE : bool *, true to flip phase
-- B_MONO : bool *
-- D_VOL : double *, 1.0 = +0dB etc
-- D_PAN : double *, -1..+1
-- D_PANLAW : double *,1.0=+0.0db, 0.5=-6dB, -1.0 = projdef etc
-- I_SENDMODE : int *, 0=post-fader, 1=pre-fx, 2=post-fx (deprecated), 3=post-fx
-- I_AUTOMODE : int * : automation mode (-1=use track automode, 0=trim/off, 1=read, 2=touch, 3=write, 4=latch)
-- I_SRCCHAN : int *, index,&1024=mono, -1 for none
-- I_DSTCHAN : int *, index, &1024=mono, otherwise stereo pair, hwout:&512=rearoute
-- I_MIDIFLAGS : int *, low 5 bits=source channel 0=all, 1-16, next 5 bits=dest channel, 0=orig, 1-16=chanSee CreateTrackSend, RemoveTrackSend, GetTrackNumSends.
--
-- number reaper.GetTrackSendInfo_Value(MediaTrack tr, integer category, integer sendidx, string parmname)
--
-- Get send/receive/hardware output numerical-value attributes.
-- category is <0 for receives, 0=sends, >0 for hardware outputs
-- parameter names:
-- B_MUTE : bool *
-- B_PHASE : bool *, true to flip phase
-- B_MONO : bool *
-- D_VOL : double *, 1.0 = +0dB etc
-- D_PAN : double *, -1..+1
-- D_PANLAW : double *,1.0=+0.0db, 0.5=-6dB, -1.0 = projdef etc
-- I_SENDMODE : int *, 0=post-fader, 1=pre-fx, 2=post-fx (deprecated), 3=post-fx
-- I_AUTOMODE : int * : automation mode (-1=use track automode, 0=trim/off, 1=read, 2=touch, 3=write, 4=latch)
-- I_SRCCHAN : int *, index,&1024=mono, -1 for none
-- I_DSTCHAN : int *, index, &1024=mono, otherwise stereo pair, hwout:&512=rearoute
-- I_MIDIFLAGS : int *, low 5 bits=source channel 0=all, 1-16, next 5 bits=dest channel, 0=orig, 1-16=chanP_DESTTRACK : read only, returns MediaTrack *, destination track, only applies for sends/recvs
-- P_SRCTRACK : read only, returns MediaTrack *, source track, only applies for sends/recvs
-- P_ENV:<envchunkname : read only, returns TrackEnvelope *. Call with :<VOLENV, :<PANENV, etc appended.
