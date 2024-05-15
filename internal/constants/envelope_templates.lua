
-- NOTE: TEMPLATE CURVES
-- --
-- Curves can consist of any number of deltas but I keep an upper maximum count.
-- --
-- The shape/slope of each delta can be completely arbitrary.
-- --
-- Since, points are encoded at double points, this means that i should always
-- be ablet to create sawtooth curves or similar with my templates since the
-- value of each node is separate from th time point encoding.

local TEMPLATE_POINT_COUNT_MAX = 20 -- template total becomes 22, (+ start/end)


-- TEST: I am just gonna have to play around with this andd see what works
-- because I dont know the limits here..
local ENV_STEP_DELTA = 0.0000000001

-- NOTE: Definition describing what the delta should be for template point N,
-- starting with the first layer, second, and then third layer.
-- In layer N = 1 the start point will be coded as a delta of D=0, and an
-- end point coded as D = 3.
-- And for the third curve, the last point is coded as D = 11
-- This should allow me to super impose at least tree curves, or have
-- at most two curves overlapping in one position at all times, so I
-- could eg. alternate layered curves and keeping the state of overlap across
-- the whole timeline.
-- HACK: For midi these will be the actual midi tick delta, and for standard
-- envelopes it will be the number times a ENV_DELTA_STEP
local LAYERED_CURVES_ENCODING = {
    { 0, 1, 2, 3 },
    { 4, 5, 6, 7 },
    { 8, 9, 10, 11 },
}

return {
    {
        name = "FLAT",
        def = {
            {},
            {},
        },
    },
    {
        name = "UP",
        def = {
            {},
            {},
        },
    },
    {
        name = "DOWN",
        def = {
            {},
            {},
        },
    },
    {
        name = "UP DOWN",
        def = {
            {},
            {},
            {},
        },
    },
    {
        name = "DOWN UP",
        def = {
            {},
            {},
            {},
        },
    },
}
