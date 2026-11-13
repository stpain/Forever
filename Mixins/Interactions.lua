

local addonName, addon = ...;

local SavedVars = addon.SavedVars;

-- StaticPopupDialogs['ForeverNewInteractionDialog'] = {
--     text = addon.locales.interactionsNewInteractionDialogText_S,
--     button1 = YES,
--     button2 = NO,
--     button3 = REPORT_PLAYER,
--     OnAccept = function(self, data)

--     end,
--     OnCancel = function()
        
--     end,
--     OnAlt = function(self, data)

--     end,
--     OnShow = function(self, data)

--     end,
--     timeout = 0,
--     whileDead = true,
--     hideOnEscape = false,
-- }

local function FormatPlayerName(first, surname, class)
    return string.format("%s:%s:%s", first, surname, class);
end

local function DecodePlayerName(playerName)
    local name, surname, class = strsplit(":", playerName);
    return name, surname, class;
end

local StandingColours = {
    --[0] = CreateColorFromHexString("ffcc0000"),
    [1] = CreateColorFromHexString("ffff0000"),
    [2] = CreateColorFromHexString("fff26000"),
    [3] = CreateColorFromHexString("ffe4e400"),
    [4] = CreateColorFromHexString("ff33ff33"),
    [5] = CreateColorFromHexString("ff5fe65d"),
    [6] = CreateColorFromHexString("ff53e9bc"),
    [7] = CreateColorFromHexString("ff2ee6e6"),
}

local RelationshipStandings = {
    { relationshipStanding ="Epic", standingID = 6, },
    { relationshipStanding = "Good", standingID = 5 },
    { relationshipStanding = "Friendly", standingID = 4 },
    { relationshipStanding = "Neutral", standingID = 3, },
    { relationshipStanding = "Unfriendly", standingID = 2, },
    { relationshipStanding = "Ignored", standingID = 1, },
}

local function GetRelationshipStandingText(interaction)
    return StandingColours[interaction.standingID]:WrapTextInColorCode(addon.locales
    ["interactionEnumRelationshipLevel_" .. interaction.standingID]);
end







ForeverTBDInteractionsCharacterMixin = {};

function ForeverTBDInteractionsCharacterMixin:ClearCharacter()
    self.Name:SetText("");
    self.ClassIcon:SetTexture(nil);
end

function ForeverTBDInteractionsCharacterMixin:SetCharacter(playerName)
    local name, surname, class = DecodePlayerName(playerName)
    self.Name:SetText(name.." "..surname)
    if class then
        self.ClassIcon:SetAtlas(string.format("UI-HUD-UnitFrame-Player-Portrait-ClassIcon-%s", class));
    end
end
















InteractionsManagerMixin = {};

-- local events = {
--     "PLAYER_ENTERING_WORLD",
--     "GROUP_ROSTER_UPDATE",
--     "GUILD_ROSTER_UPDATE",
-- }

function InteractionsManagerMixin:OnLoad()

    local characterList = CreateScrollBoxListLinearView();
    characterList:SetElementExtent(54);
    characterList:SetElementResetter(function(frame)
        frame:ClearCharacter();
    end)
    characterList:SetElementInitializer("ForeverTBDInteractionsCharacterTemplate", function(frame, data)
        frame:SetCharacter(data);
        frame:SetScript("OnClick", function(_, hwButton)
            if (hwButton == "RightButton") then
                MenuUtil.CreateContextMenu(self, function(_, rootDescription)
                    rootDescription:CreateTitle(OPTIONS);
                    rootDescription:CreateDivider();
                    rootDescription:CreateButton(DELETE, function()
                        self:DeletePlayerInteractions(data);
                        self:LoadCharacters();
                    end)
                end)

            else
                local interactions = self:GetInteractionsForPlayer(data);
                self:LoadPlayerInteractions(interactions)
            end
        end)
    end)
    ScrollUtil.InitScrollBoxListWithScrollBar(self.CharacterScrollBox, self.CharacterScrollBar, characterList);

    local interactionsList = CreateScrollBoxListLinearView();
    interactionsList:SetElementExtent(24);
    interactionsList:SetElementResetter(function(frame)
        frame.Standing:SetText(" ")
        frame.Note:SetText(" ")
    end)
    interactionsList:SetElementInitializer("ForeverTBDInteractionsHistoryListTemplate", function(frame, data)
        frame.Standing:SetText(GetRelationshipStandingText(data))
        frame.Note:SetText(data.note)
        frame.Location:SetText(data.location)
        frame.Time:SetText(date("%H:%M:%S   %d-%m-%y", data.timeStamp))
    end)
    ScrollUtil.InitScrollBoxListWithScrollBar(self.InteractionsScrollBox, self.InteractionsScrollBar, interactionsList);


    addon.CallbackRegistry:RegisterCallback(addon.Callbacks.SavedVars_OnInitialized, self.SavedVars_OnInitialized, self);
