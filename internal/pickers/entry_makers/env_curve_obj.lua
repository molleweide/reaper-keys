return function(item)
	return {
    {string.format("[%s]", item.name), 18},
    {string.format("#%s", #item), 8}
	}
end
