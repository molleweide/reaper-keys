return {
    -- SetTrackSendInfo_Value below --------------
  default_params = {
    ["v"] = {
      description = 'VOLUME | double, 1.0 = +0dB',
      param_name = 'D_VOL',
      param_value = 0.8
    },
    -- ["s"] = {
    --   description = 'SENDMODE | int, 0=post-fader, 1=pre-fx, 2=post-fx (deprecated), 3=post-fx',
    --   param_name = 'I_SENDMODE',
    --   param_value = 3
    -- },

    -- commented >>> always default to send
    -- ["k"] = {
    --   param_name = 'CATEGORY',
    --   param_value = 0, -- int, is <0 for receives, 0=sends, >0 for hardware outputs
    -- },

    -- ["i"] = {
    --   param_name = 'SEND_IDX',
    --   param_value = 0,
    -- }, -- send_idx    : int
    -- ["m"] = {
    --   param_name = 'B_MUTE',
    --   param_value = 0, -- bool
    -- },
    -- ["f"] = {
    --   param_name = 'B_PHASE',
    --   param_value = 0, -- bool
    -- },
    -- ["M"] = {
    --   param_name = 'B_MONO',
    --   param_value = 0, -- bool
    -- },
    -- ["p"] = {
    --   param_name = 'D_PAN',
    --   param_value = 0, -- double,   -1..+1
    -- },
    -- ["P"] = {
    --   param_name = 'D_PANLAW',
    --   param_value = 0, -- double,   1.0=+0.0db, 0.5=-6dB, -1.0 = projdef etc
    -- },
    -- ["a"] = {
    --   param_name = 'I_AUTOMODE',
    --   param_value = 0, -- int :     auto mode (-1=use track automode, 0=trim/off, 1=read, 2=touch, 3=write, 4=latch)
    -- },
    -- ["c"] = {
    --   description = 'SOURCE CHAN | int, index, &1024=mono, -1 for none',
    --   param_name = 'I_SRCCHAN',
    --   param_value = 0,
    -- },
    -- ["C"] = {
    --   description = 'DEST CHAN | int, index, &1024=mono, -1 for none',
    --   param_name = 'I_DSTCHAN',
    --   param_value = 0, -- int,      index, &1024=mono, otherwise stereo pair, hwout:&512=rearoute
    -- },
    -- ["I"] = {
    --   param_name = 'I_MIDIFLAGS',
    --   param_value = 0, -- int,      low 5 bits=source channel 0=all, 1-16, next 5 bits=dest channel, 0=orig, 1-16=chan
    -- },
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


-- MediaTrack reaper.BR_GetMediaTrackSendInfo_Track(MediaTrack track, integer category, integer sendidx, integer trackType)
--
-- [BR] Get source or destination media track for send/receive.
--
-- category is <0 for receives, 0=sends
-- sendidx is zero-based (see GetTrackNumSends to count track sends/receives)
-- trackType determines which track is returned (0=source track, 1=destination track)
