

local addonName, addon = ...;


--should move this later
StaticPopupDialogs['ForeverConfirmTakeInboxGoldDialog'] = {
    text = addon.locales.confirmTakeInboxGoldDialogText_S,
    button1 = YES,
    button2 = NO,
    button3 = REPORT_PLAYER,
    OnAccept = function(self, data)
        OpenMailFrame.updateButtonPositions = false;
        TakeInboxMoney(InboxFrame.openMailID);
    end,
    OnCancel = function()
        
    end,
    OnAlt = function(self, data)
        -- local reportInfo = ReportInfo:CreateMailReportInfo(Enum.ReportType.Mail, InboxFrame.openMailID);
        -- if (reportInfo) then
        --     local reportTarget = ConsortiumMailFrame:IsShown() and C_Mail.GetCraftingOrderMailInfo(InboxFrame.openMailID).crafterName or InboxFrame.openMailSender;
        --     ReportFrame:InitiateReport(reportInfo, reportTarget);
        -- end
        -- OpenMailFrame.ReportSpamButton:Disable();

        OpenMailReportSpamButton:Click();
    end,
    OnShow = function(self, data)

    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
}



local SavedVars = addon.SavedVars;

local ActiveCharacter;

local function UpdateProfessions()
    --print("UpdateProfessions")
    if (ActiveCharacter ~= nil) then
        local prof1, prof2, firstAid, fishing, cooking = GetProfessions();

        -- local slot1ID = ActiveCharacter:GetProfessionID("prof1");
        -- local slot2ID = ActiveCharacter:GetProfessionID("prof2");

        -- print(slot1ID, slot2ID)
        -- print("=================")


        -- if (slot1ID == slot2ID) then
        --     --ActiveCharacter:WipeProfession("prof1");
        -- end


        --[[
            Profession data can exists in a backwards order, for example

            Player learns first profession
            Player learns second profession
            Player unlearns first profession

            Character data now has prof1 data and recipes that no longer exist
            Character data now has prof2 data and recipes that will end up as 
            prof1 when this function is called as the GetProfessions will assign
            the only (second) profession into the prof1 return
        ]]


        if (prof1) then
            --local name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine, skillModifier, specializationIndex, specializationOffset, skillLineName = GetProfessionInfo(prof1);
            local profInfo = {GetProfessionInfo(prof1)};

            --print("in prof 1", profInfo[1])

            local slot2ID = ActiveCharacter:GetProfessionID("prof2");

            --this data matches existsing slot2 data, update prof2 instead
            if (profInfo[7] == slot2ID) then
                --print("matches prof2 character data, setting as prof2")
                ActiveCharacter:SetProfession("prof2", profInfo);


            --either we have no prof1 data or this is a first time learn
            else
                --print("didn't match prof2 character data, setting as prof1")
                ActiveCharacter:SetProfession("prof1", profInfo);

            end
        end

        --print("=================")

        if (prof2) then
            local profInfo = {GetProfessionInfo(prof2)};

            local slot1ID = ActiveCharacter:GetProfessionID("prof1");

            --print("in prof 2", profInfo[1])

            --reverse of above is true here
            if (profInfo[7] == slot1ID) then
                --print("matches prof1 character data, setting as prof1")
                ActiveCharacter:SetProfession("prof1", profInfo);
            else
                --print("didn't match prof1 character data, setting as prof2")
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
    --"PLAYER_LOGOUT",
    --"TRADE_SKILL_LIST_UPDATE",
    --"NEW_RECIPE_LEARNED",
    --"ADDON_LOADED",
    --"TRADE_SKILL_DATA_SOURCE_CHANGED",
    "UNIT_AURA",
    "UI_INFO_MESSAGE",
    "PLAYER_INTERACTION_MANAGER_FRAME_SHOW",
    "PLAYER_UPDATE_RESTING",
}


ForeverTBDMixin = {};

