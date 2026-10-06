

local addonName, addon = ...;

local SavedVars = addon.SavedVars;
--local Characters = addon.Characters;

local ActiveCharacter;

local function UpdateProfessions()
    print("UpdateProfessions")
    if (ActiveCharacter ~= nil) then
        local prof1, prof2, firstAid, fishing, cooking = GetProfessions();

        local slot1ID = ActiveCharacter:GetProfessionID("prof1");
        local slot2ID = ActiveCharacter:GetProfessionID("prof2");


        if (slot1ID == slot2ID) then
            --ActiveCharacter:WipeProfession("prof1");
        end


        --[[
            Profession data can exists in a backwards order, for example

            Player learns first profession
            Player learns seconf profession
            Player unlearns first profession

            Character data now has prof1 data and recipes that no longer exist
            Character data now has prof2 data and recipes that will end up as 
            prof1 when this function is called as the GetProfessions will assign
            the only (second) profession into the prof1 return
        ]]


        if (prof1) then
            --local name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine, skillModifier, specializationIndex, specializationOffset, skillLineName = GetProfessionInfo(prof1);
            local profInfo = {GetProfessionInfo(prof1)};

            --this data matches existsing slot2 data, update prof2 instead
            if (profInfo[7] == slot2ID) then
                ActiveCharacter:SetProfession("prof2", profInfo);

            --either we have no prof1 data or this is a first time learn
            else
                ActiveCharacter:SetProfession("prof1", profInfo);

            end
        end

        if (prof2) then
            local profInfo = {GetProfessionInfo(prof2)};

            --reverse of above is true here
            if (profInfo[7] == slot1ID) then
                ActiveCharacter:SetProfession("prof1", profInfo);
            else
                ActiveCharacter:SetProfession("prof2", profInfo);
            end
        end
        if (fishing) then
            local profInfo = {GetProfessionInfo(fishing)};
            ActiveCharacter:SetProfession("fishing", profInfo);
        end
        if (cooking) then
            local profInfo = {GetProfessionInfo(cooking)};
            ActiveCharacter:SetProfession("cooking", profInfo);
        end
        if (firstAid) then
            local profInfo = {GetProfessionInfo(firstAid)};
            ActiveCharacter:SetProfession("firstAid", profInfo);
        end
    end

    collectgarbage();
end

local function UpdateXP()
    if (ActiveCharacter ~= nil) then
        local xp, xpMax = UnitXP("player"), UnitXPMax("player");
        ActiveCharacter:SetXP(xp, xpMax);
    end
end

local function UpdateLevel(newLevel)
    if (ActiveCharacter ~= nil) then
        ActiveCharacter:SetLevel(newLevel)
    end
end

local function UpdateMoney()
    if (ActiveCharacter ~= nil) then
        local money = GetMoney();
        ActiveCharacter:SetMoney(money);
    end
end

local function UpdateLocation()
    if (ActiveCharacter ~= nil) then
        local location = GetMinimapZoneText();
        ActiveCharacter:SetLocation(location);
    end
end








local Events = {
    "PLAYER_ENTERING_WORLD",
    "CHAT_MSG_SKILL",
    "CHAT_MSG_SYSTEM", --ERR_SPELL_UNLEARNED_S
    "PLAYER_XP_UPDATE",
    "PLAYER_LEVEL_UP",
    "PLAYER_MONEY",
    "ZONE_CHANGED",
    "ZONE_CHANGED_INDOORS",
    "ZONE_CHANGED_NEW_AREA",
    "PLAYER_LOGOUT",
    --"TRADE_SKILL_LIST_UPDATE",
    --"NEW_RECIPE_LEARNED",
    --"ADDON_LOADED",
    "TRADE_SKILL_DATA_SOURCE_CHANGED",
    "UNIT_AURA",
}


ForeverTBDMixin = {};

function ForeverTBDMixin:OnLoad()
    SLASH_FOREVERALTS1 = "/foreveralts";
    SlashCmdList.FOREVERALTS = function()
        self:Show();
    end

    table.insert(UISpecialFrames, self:GetName());

    for _, event in ipairs(Events) do
        self:RegisterEvent(event);
    end

    self:RegisterForDrag("LeftButton");

    for _, tab in ipairs(self.Tabs) do
        tab:SetChecked(false);
        tab:SetCustomOnMouseUpHandler(function(tabButton, hwButton, upInside)
            self:OnTabSelected(tab)
        end)
    end

    self:SetupCharacterSummary();
    self:SetupProfessions();

    addon.CallbackRegistry:RegisterCallback(addon.Callbacks.SavedVars_OnDataChanged, self.SavedVars_OnDataChanged, self)
