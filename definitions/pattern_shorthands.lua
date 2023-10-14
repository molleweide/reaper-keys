return {
  ["A"] = function(t, idx, val_in)
    t[idx] = "matched regex. compute something based on:" .. val_in
  end,
  ["a"] = "xoxo",
  -- quarter note beats
  ["q4"] = "xxxx4", -- four QN hits, which in the end should
  ["2q"] = "xoxo4", -- four QN hits, which in the end should
  ["q2"] = "oxox4", -- four QN hits, which in the end should
  ["32"] = "xxx2,3",
  -- test
  ["b"] = "xx(xxx)",
  ["c"] = "x[xx](xox)",
  ["d"] = "xxx2,3", -- 2-
}