function ForeverTBDMixin:OnLoad()
    SLASH_FOREVER1 = "/ftbd";
    SlashCmdList.FOREVER = function()
        self:Show();
    end

    self.HelpTipButton:SetFrameLevel(self.TitleContainer:GetFrameLevel() + 2);
    _G[self:GetName().."Portrait"]:SetTexture([[Interface\Addons\Forever\Media\tbd-icon.png]])

    table.insert(UISpecialFrames, self:GetName());

    for _, event in ipairs(Events) do
        self:RegisterEvent(event);
    end

    self:RegisterForDrag("LeftButton");

    self.Options:SetScript("OnClick", function()
        for _, frame in ipairs(self.Views) do
            frame:Hide()
        end
        for _, tab in ipairs(self.Tabs) do
            tab:SetChecked(false);
        end
        self.selectedTabID = 0;
        self.helptipIndex = 0;
        HelpTip:HideAll(self)
        self.OptionsPanel:Show();
    end)

    --button = _G["MailItem"..i.."Button"];

    --[[
        hook InboxFrame:Update and loop buttons check for money and disable
    ]]

    self.OptionsPanel.RESET_EVERYTHING:SetScript("OnClick", function()
        SavedVars:Init(true);
    end)

    self.selectedTabID = 1;
    for k, tab in ipairs(self.Tabs) do
        tab:SetChecked(false);
        tab:SetCustomOnMouseUpHandler(function(tabButton, hwButton, upInside)
            self:OnTabSelected(tab);
        end)
        if (k == self.selectedTabID) then
            self:OnTabSelected(tab);
        end
    end

    self:InitHelpTips();
    self:SetupProfessions();
    self:SetupHooks();

    addon.CallbackRegistry:RegisterCallback(addon.Callbacks.SavedVars_OnDataChanged, self.SavedVars_OnDataChanged, self)
    addon.CallbackRegistry:RegisterCallback(addon.Callbacks.SavedVars_OnInitialized, self.SavedVars_OnInitialized, self)
end

function ForeverTBDMixin:CreateOptions()

    --[[
        Options panel, designed for future options,
        currently using checkboxes but open to new option templates

        The ConfigInitializer will check for a key which is used
        to determine the functionality

        for example a bool toggle uses a .Checkbox which sets up
        with a GetConfig and SetConfig 
    ]]

    local layout = {

        --this can become a menu on the left
        general = {

            -- the SavedVars .config key and template to use
            --the key is important and is also a locale lookup
            {
                configKey = "autoVendorJunk",
                configTemplate = "ForeverTBDOptionsListCheckboxTemplate"
            },
            {
                configKey = "disableInboxGold",
                configTemplate = "ForeverTBDOptionsListCheckboxTemplate"
            },
            {
                configKey = "displayRestedFlipbook",
                configTemplate = "ForeverTBDOptionsListCheckboxTemplate"
            },
            {
                configKey = "useServerTimeForJournal",
                configTemplate = "ForeverTBDOptionsListCheckboxTemplate"
            },
        }
    }

    -- local function TooltipFunc()

    -- end

    local function ConfigInitializer(frame, elementData)
        local currentConfig = SavedVars:GetConfig(elementData.configKey);

        --DevTools_Dump({elementData})
        --DevTools_Dump(addon.locales)
        local displayText = addon.locales[elementData.configKey];
        frame.Text:SetText(displayText);

        frame:SetScript("OnEnter", function()
            frame.HoverBackground:Show();
            if addon.locales[elementData.configKey.."_TT"] then
                GameTooltip:SetOwner(frame, "ANCHOR_TOP", 90);
                GameTooltip:AddLine(displayText, 1,1,1);
                GameTooltip:AddLine(addon.locales[elementData.configKey.."_TT"], nil, nil, nil, true)
                GameTooltip:Show();
            end
        end)
        frame:SetScript("OnLeave", function()
            frame.HoverBackground:Hide();
            GameTooltip_SetDefaultAnchor(GameTooltip, UIParent);
        end)

        frame.NewFeature:Show();
        
        if (frame.CheckBox) then
            frame.CheckBox:SetChecked(currentConfig.value);

            frame.CheckBox:SetScript("OnClick", function(checkbox)
                SavedVars:SetConfig(elementData.configKey, checkbox:GetChecked());
            end)
            return;
        end
    end

    --doing this for future reference on order
    local topPadding = 1;
    local bottomPadding = 1;
	local leftPadding = 1;
	local rightPadding = 1;
	local spacing = 1;
    local optionsList = CreateScrollBoxListLinearView(topPadding, bottomPadding, leftPadding, rightPadding, spacing);
    optionsList:SetElementExtent(26);
    optionsList:SetElementResetter(function(frame)
        
    end)
    optionsList:SetElementFactory(function(factory, elementData)
        factory(elementData.template, elementData.initializer)
    end)
    ScrollUtil.InitScrollBoxListWithScrollBar(self.OptionsPanel.ScrollBox, self.OptionsPanel.ScrollBar, optionsList);

    local dataProvider = CreateDataProvider();

    for _, opt in ipairs(layout.general) do
        dataProvider:Insert({
            template = opt.configTemplate,
            initializer = ConfigInitializer,
            configKey = opt.configKey,
        })
    end
    
    optionsList:SetDataProvider(dataProvider, true);
