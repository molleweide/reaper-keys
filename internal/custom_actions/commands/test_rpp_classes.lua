local log = require("utils.log")
local format = require("utils.format")
local tbl = require("utils.table")

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

    -- pickers.all_tracks = function(meta, opts)
    --     opts = opts or {}
    --     local vtt = opts.vtt or syntax.getVerifiedTree()
    --     local t_picker_results = vtt.track_list
    --     log.user("<PICKER: ALL TRACKS>")
    --
    --     -- TODO: Add
    --     -- a. Tracks that HAVE items in CURRENT region
    --     -- a2. Tracks that DO NOT HAVE items in CURRENT region
    --     -- b. Tracks that HAVE items CROSSING edit cursor
    --
    --     -- TODO: should the filter be passed as a param to syntax.get_list_of_track_objects(filter)
    --     if opts.filter then
    --         if type(opts.filter) == "string" then
    --             t_picker_results = tbl.filter(vtt.track_list, function(o)
    --                 return str.strHasOneOfChars(o.class, opts.filter)
    --             end)
    --         elseif type(opts.filter) == "function" then
    --             t_picker_results = tbl.filter(vtt.track_list, opts.filter)
    --         end
    --     end
    --
    --     -- log.user(format.block(t_track_objects))
    --     fzf.init(tbl.deep_extend({
    --         title = opts.title or "All Tracks (Default)",
    --         results = t_picker_results,
    --         -- move into module
    --         on_select_func = function(self, i)
    --             local selection = self.t_search_results[i]
    --             if opts.next then
    --                 opts.next(meta, {
    --                     selection = selection,
    --                 })
    --             end
    --             return true
    --         end,
    --         sort_comp = "name",
    --
    --         -- TODO: add zone/group name before each track name
    --         entry_maker = require("pickers.entry_makers.track_nodes"),
    --     }, opts))
    -- end
end

return M
