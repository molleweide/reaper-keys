local log = require("utils.log")
local format = require("utils.format")
local tbl = require("utils.table")

local req = require("project_classes.JProjectClassReq")

local M = {}

M.picker = function()
    local proj = require("project_classes.project"):new()

    log.user("id =", proj:getId())

    log.user("\n# TRACK PROPS #################################\n")

    local track_n = proj:getTrack(50)
    for k, v in pairs(req.all_track_props()) do
        log.user("    " .. string.format("%s -> %s", v, track_n[k]))
    end

    log.user("\n# ITEM PROPS #################################\n")
    local item_n = proj:getItem(10)
    for k, v in pairs(req.all_item_props()) do
        log.user("    " .. string.format("%s -> %s", v, item_n[k]))
    end

    log.user("\n# ITEM TAKE #################################\n")
    local take_n = item_n:getActiveTake()
    for k, v in pairs(req.all_take_props()) do
        log.user("    " .. string.format("%s -> %s", v, take_n[k]))
    end
end

return M
