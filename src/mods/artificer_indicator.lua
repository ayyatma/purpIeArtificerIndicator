---@meta _
---@diagnostic disable: lowercase-global

-- Determine which icon path to use. Priority:
local ArtificerIconPath = nil
-- Prefer explicit config override, otherwise use packaged asset at <plugin_guid>\ArtificerIcon
if _PLUGIN and _PLUGIN.guid then
    ArtificerIconPath = _PLUGIN.guid .. "\\ArtificerIcon"
end

local function clearUIFields(tr)
    if not tr then return end
    tr.ShowInHUD = false
    tr.Hidden = true
    tr.Icon = nil
    tr.AnchorId = nil
    tr.HUDScale = nil
    tr.IconScale = nil
    tr.PinIconScale = nil
    tr.PinIconFrameScale = nil
    tr.HighlightAnimScale = nil
    local raw = TraitData and TraitData[tr.Name]
    if raw then
        raw.Icon = nil
        raw.HUDScale = nil
        -- raw.IconScale = nil
        raw.PinIconScale = nil
        -- raw.PinIconFrameScale = nil
        -- raw.HighlightAnimScale = nil
    end
end

local function UpdateArtificerIndicator()
    -- If disabled, remove any existing UI and clear stored fields
    if config.Enabled == false then
        local trait = GetHeroTrait("MetaToRunMetaUpgrade")
        if trait then
            TraitUIRemove(trait)
            clearUIFields(trait)
            UpdateHeroTraitDictionary()
        end
        return
    end

    if CurrentRun == nil or CurrentRun.Hero == nil then
        return
    end

    local trait = GetHeroTrait("MetaToRunMetaUpgrade")
    -- Helper: apply scale and icon settings to both the hero trait and raw TraitData
    local function applyScaleAndIcon(tr, hudScale, pinScale)
        tr.Icon = ArtificerIconPath
        tr.HUDScale = hudScale
        -- tr.IconScale = hudScale
        tr.PinIconScale = pinScale
        -- tr.PinIconFrameScale = pinScale
        -- tr.HighlightAnimScale = pinScale
        local raw = TraitData and TraitData[tr.Name]
        if raw then
            raw.Icon = ArtificerIconPath
            raw.HUDScale = hudScale
            -- raw.IconScale = hudScale
            raw.PinIconScale = pinScale
            -- raw.PinIconFrameScale = pinScale
            -- raw.HighlightAnimScale = pinScale
        end
    end
    -- reuse top-level clearUIFields

    if not trait then
        return
    end
    print("ArtificerIndicator: Found MetaToRunMetaUpgrade trait")

    local uses = trait.MetaConversionUses or 0
    trait.RemainingUses = uses

    local hudScale = config.ArtificerHUDScale
    local pinScale = hudScale * config.ArtificerPinScale

    -- print("ArtificerIndicator: MetaConversionUses=", tostring(uses), " HUDScale=", tostring(hudScale), " PinScale=", tostring(pinScale))
    if uses > 0 then
        trait.UsesAsEncounters = false
        trait.Hidden = false
        trait.ShowInHUD = true
        applyScaleAndIcon(trait, hudScale, pinScale)

        if trait.AnchorId then
            -- update existing UI immediately
            SetAnimation({ Name = trait.Icon, DestinationId = trait.AnchorId })
            SetScale({ Id = trait.AnchorId, Fraction = hudScale })
            UpdateTraitNumber(trait)

            -- update the trait component table so future hovers/pins use our scale
            local tc = (HUDScreen and HUDScreen.SlottedTraitComponents and HUDScreen.SlottedTraitComponents[trait.AnchorId])
                    or (HUDScreen and HUDScreen.ActiveTraitComponents and HUDScreen.ActiveTraitComponents[trait.AnchorId])
            if tc then
                print("ArtificerIndicator: Updating TraitComponent scales for AnchorId=", tostring(trait.AnchorId))
                -- tc.IconScale = pinScale
                tc.PinIconScale = pinScale
                -- tc.PinIconFrameScale = pinScale
            end

            -- update any pinned hover icons that exist
            local tray = ActiveScreens and ActiveScreens.TraitTrayScreen
            if tray and tray.Pins then
                for _, pin in ipairs(tray.Pins) do
                    if pin and pin.Button == tc and pin.Components then
                        if pin.Components.Icon then
                            SetScale({ Id = pin.Components.Icon.Id, Fraction = hudScale })
                        end
                        if pin.Components.Frame then
                            SetScale({ Id = pin.Components.Frame.Id, Fraction = pinScale })
                        end
                    end
                end
            end
            -- Also update any trait icons created for the Trait Tray (these are separate components)
            -- so newly-created tray icons will have the correct PinIconScale when their pins are built.
            -- local traitTray = ActiveScreens and ActiveScreens.TraitTrayScreen
            -- if tray and tray.Components then
            --     for _, comp in ipairs(traitTray.Components) do
            --         if comp and comp.TraitData and comp.TraitData.Name == trait.Name then
            --             comp.PinIconScale = pinScale
            --             comp.PinIconFrameScale = pinScale
            --         end
            --     end
            -- end

        end

        TraitUIUpdateText(trait)
    else
        -- no uses; remove UI and clear fields so it doesn't reappear empty
        TraitUIRemove(trait)
        clearUIFields(trait)
    end

    UpdateHeroTraitDictionary()
