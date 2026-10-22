

local addonName, addon = ...;

local SavedVars = addon.SavedVars;

ForeverTBDCharacterSummaryCharacterMixin = {}


local function SetProfessionTooltip(parent, text, _min, _max, current, label)
    GameTooltip:SetOwner(parent, "ANCHOR_RIGHT");
    GameTooltip:AddLine(text);
    GameTooltip_ShowProgressBar(GameTooltip, _min, _max, current, label);
    GameTooltip:Show();
end
local function SetProfessionButton(button, data)
    button.Name:SetText(data[1]);
    button.Icon:SetTexture(data[2]);
    --button.Icon:SetAtlas(string.format("Mobile-%s", data[1]));
    SetItemButtonCount(button, data[3]);

    if not button.Bar then
        button.Bar = button:CreateTexture(nil, "BACKGROUND");
        button.Bar:SetPoint("TOPLEFT", button.NameFrame, "TOPLEFT", 2, -2);
        button.Bar:SetPoint("BOTTOMLEFT", button.NameFrame, "BOTTOMLEFT", -1, 1);
        button.Bar:SetColorTexture(201/255,148/255,93/255,0.23)
    end

    local width = button.NameFrame:GetWidth() - 3;
    local percent = (data[3] / data[4]) * 100;
    local widthPercent = (width / 100) * percent;
    button.Bar:SetWidth(widthPercent);

    button.updateTooltip = function()
        SetProfessionTooltip(button, data[1], 1, data[4], data[3], data[3])
    end

    button:SetScript("OnEnter", function()
        button.updateTooltip();
        --DevTools_Dump(data)
    end)

end

local function ResetProfessionButton(button)
    button.Name:SetText("");
    button.Icon:SetAtlas("gamepad-radial-icon-professions-down");
    button:SetScript("OnEnter", nil);
    if (button.Bar) then
        button.Bar:SetWidth(0);
    end
    SetItemButtonCount(button, nil);
end

function ForeverTBDCharacterSummaryCharacterMixin:OnLoad()
    addon.CallbackRegistry:RegisterCallback(addon.Callbacks.Character_OnChanged, self.Character_OnChanged, self);
    addon.CallbackRegistry:RegisterCallback(addon.Callbacks.SavedVars_OnConfigChanged, self.Character_OnChanged, self);
end

function ForeverTBDCharacterSummaryCharacterMixin:OnClick(...)
    local mouseButton, _ = ...;

    if (mouseButton == "RightButton") and (self.Character ~= nil) then
        
        MenuUtil.CreateContextMenu(self, function(_, rootDescription)
            rootDescription:CreateTitle(OPTIONS);
            rootDescription:CreateDivider();

            rootDescription:CreateButton(DELETE, function()
                SavedVars:DeleteCharacter(self.Character:GetName());
            end)
        end)
    end
end

function ForeverTBDCharacterSummaryCharacterMixin:ClearCharacter()
    self.Character = nil;
    self.Background:SetColorTexture(0,0,0,0);
    self.Name:SetText("");
    self.Level:SetText("");
    self.HomeLocation:SetText("");
    self.Money:SetText("");
    self.Login:SetText("");
    self.XP.Bar:SetMinMaxValues(1,100);
    self.XP.Bar:SetValue(0);
    self.RaceIcon:SetTexture(nil);
    ResetProfessionButton(self.Profession1Button);
    ResetProfessionButton(self.Profession2Button);
    ResetProfessionButton(self.CookingButton);
    ResetProfessionButton(self.FishingButton);
    ResetProfessionButton(self.FirstAidButton);
end

function ForeverTBDCharacterSummaryCharacterMixin:Init(character)
    self.Character = character;
    self:UpdateCharacter();
end

