-- if you need to define a new action for use in reaper keys, do so here
-- if you need help check out the documentation https://gwatcha.github.io/reaper-keys/configuration/actions.html
-- see ./defaults/actions.lua for examples, as well as actions you can call

local lib = require('library')
-- provides functions which are specific to reaper-keys, such as macros
-- search for 'lib' in the default actions file to see examples
local custom = require('custom_actions')
-- provides custom functions which make use of the reaper api
-- search for 'custom' in the default actions file to see examples


local syntax = require('SYNTAX.actions')

-- local reaper_syntax = require('reaper_syntax')

-- naming conventions:
-- a noun implies an action which selects the noun, or a movement to it's position
-- simple verbs are usually operators, such as 'change'
-- longer verbs are usually commands

return {
  FuzzyFx = "_RSd7bf7022d92114682d354e90dbe8aef580a5ef5c",
  ApplyConfigs = syntax.applyConfigs,
  TrackInSet_MIDI_QMK = lib.io_device.setInputTo_MIDI_QMK,
  TrackInSet_MIDI_GRAND_ROLAND = lib.io_device.setInputTo_MIDI_GRAND_ROLAND,
  TrackInSet_MIDI_VIRTUAL = lib.io_device.setInputTo_MIDI_VIRTUAL,
  TrackInSet_MIDI_DEFAULT = lib.io_device.setInputTo_MIDI_DEFAULT,

  
  gCut = syntax.gcut,
  gPut = syntax.gput,
  gYank = syntax.gyank,
  SaveAllTracksAsTemplate = {
    "Reset",
    "FirstTrack",
    "SetModeVisualTrack", -- I lose visual???
    "LastTrack",
    -- "SaveTrackTempFromSelected"
  },
  ZoomProject = {"ZoomAllTracks", "ZoomAllItems", "ScrollToSelectedTracks", "ApplyConfigs"},
  -- custom zoom project where I always call apply tree after zoom + scroll
  -- ArmTracksWithMidiRouter = { "ArmTracks", custom.hookUpMidiRouter }, -- hook setup midi router.
}
