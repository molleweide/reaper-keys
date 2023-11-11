
-- i need to handle the case of `==` smarter,
-- maybe by passing a fallback key in table
-- {
--  "main",
--  "fallback"
-- }

return function(sorter)
	if not sorter then
		return function(a, b)
			if a > b then
				return true
			elseif a == b then
				return a < b
			else
				return false
			end
		end
	elseif type(sorter) == "string" or type(sorter) == "number" then
		return function(a, b)
			a = a[sorter]
			b = b[sorter]
			if a > b then
				return true
			elseif a == b then
				return a < b
			else
				return false
			end
		end
	elseif type(sorter) == "function" then
		return sorter
	end
end
