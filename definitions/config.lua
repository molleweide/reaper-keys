-- behaviour configuration options, see
-- https://gwatcha.github.io/reaper-keys/configuration/behaviour.html

-- turn of dual keys for vitrual keyboard on macOS,
--  later this should be refactored into config!
local MACOS_PATH_KARABINER_CLI  = '/Library/Application\\ Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli'
local MACOS_KARABINER_NORMAL_MODE_PROFILE  = MACOS_PATH_KARABINER_CLI .. " --select-profile 'Molleweide'"
local MACOS_KARABINER_VKB_MODE_PROFILE     = MACOS_PATH_KARABINER_CLI .. " --select-profile 'Moll_NDK'"


return {
  -- should operators in visual modes reset the selection or have it persist?
  persist_visual_timeline_selection = false,
  persist_visual_track_selection = false,
  -- allow timeline movement when in visual track mode?
  allow_visual_track_timeline_movement = true,
  -- options in decreasing verbosity: [trace debug info warn user error fatal]
  log_level = 'user',
  repeatable_commands_action_type_match = {
    'command',
    'operator',
    'meta_command',
  },

  -- create you custom name prefix
  name_prefix_match_str = '^%a%:.*%:',

  run_ext_cmd_on_enter_mode = {
    normal  = MACOS_PATH_KARABINER_CLI .. " --select-profile 'Molleweide'",
    vkb     = MACOS_PATH_KARABINER_CLI .. " --select-profile 'Moll_NDK'",
  },
}
