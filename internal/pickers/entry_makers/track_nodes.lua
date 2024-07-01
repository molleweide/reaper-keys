return function(item)
  return {
    "Z:" .. item.zone.name,
    "G:" .. item.group.name,
    ":: " .. item.name
  }
end
