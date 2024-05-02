local log = require("utils.log")
local format = require("utils.format")

-- local libit = require("library.items")

local state_interface = require("state_machine.state_interface")
local r = require("utils.reaper")

local tbl = require("utils.table")
local fxu = require("library.fx")

local sx = require("syntax.tracks")
local midi_editor = require("library.midi_editor")

local cust_util = require("custom_actions.utils")

local tracks = {}

--- Return table of track GUIDs matching string
---@return table
tracks.getTrackGuidsByName = function()
    -- TODO: this should already be implemented in the routing UI
    -- refactor and move that function to here.

    local t = {}

    -- get all tracks
    -- for each find pattern
    -- return set
    return t
end

---Return true if a track has items with specified timeline range.
---@param track_obj table (sx track obj)
tracks.has_items_within_timeline_range = function(track_obj, range_start, range_end)
    local track = track_obj.tr or r.getTrackByGUID(track_obj.guid)
    local item_cnt = reaper.GetTrackNumMediaItems(track)
    for i = 0, item_cnt - 1 do
        local item = reaper.GetTrackMediaItem(track, i)
        local D_POSITION = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local D_LENGTH = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        if range_start <= D_POSITION and D_POSITION + D_LENGTH <= range_end then
            return true
        end
    end
    return false
end

tracks.fltr_track_objects = function(opts) end