end

function ForeverTBDMixin:CreateMinimapButton()
    
    local iconName = addonName.."MinimapButton";
    local iconDb = SavedVars:GetTable("minimap");

    local function onClick()
        self:SetShown(not self:IsVisible())
    end

    local ldb = LibStub("LibDataBroker-1.1"):NewDataObject(iconName, {
            type = "launcher",
            icon = 132222,
            OnClick = onClick,
    })
    if ldb == nil then
        return;
    end
    LibStub("LibDBIcon-1.0"):Register(iconName, ldb, iconDb)

    local minimapButtonName = string.format("LibDBIcon10_%sMinimapButton", addonName);
    
    local button = _G[minimapButtonName];
    button.icon:SetAtlas("gamepad-radial-icon-shop");
    button.icon:ClearAllPoints();
    button.icon:SetPoint("TOPLEFT", 1, -1);
    button.icon:SetPoint("BOTTOMRIGHT", 1, -1);

    button.iconMask = button:CreateMaskTexture();
    button.iconMask:SetPoint("TOPLEFT", 4, -4);
    button.iconMask:SetPoint("BOTTOMRIGHT", 1, -1);
    button.iconMask:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE");
    button.icon:AddMaskTexture(button.iconMask);
    

    local flipbookAtlasName = button:GetName() .. "FlipbookTexture"
    local flipbookAtlas = button:CreateTexture(flipbookAtlasName, "OVERLAY");
    flipbookAtlas:SetPoint("CENTER", 0, 0);
    flipbookAtlas:SetSize(80, 80);
    flipbookAtlas:SetAtlas("dragonriding_sgvigor_burst_flipbook");
    flipbookAtlas:SetAlpha(0)

    local animGroup = button:CreateAnimationGroup();
    animGroup:SetToFinalAlpha(true);

    local flipbook = animGroup:CreateAnimation("FlipBook");
    flipbook:SetFlipBookColumns(4);
    flipbook:SetFlipBookRows(4);
    flipbook:SetFlipBookFrameHeight(0);
    flipbook:SetFlipBookFrameWidth(0);
    flipbook:SetFlipBookFrames(16);
    flipbook:SetTargetName(flipbookAtlasName);
    flipbook:SetDuration(0.7);
    flipbook:SetOrder(1);

    local alphaOut = animGroup:CreateAnimation("Alpha");
    alphaOut:SetOrder(1);
    alphaOut:SetStartDelay(0.7)
    alphaOut:SetDuration(0.3);
    alphaOut:SetTargetName(flipbookAtlasName);
    alphaOut:SetFromAlpha(1);
    alphaOut:SetFromAlpha(0);

    animGroup:SetScript("OnFinished", function()
        --button.icon:Show();
        C_Timer.After(0.75, function()
            if button:IsMouseOver() then
                flipbookAtlas:SetAlpha(1);
                animGroup:Play();
            end
        end)
    end)

    button.UpdateTooltip = function()
        GameTooltip:SetOwner(button, "ANCHOR_TOPRIGHT");
        GameTooltip:AddLine(addonName);
        --tt:AddLine(" ");
        --tt:AddLine("");

        GameTooltip:Show();
    end

    button:SetScript("OnEnter", function()
        button.UpdateTooltip();
        --button.icon:Hide();
        flipbookAtlas:SetAlpha(1);
        animGroup:Play();
    end)

    button:SetScript("OnLeave", function()
        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent);
        animGroup:Stop();
        flipbookAtlas:SetAlpha(0);
        --button.icon:Show();
    end)

    --dragonriding_sgvigor_burst_flipbook UF-Essence-Flipbook-FX-Circ