end

function InteractionsManagerMixin:SavedVars_OnInitialized()
    if 1 == 1 then
        --return
    end
    --SavedVars:ResetTable("interactions", {})
    self.interactions = SavedVars:GetTable("interactions")
    self:ModifyMenus();

    self:LoadCharacters()

    self:SetScript("OnShow", function()
        self:LoadCharacters()
    end)
end

function InteractionsManagerMixin:ModifyMenus()

    local unitsToModify = {
        "PLAYER",
        "FOCUS",
        "PARTY",
        "RAID_PLAYER",
    }

    local function ModifyMenu_AddNewInteractionButton(owner, rootDescription, contextData)
        local unit = contextData.unit;
        local _, class = UnitClass(unit);
        local playerInfo = FormatPlayerName(contextData.name, contextData.surname, class);

        local newInteractionButton = rootDescription:CreateButton("New interaction", function() end);
        newInteractionButton:CreateTitle("Interaction Options");
        newInteractionButton:CreateTitle("|cffffffffAdd note");

        local editbox;
        local inputbox = newInteractionButton:CreateTemplate("InputBoxInstructionsTemplate");
        inputbox:AddInitializer(function(frame)
            editbox = frame;
            editbox:SetMaxLetters(150);
            editbox.Instructions:SetText(NOTE_COLON or "");
            editbox.Instructions:SetPoint("TOPLEFT", 6, 0);
            editbox:SetPoint("TOPLEFT", 8, 0);
            editbox:SetSize(120, 24);
            editbox:SetAutoFocus(false);
            editbox:HookScript("OnTextChanged", function(eb)
                eb.Instructions:SetShown(eb:GetText() == "");
            end)
        end)

        newInteractionButton:CreateDivider();
        newInteractionButton:CreateTitle("Select Relationship")
        
        for _, relation in ipairs(RelationshipStandings) do
            newInteractionButton:CreateButton(addon.locales["interactionEnumRelationshipLevel_"..relation.standingID], function()
                local zone, x, y = addon.Api.GetLocation(true);
                    local interaction = {
                    playerInfo = playerInfo,
                    standingID = relation.standingID,
                    timeStamp = time(),
                    note = editbox:GetText(),
                    location = zone,
                }
                self:NewInteraction(interaction)
            end)
        end
    end


    --tailor the menu modification depending on the need
    local function AddMenuInteractionOptions(owner, rootDescription, contextData)
        local unit = contextData.unit;
        local _, class = UnitClass(unit);
        local playerName = FormatPlayerName(contextData.name, contextData.surname, class);
        
        rootDescription:CreateDivider();
        rootDescription:CreateTitle(addonName .. " Interactions");

        local interactions = self:GetInteractionsForPlayer(playerName);
        
        if interactions and interactions[1] then
            rootDescription:CreateTitle("|cffffffffRecent");
            local interaction = interactions[1]; --grab the most recent interaction from the history
            local standing = rootDescription:CreateTitle(GetRelationshipStandingText(interaction));
            standing:SetTooltip(function(tooltip)
                GameTooltip_SetTitle(tooltip, playerName);
                GameTooltip_AddNormalLine(tooltip, " ");
                GameTooltip_AddNormalLine(tooltip, interaction.note);
            end)
            ModifyMenu_AddNewInteractionButton(owner, rootDescription, contextData)
            
            rootDescription:CreateButton("Clear History", function()
                self:DeletePlayerInteractions(playerName)
            end)
       
        else
            ModifyMenu_AddNewInteractionButton(owner, rootDescription, contextData)
        end

        rootDescription:CreateButton("Open Interactions", function()
            addon.Api.OpenTo(5)
        end)
    end

    for _, unit in ipairs(unitsToModify) do
        Menu.ModifyMenu("MENU_UNIT_"..unit, AddMenuInteractionOptions)
    end

    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)

        -- local inInstance, instanceType = IsInInstance();
        -- if (inInstance == true) and (instanceType ~= "none") then
        --     return;
        -- end

        local isPlayer = UnitIsPlayer("mouseover");
        if (isPlayer ~= true) then
            --print("not player");
            return;
        end

        local first, surname = UnitName("mouseover");
        local _, class = UnitClass("mouseover");

        local isSecret = issecretvalue(first);
        if isSecret == true then
            --print("is secret");
            return;
        end

        if self.interactions then
            --local name, token, guid = tooltip:GetUnit();

            --print("mouseover", name2, name3, class2)

            --isSecret = issecretvalue(value)

            --DevTools_Dump({GetPlayerInfoByGUID(guid)})
            -- local class = select(2, GetPlayerInfoByGUID(guid));
            -- if (class == nil) then
            --     return; --this should avoid tooltips for non players
            -- end
            -- if (string.sub(guid, 1, 6) ~= "Player") then
            --     return;
            -- end
            -- local characterName = select(6, GetPlayerInfoByGUID(guid));
            -- local first, surname = strsplit(" ", characterName)

            local playerName = FormatPlayerName(first, surname, class)
            local interactions = self:GetInteractionsForPlayer(playerName);

            if interactions and interactions[1] then
                local interaction = interactions[1];
                local relationshipStanding = GetRelationshipStandingText(interaction);

                tooltip:AddLine(" ");
                tooltip:AddLine(addonName .. " Interactions");
                tooltip:AddLine(relationshipStanding);
                tooltip:AddLine(interaction.note, 1,1,1, true);
            end
        end
    end)
