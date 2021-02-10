local ru = require('custom_actions.utils')
local log = require('utils.log')
local format = require('utils.format')
local rc = require('definitions.routing')
local df = rc.default_params

local routing = {}

local input_placeholder = "(176)aR"
local route_help_str = "route params:\n" .. "\nk int  = category" .. "\ni int  = send idx"
local div = '\n##########################################\n\n'
local div2 = '---------------------------------'

local USER_INPUT_TARGETS_DIV = '|'

--
--      BUG
--
--        upon writing a lot of send funcs I find that CreateTrackSend(track, nil)
--          creates a wierd kind of hwout that i have to remove manually.
--          it does not show up when logging route states
--          no error!!!!!!!!!!!!!!!!!!!!
--
--
--      TODO
--
--      -> cat
--
--        switching src/dst when creating the send did the trick! why??
--
--
--
--
--      -> cust util
--
--        test coded targets >> add new custom bindings
--
--
--      -> syntax apply update()
--
--
--
--
--      -> SYNTAX | only requires sends
--
--          >>> most important for flow
--
--          syntax > update lane mapping w/ routing.create()
--          syntax > if track M:: or A:: and no sends >> route to respective master.
--
--      -> segments
--
--      -> record random stuff w/ empa
--
--
--      `!a/m` should not require `u` ?!?!?!?!?!
--
--            if `u` or `!` current param.disable == true
--
--      -> RECIEVES
--          if RECIEVE src and dest are reversed.
--          you specify the `SRC FROM TR`
--
--      - update send by id?
--
--      - audio ch ranges?
--
--      -> COMMANDS
--
--        switch monitors
--
--
--
--
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


-- TODO
--
-- rename to something general for both create, update, and remove
--
--    routes.update()

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
    rp.coded_targets = true
    ret, rp = setRouteTargetGuids(rp, 'src_guids', coded_sources)
  end
  if coded_dests ~= nil then
    rp.coded_targets = true
    ret, rp = setRouteTargetGuids(rp, 'dst_guids', coded_dests)
  end

  -- make sure there are
  -- local validate, err = validateNewRoute(rp)
  -- if not validate then
  -- end

  -- if rp.category == 1 then
  -- end

  lrp(rp) -- log rp

  -- if rp.category == -1 and not rp.remove_routes then
  --   local tmp = rp.src_guids
  --   rp.src_guids = rp.dst_guids
  --   rp.dst_guids = tmp
  -- end

  if rp.remove_routes then
    handleRemoval(rp)
  elseif confirmRouteCreation(rp) then
    targetLoop(rp)
  else
    log.clear()
    log.user('<ROUTE COMMAND ABORTED>')
  end
end

-- refactor these into one with variable arguments
function routing.removeAllSends(tr) removeAllRoutesTrack(tr) end
function routing.removeAllRecieves(tr) removeAllRoutesTrack(tr, 1) end
function routing.removeAllBoth(tr) removeAllRoutesTrack(tr, 2) end

-- refactor and pet back to log
function routing.logRoutingInfoForSelectedTracks()
  -- log.clear()
  local log_t = ru.getSelectedTracksGUIDs()

  for i = 1, #log_t do
    local tr, tr_idx = ru.getTrackByGUID(log_t[i].guid)
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

function lrp(rp)
  -- log rp
  log.user(div, format.block(rp))
end

--////////////////////////////////////////////////////////////////////////
--  UTILS | mv to reaper util
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
-- retval, t ?
function getMatchedTrackGUIDs(search_name)
  if not search_name then return nil end
  local found = false
  local t = {}
  for i=0, reaper.CountTracks(0) - 1 do
    local tr = reaper.GetTrack(0, i)
    local _, current_name = reaper.GetTrackName(tr)
    if current_name:match(search_name) then
      t[#t+1] = { name = current_name, guid = reaper.GetTrackGUID( tr ) }
      found = true
    end
  end
  if found then return t else return false end
end

-- this function alse is defined in syntax/syntax
--
-- mv to util
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
        other_tr_idx+1, other_tr_name, si, SRC, DST, mfs, mfd))
    elseif cat > 0 then -- HARDWARE /////////////////////////////////////
    end
  end
end

--//////////////////////////////////////////////////////////////////////
--  EXTRACT ROUTE PARAMS
--///////////////////////

function logConfirmList(rp)
  log.user('::: SOURCE TRACKS :::\n')
  for i = 1, #rp.src_guids do
    local tr, tr_idx = ru.getTrackByGUID(rp.src_guids[i].guid)
    local _, src_name = reaper.GetTrackName(tr)
    log.user('\t' .. tr_idx .. ' - ' .. src_name)
  end
  log.user('\n::: DESTINATION TRACKS :::\n')
  for i = 1, #rp.dst_guids do
    local tr, tr_idx = ru.getTrackByGUID(rp.dst_guids[i].guid)
    local _, dst_name = reaper.GetTrackName(tr)
    log.user('\t' .. tr_idx .. ' - ' .. dst_name)
  end
  log.user('\n>>> CONFIRM ROUTE CREATION (y<Enter> -> confirm)\n\n')