end

function ForeverTBDMixin:InitHelpTips()
    
    local helptipAnchors = {
        [1] = {
            [1] = self.CharacterSummary.ScrollBox,
            [2] = self.CharacterSummary.DropdownButtonFaction,
            [3] = self.CharacterSummary.ScrollBox,
            [4] = self.CharacterSummary.ScrollBox,
        },

        [2] = {
            [1] = self.Professions.DropdownSelectProfession,
            [2] = self.Professions.RecipeSearchBox,
            [3] = self.Professions.CharacterTreeScrollBox,
            [4] = self.Professions.SchematicForm,
        },

        [3] = {
            [1] = self.Whispers.CharacterScrollBox,
            [2] = self.Whispers.MessagesScrollBox,
            [3] = self.Whispers.SendMessageButton,
        },
    }

    self.helptipIndex = 0;
    local function ProgressHelptip()
        self.helptipIndex = self.helptipIndex + 1;
        if addon.helptipData[self.selectedTabID] then
            local helptip = addon.helptipData[self.selectedTabID][self.helptipIndex];
            if helptip then
                helptip.onAcknowledgeCallback = ProgressHelptip;
                HelpTip:Show(self, helptip, helptipAnchors[self.selectedTabID][self.helptipIndex])
            else
                self.helptipIndex = 0;
            end
        end
    end
    self.HelpTipButton:SetScript("OnClick", function()
        ProgressHelptip()
    end)
end