end

function InteractionsManagerMixin:NewInteraction(interactionData)
    if (self.interactions == nil) then
        return;
    end
    table.insert(self.interactions, interactionData);
end


function InteractionsManagerMixin:DeletePlayerInteractions(playerInfo)
    local newTable = {};
    for _, interaction in ipairs(self.interactions) do
        if interaction.playerInfo ~= playerInfo then
            table.insert(newTable, interaction);
        end
    end
    SavedVars:ResetTable("interactions", newTable);
    self.interactions = SavedVars:GetTable("interactions");
    self:LoadCharacters();
end


function InteractionsManagerMixin:LoadCharacters()
    local DataProvider = CreateDataProvider();
    local characterList = {}
    for _, interaction in ipairs(self.interactions) do
        if characterList[interaction.playerInfo] == nil then
            characterList[interaction.playerInfo] = true;
            DataProvider:Insert(interaction.playerInfo)
        end
    end
    characterList = nil;
    self.CharacterScrollBox:SetDataProvider(DataProvider);
    self.InteractionsScrollBox:SetDataProvider(CreateDataProvider());
end

function InteractionsManagerMixin:GetInteractionsForPlayer(playerInfo)
    local interactions = {};
    for _, interaction in ipairs(self.interactions) do
        if interaction.playerInfo == playerInfo then
            table.insert(interactions, interaction)
        end
    end
    table.sort(interactions, function(a, b)
        return a.timeStamp > b.timeStamp;
    end)
    return interactions;
end

function InteractionsManagerMixin:LoadPlayerInteractions(interactions)
    local DataProvider = CreateDataProvider(interactions);
    self.InteractionsScrollBox:SetDataProvider(DataProvider);
end