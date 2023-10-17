local fu = require("utils.fzf")
local sf = require("utils.j_string_functions")

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
      b.label = item
      b.visible = true
      info.visible = true
      b.highlight = highlights
    else
      b.visible = false
      info.visible = false
    end
  end
end
