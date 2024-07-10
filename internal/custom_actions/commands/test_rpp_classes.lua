local log = require("utils.log")
local format = require("utils.format")
local tbl = require("utils.table")

local req = require("project_classes.JProjectClassReq")

local M = {}

M.picker = function()
    local proj = require("project_classes.project"):new()

    log.user("id =", proj:getId())

  -- items

    for i in proj:selectedItems() do
        local take = i:getActiveTake()
        -- local r = take:addFx(fxString)
        -- if r >= 0 then
        -- 	reaper.TakeFX_Show(take:getReaperTake(), r, pluginsData.ITEM_SHOW_FLAG) -- show FX
        -- end
        log.user("active take for item #", i)
    end

  local item_n = proj:getItem(10)

  log.user(format.block(item_n))

  -- local tot = tbl.tableConicat(req.MEDIA_ITEM_GET_INFO_VALUES, req.MEDIA_ITEM_GET_SET_INFO_STRINGS)

  for k,v in pairs(req.all_item_props()) do
    log.user(string.format("%s -> %s", v ,item_n[k]))
  end



  -- tracks
    local count = 0
    for i in proj:tracks() do
        count = count + 1
    end
    log.user("count=", count)
end

return M
