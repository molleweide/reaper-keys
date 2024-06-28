local log = require("utils.log")
local format = require("utils.format")

local fu = require("utils.fzf")
local sf = require("utils.j_string_functions")

local function makeStringLength(inputString, maxLength)

    if #inputString < maxLength then
        local numSpacesToAdd = maxLength - #inputString
        local spaces = string.rep(" ", numSpacesToAdd)
        return inputString .. spaces
    else
        return inputString
    end
end

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

      if item.zone then
        local part = "Z:" .. item.zone.name
        label_str = label_str .. makeStringLength(part, 20) .. "> "
      end

      if item.group then
        local part = "G:" .. item.group.name
        label_str = label_str .. makeStringLength(part, 20) .. "> "
      end

      -- midi editor state

      if item._midi_editor_active then
        label_str = label_str .. makeStringLength("Active", 20) .. "> "
      elseif item._midi_editor_editable then
        label_str = label_str .. makeStringLength("Editable", 20) .. "> "
      elseif item._midi_editor_visible then
        label_str = label_str .. makeStringLength("Visible", 20) .. "> "
      else
        label_str = label_str .. makeStringLength("", 20) .. "> "
      end


      b.label = label_str .. ":: " .. item.name

      b.visible = true
      info.visible = true
      b.highlight = highlights
    else
      b.visible = false
      info.visible = false
    end
  end
end
