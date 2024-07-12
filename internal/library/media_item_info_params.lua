-- NOTE: retval, stringNeedBig = reaper.GetSetMediaItemTakeInfo_String( tk, parmname, stringNeedBig, setNewValue )
--
-- Gets/sets a take attribute string:
-- P_NAME : char * : take name
-- P_EXT:xyz : char * : extension-specific persistent data
-- GUID : GUID * : 16-byte GUID, can query or update. If using a _String() function, GUID is a string {xyz-...}.

-- -- Get name of take
-- take_name = reaper.GetTakeName(reaper.GetActiveTake(reaper.GetSelectedMediaItem(0, i)))

-- new_take_name[i] = take_name .. "_" .. tostring(count)

-- -- Get active take
-- active_take = reaper.GetActiveTake(reaper.GetSelectedMediaItem(0, i))

-- -- Apply new name
-- reaper.GetSetMediaItemTakeInfo_String(active_take, 'P_NAME', new_take_name[i], true)

local T_MEDIA_ITEM_INFO_PARAMS = {
    -- B_MUTE : bool * : muted (item solo overrides). setting this value will clear C_MUTE_SOLO.
    -- B_MUTE_ACTUAL : bool * : muted (ignores solo). setting this value will not affect C_MUTE_SOLO.
    -- C_LANEPLAYS : char * : in fixed lane tracks, 0=this item lane does not play, 1=this item lane plays exclusively, 2=this item lane plays and other lanes also play (read-only)
    -- C_MUTE_SOLO : char * : solo override (-1=soloed, 0=no override, 1=unsoloed). note that this API does not automatically unsolo other items when soloing (nor clear the unsolos when clearing the last soloed item), it must be done by the caller via action or via this API.
    -- B_LOOPSRC : bool * : loop source
    -- B_ALLTAKESPLAY : bool * : all takes play
    -- B_UISEL : bool * : selected in arrange view
    -- C_BEATATTACHMODE : char * : item timebase, -1=track or project default, 1=beats (position, length, rate), 2=beats (position only). for auto-stretch timebase: C_BEATATTACHMODE=1, C_AUTOSTRETCH=1
    -- C_AUTOSTRETCH: : char * : auto-stretch at project tempo changes, 1=enabled, requires C_BEATATTACHMODE=1
    -- C_LOCK : char * : locked, &1=locked
    -- D_VOL : double * : item volume, 0=-inf, 0.5=-6dB, 1=+0dB, 2=+6dB, etc
    D_POSITION = { type = "bool", name = "D_POSITION" }, -- double * : item position in seconds
    D_LENGTH = { type = "double", name = "D_LENGTH" }, -- double * : item length in seconds
    -- D_SNAPOFFSET : double * : item snap offset in seconds
    -- D_FADEINLEN : double * : item manual fadein length in seconds
    -- D_FADEOUTLEN : double * : item manual fadeout length in seconds
    -- D_FADEINDIR : double * : item fadein curvature, -1..1
    -- D_FADEOUTDIR : double * : item fadeout curvature, -1..1
    -- D_FADEINLEN_AUTO : double * : item auto-fadein length in seconds, -1=no auto-fadein
    -- D_FADEOUTLEN_AUTO : double * : item auto-fadeout length in seconds, -1=no auto-fadeout
    -- C_FADEINSHAPE : int * : fadein shape, 0..6, 0=linear
    -- C_FADEOUTSHAPE : int * : fadeout shape, 0..6, 0=linear
    -- I_GROUPID : int * : group ID, 0=no group
    -- I_LASTY : int * : Y-position (relative to top of track) in pixels (read-only)
    -- I_LASTH : int * : height in pixels (read-only)
    -- I_CUSTOMCOLOR : int * : custom color, OS dependent color|0x1000000 (i.e. ColorToNative(r,g,b)|0x1000000). If you do not |0x1000000, then it will not be used, but will store the color
    -- I_CURTAKE : int * : active take number
    -- IP_ITEMNUMBER : int : item number on this track (read-only, returns the item number directly)
    -- F_FREEMODE_Y : float * : free item positioning or fixed lane Y-position. 0=top of track, 1.0=bottom of track
    -- F_FREEMODE_H : float * : free item positioning or fixed lane height. 0.5=half the track height, 1.0=full track height
    -- I_FIXEDLANE : int * : fixed lane of item (fine to call with setNewValue, but returned value is read-only)
    -- B_FIXEDLANE_HIDDEN : bool * : true if displaying only one fixed lane and this item is in a different lane (read-only)
    -- P_TRACK : MediaTrack * : (read-only)
}

local M = {}
M.get_item_info = function(item)
    if not item then
        log.debug("no item passed to get_item_info")
        return
    end
    local D_POSITION = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local D_LENGTH = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local guid = reaper.BR_GetMediaItemGUID(item)
end

M.get_array = function(item)
    local res = {}
    for _, v in pairs(T_MEDIA_ITEM_INFO_PARAMS) do
        v.value = reaper.GetMediaItemInfo_Value(item, v.name)
        table.insert(res, v)
    end
    return res
end

return M
