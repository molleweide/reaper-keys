local tbl = {}

function tbl.tableConcat(t1, t2)
	if type(t1) ~= "table" or type(t2) ~= "table" then
		return false
	end
	for i = 1, #t2 do
		t1[#t1 + 1] = t2[i] --corrected bug. if t1[#t1+i] is used, indices will be skipped
	end
	return t1
end

function tbl.shallow_copy(t)
	local t2 = {}
	for k, v in pairs(t) do
		t2[k] = v
	end
	return t2
end

return tbl
