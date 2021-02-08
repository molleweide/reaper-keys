local ru = require('custom_actions.utils')
local tb = require('utils.table')
local log = require('utils.log')
local format = require('utils.format')
local rc = require('definitions.routing')
local df = rc.default_params

local routing = {}

local input_placeholder = "(176|177|kick|snare)"
local route_help_str = "route params:\n" .. "\nk int  = category" .. "\ni int  = send idx"
local div = '\n##########################################\n\n'
local div2 = '---------------------------------'

local USER_INPUT_TARGETS_DIV = '|'

--      PRIORITY LIST
--
--      1. coded_sources/dest ( tr / guid / table(tr/guid) )
--
--      2. user extract list source / dest ( num/name_str )
--          (obviously no guids here...)
--
--      TODO
--
--      add dest loop >>> call updateRoutesStateLoop
--
--      `!a/m` should not require `u` ?!?!?!?!?!
--
--            if `u` or `!` current param.disable == true
--
--
--      - cat
--          if RECIEVE src and dest are reversed.
--          you specify the `SRC FROM TR`
--
--      - update send by id?
--
--      - audio ch ranges?
--
--      MUTE SEND
--
--      - nudge volume
--      - nudge pan
--
--      TOGGLE SEND PARAMS
--
--      - mono / stereo
--      - mute
--      - flip phase

--////////////////////////////////////////////////////////////////////////
--  PUBLIC | move to custom ???
--/////////

function routing.create(route_str, coded_sources, coded_dests)
  log.clear()
  local rp = rc
  local _
  if route_str == nil then
    rp.user_input = true
    _, route_str = reaper.GetUserInputs("ENTER ROUTE STRING:", 1, route_help_str, input_placeholder)
  end

  local ret
  ret, rp = extractParamsFromString(rp, route_str)
  if not ret then return end -- something went wrong

  if coded_sources ~= nil then
    local ret
    ret, rp = setRouteTargetGuids(rp, 'src_guids', coded_sources)
  end
  if coded_dests ~= nil then
    local ret
    ret, rp = setRouteTargetGuids(rp, 'dst_guids', coded_dests)
  end

  logrp(rp) -- log rp

  if confirmRouteCreation(rp) then
    -- move createRoutesLoop(rp, src_t, dest_tr)
  end
end

-- refactor these into one with variable arguments
function routing.removeAllSends(tr) removeAll(tr) end
function routing.removeAllRecieves(tr) removeAll(tr, 1) end
function routing.removeAllBoth(tr) removeAll(tr, 2) end

-- refactor and pet back to log
function routing.logRoutingInfoForSelectedTracks()
  -- log.clear()
  local log_t = ru.getSelectedTracksGUIDs()
  for i = 1, #log_t do
    local tr, tr_idx = ru.getTrackByGUID(log_t[i])
    local _, current_name = reaper.GetTrackName(tr)
    log.user('\n'..div..'\n:: routes for track #' .. tr_idx+1 .. ' `' .. current_name .. '`:')
    log.user('\n\tSENDs:')
    logRoutesByCategory(tr, rc.flags.CAT_SEND)
    log.user('\tRECIEVEs:')
    logRoutesByCategory(tr, rc.flags.CAT_REC)
    log.user('\tHARDWARE:')
    logRoutesByCategory(tr, rc.flags.CAT_HW)
  end
end

function logrp(rp)
  log.user(div, format.block(rp))
end

--////////////////////////////////////////////////////////////////////////
--  UTILS
--/////////

function isSel() return reaper.CountSelectedTracks(0) ~= 0 end