end

function ForeverTBDMixin:OnTabSelected(tab)
    for _, tab in ipairs(self.Tabs) do
        tab:SetChecked(false);
    end
    tab:SetChecked(true);
    for _, frame in ipairs(self.Views) do
        frame:Hide();
        if (frame:GetID() == tab:GetID()) then
            frame:Show();
        end
    end
end

function ForeverTBDMixin:OnEvent(event, ...)
    if self[event] then
        self[event](self, ...);
    end
end

function ForeverTBDMixin:OnShow()
    
end

function ForeverTBDMixin:OnHide()
    
end

function ForeverTBDMixin:SavedVars_OnDataChanged()
    self:LoadCharacterSummaryList();
end

function ForeverTBDMixin:PLAYER_ENTERING_WORLD(...)
    local isInitial, isReload = ...;
    local unit = "player";

    if (isInitial or isReload) then

        SavedVars:Init();

        if DevTool.AddData then
            DevTool:AddData(ForeverTBDAccount, addonName)
        end

        local firstName, surname = UnitName(unit);
        local name = string.format("%s-%s", firstName, surname);

        ActiveCharacter = SavedVars:FindCharacterByPredicate(function(character)
            return character.name == name;
        end)

        if (ActiveCharacter == nil) then
            ActiveCharacter = SavedVars:NewCharacter();
        end

        ActiveCharacter:SetName(name);

        --the player might have deleted the character and reused the name
        --set the class and race IDs to be safe
        local _, race, raceID = UnitRace(unit);
        ActiveCharacter:SetRaceID(raceID);

        local factionInfo = C_CreatureInfo.GetFactionInfo(raceID);
        ActiveCharacter:SetFaction(factionInfo.groupTag);

        local _, class, classID = UnitClass(unit);
        ActiveCharacter:SetClassID(classID);

        local sex = UnitSex(unit);
        ActiveCharacter:SetSex(sex);

        local home = GetBindLocation();
        ActiveCharacter:SetHome(home);

        UpdateLocation();
        UpdateXP();
        UpdateMoney();
        UpdateLevel(UnitLevel("player"));
        UpdateProfessions();


        -- EventRegistry:RegisterCallback("Professions.ProfessionSelected", function(id, info)
        --     C_Timer.After(1, function()
        --         self:ScanRecipes(info.professionID)
        --     end)
        -- end)


        --when the player unlearns a profession we want to wipe the Character data for it and the recipes
        --this will create a nil for the character data slot which allows the UpdateProfessions function to
        --assign the correct professions
        hooksecurefunc(C_SkillInfo, "AbandonSkill", function(skillLine)
            --print("Wiping SkillID", skillLine);
            local slot1ID = ActiveCharacter:GetProfessionID("prof1");
            if (slot1ID == skillLine) then
                ActiveCharacter:WipeProfession("prof1");
                return;
            end
            local slot2ID = ActiveCharacter:GetProfessionID("prof2");
            if (slot2ID == skillLine) then
                ActiveCharacter:WipeProfession("prof2");
                return;
            end
        end)

        if (ActiveCharacter ~= nil) then
            local loginTime = ActiveCharacter:GetLoginTime();
            if (loginTime == nil) then
                local loginTime = time();
                ActiveCharacter:SetLoginTime(loginTime);
            end
        end

    end

    if (isInitial == true) and (ActiveCharacter ~= nil) then
        local loginTime = time();
        ActiveCharacter:SetLoginTime(loginTime);
    end

    self:LoadCharacterSummaryList();
end


function ForeverTBDMixin:CHAT_MSG_SKILL(...)
    UpdateProfessions();
end

function ForeverTBDMixin:CHAT_MSG_SYSTEM(...)
    -- local msg = ...;
    -- local pattern = ERR_SPELL_UNLEARNED_S:gsub("%%s", "(.+)");
    -- local text = msg:match("^"..pattern.."$");
    -- if text then
    --     print(text)
    --     DevTools_Dump(LinkUtil.SplitLink(text))
    -- end
end

function ForeverTBDMixin:PLAYER_XP_UPDATE()
    UpdateXP();