function ForeverTBDCharacterSummaryCharacterMixin:UpdateCharacter()

    if (self.Character == nil) then
        self:ClearCharacter();
        return;
    end

    local shouldShowRestedAnim = SavedVars:GetConfig("displayRestedFlipbook");
    if (shouldShowRestedAnim.value == true) then
        --print("Show Anim = true");
        local isResting = self.Character:GetResting();
        --print(tostring(isResting), self.Character.data.name);
        if isResting == true then
            self.PlayerRestLoop:Show();
            self.PlayerRestLoop.PlayerRestLoopAnim:Play();
        else
            self.PlayerRestLoop.PlayerRestLoopAnim:Stop();
            self.PlayerRestLoop:Hide()
        end
    else
        --print("Show Anim = false");
        self.PlayerRestLoop.PlayerRestLoopAnim:Stop();
        self.PlayerRestLoop:Hide()
    end

    local classLocale, class = GetClassInfo(self.Character:GetClassID());
    local r, g, b = RAID_CLASS_COLORS[class]:GetRGB();
    self.Background:SetColorTexture(r,g,b, 0.5)
    self.Background:SetGradient("HORIZONTAL", CreateColor(r, g, b, 0.2), CreateColor(r, g, b, 0));

    --self.Name:SetText("|cffffffff"..self.Character.data.name);
    self.Name:SetText(self.Character:GetName("colourized"));
    self.Level:SetText(LEVEL..": "..self.Character:GetLevel().." "..classLocale)-- RAID_CLASS_COLORS[class]:WrapTextInColorCode(classLocale));

    --self.HomeLocation:SetText(string.format("%s |cffffffff%s|r", CreateAtlasMarkup("Innkeeper", 22, 22), self.Character.data.home or "-"));
    self.HomeLocation:SetText(string.format("%s |cffffffff%s|r", CreateAtlasMarkup("poi-islands-table", 20, 20), self.Character:GetLocation() or "-"));
    --self.Money:SetText(string.format("%s |cffffffff%s|r", CreateAtlasMarkup("Coin-Gold", 18, 18), C_CurrencyInfo.GetCoinTextureString(self.Character.data.money)));
    self.Money:SetText("|cffffffff" .. C_CurrencyInfo.GetCoinTextureString(self.Character:GetMoney()));
    
    self.Login:SetText(CreateAtlasMarkup("housing-dashboard-timertag-clock-icon").." "..addon.SecondsFormatter:Format(time() - self.Character:GetLoginTime()))
    local first, second = UnitName("player");
    if (first.."-"..second) == self.Character:GetName() then
        local x, gc = 0, 0;
        self:SetScript("OnUpdate", function(_, elapsed)
            x = (x + elapsed);
            gc = (gc + elapsed);
            if (x < 1) then
                return;
            end
            x = 0;
            if self.Character then
                self.Login:SetText(CreateAtlasMarkup("housing-dashboard-timertag-clock-icon").." "..DIM_GREEN_FONT_COLOR:WrapTextInColorCode(addon.SecondsFormatter:Format(time() - self.Character:GetLoginTime())))
            end
            if (gc > 60) then
                --once a minute, monitor this value
                collectgarbage();
                --print("gc")
                gc = 0;
            end
        end)
    else
        self:SetScript("OnUpdate", nil)
    end

    if (self.Character.data.xp and self.Character.data.xpMax) then
        local xp, xpMax, xpPer = self.Character.data.xp, self.Character.data.xpMax, ((self.Character.data.xp/self.Character.data.xpMax) * 100);
        self.XP.Bar:SetMinMaxValues(1,xpMax);
        self.XP.Bar:SetValue(xp);
        self.XP.Bar.Label:SetText(string.format("%0.1f %%", xpPer));
    else
        self.XP.Bar:SetMinMaxValues(1,100);
        self.XP.Bar:SetValue(0);
    end

    local raceInfo = C_CreatureInfo.GetRaceInfo(self.Character:GetRaceID());

    --QuestPortraitIcon-Horde-small questlog-questtypeicon-horde
    if self.Character:GetFaction() == "Horde" then
        self.FactionIcon:SetAtlas("UI-HUD-UnitFrame-SmallCircle-Horde")
    elseif self.Character:GetFaction() == "Alliance" then
        self.FactionIcon:SetAtlas("UI-HUD-UnitFrame-SmallCircle-Alliance")
    end

    --scourge fix
    if raceInfo.clientFileString == "Scourge" then
        raceInfo.clientFileString = "Undead";
    end
    if (self.Character:GetSex() == 3) then
        self.RaceIcon:SetAtlas(string.format("raceicon128-%s-female", raceInfo.clientFileString:lower()));
    elseif (self.Character:GetSex() == 2) then
        self.RaceIcon:SetAtlas(string.format("raceicon128-%s-male", raceInfo.clientFileString:lower()));
    end

    if (self.Character.data.prof1 and self.Character.data.prof1[2]) then
        SetProfessionButton(self.Profession1Button, self.Character.data.prof1)
    else
        ResetProfessionButton(self.Profession1Button)
    end

    if (self.Character.data.prof2 and self.Character.data.prof2[2]) then
        SetProfessionButton(self.Profession2Button, self.Character.data.prof2)
    else
        ResetProfessionButton(self.Profession2Button)
    end

    if (self.Character.data.cooking and self.Character.data.cooking[2]) then
        SetProfessionButton(self.CookingButton, self.Character.data.cooking)
    else
        ResetProfessionButton(self.CookingButton)
    end

    if (self.Character.data.fishing and self.Character.data.fishing[2]) then
        SetProfessionButton(self.FishingButton, self.Character.data.fishing)
    else
        ResetProfessionButton(self.FishingButton)
    end

    if (self.Character.data.firstAid and self.Character.data.firstAid[2]) then
        SetProfessionButton(self.FirstAidButton, self.Character.data.firstAid)
    else
        ResetProfessionButton(self.FirstAidButton)
    end


end

function ForeverTBDCharacterSummaryCharacterMixin:Character_OnChanged()
    self:UpdateCharacter();
end


