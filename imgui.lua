---@meta _
---@diagnostic disable: lowercase-global



local function drawModMenu()

    local value, checked = rom.ImGui.Checkbox("Enable Aritificer Indicator", config.ArtificerIndicator)

    if checked then
		config.ArtificerIndicator = value
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
