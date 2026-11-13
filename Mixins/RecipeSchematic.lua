

local addonName, addon = ...;



ForeverTBDProfessionsButtonMixin = {};

function ForeverTBDProfessionsButtonMixin:OnLoad()
	-- self.IconBorder:ClearAllPoints();
	-- self.IconBorder:SetPoint("TOPLEFT", self.Icon, "TOPLEFT", -1, 1);
	-- self.IconBorder:SetPoint("BOTTOMRIGHT", self.Icon, "BOTTOMRIGHT", 1, -1);
end

function ForeverTBDProfessionsButtonMixin:SetSlotQuality(quality, name)

    quality = quality or 1;
    local atlasData = ColorManager.GetAtlasDataForProfessionsItemQuality(quality);

    if (quality > 1) then
        --print(name, quality, "anchoring on top")
        -- self.IconBorder:ClearAllPoints();
        -- self.IconBorder:SetPoint("TOPLEFT", self.Icon, "TOPLEFT", -1, 0);
        -- self.IconBorder:SetPoint("BOTTOMRIGHT", self.Icon, "BOTTOMRIGHT", 1, -1);
    else
        --print(name, quality, "anchoring outside frame")
        -- self.IconBorder:ClearAllPoints();
        -- self.IconBorder:SetPoint("TOPLEFT", self.Icon, "TOPLEFT", -5, 4);
        -- self.IconBorder:SetPoint("BOTTOMRIGHT", self.Icon, "BOTTOMRIGHT", 4, -5);
    end

    if atlasData.atlas then
        --DevTools_Dump({ atlasData })
        --print("got atlas")
		self.IconBorder:SetAtlas(atlasData.atlas, TextureKitConstants.IgnoreAtlasSize);

		local overrideColor = atlasData.overrideColor;
        if overrideColor then
            self.IconBorder:SetVertexColor(overrideColor.r, overrideColor.g, overrideColor.b);
        else
            self.IconBorder:SetVertexColor(1, 1, 1);
        end
    else
        --print("no atlas")
	end
	self.IconBorder:Show();
end

function ForeverTBDProfessionsButtonMixin:SetReagent(reagent, count)
	local currencyID = reagent.currencyID;
	if currencyID then
		local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(currencyID);
		if currencyInfo then
			self.Icon:SetTexture(currencyInfo.iconFileID);
			self.Icon:Show();

			self:SetSlotQuality(currencyInfo.quality);
		end
	else
		local itemID = reagent.itemID;
        if itemID then
            local item = Item:CreateFromItemID(itemID);
            item:ContinueOnItemLoad(function()
                self:SetItem(itemID);
                local name, quality = self:GetItemInfo()
                self.Name:SetText(name)
                self:SetSlotQuality(quality, name);

                --i'm sure there is a proper tooltip for itembuttons
                self:SetScript("OnEnter", function()
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
                    GameTooltip:SetItemByID(itemID);
                    GameTooltip:Show();
                end)

            end)
            --DevTools_Dump({self:GetItemInfo()})
		end
	end

	self:SetItemButtonCount(count or 0);
end




ForeverTBDRecipeSchematicMixin = {};

function ForeverTBDRecipeSchematicMixin:OnLoad()
    self.OutputIcon.CircleMask:ClearAllPoints();
    self.OutputIcon.CircleMask:SetPoint("TOPLEFT", -1, 1);
    self.OutputIcon.CircleMask:SetPoint("BOTTOMRIGHT", 1, -1);
    NineSliceUtil.ApplyLayout(self.Tooltip, NineSliceLayouts.TooltipDefaultDarkLayout);
    self.OutputIcon.Icon:SetSize(48, 48)
end

function ForeverTBDRecipeSchematicMixin:OnShow()
    self:LoadRecipe();
end

local Resetter = function(_, button)
    button:SetItemButtonCount(0);
    button:SetSlotQuality(0);
    button:ClearAllPoints();
    button:Hide();
    button:SetScript("OnEnter", nil);
end

local ReagentButtonPool = CreateFramePool("ItemButton", UIParent, "ForeverTBDReagentsButtonTemplate", Resetter);
function ForeverTBDRecipeSchematicMixin:SetRecipe(recipeID, recipeData)
    self.recipeID = recipeID;
    self.recipeData = recipeData;
    self:LoadRecipe();
end

