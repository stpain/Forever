

local addonName, addon = ...;

addon.QoL = {}


local SendMailCharacterListButton = CreateFrame("Button", "ForeverSendMailCharacterListButton", SendMailNameEditBox)
SendMailCharacterListButton:SetPoint("LEFT", SendMailNameEditBox, "RIGHT",  2, 0);
SendMailCharacterListButton:SetSize(24, 24);
SendMailCharacterListButton:SetNormalAtlas("128-RedButton-Plus");
SendMailCharacterListButton:SetPushedAtlas("128-RedButton-Plus-Pressed");
SendMailCharacterListButton:SetDisabledAtlas("128-RedButton-Plus-Disabled");

SendMailCharacterListButton:SetScript("OnClick", function(self)
    --for _, character in ipairs(addon.Characters) do
    local menu = MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
        rootDescription:CreateTitle("Select Recipient");
        rootDescription:CreateDivider();
        for _, character in ipairs(addon.Characters) do
            rootDescription:CreateButton(character:GetName("colourized"), function()
                SendMailNameEditBox:SetText(character:GetName("chat"))
            end)
        end
    end)
    menu:ClearAllPoints();
    menu:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 3, 0);
end)


--addon.QoL.SendMailCharacterListButton = SendMailCharacterListButton;


--[[
    Handle config changed callbacks using the config keys and new value
]]

addon.QoL.CallbackHandlers = {
    addSendMailCharacterListButton = function(shown)
        SendMailCharacterListButton:SetShown(shown)
    end,
}

addon.CallbackRegistry:RegisterCallback(addon.Callbacks.SavedVars_OnConfigChanged, function(_, key, value)
    --DevTools_Dump({key, value})
    if addon.QoL.CallbackHandlers[key] then
        addon.QoL.CallbackHandlers[key](value);
    end
end)