function TableConcat(t1,t2)
  for i=1,#t2 do
    t1[#t1+1] = t2[i]  --corrected bug. if t1[#t1+i] is used, indices will be skipped
  end
  return t1
end

-- TODO
--
-- retval, t
function getMatchedTrackGUIDs(search_name)
  if not search_name then return nil end
  local found = false
  local t = {}
  for i=0, reaper.CountTracks(0) - 1 do
    local tr = reaper.GetTrack(0, i)
    local _, current_name = reaper.GetTrackName(tr)
    if current_name:match(search_name) then
      t[#t+1] = reaper.GetTrackGUID( tr )
      found = true
    end
  end
  if found then return t else return false end
end

-- this function alse is defined in syntax/syntax
function getStringSplitPattern(pString, pPattern)
  local Table = {}  -- NOTE: use {n = 0} in Lua-5.0
  local fpat = "(.-)" .. pPattern
  local last_end = 1
  local s, e, cap = pString:find(fpat, 1)
  while s do
    if s ~= 1 or cap ~= "" then
      table.insert(Table,cap)
    end
    last_end = e+1
    s, e, cap = pString:find(fpat, last_end)
  end
  if last_end <= #pString then
    cap = pString:sub(last_end)
    table.insert(Table, cap)
  end
  return Table
end

--//////////////////////////////////////////////////////////////////////
--  MIDI FLAGS | move to midi utils
--//////////////

--  GET FIRST 5 BITS
function get_send_flags_src(flags) return flags & ((1 << 5)- 1) end

--  GET SECOND 5 BITS
function get_send_flags_dest(flags) return flags >> 5 end

--  GET SRC AND DEST BYTE PREPARED
function create_send_flags(src_ch, dest_ch) return (dest_ch << 5) | src_ch end

--//////////////////////////////////////////////////////////////////////
--  ROUTE STATE LOGGING
--///////////////////////

-- hardware not working....
function getOtherTrack(tr, cat, si)
  local other_tr
  if cat == 0 then
    other_tr = reaper.BR_GetMediaTrackSendInfo_Track(tr, cat, si, 1)
  else
    other_tr = reaper.BR_GetMediaTrackSendInfo_Track(tr, cat, si, 0)
  end
  local other_tr_idx = reaper.GetMediaTrackInfo_Value(other_tr, "IP_TRACKNUMBER") - 1
  return other_tr, other_tr_idx
end

function logRoutesByCategory(tr, cat)
  local num_cat_sends = reaper.GetTrackNumSends(tr, cat)
  if num_cat_sends == 0 then return end
  for si = 0, num_cat_sends-1 do
    if cat <= 0 then -- REGULAR SENDS ////////////////////////////////////////////
      local other_tr, other_tr_idx = getOtherTrack(tr, cat, si)
      local _, other_tr_name = reaper.GetTrackName(other_tr)
      local SRC = reaper.GetTrackSendInfo_Value(tr, cat, si, 'I_SRCCHAN')
      local DST = reaper.GetTrackSendInfo_Value(tr, cat, si, 'I_DSTCHAN')
      local mf = reaper.GetTrackSendInfo_Value(tr, cat, si, 'I_MIDIFLAGS')
      local mfs = get_send_flags_src(mf)
      local mfd = get_send_flags_dest(mf)
      log.user(string.format("\t\t(#%i) `%s` >> %i :: %i -> %i | %i -> %i",
        other_tr_idx, other_tr_name, si, SRC, DST, mfs, mfd))
    elseif cat > 0 then -- HARDWARE /////////////////////////////////////
    end
  end
end

--//////////////////////////////////////////////////////////////////////
--  EXTRACT ROUTE PARAMS
--///////////////////////


function confirmRouteCreation(rp)
  -- LOG FINAL SOURCES TARGETS
  log.user(div, 'list SRC tracks >>>>> \n')
  for i = 1, #rp.src_guids do
    local tr, tr_idx = ru.getTrackByGUID(rp.src_guids[i])
    local ret, src_name = reaper.GetTrackName(tr)
    log.user('\t' .. tr_idx .. ' - ' .. src_name)
  end

  -- LOG FINAL DEST TARGETS
  log.user('\nlist DEST tracks >>>>> \n')
  for i = 1, #rp.dst_guids do
    local tr, tr_idx = ru.getTrackByGUID(rp.dst_guids[i])
    local ret, src_name = reaper.GetTrackName(tr)
    log.user('\t' .. tr_idx .. ' - ' .. src_name)
  end

  log.user('\n>>> confirm route creation y/n')
  local help_str = "` #src: `" .. tostring(#rp.src_guids) ..
  "` #dst: `" .. tostring(#rp.dst_guids) .. "` (y/n)"
  local _, answer = reaper.GetUserInputs("Create new route for track:", 1, help_str, "")
  if answer ~= "y" then return true end
  return false
end


--    key = src_guid/dst_guids
--    new_track_data = (tr / tr_guid / tr_name / table)
--
--
--    if
--
--
--
--
--
--
--
--  TODO
--
--  merge into setRouteTargets

-- function assignGUIDsFromUserInput(rp, pSrc, pDst)
--   -- if src_from_str
--   if tonumber(pSrc) ~= nil then
--     local tr = reaper.GetTrack(0, tonumber(pSrc) - 1)
--   rp['src_guids'] = {reaper.GetTrackGUID(tr)} else rp['src_guids'] = getMatchedTrackGUIDs(pSrc)
--   end
--   -- if dst_from_str
--   if tonumber(pDst) ~= nil then
--     local tr = reaper.GetTrack(0, tonumber(pDst) - 1)
--   rp['dst_guids'] = {reaper.GetTrackGUID(tr)} else rp['dst_guids'] = getMatchedTrackGUIDs(pDst)
--   end
--   return rp
-- end

function setRouteTargetGuids(rp, key, new_tracks_data)
  local retval = false
  local log_str = 'new_tracks_data >>> '
  local tr_guids = {}
  -- log.user(key, format.block(type(new_tracks_data)))
  if type(new_tracks_data) ~= 'table' then -- NOT TABLE ::::::::::::::
    if new_tracks_data == '<not_working_yet>' then
      --
    elseif ru.getTrackByGUID(new_tracks_data) ~= false then
      retval = true
      tr_guids = { new_tracks_data }
    else
      retval = false
      log.user('new tracks data NOT table but did not pass as TRACK/GUID')
    end

  else -- TABLE :::::::::::::::::::::::::::::::::::::::::::::::::::::
    retval = true
    for i = 1, #new_tracks_data do
      if new_tracks_data == '<not_working_yet>' then
        --
      elseif ru.getTrackByGUID(new_tracks_data[i]) ~= false then
        tr_guids[i] = new_tracks_data[i]

      elseif tonumber(new_tracks_data[i]) ~= nil then
        local tr = reaper.GetTrack(0, tonumber(new_tracks_data[i]) - 1)
        local guid_from_tr = ru.getGUIDByTrack(tr)
        tr_guids[i] = guid_from_tr

      else
        local match_t = getMatchedTrackGUIDs(new_tracks_data[i])
        local tr_guids = TableConcat(tr_guids, match_t)
      end
    end -- for
  end -- table

  if retval then rp[key] = tr_guids end
  return retval, rp
end

function removeEnclosureFromString(str, encl_type)
  for r in str:gmatch ("%b"..encl_type) do
    str = str:gsub("%("..r.."%)", "")
  end
  return str
end

function extractParenthesisTargets(str)
  local pcount = 0
  for p in str:gmatch "%b()" do
    pcount = pcount + 1
    if pcount == 1 then pDest = str.sub(p, 2, str.len(p) - 1) end
    if pcount == 2 then
      pSrc = pDest
      pDest = str.sub(p, 2, str.len(p) - 1)
      break
    end
  end
  str = removeEnclosureFromString(str, '()')
  return retval, pSrc, pDest, str
end

function getEnclosers(str, encl)
  local data
  for p in str:gmatch ("%b"..encl) do
    data = str.sub(p, 2, str.len(p) - 1)
  end
  str = removeEnclosureFromString(str, encl)
  return data, str
end

function inputHasChar(str, key)
  local pattern = "!?" .. key .. "%d?%.?%d?%d?%d?%d?" -- very generic pattern
  local s, e = string.find(str, pattern)
  local mv_offset = 1
  local retval = false
  local matched_value
  local prefix

  if s ~= nil and e ~= nil then
    retval = true
    local sub_pattern = string.sub(str,s,e)
    prefix = string.sub(sub_pattern,0,1)
    if prefix == '!' then mv_offset = 2 end
    matched_value = string.sub(str,s+mv_offset,e)
  end

  return retval, matched_value, prefix
end


function getEnclosedChannelData(str, encloser, sep, rangeL, rangeH)
  local dataBracket, str = getEnclosers(str, encloser)
  local bSrc, bDst
  if dataBracket ~= nil then
    local dataBracketSplit = getStringSplitPattern(dataBracket, sep)
    for d=1, #dataBracketSplit do
      local D = tonumber(dataBracketSplit[d])
      if D < rangeL or D > rangeH then D = 0 end
      if d==1 then if D ~= nil then bDst = D else bDst = 0 end end
      if d==2 then
        bSrc = bDst
        if D ~= nil then bDst = D else bDst = 0 end
        break
      end
    end
  end
  return str, bSrc, bDst
end

function handleSecondaryParams(rp, str, key, primary)
  local ret, val, pre = inputHasChar(str, key)
  -- log.user(key, ret, val, pre)

  -- exists or PRIMARY
  if ret or primary ~= nil then

    if primary ~= nil then val = primary else val = tonumber(val) end

    if ret and val == nil then val = df[key].param_value end

    rp.new_params[key] = {
      description = df[key].description,
      param_name = df[key].param_name,
      param_value = val,
    }

    -- exists and prefix
    if ret and pre == '!' then rp.new_params[key].param_value = df[key].disable_value end
  end

  return rp, str
end

function extractParamsFromString(rp, str)
  -- HANDLE PARENTHESIS
  local ret, src_tr_data, dst_tr_data, str = extractParenthesisTargets(str)
  if src_tr_data ~= nil and rp.userInput then -- SRC PROVIDED
    local src_tr_split =  getStringSplitPattern(src_tr_data, USER_INPUT_TARGETS_DIV)
    local ret, rp = setRouteTargetGuids(rp, 'src_guids', src_tr_split)
  elseif isSel() then -- FALLBACK SRC SEL
    rp.src_from_selection = true
    rp['src_guids'] = ru.getSelectedTracksGUIDs()
  else -- NO SRC ERR..
    log.user('ERROR: no src targets was provided')
    return false, rp
  end


  if dst_tr_data ~= nil then
    local dst_tr_split =  getStringSplitPattern(dst_tr_data, USER_INPUT_TARGETS_DIV)
    local ret, rp = setRouteTargetGuids(rp, 'dst_guids', dst_tr_split)
  else
    log.user('ERROR: no DST targets was provided')
    return false, rp
  end

  -- rp = assignGUIDsFromUserInput(rp, src_tr_data, dst_tr_data)


  -- A. HANDLE PRIMARY COMMANDS

  str, bSrc, bDst = getEnclosedChannelData(str, '[]', '|', 0, 6)

  str, cSrc, cDst = getEnclosedChannelData(str, '{}', '|', 0, 16)

  -- B. HANDLE SECONDARY PARAMS

  rp, str = handleSecondaryParams(rp, str, 'a', bSrc)

  rp, str = handleSecondaryParams(rp, str, 'd', bDst)

  local midi_flags
  if cSrc ~= nil and cDst ~= nil then midi_flags = create_send_flags(cSrc,cDst) end
  -- log.user(cSrc, cDst, midi_flags)
  rp, str = handleSecondaryParams(rp, str, 'm', midi_flags)

  ret, val, pre = inputHasChar(str, 'u')
  if ret then rp.overwrite = true end

  return true, rp
end

--//////////////////////////////////////////////////////////////////////
--  GET ROUTE STATE
--////////////////

function getPrevRouteState(src_tr, dest_tr, rp)
  rp.prev = 0
  for si=0,  reaper.GetTrackNumSends( src_tr, 0 ) do
    local dest_tr_check = reaper.BR_GetMediaTrackSendInfo_Track( src_tr, 0, si, 1 )
    if dest_tr_check == dest_tr then
      local prev_src_midi_flags = reaper.GetTrackSendInfo_Value(src_tr, 0, si, 'I_MIDIFLAGS')
      local prev_src_audio_ch = reaper.GetTrackSendInfo_Value(src_tr, 0, si, 'I_SRCCHAN')
      local retval = 3 -- both audio and midi
      rp.prev = 3
      local no_midi = prev_src_midi_flags == rc.flags.MIDI_OFF
      local no_audio = prev_src_audio_ch ==  rc.flags.AUDIO_SRC_OFF
      -- only audio = 1
      if no_midi then rp.prev = 1 end
      -- only midi = 2
      if no_audio then rp.prev = 2 end
      return rp, si
    end
  end
  return rp
end

function getNextRouteState(rp, check_str)

  if (rp.new_params['a'] ~= nil and rp.new_params['m'] == nil) or
    (rp.new_params['a'] == nil and rp.new_params['m'] == nil) then
    rp.next = 1
    rp.new_params['m'] = {
      description = df['m'].description,
      param_name = df['m'].param_name,
      param_value = rc.flags.MIDI_OFF,
    }
  elseif rp.new_params['a'] == nil and rp.new_params['m'] ~= nil then
    rp.next = 2
    rp.new_params['a'] = {
      description = df['a'].description,
      param_name = df['a'].param_name,
      param_value = rc.flags.AUDIO_SRC_OFF,
    }
  elseif rp.new_params['a'] == nil and rp.new_params['m'] ~= nil then
    rp.next = 3 -- add both
  end
  return rp -- we should never arrive here i think since default always is add audio send
end

--////////////////////////////////////////////////////////////////////
--  REMOVE ROUTES
--/////////////////

function deleteRouteIfEmpty(src_tr, rid)
  local i_src_ch = reaper.GetTrackSendInfo_Value(src_tr, 0, rid, 'I_SRCCHAN')
  local i_src_midi = reaper.GetTrackSendInfo_Value(src_tr, 0, rid, 'I_MIDIFLAGS')
  if i_src_ch == rc.flags.AUDIO_SRC_OFF and i_src_midi == rc.flags.MIDI_OFF then
    log.user('::delete send ' .. rid .. '::')
    removeSingle(src_tr, 0, rid)
  end
end

function removeSingle(tr, cat, sendidx)
  local ret = reaper.RemoveTrackSend(tr, cat, sendidx)
end

function deleteByCategory(tr, cat)
  local num_cat_sends = reaper.GetTrackNumSends(tr, cat)
  -- if num_cat_sends == 0 then return end
  while(num_cat_sends > 0) do
    for si=0, num_cat_sends-1 do
      local rm = reaper.RemoveTrackSend(tr, cat, si)
    end
    num_cat_sends = reaper.GetTrackNumSends(tr, cat)
  end
end

function removeAll(tr, kind)
  log.clear()
  log.user('removeAll')
  local target_t = {}
  target_t[#target_t] = tr
  if tr == nil or tr == false then target_t = ru.getSelectedTracksGUIDs() end -- get table of src tracks
  -- FOR EACH TRACK WE WANT TO TARGET
  for i = 1, #target_t do
    local tr = ru.getTrackByGUID(target_t[i])
    if kind == nil or kind == 0 then
      deleteByCategory(tr, rc.flags.CAT_SEND)
    elseif kind == 1 then
      deleteByCategory(tr, rc.flags.CAT_REC)
    elseif kind == 2 then
      deleteByCategory(tr, rc.flags.CAT_SEND)
      deleteByCategory(tr, rc.flags.CAT_REC)
    end
  end
  return true
end

--///////////////////////////////////////////////////////////////////////
--  UPDATE ROUTE STATE
--//////////////////////


-- TODO
--
--  dest_tr param should be DST_GUIDS
--    double loop
--
--      for src
--        for dst
--          do...............
function createRoutesLoop(rp, SRC_GUIDS, dest_tr)
  for i = 1, #SRC_GUIDS do
    local src_tr =  reaper.BR_GetMediaTrackByGUID( 0, SRC_GUIDS[i] )
    local rp, rid = getPrevRouteState(src_tr, dest_tr, rp)
    local rp = getNextRouteState(rp)
    if rp.prev == 0 then rid = reaper.CreateTrackSend(src_tr, dest_tr) end
    updateRouteState_Track(src_tr, rp, rid)
    deleteRouteIfEmpty(src_tr, rid)
  end
  -- log.user(format.block(rp))
end

function updateRouteState_Track(src_tr, rp, rid)
  -- log.user(format.block(rp))
  -- HANDLE MONO ?!?!
  -- if dest_tr_ch == 2 then
  --   reaper.SetTrackSendInfo_Value( src_tr, 0, new_rid, 'I_SRCCHAN',0)
  -- else
  --   reaper.SetTrackSendInfo_Value( src_tr, 0, new_rid, 'I_SRCCHAN',0|(1024*math.floor(src_tr_ch/2)))
  -- end

  for k, p in pairs(rp.new_params) do
    log.user(p.param_name .. '  ' .. tostring(p.param_value))
    if k == 'm' then

      -- skipp if previous route component exists and not overwrite flag
      if (rp.prev == 2 or rp.prev == 3) and not rp.overwrite then goto continue end

      -- next is only audio and first
      if rp.next == 1 and rp.prev ~= 0 then goto continue end

      reaper.SetTrackSendInfo_Value(src_tr, 0, rid, p.param_name, p.param_value)
    else

      -- skipp if previous route component exists and not overwrite flag
      if (rp.prev == 1 or rp.prev == 3) and not rp.overwrite then goto continue end

      -- next is only midi and first
      if rp.next == 2 and rp.prev ~= 0 then goto continue end


      reaper.SetTrackSendInfo_Value(src_tr, 0, rid, p.param_name, p.param_value)
    end
    :: continue ::
  end
end

--//////////////////////////////////////////////////////////////////////
--  FUTURE??
--////////////

-- TODO
--
-- remove this function

-- replace this function in Syntax with my new route_str
function routing.createSingleMIDISend(src_tr,dest_tr,dest_chan)
  log.user('createSingleMIDISend')
  local is_exist = getPrevRouteState(src_tr, dest_tr)

  -- TODO if dest_chan == nil then set to 0 (ALL)

  log.user('midi sends exists ???????  : ' .. tostring(is_exist))
  if not is_exist then
    local midi_send_id = reaper.CreateTrackSend(src_tr, dest_tr) -- create send; return sendidx for reference
    local new_midi_flags = create_send_flags(0, dest_chan)
    reaper.SetTrackSendInfo_Value(src_tr, rc.flags.CAT_SEND, midi_send_id, "I_MIDIFLAGS", new_midi_flags) -- set midi_flags on reference
    reaper.SetTrackSendInfo_Value(src_tr, rc.flags.CAT_SEND, midi_send_id, "I_SRCCHAN", rc.flags.AUDIO_SRC_OFF)
  end
end

-- rm ????????
function incrementDestChanToSrc(dest_tr, src_tr_ch)
  local dest_tr_ch = reaper.GetMediaTrackInfo_Value( dest_tr, 'I_NCHAN')
  if dest_tr_ch < src_tr_ch then reaper.SetMediaTrackInfo_Value( dest_tr, 'I_NCHAN', src_tr_ch ) end
  return dest_tr_ch
end

function preventRouteFeedback()
end

------------------------------------------------------------------------

return routing
