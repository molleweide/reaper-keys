local log = require('utils.log')
local state_interface = require('state_machine.state_interface')
local config = require('definitions.config')


-- turn of dual keys for vitrual keyboard on macOS,
--  later this should be refactored into config!
local karabiner_path            = '/Library/Application\\ Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli'
local karb_normal_mode_profile  = karabiner_path .. " --select-profile 'Molleweide'"
local karb_vkb_mode_profile     = karabiner_path .. " --select-profile 'Moll_NDK'"


local state = {}

function state.setModeNormal()
  os.execute(karb_normal_mode_profile)
  state_interface.setMode('normal')
end

function state.setModeVisualTrack()
  local current_track = reaper.GetLastTouchedTrack()
  if current_track then
    reaper.SetOnlyTrackSelected(current_track)

    local visual_track_pivot_i = reaper.GetMediaTrackInfo_Value(current_track, "IP_TRACKNUMBER") - 1

    state_interface.setMode('visual_track')
    state_interface.setVisualTrackPivotIndex(visual_track_pivot_i)
  end
end

function state.setModeVisualTimeline()
  state_interface.setMode('visual_timeline')
  if state_interface.getTimelineSelectionSide() == 'left' then
    state_interface.setTimelineSelectionSide('right')
  end
end

function state.setModeVirtualKeyboard()
  -- before we enter mode.
  --  first turn of dual-function-keys



  -- function getOS()
      -- fh,err = io.popen("uname -o 2>/dev/null","r")
      -- if fh then osname = fh:read() end
      -- log.user(fh, osname)
      -- if osname then return osname end
    -- local BinaryFormat = package.cpath:match("%p[\\|/]?%p(%a+)")
    -- if BinaryFormat == "dll" then
    --         return "Windows"
    -- elseif BinaryFormat == "so" then
    --         return "Linux"
    -- elseif BinaryFormat == "dylib" then
    --         return "MacOS"
    -- end
    -- return "unknown"
  -- end
  -- os = getOS()

  -- log.user('OS: ' .. os)

  -- https://unix.stackexchange.com/questions/8101/how-to-insert-the-result-of-a-command-into-the-text-in-vim/8109#8109
  -- how do i get the output from a shell comm

  os.execute(karb_vkb_mode_profile)
  state_interface.setMode('vkb')
end

function state.switchTimelineSelectionSide()
  local go_to_start_of_selection = 40630
  local go_to_end_of_selection = 40631

  if state_interface.getTimelineSelectionSide() == 'right' then
    reaper.Main_OnCommand(go_to_start_of_selection, 0)
    state_interface.setTimelineSelectionSide('left')
  else
    reaper.Main_OnCommand(go_to_end_of_selection, 0)
    state_interface.setTimelineSelectionSide('right')
  end
end

return state
