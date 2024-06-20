local log = require("utils.log")
local format = require("utils.format")

local su = require("utils.string")

local fu = require("utils.fzf")
local sf = require("utils.j_string_functions")

-- local function makeStringLength(inputString, maxLength, repl_str)
-- 	if #inputString < maxLength then
-- 		local numSpacesToAdd = maxLength - #inputString
-- 		local spaces = string.rep(repl_str, numSpacesToAdd)
-- 		return inputString .. spaces
-- 	else
-- 		return inputString
-- 	end
-- end

return function(tButtons, tResults)
    for i, cIds in ipairs(tButtons) do
        local b = cIds[1]
        local info = cIds[2]
        local iStart = fu._round(i + SCROLL_RESULTS)
        local highlights = sf.jStringExplode(textBox.value, " ")
        local showing

        if iStart <= #tResults then
            showing = iStart
        else
            showing = #tResults
        end

        LABEL_STATS.label = "(" .. showing .. "/" .. #tResults .. ")"

        if tResults and iStart <= #tResults then
            local item = tResults[iStart]

            -- log.user(string.format("%s < %s", item.name, item.group.name))
            local label_str = ""

            -- NOTE: Actually, probably only whatever inside this if-conditional
            -- needs to go into the entry_maker files.
            -- >>> I need to look at the telescope source and see how they
            -- define entry makers.

            -- if item.index then
            --     local part = string.format("#%s", item.index)
            --     label_str = label_str .. su.makeStringLength(part, 6)
            -- end

            -- type and index
            if item.type and item.index then
                local t = item.type == "recieve" and "R" or "S"
                local part = string.format("type=%s%s", t, item.index)
                label_str = label_str .. su.makeStringLength(part, 10)
            end

            if item.other_tr_name and item.other_tr_idx then
                local ti = su.makeStringLength(tostring(item.other_tr_idx), 3)
                if ti:match("%.") then
                    ti = ti:sub(0, -2)
                    ti = "0" .. ti
                end

                local part = string.format("other_tr: (%s) %s", ti, item.other_tr_name)
                label_str = label_str .. su.makeStringLength(part, 38)
            end

            if item.src then
                local part = string.format("src = %s", item.src)
                label_str = label_str .. su.makeStringLength(part, 10)
            end

            if item.dst then
                local part = string.format("src = %s", item.dst)
                label_str = label_str .. su.makeStringLength(part, 10)
            end

            -- if item.val then
            --   local val_str = tostring(item.val)
            --
            --   if #val_str > 5 then
            --     val_str = string.sub(val_str, 1, 5)
            --   end
            --   if #val_str < 5 then
            --     local diff = 5 - #val_str
            --     val_str = val_str .. string.rep("0", diff)
            --   end
            --
            --   local part = string.format("val:[ %s ]", val_str)
            --   label_str = label_str .. su.makeStringLength(part, 15, "_")
            -- end
            --
            -- if item.valf then
            --   local part = string.format("valf:[ %s ]", item.valf)
            --   label_str = label_str .. su.makeStringLength(part, 17, "_")
            -- end
            --
            -- local part = string.format("env:[%s]", item.envelope and "x" or " ")
            -- label_str = label_str .. su.makeStringLength(part, 20, "_")

            b.label = label_str

            b.visible = true
            info.visible = true
            b.highlight = highlights
        else
            b.visible = false
            info.visible = false
        end
    end
end
