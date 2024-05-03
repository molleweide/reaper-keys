local automation_actions = {}

-- env_points_count = reaper.CountEnvelopePoints(env)

-- br_env = reaper.BR_EnvAlloc(env, false)
--     [BR] Allocate envelope object from track or take envelope pointer. Always
--     call BR_EnvFree when done to release the object and commit changes if
--     needed.
--
--     takeEnvelopesUseProjectTime: take envelope points' positions are counted
--     from take position, not project start time. If you want to work with project
--     time instead, pass this as true.
--
--     For further manipulation see BR_EnvCountPoints, BR_EnvDeletePoint,
--     BR_EnvFind, BR_EnvFindNext, BR_EnvFindPrevious, BR_EnvGetParentTake,
--     BR_EnvGetParentTrack, BR_EnvGetPoint, BR_EnvGetProperties, BR_EnvSetPoint,
--     BR_EnvSetProperties, BR_EnvValueAtPos.

-- boolean reaper.BR_EnvFree(BR_Envelope envelope, boolean commit)
-- [BR] Free envelope object allocated with BR_EnvAlloc and commit changes if
-- needed. Returns true if changes were committed successfully. Note that when
-- envelope object wasn't modified nothing will get committed even if commit =
-- true - in that case function returns false.

--  integer reaper.GetEnvelopeScalingMode( env )
--      Returns the envelope scaling mode: 0=no scaling, 1=fader scaling. All
--      API functions deal with raw envelope point values, to convert raw
--      from/to scaled values see
--
-- number reaper.ScaleFromEnvelopeMode(integer scaling_mode, number val)

-- 	reaper.DeleteEnvelopePointRange(envelope, start_time-0.000000001, end_time+0.000000001)

-- boolean reaper.SetEnvelopePoint(env, k, timeInOptional, valueInOptional, shapeInOptional, tensionInOptional, false, true)
-- boolean reaper.SetEnvelopePoint( envelope, ptidx, timeIn, valueIn, shapeIn, tensionIn, selectedIn, noSortIn )

-- boolean reaper.InsertEnvelopePoint(
--     TrackEnvelope envelope,
--     number time,
--     number value,
--     integer shape,
--     number tension,
--     boolean selected,
--     optional boolean noSortIn
-- )
-- Insert an envelope point. If setting multiple points at once, set noSort=true, and call Envelope_SortPoints when done. See

-- retval, value, dVdS, ddVdS, dddVdS = reaper.Envelope_Evaluate( envelope, time, samplerate, samplesRequested )
--     Get the effective envelope value at a given time position.
--     samplesRequested is how long the caller expects until the next call to
--     Envelope_Evaluate (often, the buffer block size). The return value is
--     how many samples beyond that time position that the returned values are
--     valid. dVdS is the change in value per sample (first derivative), ddVdS
--     is the second derivative, dddVdS is the third derivative. See

automation_actions.test = function()
    local tl = require("library.timeline")
    local cursor_info = tl.get_cursor_info()
    local start_pos = cursor_info.msr.start
    local end_pos = cursor_info.msr._end

    local env = reaper.GetSelectedEnvelope(0)
    -- 		reaper.GetFXEnvelope( track, fxindex, parameterindex, create )
    --       Returns the FX parameter envelope. If the envelope does not exist
    --       and create=true, the envelope will be created. If the envelope
    --       already exists and is bypassed and create=true, then the envelope
    --       will be unbypassed.

    reaper.InsertEnvelopePoint(env, start_pos, 0.5, 0, 0, false, true) -- INSERT startLoop point
    reaper.InsertEnvelopePoint(env, end_pos, 0.5, 0, 0, false, true) -- INSERT startLoop point
end

return automation_actions
