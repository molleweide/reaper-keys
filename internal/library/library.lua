local log = require("utils.log")
local format = require("utils.format")
local state_interface = require("state_machine.state_interface")
local reaper_utils = require("custom_actions.utils")
local reaper_state = require("utils.reaper_state")
local feedback = require("gui.feedback.controller")
local on_command = require("library.on_command")
local marks = require("library.marks")

local library = {
    marks = marks,
    state = require("library.state"),
    routing = require("library.routing"),
    segments = require("library.segments"),
    midi = require("library.midi"),
    fx = require("library.fx"),
    io_device = require("library.io_device"),
    on_command = on_command,
}

function library.matchTrackNameBackward()
    local _, name = reaper.GetUserInputs("Match Backward", 1, "Match String", "")
    local track = reaper_utils.getMatchedTrack(name, false)
    if track then
        state_interface.setLastSearchedTrackNameAndDirection(name, false)
        reaper.SetOnlyTrackSelected(track)
    else
        state_interface.setLastSearchedTrackNameAndDirection("^$", true)
        feedback.displayMessage("No match for " .. name)
    end
end

function library.matchTrackNameForward()
    local _, name = reaper.GetUserInputs("Match Forward", 1, "Match String", "")
    local track = reaper_utils.getMatchedTrack(name, true)
    if track then
        state_interface.setLastSearchedTrackNameAndDirection(name, true)
        reaper.SetOnlyTrackSelected(track)
    else
        state_interface.setLastSearchedTrackNameAndDirection("^$", true)
        feedback.displayMessage("No match for " .. name)
    end
end

function library.repeatTrackNameMatchForward()
    local last_matched, forward = state_interface.getLastSearchedTrackNameAndDirection()
    local track = reaper_utils.getMatchedTrack(last_matched, forward)
    if track then
        reaper.SetOnlyTrackSelected(track)
    end
end

function library.repeatTrackNameMatchBackward()
    local last_searched, forward = state_interface.getLastSearchedTrackNameAndDirection()
    local track = reaper_utils.getMatchedTrack(last_searched, not forward)
    if track then
        reaper.SetOnlyTrackSelected(track)
    end
end

function library.global_reset()
    local live_mode = state_interface.getKey("live_mode")
    if not live_mode then
        on_command.main.stop_playback()
    end
end

function library.ResetFeedbackWindow()
    reaper_state.setKeys("feedback", { open = false })
end

function library.move_time_selection_to_next_region()
    local next_region = marks.get_nth_region_for_pos(_, 1)

    log.user(next_region.name)

    if next_region then
        require("custom_actions.utils").selectRegion(next_region.mark_region_idx)
    end
end

return library
