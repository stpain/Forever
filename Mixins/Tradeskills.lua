

local addonName, addon = ...;

local SavedVars = addon.SavedVars;

local professions = {
    171,
    164,
    333,
    202,
    165,
    197,
    185,
    356,
    129,
    182,
    186,
    393,
}

local professionsBackgrounds = {
    [171] = "Professions-Specializations-Background-Alchemy",
    [164] = "Professions-Specializations-Background-Blacksmithing",
    [333] = "Professions-Specializations-Background-Enchanting",
    [202] = "Professions-Specializations-Background-Engineering",
    [165] = "Professions-Specializations-Background-Leatherworking",
    [197] = "Professions-Specializations-Background-Tailoring",
    [185] = "Professions-Specializations-Background-Cooking",
    [356] = "Professions-Specializations-Background-Fishing",
    [129] = "Professions-Recipe-Background-FirstAid",
    [182] = "Professions-Specializations-Background-Herbalism",
    [186] = "Professions-Specializations-Background-Mining",
    [393] = "Professions-Specializations-Background-Skinning",
}

local function GetSortedKeys(t)
    if (t == nil) then
        return {}
    end
    local t1 = {};
    for k, v in pairs(t) do
        table.insert(t1, k);
    end
    table.sort(t1, function(a, b)
        return a < b;
    end)
    return t1;
end

ForeverTBDTradeskillsMixin = {}

function ForeverTBDTradeskillsMixin:OnLoad()
    
    self:SetupProfessions();
end