end

function ForeverTBDMixin:PLAYER_LEVEL_UP(...)
    local newLevel = ...;
    UpdateLevel(newLevel);
end

function ForeverTBDMixin:PLAYER_MONEY()
    UpdateMoney();
end

function ForeverTBDMixin:ZONE_CHANGED_INDOORS()
    UpdateLocation();
end

function ForeverTBDMixin:ZONE_CHANGED_NEW_AREA()
    UpdateLocation();
end

function ForeverTBDMixin:ZONE_CHANGED()
    UpdateLocation();
end

function ForeverTBDMixin:UNIT_AURA(...)
    local unitTarget, updateInfo = ...;
    if (unitTarget == "player") then
        
    end
end

function ForeverTBDMixin:NEW_RECIPE_LEARNED(...)
    local recipeID, recipeLevel = ...;
    if recipeID then
        local spell = Spell:CreateFromSpellID(recipeID);
        spell:ContinueOnSpellLoad(function()
            local name = spell:GetSpellName();
            local icon = C_Spell.GetSpellTexture(recipeID);
            local link = C_Spell.GetSpellLink(recipeID);
        end)
    end
end

function ForeverTBDMixin:TRADE_SKILL_DATA_SOURCE_CHANGED()
    local professionLink = C_TradeSkillUI.GetTradeSkillListLink();
    --print(professionLink)
    if (professionLink) then
        local linkType, payload, displayText = LinkUtil.ExtractLink(professionLink);
        local guid, _, profID = strsplit(":", payload);
        if tonumber(profID) then
            --print(profID)
            self:ScanRecipes(profID);
        end
    end
end


function ForeverTBDMixin:ADDON_LOADED(...)
    -- local addon = ...;
    -- if (addon == "Blizzard_Professions") then
    --     local lastCall = 0;
    --     hooksecurefunc(ProfessionsFrame.CraftingPage.RecipeList.ScrollBox, "SetDataProvider", function()
            
    --     end)
    -- end
end

function ForeverTBDMixin:SetupCharacterSummary()

    --[[
        Setup the main listbox
        uses the 'ForeverTBDCharacterSummaryTemplate' template
    ]]
    local characterSummaryView = CreateScrollBoxListLinearView();
    characterSummaryView:SetElementExtent(70);
    characterSummaryView:SetElementResetter(function(frame)
        frame:ClearCharacter();
    end)
    characterSummaryView:SetElementInitializer("ForeverTBDCharacterSummaryTemplate", function(frame, data)
        frame:Init(data);
    end)
    ScrollUtil.InitScrollBoxListWithScrollBar(self.CharacterSummary.ScrollBox, self.CharacterSummary.ScrollBar, characterSummaryView);

    --[[
        Create the class filter menu button
    ]]
    self.CharacterSummary.DropdownButtonClass.OpenMenu:SetScript("OnClick", function()
        local menu = MenuUtil.CreateContextMenu(self.CharacterSummary.DropdownButtonClass, function(owner, rootDescription)
            rootDescription:CreateTitle(FILTER);
            rootDescription:CreateButton(ALL, function()
                self.CharacterSummary.DropdownButtonClass.Text:SetText(CLASS);
                self:LoadCharacterSummaryList({
                    key = "classID",
                    func = nil;
                })
            end)
            rootDescription:CreateDivider();

            for i = 1, 12 do
                    local class, _, classID = GetClassInfo(i);
                if (class and classID) then
                    rootDescription:CreateButton(class, function()
                        self.CharacterSummary.DropdownButtonClass.Text:SetText(class);
                        local filter = function(character)
                            return character:GetClassID() == classID;
                        end
                        self:LoadCharacterSummaryList({
                            key = "classID",
                            func = filter,
                        });
                    end)
                end
            end
        end)

        menu:ClearAllPoints();
        menu:SetPoint("TOPLEFT", self.CharacterSummary.DropdownButtonClass, "BOTTOMLEFT", 3, 0);
    end)

    --[[
        Create the profession filter menu button
    ]]
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
    self.CharacterSummary.DropdownButtonProfession.OpenMenu:SetScript("OnClick", function()
        local menu = MenuUtil.CreateContextMenu(self.CharacterSummary.DropdownButtonProfession, function(owner, rootDescription)
            rootDescription:CreateTitle(FILTER);
            rootDescription:CreateButton(ALL, function()
                self.CharacterSummary.DropdownButtonProfession.Text:SetText(PROFESSIONS_BUTTON);
                self:LoadCharacterSummaryList({
                    key = "profession",
                    func = nil;
                })
            end)
            rootDescription:CreateDivider();
                for _, id in ipairs(professions) do
                local profName = C_TradeSkillUI.GetTradeSkillDisplayName(id)
                rootDescription:CreateButton(profName, function()
                    self.CharacterSummary.DropdownButtonProfession.Text:SetText(profName);
                    local filter = function(character)
                        local prof1 = character:GetProfession("prof1");
                        local prof2 = character:GetProfession("prof2");
                        if prof1 and (prof1[7] == id) then
                            return true;
                        end
                        if prof2 and (prof2[7] == id) then
                            return true;
                        end
                        
                        --for these we just need to know if it exists and has skillLevel
                        if (id == 185) then
                            local cooking = character:GetProfession("cooking");
                            if cooking and cooking[3] and (cooking[3] > 0) then
                                return true;
                            end
                        end
                        if (id == 129) then
                            local firstAid = character:GetProfession("firstAid");
                            if firstAid and firstAid[3] and (firstAid[3] > 0) then
                                return true;
                            end
                        end
                        if (id == 356) then
                            local fishing = character:GetProfession("fishing");
                            if fishing and fishing[3] and (fishing[3] > 0) then
                                return true;
                            end
                        end
                    end
                    self:LoadCharacterSummaryList({
                        key = "profession",
                        func = filter,
                    });
                end)
            end
        end)

        menu:ClearAllPoints();
        menu:SetPoint("TOPLEFT", self.CharacterSummary.DropdownButtonProfession, "BOTTOMLEFT", 3, 0);
    end)

    self.characterSummaryFilters = {};
