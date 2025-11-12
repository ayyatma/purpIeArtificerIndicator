---@meta _
---@diagnostic disable: lowercase-global

-- 
local function drawModMenu()

	local newValue, changed = rom.ImGui.Checkbox("Enable Aritificer Indicator", config.Enabled)
	if changed then
		config.Enabled = newValue
		-- apply change immediately
		if purpIe_ArtificerIndicator and purpIe_ArtificerIndicator.UpdateNow then
			purpIe_ArtificerIndicator.UpdateNow()
		else
			print("ArtificerIndicator: UpdateNow not available")
		end
	end
	
	-- HUD/icon scale slider
	rom.ImGui.Separator()
	local hudScale = config.ArtificerHUDScale
	local newHud, changed = rom.ImGui.SliderFloat("Tray Icon Scale", hudScale, 0.05, 0.6)
	if changed then
		config.ArtificerHUDScale = newHud
	end

	rom.ImGui.Separator()
	local pinScale = config.ArtificerPinScale
	local newPin, changed = rom.ImGui.SliderFloat("Pin Icon Scale", pinScale, 0.1, 1)
	if changed then
		config.ArtificerPinScale = newPin
	end


	rom.ImGui.Separator()
	if rom.ImGui.Button("Apply Now") then
		-- Trigger update immediately (exposed by the mod)
		if purpIe_ArtificerIndicator and purpIe_ArtificerIndicator.UpdateNow then
			purpIe_ArtificerIndicator.UpdateNow()
		else
			print("ArtificerIndicator: UpdateNow not available")
		end
	end
end



rom.gui.add_imgui(function()
	if rom.ImGui.Begin("ArtificerIndicator") then
		drawModMenu()
		rom.ImGui.End()
	end
end)

rom.gui.add_to_menu_bar(function()
	if rom.ImGui.BeginMenu("Configure") then
		drawModMenu()
		rom.ImGui.EndMenu()
	end
end)


