---@meta _
---@diagnostic disable: lowercase-global

---@meta _
---@diagnostic disable: lowercase-global

-- Initialize mod data
local function initializeModData()
	print("ArtificerIndicator: Initializing mod data")
	-- Add the expired text for MetaToRunMetaUpgrade
	if not TextData.MetaToRunMetaUpgrade_Expired then
		TextData.MetaToRunMetaUpgrade_Expired = "Artificer Depleted"
		print("ArtificerIndicator: Added expired text")
	end

	-- Create the Artificer indicator trait similar to StorePendingDeliveryItem
	if not TraitData.MetaToRunIndicator then
		TraitData.MetaToRunIndicator = {
			Frame = "Shop",
			PriorityDisplay = true,
			Icon = "Trait_StorePendingDeliveryItem", -- Using the same icon as delivery system
			RemainingUses = 3, -- Will be set dynamically
			UsesAsEncounters = false, -- Don't decrement automatically
			HideInRunHistory = true,
			StatLines = {
				"DeliveryTimeRemainingDisplay1", -- Reuse the delivery stat line
			},
			SpeakerNames = { "Hermes" },
			SetupFunction = {
				Name = "LoadResourcesForPendingDeliveryItem", -- Reuse the setup function
				Args = {},
			},
		}
		print("ArtificerIndicator: Created MetaToRunIndicator trait")
	end
end

-- Call initialization
initializeModData()

-- Function to update the indicator trait
local function updateArtificerIndicator()
	print("ArtificerIndicator: updateArtificerIndicator called")
	if not config.ArtificerIndicator then
		print("ArtificerIndicator: Indicator disabled in config")
		return
	end

	local hero = CurrentRun and CurrentRun.Hero
	if not hero then
		print("ArtificerIndicator: No hero found")
		return
	end

	print("ArtificerIndicator: Checking for MetaToRunMetaUpgrade")
	-- Check if player has MetaToRunMetaUpgrade
	if HeroHasTrait("MetaToRunMetaUpgrade") then
		local metaTrait = GetHeroTrait("MetaToRunMetaUpgrade")
		local remainingUses = metaTrait.MetaConversionUses or 0
		print("ArtificerIndicator: Found MetaToRunMetaUpgrade with " .. remainingUses .. " uses")

		-- Only show indicator if there are uses remaining
		if remainingUses > 0 then
			print("ArtificerIndicator: Creating indicator trait")
			local indicatorTrait = DeepCopyTable(TraitData.MetaToRunIndicator)
			indicatorTrait.RemainingUses = remainingUses
			indicatorTrait.ItemDisplayName = "Artificer Uses"
			indicatorTrait.ShopItemName = "MetaToRunUpgrade"

			AddTraitToHero({ TraitData = indicatorTrait, SkipUIUpdate = false })
			print("ArtificerIndicator: Added indicator trait to hero")
		else
			print("ArtificerIndicator: No uses remaining, removing indicator")
			-- Remove existing indicator
			if hero.TraitDictionary and hero.TraitDictionary.MetaToRunIndicator then
				for i, trait in pairs(hero.TraitDictionary.MetaToRunIndicator) do
					RemoveTraitData(hero, trait, { SkipExpire = true })
				end
			end
		end
	else
		print("ArtificerIndicator: No MetaToRunMetaUpgrade found")
	end
end

-- Hook into SetupMetaUpgradeData to add ZeroBonusTrayText
modutil.mod.Path.Wrap("SetupMetaUpgradeData", function(base)
	print("ArtificerIndicator: SetupMetaUpgradeData hook called")
	base()

	-- Add ZeroBonusTrayText to MetaToRunMetaUpgrade
	if TraitData.MetaToRunMetaUpgrade and config.ArtificerIndicator then
		TraitData.MetaToRunMetaUpgrade.ZeroBonusTrayText = "MetaToRunMetaUpgrade_Expired"
		print("ArtificerIndicator: Added ZeroBonusTrayText to MetaToRunMetaUpgrade")
	end
end)

-- Hook into GetHeroTrait to update tray text when uses change
modutil.mod.Path.Wrap("GetHeroTrait", function(base, traitName)
	local trait = base(traitName)
	if trait and trait.Name == "MetaToRunMetaUpgrade" and config.ArtificerIndicator then
		if trait.MetaConversionUses and trait.MetaConversionUses <= 0 and trait.ZeroBonusTrayText then
			trait.CustomTrayText = trait.ZeroBonusTrayText
			print("ArtificerIndicator: Updated tray text for depleted MetaToRunMetaUpgrade")
		end
	end
	return trait
end)

-- Hook into the gift logic where MetaConversionUses is consumed
modutil.mod.Path.Wrap("UseGift", function(base, giftData)
	print("ArtificerIndicator: UseGift hook called")
	local result = base(giftData)

	-- Update indicator after use
	updateArtificerIndicator()

	return result
end)

-- Hook into ConvertMetaRewardPresentation which is called during conversion
modutil.mod.Path.Wrap("ConvertMetaRewardPresentation", function(base, target)
	print("ArtificerIndicator: ConvertMetaRewardPresentation hook called")
	local result = base(target)

	-- Update indicator after conversion
	updateArtificerIndicator()

	return result
end)

-- Hook into EquipMetaUpgrades to set up the indicator initially
modutil.mod.Path.Wrap("EquipMetaUpgrades", function(base, hero, args)
	print("ArtificerIndicator: EquipMetaUpgrades hook called")
	local result = base(hero, args)

	-- Update indicator after equipping meta upgrades
	updateArtificerIndicator()

	return result
end)

-- Hook into StartNewRun to ensure indicator is set up at run start
modutil.mod.Path.Wrap("StartNewRun", function(base, args)
	print("ArtificerIndicator: StartNewRun hook called")
	local result = base(args)

	-- Update indicator at the start of a new run
	updateArtificerIndicator()

	return result
end)

-- Hook into the specific function that decrements MetaConversionUses
modutil.mod.Path.Wrap("IncrementTableValue", function(base, table, key, amount)
	local result = base(table, key, amount or 1)

	-- If this is incrementing MetaConversionUses, update the indicator
	if key == "MetaConversionUses" then
		print("ArtificerIndicator: MetaConversionUses incremented, updating indicator")
		updateArtificerIndicator()
	end

	return result
end)