local project_io = require('utils.project_io')
local state_interface = require('state_machine.state_interface')
local reaper_utils = require('custom_actions.utils')
local log = require('utils.log')
local format = require('utils.format')

local serpent = require('serpent')

local marks = {}

function countProjectMarkers()
  local count = 0
  local ok, num_markers, num_regions = reaper.CountProjectMarkers(0)
  if ok and num_markers then
    if num_markers then
      count = count + num_markers
    end
    if num_regions then
      count = count + num_regions
    end
  end
  return count
end

function overwriteMark(mark, register)
  ok, old_mark = project_io.read('marks', register)
  local next_marker_index = 0
  if ok and old_mark and old_mark.type ~= 'track_selection' then
      reaper.DeleteProjectMarkerByIndex(0, old_mark.index)
      next_marker_index = old_mark.index
  else
    next_marker_index = countProjectMarkers()
  end

  if mark.type == 'region' then
    if not mark.left or not mark.right then
      return
    end
    mark.index = reaper.AddProjectMarker(0, true, mark.left, mark.right, register, next_marker_index)
  elseif mark.type == 'cursor_position' then
    mark.index = reaper.AddProjectMarker(0, false, mark.position, mark.position, register, next_marker_index)
  end

  project_io.write('marks', register, mark)
end

function marks.save(register)
  local mark = {}

  local current_position = reaper.GetCursorPosition()
  local mode = state_interface.getMode()
  local track_position = reaper_utils.getTrackPosition()

  if mode == 'visual_timeline' then
    mark.type = 'region'
    mark.left, mark.right = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    mark.position = mark.left
    state_interface.setMode('normal')
    reaper_utils.unselectAllButLastTouchedTrack()
  elseif mode == 'visual_track' then
    mark.type = 'track_selection'
    mark.position = current_position
    mark.track_position = track_position
    mark.track_selection = reaper_utils.getSelectedTrackIndices()
    state_interface.setMode('normal')
    reaper_utils.unselectAllButLastTouchedTrack()
  else
    mark.type = 'cursor_position'
    mark.position = current_position
    mark.track_position = track_position
  end

  overwriteMark(mark, register)
end

function marks.moveTo(register)
  local ok, mark = project_io.read('marks', register)
  if not ok or not mark then
    return
  end

  if mark.type == 'track_selection' then
    reaper_utils.setCurrentTrack(mark.track_position)
  else
    reaper.SetEditCurPos(mark.position, true, false)
  end
end

function marks.recall(register)
  local ok, mark = project_io.read('marks', register)
  if not ok or not mark then
    return
  end

  if mark.type == 'region' then
    reaper.GetSet_LoopTimeRange(true, false, mark.left, mark.right, false)
    reaper_utils.scrollToPosition(mark.left)
    reaper.SetProjectMarker(mark.index, true, mark.left, mark.right, register)
  else
    reaper_utils.setCurrentTrack(mark.track_position)
    if mark.type == 'track_selection' then
      reaper_utils.setTrackSelection(mark.track_selection)
    else
      reaper.SetEditCurPos(mark.position, true, false)
      local track = reaper.GetTrack(0, mark.track_position)
      if track then
        reaper.SetOnlyTrackSelected(track)
      end
    end
  end
end

function marks.delete(register)
  local ok, old_mark = project_io.read('marks', register)
  if ok and old_mark and old_mark.type ~= 'track_selection' then
    reaper.DeleteProjectMarkerByIndex(0, old_mark.index)
  end

  project_io.clear('marks', register)
end

return marks