function ForeverTBDTradeskillsMixin:SetupProfessions()

    local function OnProfessionSearch(searchTerm)
        self.SchematicForm.Background:SetAtlas("Professions-Recipe-Background")
        local dataProvider = CreateTreeDataProvider();
        local characterNodes = {};
        local professionNodes = {};
        local matchingRecipes = SavedVars:FindRecipeByName(searchTerm, true);
        if #matchingRecipes > 0 then
            for _, character in ipairs(addon.Characters) do
                professionNodes = {};
                for _, recipeID in ipairs(matchingRecipes) do
                    if character:HasRecipe(recipeID) then
                        if characterNodes[character:GetName()] == nil then
                            local characterName = character:GetName("colourized");
                            characterNodes[character:GetName()] = dataProvider:Insert({
                                name = characterName,
                                isHeader = true,
                            })
                        end
                        --characterNode:Insert(recipeID);
                        local recipeProfessionID = SavedVars:GetRecipeProfessionID(recipeID)
                        local professionName = C_TradeSkillUI.GetTradeSkillDisplayName(recipeProfessionID);
                        if professionNodes[professionName] == nil then
                            professionNodes[professionName] = characterNodes[character:GetName()]:Insert({
                                isHeader = true,
                                name = professionName,
                            })
                        end
                        professionNodes[professionName]:Insert(recipeID);
                    end
                end
            end
        end

        self.CharacterTreeScrollBox:SetDataProvider(dataProvider)
    end

    self.RecipeSearchBox:SetScript("OnTextChanged", function(editBox)
        local text = editBox:GetText();
        if (text == "") then
            editBox.Label:Show();
        else
            editBox.Label:Hide();
            if #text > 2 then
                OnProfessionSearch(text);
            end
        end
    end)


    local indent = 15;
    local padding = 10;
    local elementSpacing = 3;
    local characterTree = CreateScrollBoxListTreeListView(indent, padding, padding, padding, padding, elementSpacing);

    local function InitHeaderButton(button, elementData)
        button.treeNode = elementData;
        button.elementData = elementData:GetData();
        button.Name:SetText(button.elementData.name)
        button:RefreshStateIcon()
    end

    local function InitRecipeButton(button, elementData)
        button.recipeID = elementData:GetData();
        button.recipeData = SavedVars:FindRecipeByID(button.recipeID)

        if button.recipeData == nil then
            button.Content.Name:SetText("No data");
            button:SetScript("OnClick", nil);
            return;
        end
        button.Content.Name:SetText(button.recipeData.name)

        --since this is borrowed from blizz i need to adjust the anchors
        button.Content.Name:SetPoint("RIGHT", button.Content, "RIGHT", -4, 0)

        button:SetScript("OnClick", function()
            self.SchematicForm:SetRecipe(button.recipeID, button.recipeData)
        end)
    end

    characterTree:SetElementFactory(function(factory, treeNode)
        local elementData = treeNode:GetData();

        --this works for now but maybe could be neater
        --the treeview dp is getting either a recipeID or a characterName
        if (type(elementData) == "table") and elementData.isHeader then
            factory("StatisticsHeaderTemplate", InitHeaderButton);
        else
            factory("StatisticsEntryTemplate", InitRecipeButton)
        end
    end)
    ScrollUtil.InitScrollBoxListWithScrollBar(self.CharacterTreeScrollBox,
        self.CharacterTreeScrollBar, characterTree);


    local function OnProfessionSelected(profID)
        self.SchematicForm.Background:SetAtlas(professionsBackgrounds[profID])
        local dataProvider = CreateTreeDataProvider();


        local characters = self:GetCharactersForProfession(profID)
        if (#characters > 0) then
            for _, character in ipairs(characters) do
                local characterName = character:GetName("colourized");
                local characterNode = dataProvider:Insert({
                    name = characterName,
                    isHeader = true,
                });
                -- local key = character:GetProfessionKey(profID)
                -- if key then
                --     local recipeIDs = character:GetProfessionRecipeIDs(key); --re work this to extract from SavedVars
                --     if recipeIDs then
                --         for _, recipeID in ipairs(recipeIDs) do
                --             characterNode:Insert(recipeID);
                --         end
                --     end
                -- end

                local professionData = SavedVars:GetProfessionCategories(profID);
                local profDataSorted = GetSortedKeys(professionData);
                for _, categoryID in ipairs(profDataSorted) do
                    local categoryNode = characterNode:Insert({
                        name = professionData[categoryID].name,
                        isHeader = true,
                    })

                    local recipesSorted = GetSortedKeys(professionData[categoryID].recipes);
                    for _, recipeID in ipairs(recipesSorted) do
                        categoryNode:Insert(recipeID);
                    end
                end
            end
        end

        self.CharacterTreeScrollBox:SetDataProvider(dataProvider)
    end

    self.DropdownSelectProfession.OpenMenu:SetScript("OnClick", function()
        local menu = MenuUtil.CreateContextMenu(self.DropdownSelectProfession,
            function(owner, rootDescription)
                for _, id in ipairs(professions) do
                    local profName = C_TradeSkillUI.GetTradeSkillDisplayName(id)
                    rootDescription:CreateButton(profName, function()
                        self.DropdownSelectProfession.Text:SetText(profName);
                        OnProfessionSelected(id);
                        self.SchematicForm:ClearRecipe();
                    end)
                end
            end)
        menu:ClearAllPoints();
        menu:SetPoint("TOPLEFT", self.DropdownSelectProfession, "BOTTOMLEFT", 3, 0);
    end)
end

function ForeverTBDTradeskillsMixin:GetCharactersForProfession(professionID)
    local t = {};
    local professions = {"prof1", "prof2", "cooking", "fishing", "firstAid" };
    for _, character in ipairs(addon.Characters) do
        for _, profession in ipairs(professions) do
            if (character:GetProfessionID(profession) == professionID) then
                table.insert(t, character)
            end
        end
    end
    return t;
end






ForeverTBDDisenchantingSchematicMixin = {}

function ForeverTBDDisenchantingSchematicMixin:OnLoad()
    self.ScrollBox = CreateFrame("Frame", nil, self, "WowScrollBoxList")
    self.ScrollBox:SetPoint("TOPLEFT", self, "TOPLEFT", 20, -50)
    self.ScrollBox:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -30, 20)

    self.ScrollBar = CreateFrame("EventFrame", "AdventureGuideDungeonGridScrollBar", self, "MinimalScrollBar")
    self.ScrollBar:SetPoint("TOPRIGHT", -8, -4)
    self.ScrollBar:SetPoint("BOTTOMRIGHT", -8, 4)

    self.GridView = CreateScrollBoxListGridView(5, 0, 0, 0, 0, 5, 5)

    local function OnElementInitialize(element, elementData, isNew)
        element:SetDataBinding(elementData)
    end

    local function OnElementReset(element)
        element:ResetDataBinding()
    end

    self.GridView:SetElementInitializer("ForeverTBDDE_SecureMacroButton", GenerateClosure(OnElementInitialize));
    self.GridView:SetElementResetter(GenerateClosure(OnElementReset));

    self.GridView:SetPadding(1, 1, 1, 1, 1);

    ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, self.GridView);

    local anchorsWithBar = {
        CreateAnchor("TOPLEFT", self, "TOPLEFT", 20, -50),
        CreateAnchor("BOTTOMRIGHT", self.ScrollBar, "BOTTOMLEFT", -30, 20),
    };
    local anchorsWithoutBar = {
        CreateAnchor("TOPLEFT", self, "TOPLEFT", 20, -50),
        CreateAnchor("BOTTOMRIGHT", self, "BOTTOMRIGHT", -20, 20),
    };
    ScrollUtil.AddManagedScrollBarVisibilityBehavior(self.ScrollBox, self.ScrollBar, anchorsWithBar, anchorsWithoutBar);

    self:RegisterEvent("BAG_UPDATE_DELAYED");
    self:SetScript("OnEvent", function(_, event, ...)
        if self:IsShown() and (event == "BAG_UPDATE_DELAYED") then
            self:UpdateDisenchantGrid();
        end
    end)