function ForeverTBDRecipeSchematicMixin:UpdateDescription()

    self.Description:Hide();

    local spell = Spell:CreateFromSpellID(self.recipeID);
    spell:ContinueOnSpellLoad(function()
        --local reagentInfos = self.transaction:CreateCraftingReagentInfoTbl();
        local description = C_TradeSkillUI.GetRecipeDescription(spell:GetSpellID(), {}) --, reagentInfos, self.transaction:GetAllocationItemGUID());
        --print(">", description)
        -- If an embedded icon is present, substitute a small vertical offset so the icon is centered with the adjacent text.
        local textureID, height = string.match(description, "|T(%d+):(%d+)|t");
        if textureID then
            local size = height or 24;
            local xOffset, yOffset = 0, 3;
            description = string.gsub(description, "|T.*|t", CreateSimpleTextureMarkup(textureID, size, size, xOffset, yOffset));
        end

        if description and description ~= "" then
            self.Description:SetText(description);
            self.Description:SetWidth(340);
            --self.Description:SetWidth(self:GetDescriptionWidth());
            self.Description:SetHeight(600);
            self.Description:SetHeight(self.Description:GetStringHeight() + 1);
            self.Description:Show();
            --self.Tooltip:SetSpellByID(spell:GetSpellID())
--135913
        --     self.Tooltip:Hide();
        -- else
        --     self.Tooltip:Show();
        end

        if spell:GetSpellTexture() == 135913 then
            --self.Tooltip:SetSpellByID(spell:GetSpellID())
            self.Tooltip:Hide();
        end
    end)

end

function ForeverTBDRecipeSchematicMixin:LoadRecipe()

    if self.recipeData == nil then
        return;
    end
    if self.recipeID == nil then
        return;
    end

    self.OutputIcon:Show();
    self.OutputText:Show();
    self.ReagentsContainer:Show();
    self.Tooltip:Show()
    ReagentButtonPool:ReleaseAll();

    --bit of a guess on this atm
    --local schematic = C_TradeSkillUI.GetRecipeSchematic(recipe.recipeID, false, recipe.maxTrivialLevel);
    local schematic = ProfessionsUtil.GetRecipeSchematic(self.recipeID, false) --, recipe.maxTrivialLevel);

    if self.recipeData.hyperlink then
        local item = Item:CreateFromItemLink(self.recipeData.hyperlink);
        item:ContinueOnItemLoad(function()
            local quality = item:GetItemQuality();
            self.OutputIcon:SetItemButtonQuality(quality, self.recipeData.hyperlink);
            self.OutputIcon.Icon:SetTexture(item:GetItemIcon());
            self.OutputText:SetText(item:GetItemName());

            self.OutputIcon:SetScript("OnClick", function()

            end)

            self.Tooltip:SetOwner(self, "ANCHOR_PRESERVE");
            self.Tooltip:SetHyperlink(self.recipeData.hyperlink);
            self.Tooltip:Show()
        end)

    else
        --print("Enchants have no hyperlink, grrr");
        self.OutputIcon:SetItemButtonQuality(1)
        self.OutputIcon.Icon:SetTexture(self.recipeData.icon);
        self.OutputText:SetText(self.recipeData.name);
    end

    self:UpdateDescription()

    --DevTools_Dump({schematic})

    local lastButton;
    local height = 1;
    if schematic and schematic.reagentSlotSchematics then
        for _, reagent in ipairs(schematic.reagentSlotSchematics) do
            local numRequired = reagent.quantityRequired;
            local itemID = reagent.reagents[1].itemID;

            local button = ReagentButtonPool:Acquire();
            button:SetParent(self.ReagentsContainer);
            button:SetReagent({itemID=itemID,}, numRequired);

            if (lastButton == nil) then
                button:SetPoint("TOPLEFT");
                lastButton = button;
            else
                button:SetPoint("TOPLEFT", lastButton, "BOTTOMLEFT", 0, -3);
                lastButton = button;
            end

            height = height + button:GetHeight() + 3;
            button:Show();
        end

        self.ReagentsContainer:SetSize(200, height)
    end


end

function ForeverTBDRecipeSchematicMixin:ClearRecipe()
    self.recipeData = nil;
    self.recipeID = nil;
    ReagentButtonPool:ReleaseAll();
    self.OutputIcon:Hide();
    self.OutputText:Hide();
    self.ReagentsContainer:Hide();
    self.Tooltip:Hide()
    self.Description:Hide();
end