end


---Loads Characters into the summary using set filters, if none it loads all characters
---@param filter table? { key=filterKey, func=function, } the filterKey is used to manage adding/updating/removing the filter, the func is passed the Character and should return true for valid matches
function ForeverTBDMixin:LoadCharacterSummaryList(filter)

    if (filter) then
        self.characterSummaryFilters[filter.key] = filter.func;
    end

    local dataProvider = CreateDataProvider();

    if next(self.characterSummaryFilters) ~= nil then
        for _, character in ipairs(addon.Characters) do
            local isMatch = true;
            for k, filter in pairs(self.characterSummaryFilters) do
                if filter(character) ~= true then
                    isMatch = false;
                end
            end
            if (isMatch == true) then
                dataProvider:Insert(character);
            end
        end
    else
        for _, character in ipairs(addon.Characters) do
            dataProvider:Insert(character);
        end
    end

    self.CharacterSummary.ScrollBox:SetDataProvider(dataProvider);
end


function ForeverTBDMixin:SetupProfessions()
    local function OnProfessionSearch(searchTerm)
        self.Professions.SchematicForm.Background:SetAtlas("Professions-Recipe-Background")
        local dataProvider = CreateTreeDataProvider();
        for _, character in ipairs(addon.Characters) do
            local recipesFound = character:SearchRecipes(searchTerm);
            if (#recipesFound > 0) then
                local name = character:GetName();
                local characterNode = dataProvider:Insert({
                    name = name,
                    isCharacter = true,
                });
                for _, recipe in ipairs(recipesFound) do
                    characterNode:Insert(recipe);
                end
            end
        end
        self.Professions.CharacterTreeScrollBox:SetDataProvider(dataProvider)
        --        collectgarbage();
    end

    self.Professions.RecipeSearchBox:SetScript("OnTextChanged", function(editBox)
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

    local function InitCharacterButton(button, elementData)
        button.treeNode = elementData;
        button.elementData = elementData:GetData();
        button.Name:SetText(button.elementData.name)
        button:RefreshStateIcon()
    end

    local function InitRecipeButton(button, elementData)
        button.elementData = elementData:GetData();
        button.Content.Name:SetText(button.elementData.name)

        --since this is borrowed from blizz i need to adjust the anchors
        button.Content.Name:SetPoint("RIGHT", button.Content, "RIGHT", -4, 0)

        button:SetScript("OnClick", function()
            self.Professions.SchematicForm:LoadRecipe(button.elementData)
        end)
    end

    characterTree:SetElementFactory(function(factory, treeNode)
        local elementData = treeNode:GetData();
        if elementData.isCharacter then
            factory("StatisticsHeaderTemplate", InitCharacterButton);
        else
            factory("StatisticsEntryTemplate", InitRecipeButton)
        end
    end)
    ScrollUtil.InitScrollBoxListWithScrollBar(self.Professions.CharacterTreeScrollBox,
        self.Professions.CharacterTreeScrollBar, characterTree);

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
    local function OnProfessionSelected(profID)
        self.Professions.SchematicForm.Background:SetAtlas(professionsBackgrounds[profID])
        local dataProvider = CreateTreeDataProvider();
        local characters = self:GetCharactersForProfession(profID)
        if (#characters > 0) then
            for _, character in ipairs(characters) do
                local name = character:GetName();
                local characterNode = dataProvider:Insert({
                    name = name,
                    isCharacter = true,
                });
                local key = character:GetProfessionKey(profID)
                if key then
                    local recipes = character:GetProfessionRecipes(key);
                    if recipes then
                        for _, recipe in ipairs(recipes) do
                            characterNode:Insert(recipe);
                        end
                    end
                end
            end
        end
        self.Professions.CharacterTreeScrollBox:SetDataProvider(dataProvider)
    end

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
    self.Professions.DropdownSelectProfession.OpenMenu:SetScript("OnClick", function()
        local menu = MenuUtil.CreateContextMenu(self.Professions.DropdownSelectProfession,
            function(owner, rootDescription)
                for _, id in ipairs(professions) do
                    local profName = C_TradeSkillUI.GetTradeSkillDisplayName(id)
                    rootDescription:CreateButton(profName, function()
                        self.Professions.DropdownSelectProfession.Text:SetText(profName);
                        OnProfessionSelected(id);
                        self.Professions.SchematicForm:ClearRecipe();
                    end)
                end
            end)
        menu:ClearAllPoints();
        menu:SetPoint("TOPLEFT", self.Professions.DropdownSelectProfession, "BOTTOMLEFT", 3, 0);
    end)
end

local RecipeListHooked = false;
function ForeverTBDMixin:ScanRecipes(professionID)

    professionID = tonumber(professionID);

    local hasUpdated = false;

    local function ScanAndSetCharacterRecipes(recipes)
        --print("scan and set")
        local professions = {"prof1", "prof2", "cooking", "fishing", "firstAid" };
        for _, profession in ipairs(professions) do
            local profID = ActiveCharacter:GetProfessionID(profession);
            --print(profID, professionID)
            --print(type(profID), type(professionID));
            if (ActiveCharacter:GetProfessionID(profession) == professionID) then
                ActiveCharacter:SetProfessionRecipes(profession, recipes);
                hasUpdated = true;
                --print("updated prof")
            end
        end
    end

    local function ScanDataProvider()
        if (ProfessionsFrame.CraftingPage.RecipeList.ScrollBox:HasDataProvider() == true) then
            local recipes = {}
            for k, element in ProfessionsFrame.CraftingPage.RecipeList.ScrollBox:GetDataProvider():EnumerateEntireRange() do
                if element.data and element.data.recipeInfo then
                    local capture = {}
                    capture.recipeID = element.data.recipeInfo.recipeID
                    capture.name = element.data.recipeInfo.name
                    --capture.categoryID = element.data.recipeInfo.categoryID
                    capture.hyperlink = element.data.recipeInfo.hyperlink
                    capture.icon = element.data.recipeInfo.icon
                    --capture.learned = element.data.recipeInfo.learned
                    capture.maxTrivialLevel = element.data.recipeInfo.maxTrivialLevel
                    --capture.relativeDifficulty = element.data.recipeInfo.relativeDifficulty
                    table.insert(recipes, capture)
                end
            end

            ScanAndSetCharacterRecipes(recipes);

            if (hasUpdated == false) then
                UpdateProfessions();
                ScanAndSetCharacterRecipes(recipes);
            end

            recipes = nil;
        end
    end

    --could probably move this into the PEW but would need to rejiggle the local functions into the mixin
    if (RecipeListHooked == false) then
        hooksecurefunc(ProfessionsFrame.CraftingPage.RecipeList.ScrollBox, "SetDataProvider", function()
            ScanDataProvider();
            --print("hook run > call scan recipes")
        end)
        RecipeListHooked = true;
        --print("hook SetDataProvider")
    end

end


function ForeverTBDMixin:GetCharactersForProfession(professionID)
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