end

-- Expose an UpdateNow function for the ImGui "Apply Now" button and external callers
purpIe_ArtificerIndicator.UpdateNow = UpdateArtificerIndicator



-- Hook EquipMetaUpgrades to set up indicator when equipping
modutil.mod.Path.Wrap("EquipMetaUpgrades", function(base, hero, args)
    base(hero, args)
    UpdateArtificerIndicator()
end)

-- Hook ConvertMetaRewardPresentation to update after gift usage
modutil.mod.Path.Wrap("ConvertMetaRewardPresentation", function(base, sourceDrop)
    base(sourceDrop)
    UpdateArtificerIndicator()
end)


-- Hook TraitUIAdd so we update when the trait's HUD component is created (fires once on creation)
modutil.mod.Path.Wrap("TraitUIAdd", function(base, trait, args)
    base(trait, args)
    -- Only trigger for our specific trait so we don't run every HUD add
    if trait and trait.Name == "MetaToRunMetaUpgrade" then
        UpdateArtificerIndicator()
    end
end)

-- Hook IncrementTableValue to catch MetaConversionUses changes
modutil.mod.Path.Wrap("IncrementTableValue", function(base, tableArg, key, amount)
    base(tableArg, key, amount)
    if key == "MetaConversionUses" then
        UpdateArtificerIndicator()
    end
end)

modutil.mod.Path.Wrap("DecrementTableValue", function(base, tableArg, key, amount)
    base(tableArg, key, amount)
    if key == "MetaConversionUses" then
        UpdateArtificerIndicator()
    end
end)


-- -- Wrap AddTraitToHero so mid-run grants (e.g., NPC boons like Circe) update the indicator immediately
-- modutil.mod.Path.Wrap("AddTraitToHero", function(base, args)
--     local result = base(args)
--     -- args may carry TraitName or TraitData
--     local traitName = nil
--     if args then
--         traitName = args.TraitName or (args.TraitData and args.TraitData.Name) or (args.TraitData and args.TraitData.TraitName)
--     end
--     if traitName == "MetaToRunMetaUpgrade" then
--         -- Log initial MetaConversionUses when the trait is added so we can see default values
--         local trait = GetHeroTrait("MetaToRunMetaUpgrade")
--         if trait then
--             print("ArtificerIndicator: AddTraitToHero added MetaToRunMetaUpgrade, MetaConversionUses=", tostring(trait.MetaConversionUses))
--         else
--             print("ArtificerIndicator: AddTraitToHero added MetaToRunMetaUpgrade but trait not found on hero yet")
--         end
--         UpdateArtificerIndicator()
--     end
--     return result
-- end)

-- Ensure initial setup when the module is imported (on mod load)
-- This makes sure TraitData/Icon fields are populated when the mod is first loaded
-- (on_ready in `main.lua` imports this file). UpdateArtificerIndicator is safe to call
-- because it respects `config.Enabled`.
-- UpdateArtificerIndicator()


