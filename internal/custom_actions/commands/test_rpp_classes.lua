local log = require("utils.log")
local format = require("utils.format")
local tbl = require("utils.table")

local fzf = require("library.fzf")
local req = require("project_classes.JProjectClassReq")

local M = {}

M.picker = function()
    log.clear()
    local proj = require("project_classes.project"):new()

    log.user("id =", proj:getId())

    log.user("\n# TRACK PROPS #################################\n")

    local track_n = (proj:selectedTracks())()

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

    -------------------------------------------------------------------------------

    -- fzf.init({
    --     title = "TRACKS",
    --     results = proj:get_all_tracks(),
    --     results_filter = "name",
    --     sort_comp = "name",
    --     entry_maker = function(item)
    --         return { item.name }
    --     end,
    -- })

    -- fzf.init({
    --     title = "fx for track = "..track_n.name,
    --     results = track_n:get_all_fx(),
    --     results_filter = "name",
    --     sort_comp = "name",
    --     entry_maker = function(item)
    --         return { item.name, item.paramcount, item.enabled  }
    --     end,
    -- })

    local tr = proj:getTrack(80)

    -- log.user(format.block(#track_n))

    local fx = tr:get_all_fx()

    -- log.user("name->", fx[1].name, fx[1].type)
    -- log.user("track?", fx[1]:getParam(5).name)

  -- WARN: This is incredibly slow. It is almost riddiculous.
  -- It might be because getting the name by index many times in a row?

    if #fx > 0 then
        local fx_1 = fx[1]
        local fxp = fx_1:get_all_fx_params()
        -- log.user("#",#fxp)
        fzf.init({
            title = "fx = " .. fx[1].name,
            results = fxp,
            results_filter = "name",
            sort_comp = "name",
            entry_maker = function(item)
                return { item.name } --, fx_1:getParam(item.iParam)
            end,
        })
    end

end

return M
