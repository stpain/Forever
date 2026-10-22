

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

local function FormatPlayerName(first, surname)
    return string.format("%s %s", first, surname);
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

local function GetRelationshipStanding(standingID)
    for k, v in ipairs(RelationshipStandings) do
        if v.standingID == standingID then
            return v;
        end
    end
end

local InteractionsManagerMixin = {};

-- local events = {
--     "PLAYER_ENTERING_WORLD",
--     "GROUP_ROSTER_UPDATE",
--     "GUILD_ROSTER_UPDATE",
-- }

function InteractionsManagerMixin:OnLoad()
    addon.CallbackRegistry:RegisterCallback(addon.Callbacks.SavedVars_OnInitialized, self.SavedVars_OnInitialized, self);
end

function InteractionsManagerMixin:SavedVars_OnInitialized()
    if 1 == 1 then
        return
    end
    SavedVars:ResetTable("interactions", {})
    self.interactions = SavedVars:GetTable("interactions")
    self:ModifyMenus();
end

function InteractionsManagerMixin:ModifyMenus()

    local unitsToModify = {
        "PLAYER",
        "FOCUS",
        "PARTY",
        "RAID",
    }

    local function ModifyMenu_AddNewInteractionButton(owner, rootDescription, contextData)
        local playerName = FormatPlayerName(contextData.name, contextData.surname);
        local newInteractionButton = rootDescription:CreateButton("New interaction", function() end);
        newInteractionButton:CreateTitle("Interaction Options");
        newInteractionButton:CreateTitle("|cffffffffAdd note");

        local editbox;
        local inputbox = newInteractionButton:CreateTemplate("InputBoxInstructionsTemplate");
        inputbox:AddInitializer(function(frame)
            editbox = frame;
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
                    standingID = relation.standingID,
                    timeStamp = time(),
                    note = editbox:GetText(),
                    location = string.format("%s:%s:%s", zone, x, y),
                }
                self:NewInteraction(playerName, interaction)
            end)
        end
    end

    local function ModifyMenu_AddEditInteractionButton(owner, rootDescription, contextData)
        local playerName = FormatPlayerName(contextData.name, contextData.surname);
        local interaction = self.interactions[playerName];
        local standing = rootDescription:CreateTitle(StandingColours[interaction.standingID]:WrapTextInColorCode(addon.locales["interactionEnumRelationshipLevel_" .. interaction.standingID]));
        standing:SetTooltip(function(tooltip)
            GameTooltip_SetTitle(tooltip, playerName);
            GameTooltip_AddNormalLine(tooltip, " ");
            GameTooltip_AddNormalLine(tooltip, interaction.note);
        end)
        local editInteractionButton = rootDescription:CreateButton("Edit", function() end);
        editInteractionButton:CreateTitle("Interaction Options");
        editInteractionButton:CreateTitle("|cffffffffUpdate note");

        local editbox;
        local inputbox = editInteractionButton:CreateTemplate("InputBoxInstructionsTemplate");
        inputbox:AddInitializer(function(frame)
            editbox = frame;
            editbox.Instructions:SetText(NOTE_COLON or "");
            editbox.Instructions:SetPoint("TOPLEFT", 6, 0);
            editbox:SetPoint("TOPLEFT", 8, 0);
            editbox:SetSize(120, 24);
            editbox:SetAutoFocus(false);
            editbox:HookScript("OnTextChanged", function(eb)
                eb.Instructions:SetShown(eb:GetText() == "");
            end)
        end)

        rootDescription:CreateButton("Share", function()
            
        end)

        rootDescription:CreateButton("Delete", function()
            self.interactions[playerName] = nil;
        end)
    end


    --tailor the menu modification depending on the need
    local function AddMenuInteractionOptions(owner, rootDescription, contextData)
        local unit = contextData.unit;
        local playerName = FormatPlayerName(contextData.name, contextData.surname);
        rootDescription:CreateDivider();
        rootDescription:CreateTitle(addonName .. " Interactions");
        if self.interactions and self.interactions[playerName] then
            ModifyMenu_AddEditInteractionButton(owner, rootDescription, contextData)
        else
            ModifyMenu_AddNewInteractionButton(owner, rootDescription, contextData)
        end
    end

    for _, unit in ipairs(unitsToModify) do
        Menu.ModifyMenu("MENU_UNIT_"..unit, AddMenuInteractionOptions)
    end
end

function InteractionsManagerMixin:NewInteraction(playerName, interaction)

    if self.interactions then
        self.interactions[playerName] = interaction;
    end

    --update
end

function InteractionsManagerMixin:EditInteraction(playerName, interaction)
    
end








addon.InteractionsManagerMixin = InteractionsManagerMixin;