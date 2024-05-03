local log = require("utils.log")
local midi_util = require("utils.midi")

local route_util = {}

function route_util.get_num_routes_by_category(tr, cat)
    return reaper.GetTrackNumSends(tr, cat)
end

function route_util.get_routes_table_by_category(tr, cat, rtype)
    local count_routes_by_cat = route_util.get_num_routes_by_category(tr, cat)

    if count_routes_by_cat == 0 then
        return {}
    end

    local t_routes = {}

    for si = 0, count_routes_by_cat - 1 do
        if cat <= 0 then -- REGULAR SENDS ////////////////////////////////////////////
            local other_tr, other_tr_idx = getOtherTrack(tr, cat, si)
            local _, other_tr_name = reaper.GetTrackName(other_tr)
            local src = reaper.GetTrackSendInfo_Value(tr, cat, si, "I_SRCCHAN")
            local dst = reaper.GetTrackSendInfo_Value(tr, cat, si, "I_DSTCHAN")
            local mf = reaper.GetTrackSendInfo_Value(tr, cat, si, "I_MIDIFLAGS")
            local mfs = midi_util.get_send_flags_src(mf)
            local mfd = midi_util.get_send_flags_dest(mf)
            local log_str = string.format(
                "[[(#%i) <%s> `%s` >> %i :: %i -> %i | %i -> %i]]",
                other_tr_idx + 1,
                rtype,
                other_tr_name,
                si,
                src,
                dst,
                mfs,
                mfd
            )
            log.user()

            table.insert(t_routes, {
                type = rtype,
                index = si,
                log_str = log_str,
                other_tr_name = other_tr_name,
                other_tr_idx = other_tr_idx,
                src = src,
                dst = dst,
                midi_flags = mf,
                midi_flags_send = mfs,
                midi_flags_dst = mfd,
            })
        elseif cat > 0 then -- HARDWARE /////////////////////////////////////
        end
    end

    return t_routes
end

return route_util
