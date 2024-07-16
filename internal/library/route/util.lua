local log = require("utils.log")
local midi_util = require("utils.midi")

local route_util = {}

function route_util.get_num_routes_by_category(tr, cat)
    return reaper.GetTrackNumSends(tr, cat)
end

local T_route_info_params = {
    B_MUTE = {
        type = "bool",
        name = "B_MUTE",
    },
    B_PHASE = { type = "bool", name = "B_PHASE", description = "True to flip the phase." },
    B_MONO = { type = "bool", name = "B_MONO" },
    -- D_VOL : double * : 1.0 = +0dB etc
    D_VOL = { type = "double", name = "D_VOL", description = "1.0 = +0dB etc" },
    -- D_PAN : double * : -1..+1
    D_PAN = { type = "double", name = "D_PAN", description = "-1...+1", min = -1, max = 1 },
    -- D_PANLAW : double * :
    D_PANLAW = { type = "double", name = "D_PANLAW", description = "1.0=+0.0db, 0.5=-6dB, -1.0 = projdef etc" },
    -- I_SENDMODE : int * :
    I_SENDMODE = {
        type = "int",
        name = "I_SENDMODE",
        description = "0=post-fader, 1=pre-fx, 2=post-fx (deprecated), 3=post-fx",
    },
    -- I_AUTOMODE : int * :
    I_AUTOMODE = {
        type = "int",
        name = "I_AUTOMODE",
        description = "automation mode (-1=use track automode, 0=trim/off, 1=read, 2=touch, 3=write, 4=latch)",
        min = -1,
        max = 4,
    },
    -- I_SRCCHAN : int * :
    I_SRCCHAN = {
        type = "bitfield",
        name = "I_SRCCHAN",
        description = [[-1 for no audio send. Low 10 bits specify channel
        offset, and higher bits specify channel count. (srcchan>>10) == 0 for
        stereo, 1 for mono, 2 for 4 channel, 3 for 6 channel, etc.]],
    },
    -- I_DSTCHAN : int * :
    I_DSTCHAN = {
        type = "int",
        name = "I_DSTCHAN",
        description = "low 10 bits are destination index, &1024 set to mix to mono.",
    },
    -- I_MIDIFLAGS : int * :
    I_MIDIFLAGS = {
        type = "bitfield",
        name = "I_MIDIFLAGS",
        description = [[low 5 bits=source channel 0=all, 1-16, 31=MIDI send
        disabled, next 5 bits=dest channel, 0=orig, 1-16=chan. &1024 for
        faders-send MIDI vol/pan. (>>14)&255 = src bus (0 for all, 1 for
        normal, 2+). (>>22)&255=destination bus (0 for all, 1 for normal,
        2+)]],
    },
}

function route_util.get_routes_table_by_category(tr, cat, rtype)
    local count_routes_by_cat = route_util.get_num_routes_by_category(tr, cat)

    if count_routes_by_cat == 0 then
        return {}
    end

    local t_routes = {}

    for si = 0, count_routes_by_cat - 1 do
        if cat <= 0 then -- REGULAR SENDS ////////////////////////////////////////////
            -- OTHER TRACK
            local other_tr, other_tr_idx = getOtherTrack(tr, cat, si)
            local _, other_tr_name = reaper.GetTrackName(other_tr)

            -- get all info params
            local b_mute = reaper.GetTrackSendInfo_Value(tr, cat, si, "I_SRCCHAN")

            local src_chan = reaper.GetTrackSendInfo_Value(tr, cat, si, "I_SRCCHAN")
            local dst_chan = reaper.GetTrackSendInfo_Value(tr, cat, si, "I_DSTCHAN")
            local midi_flags = reaper.GetTrackSendInfo_Value(tr, cat, si, "I_MIDIFLAGS")

            -- B_MUTE : bool *
            -- B_PHASE : bool * : true to flip phase
            -- B_MONO : bool *
            -- D_VOL : double * : 1.0 = +0dB etc
            -- D_PAN : double * : -1..+1
            -- D_PANLAW : double * : 1.0=+0.0db, 0.5=-6dB, -1.0 = projdef etc
            -- I_SENDMODE : int * : 0=post-fader, 1=pre-fx, 2=post-fx (deprecated), 3=post-fx
            -- I_AUTOMODE : int * : automation mode (-1=use track automode, 0=trim/off, 1=read, 2=touch, 3=write, 4=latch)
            -- I_SRCCHAN : int * : -1 for no audio send. Low 10 bits specify channel offset, and higher bits specify channel count. (srcchan>>10) == 0 for stereo, 1 for mono, 2 for 4 channel, 3 for 6 channel, etc.
            -- I_DSTCHAN : int * : low 10 bits are destination index, &1024 set to mix to mono.
            -- I_MIDIFLAGS : int * : low 5 bits=source channel 0=all, 1-16, 31=MIDI send disabled, next 5 bits=dest channel, 0=orig, 1-16=chan. &1024 for faders-send MIDI vol/pan. (>>14)&255 = src bus (0 for all, 1 for normal, 2+). (>>22)&255=destination bus (0 for all, 1 for normal, 2+)
            -- P_DESTTRACK : MediaTrack * : destination track, only applies for sends/recvs (read-only)
            -- P_SRCTRACK : MediaTrack * : source track, only applies for sends/recvs (read-only)
            -- P_ENV:<envchunkname : TrackEnvelope * : call with :<VOLENV, :<PANENV, etc appended (read-only)
            -- See CreateTrackSend, RemoveTrackSend, GetTrackNumSends.

            -- extra processing
            local midi_flags_send = midi_util.get_send_flags_src(midi_flags)
            local midi_flags_dest = midi_util.get_send_flags_dest(midi_flags)

            local log_str = string.format(
                "[[(#%i) <%s> `%s` >> %i :: %i -> %i | %i -> %i]]",
                other_tr_idx + 1,
                rtype,
                other_tr_name,
                si,
                src_chan,
                dst_chan,
                midi_flags_send,
                midi_flags_dest
            )
            log.user()

            table.insert(t_routes, {
                type = rtype,
                cat = cat, -- the raw number code for each type
                index = si,
                log_str = log_str,
                other_tr_name = other_tr_name,
                other_tr_idx = other_tr_idx,
                src_chan = src_chan,
                dst_chan = dst_chan,
                midi_flags = midi_flags,
                midi_flags_send = midi_flags_send,
                midi_flags_dst = midi_flags_dest,
            })
        elseif cat > 0 then -- HARDWARE /////////////////////////////////////
        end
    end

    return t_routes
end

return route_util
