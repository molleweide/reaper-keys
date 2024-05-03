local envelopes = {}

envelopes.track_fltr_env_points = function(opts)
end

envelopes.single_get_properties = function(br_env)
  local active, visible, armed, inLane, laneHeight, defaultShape, minValue, maxValue, centerValue, type_, faderScaling =
  reaper.BR_EnvGetProperties(br_env, true, true, true, true, 0, 0, 0, 0, 0, 0, true)
  return {
    active = active,
    visible = visible,
    armed = armed,
    in_lane = inLane,
    lane_height = laneHeight,
    default_shape = defaultShape,
    min_val = minValue,
    max_val = maxValue,
    center_val = centerValue,
    type = type_,
    fader_scaling = faderScaling,
  }
end

return envelopes
