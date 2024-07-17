local M = {}

M.to_volume = function(db)
    return 10 ^ (0.05 * db)
end

M.to_decibel = function(vol)
    return 20 * math.log(vol, 10)
end

return M