-- function JProject.prototype:getTracksByName(sPattern, iInstance, find_init, find_plain)
--     -- Search track(s) by name
-- 	-- sPattern: Specify pattern to look for
-- 	-- iInstance: leave empty (or false) to get a TABLE of all the tracks that match the pattern. Specify a number > 0 to get the nth track that matches
-- 	-- The default searches from the first character (find_init = 1) and uses plain string (find_plain = true). See Lua's string.find() for more info
--
--
-- 	local iInstance = iInstance or false
-- 	local find_init = find_init or 1
-- 	local find_plain = find_plain or true
--
--     local tResult = {}
--     local iCount = 0
--
-- 	if type(iInstance) == "number" and iInstance <= 0 then
-- 		jError("project:getTracksByName(), instance <= 0. First instance is 1! iInstance: " .. tostring(iInstance), J_ERROR_ERROR)
-- 		return false
-- 	end
--
--     local iTracks = self.trackcount
--
-- 	for t in self:tracks() do
-- 		if t.name:lower():find(sPattern:lower(), find_init, find_plain) then
-- 			iCount = iCount + 1
--             if iInstance == false then
--                 tResult[#tResult + 1] = t
--             elseif iInstance == iCount then
--                 return t
--             end
--         end
--     end
--
--     if not iInstance then
--         -- return table
--         if #tResult == 0 then
--             return false
--         else
--             return tResult
--         end
--     else
--         -- instance not found
--         return false
--     end
-- end
--
-- function JProject.prototype:getTrackByName(sPattern, iInstance, find_init, find_plain)
-- 	local iInstance = iInstance or 1
-- 	return self:getTracksByName(sPattern, iInstance, find_init, find_plain)
-- end

tracks.get_dimensions_for = function(tr)
    -- I_TCPH : int * : current TCP window height in pixels not including envelopes (read-only)
    local i_tcph = reaper.GetMediaTrackInfo_Value(track, "I_TCPH")

    -- I_TCPY : int * : current TCP window Y-position in pixels relative to top of arrange view (read-only)
    local i_tcpy = reaper.GetMediaTrackInfo_Value(track, "I_TCPY")

    -- I_WNDH : int * : current TCP window height in pixels including envelopes (read-only)
    local i_wndh = reaper.GetMediaTrackInfo_Value(track, "I_WNDH")

    -- I_MCPX : int * : current MCP X-position in pixels relative to mixer container (read-only)
    local i_mcpx = reaper.GetMediaTrackInfo_Value(track, "I_MCPX")

    -- I_MCPY : int * : current MCP Y-position in pixels relative to mixer container (read-only)
    local i_mcpy = reaper.GetMediaTrackInfo_Value(track, "I_MCPY")

    -- I_MCPW : int * : current MCP width in pixels (read-only)
    local i_mcpw = reaper.GetMediaTrackInfo_Value(track, "I_MCPW")

    -- I_MCPH : int * : current MCP height in pixels (read-only)
    local i_mcph = reaper.GetMediaTrackInfo_Value(track, "I_MCPH")

    return {
        tcp_win_height = i_tcph,
        tcp_win_y = i_tcpy,
        tcp_win_yh = i_tcpy + i_tcph,
    }
end

-- FIX: should not return ME if ME is open AND NOT focused.
--
-- option: not to get track tree
--
tracks.get_focused_track_objects = function()
    local context = state_interface.getContext()
    log.debug("get_focused_track_objects/rk context:", context)

    local vtt = sx.getVerifiedTree()

    local focused_track_objects = {}

    if context == "midi" then
        local ME_ACTIVE, ME = midi_editor.getMidiValidContext(hwnd)
        if ME_ACTIVE then
            local take = reaper.MIDIEditor_GetTake(ME.editor)
            local active_midi_take_track = reaper.GetMediaItemTake_Track(take)
            local tr_guid = r.getGUIDByTrack(active_midi_take_track)

            -- TODO: handle drumkit and channelsplitters here
            for _, node in ipairs(vtt.track_list) do
                if node.guid == tr_guid then
                    table.insert(focused_track_objects, node)
                end
            end
        end
    elseif context == "main" then
        local t_sel_trk_indices = cust_util.getSelectedTrackIndices()
        for _, tidx in ipairs(t_sel_trk_indices) do
            -- these should map 1:1 with vtt.track_list
            table.insert(focused_track_objects, vtt.track_list[tidx + 1])
        end
    end

    return focused_track_objects, vtt, context
end

tracks.get_track_info_params = function(track)
    -- Get track numerical-value attributes.
    local t_track_info = {
        -- B_MUTE : bool * : muted
        B_MUTE = reaper.GetMediaTrackInfo_Value(track, "B_MUTE"),
        -- B_PHASE : bool * : track phase inverted
        B_PHASE = reaper.GetMediaTrackInfo_Value(track, "B_PHASE"),
        -- B_RECMON_IN_EFFECT : bool * : record monitoring in effect (current audio-thread playback state, read-only)
        B_RECMON_IN_EFFECT = reaper.GetMediaTrackInfo_Value(track, "B_RECMON_IN_EFFECT"),
        -- IP_TRACKNUMBER : int : track number 1-based, 0=not found, -1=master track (read-only, returns the int directly)
        IP_TRACKNUMBER = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER"),
        -- I_SOLO : int * : soloed, 0=not soloed, 1=soloed, 2=soloed in place, 5=safe soloed, 6=safe soloed in place
        I_SOLO = reaper.GetMediaTrackInfo_Value(track, "I_SOLO"),
        -- B_SOLO_DEFEAT : bool * : when set, if anything else is soloed and this track is not muted, this track acts soloed
        B_SOLO_DEFEAT = reaper.GetMediaTrackInfo_Value(track, "B_SOLO_DEFEAT"),
        -- I_FXEN : int * : fx enabled, 0=bypassed, !0=fx active
        I_FXEN = reaper.GetMediaTrackInfo_Value(track, "I_FXEN"),
        -- I_RECARM : int * : record armed, 0=not record armed, 1=record armed
        I_RECARM = reaper.GetMediaTrackInfo_Value(track, "I_RECARM"),
        -- I_RECINPUT : int * : record input, <0=no input. if 4096 set, input is MIDI and low 5 bits represent channel (0=all, 1-16=only chan), next 6 bits represent physical input (63=all, 62=VKB). If 4096 is not set, low 10 bits (0..1023) are input start channel (ReaRoute/Loopback start at 512). If 2048 is set, input is multichannel input (using track channel count), or if 1024 is set, input is stereo input, otherwise input is mono.
        I_RECINPUT = reaper.GetMediaTrackInfo_Value(track, "I_RECINPUT"),
        -- I_RECMODE : int * : record mode, 0=input, 1=stereo out, 2=none, 3=stereo out w/latency compensation, 4=midi output, 5=mono out, 6=mono out w/ latency compensation, 7=midi overdub, 8=midi replace
        I_RECMODE = reaper.GetMediaTrackInfo_Value(track, "I_RECMODE"),
        -- I_RECMODE_FLAGS : int * : record mode flags, &3=output recording mode (0=post fader, 1=pre-fx, 2=post-fx/pre-fader)
        I_RECMODE_FLAGS = reaper.GetMediaTrackInfo_Value(track, "I_RECMODE_FLAGS"),
        -- I_RECMON : int * : record monitoring, 0=off, 1=normal, 2=not when playing (tape style)
        I_RECINPUT = reaper.GetMediaTrackInfo_Value(track, "I_RECINPUT"),
        -- I_RECMONITEMS : int * : monitor items while recording, 0=off, 1=on
        I_RECMONITEMS = reaper.GetMediaTrackInfo_Value(track, "I_RECMONITEMS"),
        -- B_AUTO_RECARM : bool * : automatically set record arm when selected (does not immediately affect recarm state, script should set directly if desired)
        B_AUTO_RECARM = reaper.GetMediaTrackInfo_Value(track, "B_AUTO_RECARM"),
        -- I_VUMODE : int * : track vu mode, &1:disabled, &30==0:stereo peaks, &30==2:multichannel peaks, &30==4:stereo RMS, &30==8:combined RMS, &30==12:LUFS-M, &30==16:LUFS-S (readout=max), &30==20:LUFS-S (readout=current), &32:LUFS calculation on channels 1+2 only
        I_VUMODE = reaper.GetMediaTrackInfo_Value(track, "I_VUMODE"),
        -- I_AUTOMODE : int * : track automation mode, 0=trim/off, 1=read, 2=touch, 3=write, 4=latch
        I_AUTOMODE = reaper.GetMediaTrackInfo_Value(track, "I_AUTOMODE"),
        -- I_NCHAN : int * : number of track channels, 2-128, even numbers only
        I_NCHAN = reaper.GetMediaTrackInfo_Value(track, "I_NCHAN"),
        -- I_SELECTED : int * : track selected, 0=unselected, 1=selected
        I_SELECTED = reaper.GetMediaTrackInfo_Value(track, "I_SELECTED"),
        -- I_WNDH : int * : current TCP window height in pixels including envelopes (read-only)
        I_WNDH = reaper.GetMediaTrackInfo_Value(track, "I_WNDH"),
        -- I_TCPH : int * : current TCP window height in pixels not including envelopes (read-only)
        I_TCPH = reaper.GetMediaTrackInfo_Value(track, "I_TCPH"),
        -- I_TCPY : int * : current TCP window Y-position in pixels relative to top of arrange view (read-only)
        I_TCPY = reaper.GetMediaTrackInfo_Value(track, "I_TCPY"),
        -- I_MCPX : int * : current MCP X-position in pixels relative to mixer container (read-only)
        I_MCPX = reaper.GetMediaTrackInfo_Value(track, "I_MCPX"),
        -- I_MCPY : int * : current MCP Y-position in pixels relative to mixer container (read-only)
        I_MCPY = reaper.GetMediaTrackInfo_Value(track, "I_MCPY"),
        -- I_MCPW : int * : current MCP width in pixels (read-only)
        I_MCPW = reaper.GetMediaTrackInfo_Value(track, "I_MCPW"),
        -- I_MCPH : int * : current MCP height in pixels (read-only)
        I_MCPH = reaper.GetMediaTrackInfo_Value(track, "I_MCPH"),
        -- I_FOLDERDEPTH : int * : folder depth change, 0=normal, 1=track is a folder parent, -1=track is the last in the innermost folder, -2=track is the last in the innermost and next-innermost folders, etc
        I_FOLDERDEPTH = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH"),
        -- I_FOLDERCOMPACT : int * : folder collapsed state (only valid on folders), 0=normal, 1=collapsed, 2=fully collapsed
        I_FOLDERCOMPACT = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT"),
        -- I_MIDIHWOUT : int * : track midi hardware output index, <0=disabled, low 5 bits are which channels (0=all, 1-16), next 5 bits are output device index (0-31)
        I_MIDIHWOUT = reaper.GetMediaTrackInfo_Value(track, "I_MIDIHWOUT"),
        -- I_PERFFLAGS : int * : track performance flags, &1=no media buffering, &2=no anticipative FX
        I_PERFFLAGS = reaper.GetMediaTrackInfo_Value(track, "I_PERFFLAGS"),
        -- I_CUSTOMCOLOR : int * : custom color, OS dependent color|0x1000000 (i.e. ColorToNative(r,g,b)|0x1000000). If you do not |0x1000000, then it will not be used, but will store the color
        I_CUSTOMCOLOR = reaper.GetMediaTrackInfo_Value(track, "I_CUSTOMCOLOR"),
        -- I_HEIGHTOVERRIDE : int * : custom height override for TCP window, 0 for none, otherwise size in pixels
        I_HEIGHTOVERRIDE = reaper.GetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE"),
        -- I_SPACER : int * : 1=TCP track spacer above this trackB_HEIGHTLOCK : bool * : track height lock (must set I_HEIGHTOVERRIDE before locking)
        I_SPACER = reaper.GetMediaTrackInfo_Value(track, "I_SPACER"),
        -- D_VOL : double * : trim volume of track, 0=-inf, 0.5=-6dB, 1=+0dB, 2=+6dB, etc
        D_VOL = reaper.GetMediaTrackInfo_Value(track, "D_VOL"),
        -- D_PAN : double * : trim pan of track, -1..1
        D_PAN = reaper.GetMediaTrackInfo_Value(track, "D_PAN"),
        -- D_WIDTH : double * : width of track, -1..1
        D_WIDTH = reaper.GetMediaTrackInfo_Value(track, "D_WIDTH"),
        -- D_DUALPANL : double * : dualpan position 1, -1..1, only if I_PANMODE==6
        D_DUALPANL = reaper.GetMediaTrackInfo_Value(track, "D_DUALPANL"),
        -- D_DUALPANR : double * : dualpan position 2, -1..1, only if I_PANMODE==6
        D_DUALPANR = reaper.GetMediaTrackInfo_Value(track, "D_DUALPANR"),
        -- I_PANMODE : int * : pan mode, 0=classic 3.x, 3=new balance, 5=stereo pan, 6=dual pan
        I_PANMODE = reaper.GetMediaTrackInfo_Value(track, "I_PANMODE"),
        -- D_PANLAW : double * : pan law of track, <0=project default, 0.5=-6dB, 0.707..=-3dB, 1=+0dB, 1.414..=-3dB with gain compensation, 2=-6dB with gain compensation, etc
        D_PANLAW = reaper.GetMediaTrackInfo_Value(track, "D_PANLAW"),
        -- I_PANLAW_FLAGS : int * : pan law flags, 0=sine taper, 1=hybrid taper with deprecated behavior when gain compensation enabled, 2=linear taper, 3=hybrid taper
        I_PANLAW_FLAGS = reaper.GetMediaTrackInfo_Value(track, "I_PANLAW_FLAGS"),
        -- P_ENV:<envchunkname or P_ENV:{GUID... : TrackEnvelope * : (read-only) chunkname can be <VOLENV, <PANENV, etc; GUID is the stringified envelope GUID.
        P_ENV = reaper.GetMediaTrackInfo_Value(track, "P_ENV"),
        -- B_SHOWINMIXER : bool * : track control panel visible in mixer (do not use on master track)
        B_SHOWINMIXER = reaper.GetMediaTrackInfo_Value(track, "B_SHOWINMIXER"),
        -- B_SHOWINTCP : bool * : track control panel visible in arrange view (do not use on master track)
        B_SHOWINTCP = reaper.GetMediaTrackInfo_Value(track, "B_SHOWINTCP"),
        -- B_MAINSEND : bool * : track sends audio to parent
        B_MAINSEND = reaper.GetMediaTrackInfo_Value(track, "B_MAINSEND"),
        -- C_MAINSEND_OFFS : char * : channel offset of track send to parent
        C_MAINSEND_OFFS = reaper.GetMediaTrackInfo_Value(track, "C_MAINSEND_OFFS"),
        -- C_MAINSEND_NCH : char * : channel count of track send to parent (0=use all child track channels, 1=use one channel only)
        C_MAINSEND_NCH = reaper.GetMediaTrackInfo_Value(track, "C_MAINSEND_NCH"),
        -- I_FREEMODE : int * : 1=track free item positioning enabled, 2=track fixed lanes enabled (call UpdateTimeline() after changing)
        I_FREEMODE = reaper.GetMediaTrackInfo_Value(track, "I_FREEMODE"),
        -- I_NUMFIXEDLANES : int * : number of track fixed lanes (fine to call with setNewValue, but returned value is read-only)
        I_NUMFIXEDLANES = reaper.GetMediaTrackInfo_Value(track, "I_NUMFIXEDLANES"),
        -- C_LANESCOLLAPSED : char * : fixed lane collapse state (1=lanes collapsed, 2=track displays as non-fixed-lanes but hidden lanes exist)
        C_LANESCOLLAPSED = reaper.GetMediaTrackInfo_Value(track, "C_LANESCOLLAPSED"),
        -- C_LANEPLAYS:N : char * : in fixed lane tracks, 0=lane N does not play, 1=lane N plays exclusively, 2=lane N plays and other lanes also play (fine to call with setNewValue, but returned value is read-only)
        C_LANEPLAYS = reaper.GetMediaTrackInfo_Value(track, "C_LANEPLAYS"),
        -- C_BEATATTACHMODE : char * : track timebase, -1=project default, 0=time, 1=beats (position, length, rate), 2=beats (position only)
        C_BEATATTACHMODE = reaper.GetMediaTrackInfo_Value(track, "C_BEATATTACHMODE"),
        -- F_MCP_FXSEND_SCALE : float * : scale of fx+send area in MCP (0=minimum allowed, 1=maximum allowed)
        F_MCP_FXSEND_SCALE = reaper.GetMediaTrackInfo_Value(track, "F_MCP_FXSEND_SCALE"),
        -- F_MCP_FXPARM_SCALE : float * : scale of fx parameter area in MCP (0=minimum allowed, 1=maximum allowed)
        F_MCP_FXPARM_SCALE = reaper.GetMediaTrackInfo_Value(track, "F_MCP_FXPARM_SCALE"),
        -- F_MCP_SENDRGN_SCALE : float * : scale of send area as proportion of the fx+send total area (0=minimum allowed, 1=maximum allowed)
        F_MCP_SENDRGN_SCALE = reaper.GetMediaTrackInfo_Value(track, "F_MCP_SENDRGN_SCALE"),
        -- F_TCP_FXPARM_SCALE : float * : scale of TCP parameter area when TCP FX are embedded (0=min allowed, default, 1=max allowed)
        F_TCP_FXPARM_SCALE = reaper.GetMediaTrackInfo_Value(track, "F_TCP_FXPARM_SCALE"),
        -- I_PLAY_OFFSET_FLAG : int * : track media playback offset state, &1=bypassed, &2=offset value is measured in samples (otherwise measured in seconds)
        I_PLAY_OFFSET_FLAG = reaper.GetMediaTrackInfo_Value(track, "I_PLAY_OFFSET_FLAG"),
        -- D_PLAY_OFFSET : double * : track media playback offset, units depend on I_PLAY_OFFSET_FLAG
        D_PLAY_OFFSET = reaper.GetMediaTrackInfo_Value(track, "D_PLAY_OFFSET"),
        -- P_PARTRACK : MediaTrack * : parent track (read-only)
        -- P_PARTRACK = reaper.GetMediaTrackInfo_Value(track, "P_PARTRACK"),
        -- P_PROJECT : ReaProject * : parent project (read-only)
        -- P_PROJECT = reaper.GetMediaTrackInfo_Value(track, "P_PROJECT"),
    }
    return t_track_info
end

--
--
--
--
--
--
--
--
-- FIX: rename -> the current name is a bit misleading
--
--
-- TEST: does this function work from all aspects, as standalone passed with tobj,
-- from main selection, or from ME?
--
--
-- NOTE: only targets first instance of effect_name found
--
-- TODO: add rec_fx
--
-- TODO: move everything that pertains to fx over into lib.fx but
-- keep the track selection in this file.
--
--
tracks.focus_tracks_fx_do = function(meta, opts)
    -- log.user("plugname", format.block(plugin_name))

    local plugin_name = opts[1]
    local callback = opts[2]

    -- FIX: this has to be passed to the fx lib
    local target_trk_objects, vtt = tracks.get_focused_track_objects()

    for _, tobj in pairs(target_trk_objects) do
        local fx_obj = fxu.get_fx_objs_by_name_string(tobj.guid, plugin_name)

        if not fx_obj then
            log.debug(
                string.format([[ [plugins.randomize_rs5k_...]: %s has no RS5K to load with samples..]], tobj.name)
            )
        else
            local ok, fx_mod = pcall(require, "plugins." .. plugin_name)
            if not ok then
                log.debug("fx has no module or doesn't exist")
            end

            -- if is_rec_fx then
            --   Pcall, FXGUID = pcall(reaper.TrackFX_GetFXGUID, tr, REC_FX + idx_fx)
            -- else
            --   Pcall, FXGUID = pcall(reaper.TrackFX_GetFXGUID, tr, idx_fx)
            -- end

            if type(callback) == "string" then
                fx_mod[callback](tobj, fx_obj.idx)
            elseif type(callback) == "function" then
                callback(fx_mod)
            end
        end

        -- -- check that we are working with a midi drum track
        -- if sxlu.trackObjHasOption(gobj, "m") then
        --   rs5k.updateSample(tobj, fx_idx)
        -- else
        --   log.debug(
        --     string.format([[ [plugins.randomize_rs5k_...]: %s has no RS5K to load with samples..]], tobj.name)
        --   )
        -- end
    end
end

return tracks
