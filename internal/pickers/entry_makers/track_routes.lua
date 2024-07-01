local log = require("utils.log")
local format = require("utils.format")

local su = require("utils.string")

local fu = require("utils.fzf")
local sf = require("utils.j_string_functions")

return function(item)
    local ti = su.makeStringLength(tostring(item.other_tr_idx), 3)
    if ti:match("%.") then
        ti = ti:sub(0, -2)
        ti = "0" .. ti
    end
    local other = string.format("other_tr: (%s) %s", ti, item.other_tr_name)
    return {
        { string.format("type=%s%s", item.type == "recieve" and "R" or "S", item.index), 10 },
        { other, 38 },
        { string.format("src = %s", item.src), 10 },
        { string.format("dst = %s", item.dst), 10 },
    }
end
