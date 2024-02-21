local log = require("utils.log")
local format = require("utils.format")

local s = require("utils.string")

-- TODO: move this to `library/parsers/{...}`

local nodes_string = {}

local function containsOnlyAlphanumericAndPeriod(str)
	return not string.match(str, "[^%w%.]")
end

-- ::: ADD TRACK NODES UI :::
--
-- 3. ZG/xxx,yyy
--    Create zone `xxx` and populate it with group `yyy`
--
-- 4. G/xx,yy4
--    The final number that I want N number of leaf tracks.
--
-- 5. Z/arst
--    Only adding a Zone requires one to also add user input name for new
--    contained group.
--
-- 6. feat: add class T, A, and B.
--
-- 7. feat: specify templates/presets/patches/etc.
--
-- 8.
--
-- Words prefixed w/ ZGS expect names, and then each following
-- name will be a default track in that group.
--
--
nodes_string.handle_add_nodes_string = function(add_nodes_str)
	log.user("-------- ADD NODES STRING:", add_nodes_str)
	local main_divider = "/"
	local name_divider = ","

	local valid = true
	local initial_slash = add_nodes_str:match("^/")
	local trailing_slash = add_nodes_str:match("/$")
	local input_units = s.split(add_nodes_str, main_divider)
	local zgs_match
	local names_index
	local name_idx_counter = 1
	local node_creation_type
	local t_final = {}
	local t_branches = {}
	local t_leaves = {}

	log.user("length # input_units:", #input_units, format.block(input_units))

	if #input_units == 1 then
		names_index = 1

		if initial_slash then
			node_creation_type = "only_leaves" -- /arst
		elseif trailing_slash then
			node_creation_type = "only_branches" -- arst/
		else
			node_creation_type = "only_leaves" -- `arst`
		end
	else
		node_creation_type = "both" -- (/)arst/arst(/...)
		names_index = 2
	end

	if node_creation_type == "only_branches" or node_creation_type == "both" then
		zgs_match = input_units[1]:match("^z?g?s?$")
		if zgs_match == "zs" then
			zgs_match = false
		end
	end

	local add_to_current_parrent = not zgs_match
	local names_match = s.split(input_units[names_index], name_divider)

	log.user(string.format(
		[[
		---
		  zgs match = %s
		  add to pas = %s
		  name match = %s
		  type = %s
		  ----
		  ]],
		zgs_match,
		add_to_current_parrent,
		format.block(names_match),
		node_creation_type
	))

	-- log.user("zgs_match:", zgs_match, add_to_current_parrent)
	-- log.user("names:", format.block(names_match))

	local function incr()
		name_idx_counter = name_idx_counter + 1
	end

	local function verify_name()
		if node_creation_type == "only_branches" then
			return false
		end

		if names_match[name_idx_counter] ~= nil then
			local name = names_match[name_idx_counter]
			incr()
			return name
		else
			return false
		end
	end

	if zgs_match then
		if zgs_match:find("z") then
			table.insert(t_branches, {
				class = "z",
				name = verify_name(),
			})
		end

		if zgs_match:find("g") then
			table.insert(t_branches, {
				class = "g",
				name = verify_name(),
			})
			-- incr()
		end

		if zgs_match:find("s") then
			table.insert(t_branches, {
				class = "s",
				name = verify_name(),
			})
			-- incr()
		end

		t_final["branches"] = t_branches
	end

	if node_creation_type ~= "only_branches" then
		log.user(name_idx_counter)
		for i = name_idx_counter, #names_match, 1 do
			local name = verify_name()
			if not containsOnlyAlphanumericAndPeriod(name) then
				valid = false
			end
			table.insert(t_leaves, {
				name = name,
			})
		end
		t_final["leaves"] = t_leaves
	end

	log.user(format.block(t_final))

	return valid, data
end

return nodes_string
