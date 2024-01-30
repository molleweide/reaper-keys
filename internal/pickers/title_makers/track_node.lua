return function(node, t_fx_params)
	local tr_node_header_string = ""
	if node.zone then
		local part = "Z:" .. node.zone.name
		tr_node_header_string = tr_node_header_string .. part .. "> "
	end
	if node.group then
		local part = "G:" .. node.group.name
		tr_node_header_string = tr_node_header_string .. part .. "> "
	end
	tr_node_header_string = tr_node_header_string .. ":: " .. node.name
	--------
	return string.format("FXparams: NODE(%s) -> FX(%s)", tr_node_header_string, t_fx_params.name)
end