function ForeverTBDMixin:SetupHooks()
    local professionSelected;

    ProfessionsFrame:HookScript("OnHide", function()
        self.lastProfessionID = nil;
    end)

    EventRegistry:RegisterCallback("Professions.ProfessionSelected", function(id, info)
        professionSelected = info.professionID;
        --print("selected prof id set")
    end)
    hooksecurefunc(ProfessionsFrame.CraftingPage.RecipeList.ScrollBox, "SetDataProvider", function()
        --print("Prof data provider set > hook call")
        if (ActiveCharacter == nil) then
            return;
        end
        local professionID;
        local professionLink = C_TradeSkillUI.GetTradeSkillListLink();
        if (professionLink) then
            local linkType, payload, displayText = LinkUtil.ExtractLink(professionLink);
            local guid, _, profID = strsplit(":", payload);
            if tonumber(profID) then
                professionID = profID;
                --print(professionLink, profID)
            end
        end
        if (professionID == nil) then
            if (professionSelected) then
                professionID = professionSelected;
                --print("professionID=nil, no link, falling back to profession selected ID")
            end
        end
        self:ScanRecipes(professionID);
        professionSelected = nil;
    end)

    --when the player unlearns a profession we want to wipe the Character data for it and the recipes
    --this will create a nil for the character data slot which allows the UpdateProfessions function to
    --assign the correct professions
    hooksecurefunc(C_SkillInfo, "AbandonSkill", function(skillLine)
        if (ActiveCharacter == nil) then
            return;
        end
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


    --[[
        With the RMT issues and Blizzard taking action
        its possible to get sent gold from a bad actor

        The aim here is to prevent the player from accidently
        taking gold from their inbox.

        Blizzard OpenMailmoneyButton script
            OpenMailFrame.updateButtonPositions = false;
            TakeInboxMoney(InboxFrame.openMailID);
    ]]
    OpenMailMoneyButton:HookScript("OnShow", function(button)
        local bodyText, stationeryID1, stationeryID2, isTakeable, isInvoice, isConsortium = GetInboxText(InboxFrame.openMailID);
        if (isInvoice == true) then
            --AH invoice should be legit gold
            return;
        end

        local shouldDisableMailGold = SavedVars:GetConfig("disableInboxGold");
        if (shouldDisableMailGold.value == true) then
            --local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, itemCount, wasRead, wasReturned, textCreated, canReply = GetInboxHeaderInfo(InboxFrame.openMailID);
            local sender = select(3, GetInboxHeaderInfo(InboxFrame.openMailID));
            button:SetScript("OnClick", function()
                StaticPopup_Show("ForeverConfirmTakeInboxGoldDialog", sender)
            end)
        else
            button:SetScript("OnClick", function()
                OpenMailFrame.updateButtonPositions = false;
                TakeInboxMoney(InboxFrame.openMailID);
            end)
        end
    end)

end

function ForeverTBDMixin:OnTabSelected(tab)
    HelpTip:HideAll(self)
    self.helptipIndex = 0;
    for _, tab in ipairs(self.Tabs) do
        tab:SetChecked(false);
    end
    tab:SetChecked(true);
    for _, frame in ipairs(self.Views) do
        frame:Hide();
        if (frame:GetID() == tab:GetID()) then
            frame:Show();
            self.selectedTabID = tab:GetID();
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

function ForeverTBDMixin:SavedVars_OnInitialized()

    if DevTool.AddData then
        DevTool:AddData(ForeverTBDAccount, addonName)
        DevTool:AddData(ForeverTBDCharacter, addonName.."Character")
    end

    self:CreateMinimapButton();
    self:CreateOptions();

    local unit = "player";

    local firstName, surname = UnitName(unit);
    local name = string.format("%s-%s", firstName, surname);

    ActiveCharacter = SavedVars:FindCharacterByPredicate(function(character)
        return character.name == name;
    end)

    local isNew = false;
    if (ActiveCharacter == nil) then
        ActiveCharacter = SavedVars:NewCharacter();
        isNew = true;
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

    local isResting = IsResting();
    ActiveCharacter:SetResting(isResting);

    UpdateLocation();
    UpdateXP();
    UpdateMoney();
    UpdateLevel(UnitLevel("player"));
    UpdateProfessions();

    if (ActiveCharacter ~= nil) then
        local loginTime = ActiveCharacter:GetLoginTime();
        if (loginTime == nil) then
            local loginTime = time();
            ActiveCharacter:SetLoginTime(loginTime);
        end
    end

    if isNew == true then
        addon.CallbackRegistry:TriggerEvent(addon.Callbacks.SavedVars_OnDataChanged);
    end
end

function ForeverTBDMixin:SavedVars_OnDataChanged()
    
end

function ForeverTBDMixin:PLAYER_ENTERING_WORLD(...)
    local isInitial, isReload = ...;
    
    if (isInitial or isReload) then
        SavedVars:Init(); --force reset for sv updates
    end

    if (isInitial == true) and (ActiveCharacter ~= nil) then
        local loginTime = time();
        ActiveCharacter:SetLoginTime(loginTime);
    end
end


function ForeverTBDMixin:PLAYER_INTERACTION_MANAGER_FRAME_SHOW(...)
    local id = ...;
    if (id == 5) and (MerchantSellAllJunkButton:IsVisible()) then
        local shouldVendorJunk = SavedVars:GetConfig("autoVendorJunk");
        if (shouldVendorJunk.value == true) then
            C_MerchantFrame.SellAllJunkItems();
        end
    end
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

local zoneXpPatternMatch = ("^"..ERR_ZONE_EXPLORED_XP:gsub("%%s", "(.+)")):gsub("%%d", "(%%d+)").."$";
local zonePatternMatch = "^"..ERR_ZONE_EXPLORED:gsub("%%s", "(.+)").."$";
function ForeverTBDMixin:UI_INFO_MESSAGE(...)
    local id, msg = ...;
    local area, xp;
    area, xp = msg:match(zoneXpPatternMatch);
    if (area == nil) then
        area = msg:match(zonePatternMatch);
    end
    --print("Area:", area, "XP:", xp);
end

function ForeverTBDMixin:ZONE_CHANGED_INDOORS()
    UpdateLocation();
end

function ForeverTBDMixin:ZONE_CHANGED_NEW_AREA()
    UpdateLocation();
end

function ForeverTBDMixin:PLAYER_UPDATE_RESTING()
    if ActiveCharacter then
        local isResting = IsResting();
        ActiveCharacter:SetResting(isResting);
    end
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
    if (professionLink) then
        local linkType, payload, displayText = LinkUtil.ExtractLink(professionLink);
        local guid, _, profID = strsplit(":", payload);
        if tonumber(profID) then
            print(professionLink, profID)
        end
    end
end































--all this needs to move into a profession mixin and template structure

function ForeverTBDMixin:SetupProfessions()

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

    local function OnProfessionSearch(searchTerm)
        self.Professions.SchematicForm.Background:SetAtlas("Professions-Recipe-Background")
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

        self.Professions.CharacterTreeScrollBox:SetDataProvider(dataProvider)
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
            self.Professions.SchematicForm:LoadRecipe(button.recipeID, button.recipeData)
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

function ForeverTBDMixin:ScanRecipes(professionID)

    --must have an ID
    if (professionID == nil) then
        return;
    end

    --check its a valid number
    professionID = tonumber(professionID);
    if type(professionID) ~= "number" then
        return;
    end

    --dont scan for the same recipe (the DataProvider can get set multiple times in one showing)
    if self.lastProfessionID == professionID then
        return;
    end

    self.lastProfessionID = professionID;

    --print("ScanRecipes", time())

    --[[
        Changing the storage of prof recipe data,
        the character object will now only contain recipeIDs

        recipeData will be saved seperately to reduce duplication
    ]]

    local hasUpdated = false;

    local function ScanAndSetCharacterRecipes(recipes)
        --print("scan and set")
        local professions = {"prof1", "prof2", "cooking", "fishing", "firstAid" };
        for _, profession in ipairs(professions) do
            local profID = ActiveCharacter:GetProfessionID(profession);
            --print(profID, professionID)
            --print(type(profID), type(professionID));
            if (profID ~= nil) and (profID == professionID) then
                ActiveCharacter:SetProfessionRecipes(profession, recipes);
                hasUpdated = true;
                --print("updated prof")
            end
        end
    end

    if (ProfessionsFrame.CraftingPage.RecipeList.ScrollBox:HasDataProvider() == true) then
        local recipeIDs = {};
        local categories = {};
        for k, element in ProfessionsFrame.CraftingPage.RecipeList.ScrollBox:GetDataProvider():EnumerateEntireRange() do

            --this is the category header which it seems also has a table of recipes!
            if element.data and element.data.categoryInfo then
                --DevTools_Dump({element.data.categoryInfo});

                --print("processing", element.data.categoryInfo.name, element.data.categoryInfo.categoryID, element.data.categoryInfo.skillLineID)

                categories[element.data.categoryInfo.categoryID] = {
                    --categoryID = element.data.categoryInfo.categoryID,
                    skillLineID = element.data.categoryInfo.skillLineID,
                    parentCategoryID = element.data.categoryInfo.parentCategoryID,
                    name = element.data.categoryInfo.name,
                    recipes = {},
                }

                if element.data.categoryInfo.recipes then
                    for _, recipe in ipairs(element.data.categoryInfo.recipes) do
                        categories[element.data.categoryInfo.categoryID].recipes[recipe.recipeID] = {
                            icon = recipe.icon,
                            name = recipe.name,
                            hyperlink = recipe.hyperlink,
                            maxTrivialLevel = recipe.maxTrivialLevel
                        }
                        --print(">>> added recipe", recipe.name)
                        table.insert(recipeIDs, recipe.recipeID); --this goes to the character object
                    end
                end
            end
            -- if element.data and element.data.recipeInfo then
            --     local capture = {}
            --     --capture.recipeID = element.data.recipeInfo.recipeID
            --     capture.name = element.data.recipeInfo.name
            --     capture.categoryID = element.data.recipeInfo.categoryID
            --     capture.hyperlink = element.data.recipeInfo.hyperlink
            --     capture.icon = element.data.recipeInfo.icon
            --     --capture.learned = element.data.recipeInfo.learned
            --     capture.maxTrivialLevel = element.data.recipeInfo.maxTrivialLevel
            --     --capture.relativeDifficulty = element.data.recipeInfo.relativeDifficulty


            --     table.insert(recipeIDs, element.data.recipeInfo.recipeID);
            --     table.insert(recipeData, capture);
            -- end
        end

        --SavedVars:UpdateProfessionRecipes(recipeIDs, recipeData)
        SavedVars:UpdateProfessionRecipes(professionID, categories)
        ScanAndSetCharacterRecipes(recipeIDs);

        if (hasUpdated == false) then
            UpdateProfessions();
            ScanAndSetCharacterRecipes(recipeIDs);
        end

        --recipeIDs = nil;
        --recipeData = nil;
        --collectgarbage();
    end

    --[[
        omg how hard is it to keep track fo this stuff without mixing prof data

        gone back to the original method which while limited is at least accurate
    ]]

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

