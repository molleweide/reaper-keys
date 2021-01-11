-- local project_state = require('utils.project_state')
-- local state_interface = require('state_machine.state_interface')
local reaper_utils = require('custom_actions.utils')
local log = require('utils.log')
local format = require('utils.format')
local routing_defaults = require('definitions.routing')

-- local serpent = require('serpent')

local routing = {}

function routing.addRouteForSelectedTracks()
  local num_sel = reaper.CountSelectedTracks(0)
  if num_sel == 0 then return end
  local src_GUID = GetSrcTrGUID() -- get table of src tracks

  local route_help_str = "route params:\n" ..
  "\nk int  = category" ..
  "\ni int  = send idx" -- this is not displaying properly...

  local test_str = "xxi5c...C555555C5.54v^#$∞¶M1a1.4s5.555d44.456P12.456789"
  local _, input_str = reaper.GetUserInputs("SPECIFY ROUTE:", 1, route_help_str, test_str)

  local new_route_params = getSendParamsFromUserInput(input_str)

  addRoutes(new_route_params, src_GUID)
end

function routing.sidechainSelTrkToGhostSnareTrack()
 sidechainToTrackWithNameString('ghostsnare')
end

function routing.sidechainSelTrkToGhostKickTrack()
 sidechainToTrackWithNameString('ghostkick')
end

function sidechainToTrackWithNameString(str)
  --  1. if track w/name containing 'ghostkick'
      -- if not has_no_name and current_name:match(search_name:lower()) then
      --   return track
      -- end
  --  2. check if 3/4 send exists (util)
  --  2. createSend (util)
  --  3. add reacomp to track
  --  4. rename the function to sidechain_to_ghostkick
  --    take all of my renaming functions etc and move them out to RK lib
  --    so that my syntax module is completely separated from the lib functions
  --  5. create generalized send function that works with send_str_input
end

function addRoutes(route_params, src_t, dest_t)
  log.user(format.block(route_params))

  if route_params["d"].param_value == nil then return end

  local dest_tr = reaper.GetTrack(0, math.floor(route_params["d"].param_value-1))
  local ret, dest_name = reaper.GetTrackName(dest_tr)
  local help_str = "`"..dest_name .. "` (y/n)"
  local _, answer = reaper.GetUserInputs("Create new route for track:", 1, help_str, "")

  if answer ~= "y" then return end

  for i = 1, #src_t do
    --   local src_tr =  BR_GetMediaTrackByGUID( 0, src_t[i] )
    --   local src_tr_ch = GetMediaTrackInfo_Value( src_tr, 'I_NCHAN')
    local src_tr =  reaper.BR_GetMediaTrackByGUID( 0, src_t[i] )
    local src_tr_ch = reaper.GetMediaTrackInfo_Value( src_tr, 'I_NCHAN')

    --   for i = 1, #dest_t do
    -- !!! only one dest track possible !!!

    -- increase ch up to src track
    local dest_tr_ch = reaper.GetMediaTrackInfo_Value( dest_tr, 'I_NCHAN')
    if dest_tr_ch < src_tr_ch then reaper.SetMediaTrackInfo_Value( dest_tr, 'I_NCHAN', src_tr_ch ) end

    log.user(src_tr_ch, dest_tr_ch)

    -- check for existing sends
    local is_exist = false
    for i =1,  reaper.GetTrackNumSends( src_tr, 0 ) do
      local dest_tr_check = reaper.BR_GetMediaTrackSendInfo_Track( src_tr, 0, i-1, 1 )
      if dest_tr_check == dest_tr then is_exist = true break end
    end

    -- create send
    if not is_exist then

      local new_id = reaper.CreateTrackSend( src_tr, dest_tr )

      for _, p in pairs(route_params) do
        reaper.SetTrackSendInfo_Value( src_tr, 0, new_id, p.param_name, p.param_value)

        if p.param_name == 'I_SRCCHAN' then
          if dest_tr_ch == 2 then
            reaper.SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_SRCCHAN',0)
          else
            reaper.SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_SRCCHAN',0|(1024*math.floor(src_tr_ch/2)))
          end
        end
      end
    end
    --   end -----------------------------------------------------------------------------
  end
end

function GetDestTrGUID()
  --   local t = {}
  --   local _, sendidx = reaper.GetUserInputs("Send track dest idx:", 1, "send idx", "")
  --   local dest_track = reaper.GetTrack(0, sendidx-1)
  --   if dest_track  then t[1] = reaper.GetTrackGUID( dest_track  ) end
  --   return t
end

function GetSrcTrGUID()
  local t = {}
  for i = 1, reaper.CountSelectedTracks(0) do
    local tr = reaper.GetSelectedTrack(0,i-1)
    t[#t+1] = reaper.GetTrackGUID( tr )
  end
  return t
end

function getSendParamsFromUserInput(str)
  local new_route_params = routing_defaults.default_params
  for key, val in pairs(new_route_params) do

    local pattern = key .. "%d+%.?%d?%d?"

    local s, e = string.find(str, pattern)
    if s ~= nil and e ~= nil then
      -- log.user('key: ' .. string.sub(str,s,s) .. ', val: ' .. string.sub(str,s+1,e))
      new_route_params[key].param_value = tonumber(string.sub(str,s+1,e))
    end
  end

  return new_route_params
end

return routing
