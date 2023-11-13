local project_state = require("utils.project_state")
local state_interface = require("state_machine.state_interface")
local reaper_utils = require("custom_actions.utils")
local log = require("utils.log")
local format = require("utils.format")

local serpent = require("serpent")

local marks = {}

function deleteMarkIndications(mark)
  if mark.index then
    if mark.type == "region" then
      reaper.DeleteProjectMarker(0, mark.index, true)
    elseif mark.type == "timeline_position" then
      reaper.DeleteProjectMarker(0, mark.index, false)
    end
  end
end

function overwriteMark(mark, register)
  local mode = state_interface.getMode()

  -- build and apply mark
  if mode == "visual_timeline" then
    local region_name = string.format("%s # %s", register, mark.name)
    mark["type"] = "region"
    mark["index"] = reaper.AddProjectMarker(0, true, mark.left, mark.right, region_name, -1)
  elseif mode == "visual_track" then
    mark["type"] = "track_selection"
  else
    local mark_name = string.format("%s # %s", register, mark.name)
    mark["type"] = "timeline_position"
    mark["index"] = reaper.AddProjectMarker(0, false, mark.position, mark.position, mark_name, -1)
  end
  mark["register"] = register
  mark["time"] = os.time()

  -- delete old
  local ok, old_mark = project_state.get("marks", register)
  if ok and old_mark then
    deleteMarkIndications(old_mark)
  end

  -- add new
  project_state.overwrite("marks", register, mark)
  state_interface.setMode("normal")

  -- debug
  local _, all_project_marks = project_state.getAll("marks")
  log.trace("New Marks State: " .. format.block(all_project_marks))
end

function marks.save(register)
  local time_left, time_right = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)

  local _, marks_named_input = reaper.GetUserInputs(
    "Name for new region:",
    1, -- num inputs
    "region " .. register, -- placeholder
    ""
  )

  local mark = {
    name = marks_named_input,
    left = time_left,
    right = time_right,
    position = reaper.GetCursorPosition(),
    track_position = reaper_utils.getTrackPosition(),
    track_selection = reaper_utils.getSelectedTrackIndices(),
  }

  overwriteMark(mark, register)
end

function marks.delete(register)
  local ok, old_mark = project_state.get("marks", register)
  if ok and old_mark then
    deleteMarkIndications(old_mark)
  end
  project_state.delete("marks", register)
end

marks.deleteAll = function()
  local ok, all_marks = project_state.getAll("marks")
  -- log.user("delete all ->", ok, format.block(all_marks))
  if ok and all_marks then
    for register, the_mark in pairs(all_marks) do
      log.user(register, format.block(the_mark))
      marks.delete(register)
      -- project_state.delete("marks", register)
    end
  end
  -- force remove all regions/markers manually
  marks.delete_all_markers_manually()
  -- reset the ext state marks table
  project_state.deleteExt("marks")
end

function marks.recallMarkedTimelinePosition(register)
  local ok, mark = project_state.get("marks", register)
  if not ok or not mark then
    return
  end

  local target_pos = mark.position
  if mark.type == "region" then
    target_pos = mark.left
  end

  reaper.SetEditCurPos(target_pos, true, false)
end

function marks.recallMarkedRegion(register)
  local ok, mark = project_state.get("marks", register)
  if not ok or not mark then
    return
  end

  reaper.GetSet_LoopTimeRange(true, false, mark.left, mark.right, false)
  reaper_utils.scrollToPosition(mark.left)
end

function marks.recallMarkedTracks(register)
  local ok, mark = project_state.get("marks", register)
  if not ok or not mark then
    return
  end

  reaper_utils.setCurrentTrack(mark.track_position)
  reaper_utils.setTrackSelection(mark.track_selection)
end

--
-- TODO: "regions" |"marks" |"both"
--
-- FIX: redo this with the existing api
--

marks.get_all_manually_without_state = function(user_wants)
  local t_results = {}
  local ret, num_markers, num_regions = reaper.CountProjectMarkers(0)
  local num_total = num_markers + num_regions
  if num_regions > 0 then
    local i = 0
    while i < num_total do
      local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3(0, i)
      local t_prepare = {
        isrgn = isrgn,
        pos = pos,
        rgnend = rgnend,
        name = name,
        mark_region_idx = markrgnindexnumber,
        color = color,
      }
      if user_wants == isrgn then
        table.insert(t_results, t_prepare)
      end
      i = i + 1
    end
  else
    log.user("Project has no regions!")
  end
  return t_results
end

marks.delete_all_markers_manually = function()
  local ret, num_markers, num_regions = reaper.CountProjectMarkers(0)
  local num_total = num_markers + num_regions

  local i = 0
  while i < num_total do
    local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3(0, i)
    reaper.DeleteProjectMarkerByIndex(proj, i)
    -- reaper.DeleteProjectMarker(0, mark.index, true)
    i = i + 1
  end
end

return marks