end

function ForeverTBDDisenchantingSchematicMixin:UpdateDisenchantGrid()
    local deItems = self:GetContainerDisenchantableItems();
    local DataProvider = CreateDataProvider(deItems);
    self.GridView:SetDataProvider(DataProvider);
    if AuctionatorCraftingInfoProfessionsFrame then
        AuctionatorCraftingInfoProfessionsFrame:Hide()
    end
end

function ForeverTBDDisenchantingSchematicMixin:OnShow()
    if AuctionatorCraftingInfoProfessionsFrame then
        AuctionatorCraftingInfoProfessionsFrame:Hide()
    end
    self:UpdateDisenchantGrid();
end
function ForeverTBDDisenchantingSchematicMixin:OnHide()
    if AuctionatorCraftingInfoProfessionsFrame then
        AuctionatorCraftingInfoProfessionsFrame:Show()
    end
end

local function GetItemFullNameFromLink(link)
    if link:find("|Hitem") then
        local s = link:find("|h%[")
        local e = link:find("%]|h")
        return true, link:sub(s+3,e-1)
    end
    return false, "";
end
function ForeverTBDDisenchantingSchematicMixin:GetContainerDisenchantableItems()
    local equipment = {}
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local slotInfo = C_Container.GetContainerItemInfo(bag, slot)
            if slotInfo and slotInfo.itemID and slotInfo.hyperlink then
                local _, _, _, _, icon, itemClassID, itemSubClassID = C_Item.GetItemInfoInstant(slotInfo.itemID)
                local _, _, _, itemLevel = C_Item.GetItemInfo(slotInfo.itemID)
                local itemExpansion = select(15, C_Item.GetItemInfo(slotInfo.hyperlink))
                --print(itemExpansion)
                local itemLoc = ItemLocation:CreateFromBagAndSlot(bag, slot)
                if itemLoc then
                    local itemGUID = C_Item.GetItemGUID(itemLoc)
                    if itemGUID then
                        if (itemClassID == 2 or itemClassID == 4) and (slotInfo.quality > 1) then
                            local haveName, fullName = GetItemFullNameFromLink(slotInfo.hyperlink)
                            if haveName then
                                table.insert(equipment, {
                                    icon = icon,
                                    link = slotInfo.hyperlink,
                                    count = slotInfo.stackCount,
                                    name = fullName,
                                    ilvl = itemLevel or -1,
                                    guid = itemGUID,
                                    bagID = bag,
                                    slotID = slot,
                                    quality = slotInfo.quality,
                                })
                            end
                        end
                    end
                end
            end
        end
    end
    return equipment;
end













ForeverTBDDE_SecureMacroButtonMixin = {}

--this allows the gridview to use the current templates
function ForeverTBDDE_SecureMacroButtonMixin:SetDataBinding(binding)
    self:Init(binding)
end
function ForeverTBDDE_SecureMacroButtonMixin:ResetDataBinding()

end
function ForeverTBDDE_SecureMacroButtonMixin:OnEnter()
    if self.item then
        GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
        GameTooltip:SetHyperlink(self.item.link)
        GameTooltip:Show()
    end
end
function ForeverTBDDE_SecureMacroButtonMixin:OnLeave()
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
end

local borderColours = {
    [2] = "dressingroom-itemborder-green", --dressingroom-itemborder-green
    [3] = "dressingroom-itemborder-blue", --loottab-set-itemborder-green
    [4] = "dressingroom-itemborder-purple",
    [5] = "dressingroom-itemborder-orange",
}
function ForeverTBDDE_SecureMacroButtonMixin:Init(elementData)
    self.item = elementData;
    self:RegisterForClicks("AnyUp", "AnyDown")

    if self.text then
        self.text:SetText(elementData.link)
    end
    if self.icon then
        self.icon:SetTexture(elementData.icon)
    end
    if self.border then
        self.border:SetAtlas(borderColours[elementData.quality])
    end
    local macro = string.format([[
/cast %1$s
/use %2$d %3$d
]], "Disenchant", elementData.bagID, elementData.slotID) --will need to localize the spell name
    self:SetAttribute("type1", "macro")
    self:SetAttribute("macrotext1", macro)
end
