local log = require("utils.log")
local format = require("utils.format")

local fzfutils = require("utils.fzf")

local settings = require("utils.j_settings_functions")


local data_loaders = {}

--
-- FIX: unused jGetActions
-- I believe this one loads reaper actions into the picker, so that one
-- could run custom actions via the picker.
--
-- I shall investiaget this further later.
--
-- TODO: i should move this into the plugins data loader file and rename it
-- to something more meaningful relating to:
--
-- >>>>>>>> get_data ??
--

function data_loaders.jGetActions()
	-- local blacklist = {".*MIDI CC/OSC only%)$", ".*MIDI/OSC only.*", ".*MIDI CC/mousewheel.*", ".*MIDI CC relative/mousewheel.*"}
	-- local blacklist = {}
	local tResult = {}

	local name = ""

	-- Main=0, Main (alt recording)=100, MIDI Editor=32060, MIDI Event List Editor=32061, MIDI Inline Editor=32062, Media Explorer=32063

	local i = 0
	local go = 1
	local section = 0
	while go > 0 do
		go, name = reaper.CF_EnumerateActions(section, i, "")

		if go > 0 then
			local command = reaper.CF_GetCommandText(section, i)
			-- local command2 =  reaper.ReverseNamedCommandLookup(i)
			-- if not _nameOnBlacklist(blacklist, name) then
			tResult[#tResult + 1] =
				{ name = name, desc = name, action_id = i, action = true, rating = 0, command = go, section = section } -- command2 = command2}
			-- end
		end
		i = i + 1
	end

	-- local i = 0
	-- local go = 1
	-- local section = 32060
	-- while go > 0 do
	-- 	go, name = reaper.CF_EnumerateActions(section, i, "")
	-- 	local command = reaper.CF_GetCommandText(section, i)
	-- 	tResult[#tResult + 1] = {name = name, desc = name, action_id = i, action = true, rating = 0, command = go, section = section} -- command2 = command2}
	-- 	i = i + 1
	-- end

	return tResult
end


function data_loaders.load_plugins_data(env)

	local SETTINGS_INI_FILE = env.SETTINGS_INI_FILE
	local SETTINGS_DEFAULT_FILE = env.SETTINGS_DEFAULT_FILE

	log.user(SETTINGS_INI_FILE, SETTINGS_DEFAULT_FILE)

	settings.jSettingsCreate(SETTINGS_INI_FILE, SETTINGS_DEFAULT_FILE)
	SETTINGS = assert(settings.jSettingsReadFromFile(SETTINGS_INI_FILE), "Could not open settings file.")

	pluginsData = {}

	--
	-- NOTE: create new settings file. should i keep this??!
	--

	-- new settings since 0.7.16, will be created if not present
	if not SETTINGS["window_save_state"] then
		settings.jSettingsWriteToFile(SETTINGS_INI_FILE, "gui", "window_save_state", "true", true)
		SETTINGS["window_save_state"] = { true }
	end

	if not SETTINGS["window_dock_state"] then
		settings.jSettingsWriteToFile(SETTINGS_INI_FILE, "gui", "window_dock_state", "0", true)
		SETTINGS["window_dock_state"] = { 0 }
	end

	if not SETTINGS["gui_size"] then
		settings.jSettingsWriteToFile(SETTINGS_INI_FILE, "gui", "gui_size", "20", true)
		SETTINGS["gui_size"] = { 20 }
	end

	if not SETTINGS["track_show_flag"] then
		settings.jSettingsWriteToFile(
			SETTINGS_INI_FILE,
			"fx",
			"track_show_flag",
			"3 ; 0 hidechain, 1 show chain, 2 hide floating, 3 for show floating window (default)",
			true
		)
		SETTINGS["track_show_flag"] = { 3 }
	end

	if not SETTINGS["item_show_flag"] then
		settings.jSettingsWriteToFile(SETTINGS_INI_FILE, "fx", "item_show_flag", "3", true)
		SETTINGS["item_show_flag"] = { 3 }
	end

	if not SETTINGS["jsfx_ini_file"] then
		settings.jSettingsWriteToFile(SETTINGS_INI_FILE, "files", "jsfx_ini_file", "reaper-jsfx.ini", true)
		SETTINGS["jsfx_ini_file"] = { "reaper-jsfx.ini" }
	end

	if not SETTINGS["load_actions"] then
		settings.jSettingsWriteToFile(SETTINGS_INI_FILE, "fx", "load_actions", "false", true)
		SETTINGS["load_actions"] = { false }
	end

	if not SETTINGS["load_au"] then
		settings.jSettingsWriteToFile(SETTINGS_INI_FILE, "fx", "load_au", "true", true)
		SETTINGS["load_au"] = { true }
	end

	if not SETTINGS["au_ini_file"] then
		settings.jSettingsWriteToFile(SETTINGS_INI_FILE, "files", "au_ini_file", "reaper-auplugins64.ini", true)
		SETTINGS["au_ini_file"] = { "reaper-auplugins64.ini" }
	end

	if not SETTINGS["fxchain_float_windows"] then
		settings.jSettingsWriteToFile(SETTINGS_INI_FILE, "fx", "fxchain_float_windows", "false", true)
		SETTINGS["fxchain_float_windows"] = { false }
	end

	--	FIX:  what to do with this??
	-- if not SETTINGS['ultraschall_api_file'] then
	-- 	settings.jSettingsWriteToFile(SETTINGS_INI_FILE, "files", "ultraschall_api_file", "UserPlugins/ultraschall_api.lua")
	-- 	SETTINGS['ultraschall_api_file'] = {"UserPlugins/ultraschall_api.lua"}
	-- end

	--	FIX:  what to do with this??
	-- 	ULTRASCHALL_API_FILE = reaper.GetResourcePath()
	-- 		.. "/"
	-- 		.. settings.jSettingsGet(SETTINGS, "ultraschall_api_file", "string")

	pluginsData = {
		VST_INI_FILE = fzfutils._jPath(
			reaper.GetResourcePath() .. "/" .. settings.jSettingsGet(SETTINGS, "vst_ini_file", "string")
		),
		AU_INI_FILE = fzfutils._jPath(
			reaper.GetResourcePath() .. "/" .. settings.jSettingsGet(SETTINGS, "au_ini_file", "string")
		),
		JSFX_INI_FILE = fzfutils._jPath(
			reaper.GetResourcePath() .. "/" .. settings.jSettingsGet(SETTINGS, "jsfx_ini_file", "string")
		),
		DATA_INI_FILE = fzfutils._jPath(env.RK_DATA .. "/" .. settings.jSettingsGet(SETTINGS, "fx_finder_data_file", "string")),
		PREFER_VST3 = settings.jSettingsGet(SETTINGS, "prefer_vst3", "boolean"),
		ITEM_SHOW_FLAG = settings.jSettingsGet(SETTINGS, "item_show_flag", "number"),
		TRACK_SHOW_FLAG = settings.jSettingsGet(SETTINGS, "track_show_flag", "number"),
		LOAD_ACTIONS = settings.jSettingsGet(SETTINGS, "load_actions", "boolean"),
		FXCHAIN_FLOAT_WINDOWS = settings.jSettingsGet(SETTINGS, "fxchain_float_windows", "boolean"),
		LOAD_AU = (reaper.GetOS() == "OSX64" or reaper.GetOS() == "OSX32")
				and settings.jSettingsGet(SETTINGS, "load_au", "boolean")
			or false,
		TEMPLATE_ROOT_DIR = fzfutils._jPath(
			reaper.GetResourcePath() .. "/" .. settings.jSettingsGet(SETTINGS, "template_root_dir", "string")
		),
		FXCHAIN_ROOT_DIR = fzfutils._jPath(
			reaper.GetResourcePath() .. "/" .. settings.jSettingsGet(SETTINGS, "fxchain_root_dir", "string")
		),
		PLUGIN_BLACKLIST_ENABLE = settings.jSettingsGet(SETTINGS, "plugin_blacklist_enable", "boolean"),
		TEMPLATE_SUBDIRS_ENABLE = settings.jSettingsGet(SETTINGS, "template_subdirs_enable", "boolean"),
		FXCHAIN_SUBDIRS_ENABLE = settings.jSettingsGet(SETTINGS, "fxchain_subdirs_enable", "boolean"),
		-- PLUGIN_BLACKLIST = PLUGIN_BLACKLIST,
		PLUGIN_BLACKLIST = pluginsData.PLUGIN_BLACKLIST_ENABLE
				and settings.jSettingsGet(SETTINGS, "plugin_blacklist_regex", "table")
			or {},

		-- TEMPLATE_SUB_DIRS = TEMPLATE_SUB_DIRS,
		TEMPLATE_SUB_DIRS = pluginsData.TEMPLATE_SUBDIRS_ENABLE and settings._joinSettingsTables(
			settings.jSettingsGet(SETTINGS, "template_subdirs_dir", "table"),
			settings.jSettingsGet(SETTINGS, "template_subdirs_rec", "table")
		) or { { "", true } },

		-- FXCHAIN_SUB_DIRS = FXCHAIN_SUB_DIRS,
		FXCHAIN_SUB_DIRS = pluginsData.FXCHAIN_SUBDIRS_ENABLE and settings._joinSettingsTables(
			settings.jSettingsGet(SETTINGS, "fxchain_subdirs_dir", "table"),
			settings.jSettingsGet(SETTINGS, "fxchain_subdirs_rec", "table")
		) or { { "", true } },
	}

	-- FIX:  what to do with this??
	-- -- Load Ultraschall Api if available
	-- ULTRASCHALL_API_ENABLED = reaper.file_exists(ULTRASCHALL_API_FILE)
	-- if ULTRASCHALL_API_ENABLED then
	-- 	dofile(ULTRASCHALL_API_FILE)
	-- end

	return true, pluginsData
end

return data_loaders
