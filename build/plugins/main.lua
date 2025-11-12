---@meta _
purpIe_ArtificerIndicator = purpIe_ArtificerIndicator or {}

---@diagnostic disable-next-line: undefined-global
local mods = rom.mods

---@diagnostic disable: lowercase-global
---@module 'SGG_Modding-ENVY-auto'
mods['SGG_Modding-ENVY'].auto()

---@diagnostic disable-next-line: undefined-global
rom = rom
---@diagnostic disable-next-line: undefined-global
_PLUGIN = PLUGIN

---@module 'SGG_Modding-Hades2GameDef-Globals'
game = rom.game

---@module 'SGG_Modding-SJSON'
sjson = mods['SGG_Modding-SJSON']

---@module 'SGG_Modding-ModUtil'
modutil = mods['SGG_Modding-ModUtil']

---@module 'SGG_Modding-Chalk'
chalk = mods["SGG_Modding-Chalk"]

---@module 'SGG_Modding-ReLoad'
reload = mods['SGG_Modding-ReLoad']

---@module 'purpIe-config-ArtificerIndicator'
config = chalk.auto('config.lua')
public.config = config


---@module 'game.import'
import_as_fallback(rom.game)

local function on_ready()
	if config.Enabled == false then
		return
	end


	import("mods/artificer_indicator.lua")

end

local function on_reload()
	if config.Enabled == false then
		return
	end

	import("imgui.lua")
end

local loader = reload.auto_single()

modutil.once_loaded.game(function()
	-- Ensure our mod package (assets placed under the plugin data folder) is loaded into the game's package system
	-- so references like "<mod-guid>\\ArtificerIcon" work. This mirrors the pattern used by other mods.
	local package = rom.path.combine(_PLUGIN.plugins_data_mod_folder_path, _PLUGIN.guid)
	modutil.mod.Path.Wrap("SetupMap", function(base)
		LoadPackages({ Name = package, })
		base()
	end)

	loader.load(on_ready, on_reload)
end)


