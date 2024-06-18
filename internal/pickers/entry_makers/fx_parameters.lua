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

      if item.index then
        local part = string.format("[%s]", item.index)
        label_str = label_str .. su.makeStringLength(part, 10, "_")
      end

      if item.name then
        local part = string.format("parm:[%s]", item.name)
        label_str = label_str .. su.makeStringLength(part, 30, "_")
      end

      if item.val then
        local val_str = tostring(item.val)

        if #val_str > 5 then
          val_str = string.sub(val_str, 1, 5)
        end
        if #val_str < 5 then
          local diff = 5 - #val_str
          val_str = val_str .. string.rep("0", diff)
        end

        local part = string.format("val:[ %s ]", val_str)
        label_str = label_str .. su.makeStringLength(part, 15, "_")
      end

      if item.valf then
        local part = string.format("valf:[ %s ]", item.valf)
        label_str = label_str .. su.makeStringLength(part, 17, "_")
      end

      local part = string.format("env:[%s]", item.envelope and "x" or " ")
      label_str = label_str .. su.makeStringLength(part, 20, "_")

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