--[[
        button:SetID(id);
        button.Icon:SetTexture(texture);
        button.Name:SetText(name);

        SetItemButtonQuality(button, quality, link);
        SetItemButtonCount(button, numItems);
        if ( isUsable ) then
            SetItemButtonTextureVertexColor(button, 1.0, 1.0, 1.0);
            SetItemButtonNameFrameVertexColor(button, 1.0, 1.0, 1.0);
        else
            SetItemButtonTextureVertexColor(button, 0.9, 0, 0);
            SetItemButtonNameFrameVertexColor(button, 0.9, 0, 0);
        end
]]




ForeverTBDCharacterSummaryMixin = {};

function ForeverTBDCharacterSummaryMixin:OnLoad()
    self:SetupCharacterSummary();
    addon.CallbackRegistry:RegisterCallback(addon.Callbacks.SavedVars_OnInitialized, self.LoadCharacterSummaryList, self);
    addon.CallbackRegistry:RegisterCallback(addon.Callbacks.SavedVars_OnDataChanged, self.LoadCharacterSummaryList, self);
end



function ForeverTBDCharacterSummaryMixin:SetupCharacterSummary()

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
    ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, characterSummaryView);

    local hordeFactionInfo = C_CreatureInfo.GetFactionInfo(2); --orc
    local allianceFactionInfo = C_CreatureInfo.GetFactionInfo(1); --human

    --faction menu
    self.DropdownButtonFaction.OpenMenu:SetScript("OnClick", function()
        local menu = MenuUtil.CreateContextMenu(self.DropdownButtonFaction, function(owner, rootDescription)
            rootDescription:CreateTitle(FILTER);
            rootDescription:CreateButton(ALL, function()
                self.DropdownButtonFaction.Text:SetText(FACTION);
                self:LoadCharacterSummaryList({
                    key = "faction",
                    func = nil;
                })
            end)
            rootDescription:CreateDivider();

            rootDescription:CreateButton(allianceFactionInfo.name, function()
                self.DropdownButtonFaction.Text:SetText(allianceFactionInfo.name);
                local filter = function(character)
                    return character:GetFaction() == "Alliance";
                end
                self:LoadCharacterSummaryList({
                    key = "faction",
                    func = filter,
                });
            end)
            rootDescription:CreateButton(hordeFactionInfo.name, function()
                self.DropdownButtonFaction.Text:SetText(hordeFactionInfo.name);
                local filter = function(character)
                    return character:GetFaction() == "Horde";
                end
                self:LoadCharacterSummaryList({
                    key = "faction",
                    func = filter,
                });
            end)
        end)
        menu:ClearAllPoints();
        menu:SetPoint("TOPLEFT", self.DropdownButtonFaction, "BOTTOMLEFT", 3, 0);
    end)


    --[[
        Create the class filter menu button
    ]]
    self.DropdownButtonClass.OpenMenu:SetScript("OnClick", function()
        local menu = MenuUtil.CreateContextMenu(self.DropdownButtonClass, function(owner, rootDescription)
            rootDescription:CreateTitle(FILTER);
            rootDescription:CreateButton(ALL, function()
                self.DropdownButtonClass.Text:SetText(CLASS);
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
                        self.DropdownButtonClass.Text:SetText(class);
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
        menu:SetPoint("TOPLEFT", self.DropdownButtonClass, "BOTTOMLEFT", 3, 0);
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
    self.DropdownButtonProfession.OpenMenu:SetScript("OnClick", function()
        local menu = MenuUtil.CreateContextMenu(self.DropdownButtonProfession, function(owner, rootDescription)
            rootDescription:CreateTitle(FILTER);
            rootDescription:CreateButton(ALL, function()
                self.DropdownButtonProfession.Text:SetText(PROFESSIONS_BUTTON);
                self:LoadCharacterSummaryList({
                    key = "profession",
                    func = nil;
                })
            end)
            rootDescription:CreateDivider();
                for _, id in ipairs(professions) do
                local profName = C_TradeSkillUI.GetTradeSkillDisplayName(id)
                rootDescription:CreateButton(profName, function()
                    self.DropdownButtonProfession.Text:SetText(profName);
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
        menu:SetPoint("TOPLEFT", self.DropdownButtonProfession, "BOTTOMLEFT", 3, 0);
    end)

    self.filters = {};
end


---Loads Characters into the summary using set filters, if none it loads all characters
---@param filter table? { key=filterKey, func=function, } the filterKey is used to manage adding/updating/removing the filter, the func is passed the Character and should return true for valid matches
function ForeverTBDCharacterSummaryMixin:LoadCharacterSummaryList(filter)

    if (filter) then
        self.filters[filter.key] = filter.func;
    end

    local dataProvider = CreateDataProvider();


    --default sorting for now
    table.sort(addon.Characters, function(a, b)
        return a.data.loginTime > b.data.loginTime;
    end)


    if next(self.filters) ~= nil then
        for _, character in ipairs(addon.Characters) do
            local isMatch = true;
            for k, filter in pairs(self.filters) do
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

    self.ScrollBox:SetDataProvider(dataProvider);
end
