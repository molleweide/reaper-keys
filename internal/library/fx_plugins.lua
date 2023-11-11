local fu = require("utils.fzf")
local tf = require("utils.j_tables")
local data_loaders = require("pickers.data.load_plugins_data")

local plugins = {}

plugins.get_all_plugins_data = function()
	local results = {}
	local tRatingData = fu.jReadVstData(pluginsData.DATA_INI_FILE)
	results = fu.jReadVstIni(pluginsData.VST_INI_FILE, tRatingData)
	local tTemplates = fu.getTemplates(pluginsData.TEMPLATE_SUB_DIRS, pluginsData.TEMPLATE_ROOT_DIR, tRatingData)
	results = tf.jTablesGlue(tTemplates, results)
	local tFXChains = fu.getFXChains(pluginsData.FXCHAIN_SUB_DIRS, pluginsData.FXCHAIN_ROOT_DIR, tRatingData)
	results = tf.jTablesGlue(tFXChains, results)
	local tJsfx = fu.jReadJsfxIni(pluginsData.JSFX_INI_FILE, tRatingData)
	results = tf.jTablesGlue(tJsfx, results)
	if pluginsData.LOAD_AU then
		local tAu = fu.jReadAuIni(pluginsData.AU_INI_FILE, tRatingData)
		results = tf.jTablesGlue(tAu, results)
	end
	if pluginsData.LOAD_ACTIONS then
		local tActions = data_loaders.jGetActions()
		results = tf.jTablesGlue(tActions, results)
	end
	-- msg(os.clock() - time)
	-- table.sort(results, sortByRating)
	return results
end

return plugins