end

function logHeader(str)
  log.user(div, str .. '\n\n')
end

function confirmRouteCreation(rp)
  -- LOG FINAL SOURCES TARGETS
  local num_tr_affected = #rp.src_guids*#rp.dst_guids

  local warning_str = 'Tot num routes being affected = '.. num_tr_affected
  local r_u_sure = 'Are you sure you want to do this?'
  logHeader(warning_str)
  -- log.user(div, warning_str)

  logConfirmList(rp)


  local help_str = "` #src: `" .. tostring(#rp.src_guids) ..
  "` #dst: `" .. tostring(#rp.dst_guids) .. "` (y/n)"


  -- rm one of these three prompts

  local _, answer = reaper.GetUserInputs("Create new route for track:", 1, help_str, "")


  if answer == "y" and num_tr_affected > rc.code_tot_route_num_limit and not rp.coded_targets then
    _, answer = reaper.GetUserInputs(r_u_sure, 1, warning_str, "")
  end

  if answer == "y" and num_tr_affected > rc.gui_tot_route_num_limit and rp.coded_targets then
    _, answer = reaper.GetUserInputs(r_u_sure, 1, warning_str, "")
  end

  if answer == "y" then return true end
  return false
end


--    key = src_guid/dst_guids
--    new_track_data = (tr / tr_guid / tr_name / table)
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
      local tr, tr_idx = ru.getTrackByGUID(new_tracks_data[i])
      local _, current_name = reaper.GetTrackName(tr)
      tr_guids = { name = current_name, guid = new_tracks_data }
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
        local tr, tr_idx = ru.getTrackByGUID(new_tracks_data[i])
        local _, current_name = reaper.GetTrackName(tr)
        tr_guids[i] = { name = current_name, guid = new_tracks_data[i] }

      elseif tonumber(new_tracks_data[i]) ~= nil then
        local tr = reaper.GetTrack(0, tonumber(new_tracks_data[i]) - 1)
        local _, current_name = reaper.GetTrackName(tr)

        local guid_from_tr = ru.getGUIDByTrack(tr)
        tr_guids[i] = { name = current_name, guid = guid_from_tr }
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
  if str:find('%-') then
    rp.remove_routes = true
    rp.remove_both = true
  end
  if str:find('S') then
    rp.category = 0
    rp.remove_both = false
  end
  if str:find('R') then
    rp.category = -1
    rp.remove_both = false
  end

  -- HANDLE PARENTHESIS
  local ret, src_tr_data, dst_tr_data, str = extractParenthesisTargets(str)



  if src_tr_data ~= nil and rp.userInput then -- SRC PROVIDED
    local src_tr_split =  getStringSplitPattern(src_tr_data, USER_INPUT_TARGETS_DIV)
    local ret, rp = setRouteTargetGuids(rp, 'src_guids', src_tr_split)
  elseif isSel() then -- FALLBACK SRC SEL
    rp.src_from_selection = true
    rp['src_guids'] = ru.getSelectedTracksGUIDs()
  end


  if dst_tr_data ~= nil then
    local dst_tr_split =  getStringSplitPattern(dst_tr_data, USER_INPUT_TARGETS_DIV)
    local ret, rp = setRouteTargetGuids(rp, 'dst_guids', dst_tr_split)
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
--  VALIDATE NEW ROUTE
--//////////////////////

-- function validateNewRoute(rp)
--   local err = {}
--   -- rp.user_input
--   -- rp.coded_targets
--   if rp.category == 'BOTH' then
--
--   elseif (#rp.src_guids == 0 or #rp.dst_guids == 0) then
--     return ret, err
--   end
-- end

--//////////////////////////////////////////////////////////////////////
--  GET ROUTE STATE
--////////////////

function getPrevRouteState(rp, src_tr, dest_tr)
  local cat = rp.category
  local check_other = 1
  if rp.category == -1 then check_other = 0 end
  rp.prev = 0



  local num_routes_by_cat = reaper.GetTrackNumSends( src_tr, cat )
  log.user('num:::: ' .. num_routes_by_cat)

  for si=0,  num_routes_by_cat do
    local dest_tr_check = reaper.BR_GetMediaTrackSendInfo_Track( src_tr, cat, si, check_other )


    -- local _, current_name = reaper.GetTrackName(dest_tr_check)
    -- log.user('dst check: ' .. current_name)


    if dest_tr_check == dest_tr then
      log.user('prev match!!!!!')
      local prev_src_midi_flags = reaper.GetTrackSendInfo_Value(src_tr, cat, si, 'I_MIDIFLAGS')
      local prev_src_audio_ch = reaper.GetTrackSendInfo_Value(src_tr, cat, si, 'I_SRCCHAN')
      -- local prev_src_hw = reaper.GetTrackSendInfo_Value(src_tr, 1, si, 'I_SRCCHAN')
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


-- TODO
--
-- src and dest are required here
--
--  if no source throw error
--
--    coded targets need to make sure both src/dst are provided

function handleRemoval(rp)
  if #rp.src_guids == 0 then
    -- it is up to user to make sure we have targets
    log.user('REMOVAL ERROR > NO BASE TARGETS')

  elseif #rp.dst_guids == 0 then
    logHeader('REMOVE ALL ROUTES ON BASE')
    logConfirmList(rp)
    removeAllRoutesTrack(rp) -- 2 == both send/rec

  else
    logHeader('src rm > connections btw list src/dst')
    logConfirmList(rp)
    targetLoop(rp)

  end
end

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

function removeAllRoutesTrack(rp)
  log.user('>>> removeAllRoutesTrack')
  for i = 1, #rp.src_guids do
    local tr, tr_idx = ru.getTrackByGUID(rp.src_guids[i].guid)
    if not rp.remove_both and rp.category == 0 then
      deleteByCategory(tr, rc.flags.CAT_SEND)
    elseif not rp.remove_both and rp.category == -1 then
      deleteByCategory(tr, rc.flags.CAT_REC)
    elseif rp.remove_both then
      deleteByCategory(tr, rc.flags.CAT_SEND)
      deleteByCategory(tr, rc.flags.CAT_REC)
    end -- if
  end -- for
  return true
end

--///////////////////////////////////////////////////////////////////////
--  UPDATE ROUTE STATE
--//////////////////////

-- TODO
--
function targetLoop(rp)
  for i = 1, #rp.src_guids do
    for j = 1, #rp.dst_guids do
      local rid
      if rp.src_guids[i].guid == rp.dst_guids[j].guid then goto continue end

      local src_tr, sidx = ru.getTrackByGUID(rp.src_guids[i].guid)
      local dst_tr, didx = ru.getTrackByGUID(rp.dst_guids[j].guid)

      rp, rid = getPrevRouteState(rp, src_tr, dst_tr)
      rp      = getNextRouteState(rp)

      log.user(rp.prev, rp.next)

      if rp.remove_routes then
        if rid == nil then
          log.user('TR: ' .. rp.src_guids[i].name .. ' has no sends..')
          return false
        end
        log.user('TR: ' .. rp.src_guids[i].name .. ' , rm send id: ' .. rid)
        removeSingle(src_tr, rp.category, rid)
      else
        log.user('ROUTE #'.. sidx+1 ..' `'.. rp.src_guids[i].name ..'`  -->  #'.. didx+1 ..' `'.. rp.dst_guids[j].name .. '`')
        if rp.prev == 0 then
          if rp.category == 0 then
            rid = reaper.CreateTrackSend(src_tr, dst_tr)
          elseif rp.category == -1 then
            rid = reaper.CreateTrackSend(dst_tr,src_tr)
          end
        end
        updateRouteState_Track(src_tr, rp, rid)


        -- TODO
        --
        -- if you don't supply
        -- `a`
        -- then ONLY one route is created
        -- and all others are deleted ?!?!
        deleteRouteIfEmpty(src_tr, rid)
      end
      :: continue ::
    end -- dst
  end -- src
end

function updateRouteState_Track(src_tr, rp, rid)
  -- log.user(format.block(rp))
  -- HANDLE MONO ?!?!
  -- if dest_tr_ch == 2 then
  --   reaper.SetTrackSendInfo_Value( src_tr, 0, new_rid, 'I_SRCCHAN',0)
  -- else
  --   reaper.SetTrackSendInfo_Value( src_tr, 0, new_rid, 'I_SRCCHAN',0|(1024*math.floor(src_tr_ch/2)))
  -- end
  --
  -- log.user(src_tr)

  for k, p in pairs(rp.new_params) do
    if k == 'm' then

      -- skipp if previous route component exists and not overwrite flag
      if (rp.prev == 2 or rp.prev == 3) and not rp.overwrite then goto continue end

      -- next is only audio and first
      if rp.next == 1 and rp.prev ~= 0 then goto continue end

      reaper.SetTrackSendInfo_Value(src_tr, rp.category, rid, p.param_name, p.param_value)
    else

      -- skipp if previous route component exists and not overwrite flag
      if (rp.prev == 1 or rp.prev == 3) and not rp.overwrite then goto continue end

      -- next is only midi and first
      if rp.next == 2 and rp.prev ~= 0 then goto continue end

      log.user(p.param_name .. '  ' .. tostring(p.param_value))
      reaper.SetTrackSendInfo_Value(src_tr, rp.category, rid, p.param_name, p.param_value)
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
