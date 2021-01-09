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

function AddFXChainToTrack_ExtractBlock(str)
  local s = ''
  local count = 1
  count_lines = 0
  for line in str:gmatch('[^\n]+') do
    count_lines = count_lines + 1
    s = s..'\n'..line
    if line:find('<') then count = count +1 end
    if line:find('>') then count = count -1 end
    if count == 1 then return s, count_lines end
  end
end

function AddFXChainToTrack(track, chain_fp)
  -- get some chain file, ex. from GetUserFileForRead()
  local file = io.open(chain_fp)
  if not file then return end
  local external_FX_chain_content = file:read('a')
  file:close()

  -- get track chunk
  local chunk = eugen27771_GetObjStateChunk(track)
  if not chunk then return end
  -- split chunk by lines into table
  local t = {}
  for line in chunk:gmatch('[^\n]+') do       if line:find('<FXCHAIN') then fx_chain_id0 = #t end       t[#t+1] = line     end
  --  find size of FX chain and where it placed
  local _, cnt_lines = AddFXChainToTrack_ExtractBlock(chunk:match('<FXCHAIN.*'))
  local fx_chain_id1 = fx_chain_id0 + cnt_lines -1
  -- insert FX chain
  local new_chunk = table.concat(t,'\n',  1, fx_chain_id1)..'\n'..
  external_FX_chain_content..
  table.concat(t,'\n',  fx_chain_id1)
  -- apply new chunk
  SetTrackStateChunk(track, new_chunk, false)
end


function SetFXName(track, fx, new_name)
  if not new_name then return end
  local edited_line,edited_line_id, segm
  -- get ref guid
  if not track or not tonumber(fx) then return end
  local FX_GUID = reaper.TrackFX_GetFXGUID( track, fx )
  if not FX_GUID then return else FX_GUID = FX_GUID:gsub('-',''):sub(2,-2) end
  local plug_type = reaper.TrackFX_GetIOSize( track, fx )
  -- get chunk t
  local _, chunk = reaper.GetTrackStateChunk( track, '', false )
  local t = {} for line in chunk:gmatch("[^\r\n]+") do t[#t+1] = line end
  -- find edit line
  local search
  for i = #t, 1, -1 do
    local t_check = t[i]:gsub('-','')
    if t_check:find(FX_GUID) then search = true  end
    if t[i]:find('<') and search and not t[i]:find('JS_SER') then
      edited_line = t[i]:sub(2)
      edited_line_id = i
      break
    end
  end
  -- parse line
  if not edited_line then return end
  local t1 = {}
  for word in edited_line:gmatch('[%S]+') do t1[#t1+1] = word end
  local t2 = {}
  for i = 1, #t1 do
    segm = t1[i]
    if not q then t2[#t2+1] = segm else t2[#t2] = t2[#t2]..' '..segm end
    if segm:find('"') and not segm:find('""') then if not q then q = true else q = nil end end
  end

  if plug_type == 2 then t2[3] = '"'..new_name..'"' end -- if JS
  if plug_type == 3 then t2[5] = '"'..new_name..'"' end -- if VST

  local out_line = table.concat(t2,' ')
  t[edited_line_id] = '<'..out_line
  local out_chunk = table.concat(t,'\n')
  --msg(out_chunk)
  reaper.SetTrackStateChunk( track, out_chunk, false )
  reaper.UpdateArrange()
end
