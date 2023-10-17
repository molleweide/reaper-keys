return function(a, b)
  if a > b then
    return true
  elseif a == b then
    return a < b
  else
    return false
  end
end
