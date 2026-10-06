

local addonName, addon = ...;

ForeverTBDCharacterSummaryMixin = {}


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

function ForeverTBDCharacterSummaryMixin:OnLoad()
    addon.CallbackRegistry:RegisterCallback(addon.Callbacks.Character_OnChanged, self.Character_OnChanged, self);
end

function ForeverTBDCharacterSummaryMixin:OnClick(...)
    local mouseButton, _ = ...;

    if (mouseButton == "RightButton") and (self.Character ~= nil) then
        
        MenuUtil.CreateContextMenu(self, function(_, rootDescription)
            rootDescription:CreateTitle(OPTIONS);
            rootDescription:CreateDivider();

            rootDescription:CreateButton(DELETE, function()
            
            end)
        end)
    end
end

function ForeverTBDCharacterSummaryMixin:ClearCharacter()
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

function ForeverTBDCharacterSummaryMixin:Init(character)
    self.Character = character;
    self:UpdateCharacter();
end

function ForeverTBDCharacterSummaryMixin:UpdateCharacter()

    if (self.Character == nil) then
        self:ClearCharacter();
        return;
    end

    local classLocale, class = GetClassInfo(self.Character:GetClassID());
    local r, g, b = RAID_CLASS_COLORS[class]:GetRGB();
    self.Background:SetColorTexture(r,g,b, 0.5)
    self.Background:SetGradient("HORIZONTAL", CreateColor(r, g, b, 0.2), CreateColor(r, g, b, 0));

    --self.Name:SetText("|cffffffff"..self.Character.data.name);
    self.Name:SetText(RAID_CLASS_COLORS[class]:WrapTextInColorCode(self.Character:GetName()));
    self.Level:SetText(LEVEL..": "..self.Character:GetLevel().." "..classLocale)-- RAID_CLASS_COLORS[class]:WrapTextInColorCode(classLocale));

    --self.HomeLocation:SetText(string.format("%s |cffffffff%s|r", CreateAtlasMarkup("Innkeeper", 22, 22), self.Character.data.home or "-"));
    self.HomeLocation:SetText(string.format("%s |cffffffff%s|r", CreateAtlasMarkup("poi-islands-table", 20, 20), self.Character:GetLocation() or "-"));
    --self.Money:SetText(string.format("%s |cffffffff%s|r", CreateAtlasMarkup("Coin-Gold", 18, 18), C_CurrencyInfo.GetCoinTextureString(self.Character.data.money)));
    self.Money:SetText("|cffffffff" .. C_CurrencyInfo.GetCoinTextureString(self.Character:GetMoney()));
    
    self.Login:SetText(CreateAtlasMarkup("housing-dashboard-timertag-clock-icon").." "..addon.SecondsFormatter:Format(time() - self.Character:GetLoginTime()))
    local first, second = UnitName("player");
    if (first.."-"..second) == self.Character:GetName() then
        self:SetScript("OnUpdate", function()
            if self.Character then
                self.Login:SetText(CreateAtlasMarkup("housing-dashboard-timertag-clock-icon").." "..DIM_GREEN_FONT_COLOR:WrapTextInColorCode(addon.SecondsFormatter:Format(time() - self.Character:GetLoginTime())))
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

    local raceInfo = C_CreatureInfo.GetRaceInfo(self.Character:GetRaceID())
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

function ForeverTBDCharacterSummaryMixin:Character_OnChanged()
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