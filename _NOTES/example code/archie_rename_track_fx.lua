function Arc_Module.TrackFx_Rename(Track,idx_fx,newName)
  local strT, found, slot = {}
  local Pcall,FXGUID = pcall(reaper.TrackFX_GetFXGUID,Track,idx_fx)
  if not Pcall or not FXGUID then return false end
  local retval, str = reaper.GetTrackStateChunk(Track,"",false)

  -- log str to veiw statechunk

  for l in (str.."\n"):gmatch(".-\n") do
    table.insert(strT,l)
  end

  for i = #strT,1,-1 do
    if strT[i]:match(FXGUID:gsub("%p","%%%0")) then
      found = true
    end
    if strT[i]:match("^<") and found and not strT[i]:match("JS_SER") then
      found = nil
      local nStr = {}
      for S in strT[i]:gmatch("%S+") do
        if not X then
          nStr[#nStr+1] = S
        else
          nStr[#nStr] = nStr[#nStr].." "..S
        end
        if S:match('"') and not S:match('""')and not S:match('".-"') then
          if not X then
            X = true
          else
            X = nil
          end
        end
      end
      if strT[i]:match("^<%s-JS") then
        slot = 3
      elseif strT[i]:match("^<%s-AU")
        then
        slot = 4
      elseif strT[i]:match("^<%s-VST") then
        slot = 5
      end
      if not slot then error("Failed to rename",2)
      end
      nStr[slot] = newName:gsub(newName:gsub("%p","%%%0"),'"%0"')
      nStr[#nStr+1]="\n"
      strT[i] = table.concat(nStr," ")
      break
    end
  end
  return reaper.SetTrackStateChunk(Track,table.concat(strT),false)
end
-- TrackFx_Rename = Arc_Module.TrackFx_Rename;
