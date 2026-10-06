

local addonName, addon = ...;

local ThisCharacter;
local MyCharacters = {};
local SavedVars = addon.SavedVars;

local chatBubbleFont = "GameFontWhite";
local FontStringHeightChecker = UIParent:CreateFontString(string.format("%s_HiddenFontStringHeightChecker", addonName), "BACKGROUND", chatBubbleFont);
FontStringHeightChecker:SetPoint("RIGHT", UIParent, "LEFT", -10);
FontStringHeightChecker:SetSize(320, 1000);
FontStringHeightChecker:SetWordWrap(true);






ForeverTBDWhisperCharacterMixin = {};

function ForeverTBDWhisperCharacterMixin:ClearCharacter()
    self.Name:SetText("");
    self.ClassIcon:SetTexture(nil);
    self.onClick = nil;
end

function ForeverTBDWhisperCharacterMixin:SetCharacter(character)
    self.Name:SetText(character.name);
    self.ClassIcon:SetAtlas(string.format("UI-HUD-UnitFrame-Player-Portrait-ClassIcon-%s", character.class));
    self.onClick = character.onClick;
end

function ForeverTBDWhisperCharacterMixin:OnClick()
    if self.onClick then
        self.onClick();
    end
end








ForeverTBDWhisperMessageMixin = {};

function ForeverTBDWhisperMessageMixin:OnLoad()
    self.Bubble.MessageText:SetFontObject(chatBubbleFont);
    NineSliceUtil.ApplyLayout(self.Bubble, NineSliceLayouts.ChatBubble)
end

function ForeverTBDWhisperMessageMixin:SetMessage(message)
    self.Bubble.MessageText:SetText(message.messageText);

    self.Bubble.TimeStamp:SetText(date("%H:%M", message.timeStamp));

    self.Bubble.AltName:Hide();

    if (message.sender == ThisCharacter) then
        self.Bubble:ClearAllPoints();
        self.Bubble:SetPoint("TOPRIGHT", -5, -5);
        self.Bubble:SetPoint("BOTTOMRIGHT", -5, 5);

    elseif (MyCharacters[message.sender] ~= nil) then
        self.Bubble:ClearAllPoints();
        self.Bubble:SetPoint("TOPRIGHT", -5, -17);
        self.Bubble:SetPoint("BOTTOMRIGHT", -5, 5);
        self.Bubble.AltName:SetText(MyCharacters[message.sender]);
        self.Bubble.AltName:Show();
    else
        self.Bubble:ClearAllPoints();
        self.Bubble:SetPoint("TOPLEFT", 5, -5);
        self.Bubble:SetPoint("BOTTOMLEFT", 5, 5);
    end
end







ForeverTBDWhispersMixin = {};

local events = {
    "CHAT_MSG_WHISPER",
    "CHAT_MSG_WHISPER_INFORM",
    --"CHAT_MSG_SYSTEM",
    "CHAT_MSG_BN_WHISPER_INFORM",
    "CHAT_MSG_BN_WHISPER",
    --"PLAYER_ENTERING_WORLD",
}

function ForeverTBDWhispersMixin:OnLoad()

    for _, event in ipairs(events) do
        self:RegisterEvent(event);
    end

    local function SendMessage()
        if (self.currentChatHistoryRecipient == nil) then
            return;
        end
        local messageText = self.SendMessageInput.EditBox:GetText();
        if (messageText == "") then
            return;
        end
        C_ChatInfo.SendChatMessage(messageText, "WHISPER", nil, self.currentChatHistoryRecipient);
        self.SendMessageInput.EditBox:SetText("");
        self.SendMessageInput.EditBox:ClearFocus();
    end

    self.SendMessageButton:Disable()
    self.SendMessageButton:SetScript("OnClick", function()
        SendMessage();
    end)

    self.SendMessageInput.EditBox:SetAutoFocus(false)
    self.SendMessageInput.EditBox:SetMultiLine(true)
    self.SendMessageInput.EditBox:SetScript("OnEnterPressed", function(editbox)
        SendMessage();
    end)
    self.SendMessageInput.EditBox:SetScript("OnTextChanged", function(editbox)
        local text = editbox:GetText();
        if (text == "") then
            self.SendMessageButton:Disable();
        else
            self.SendMessageButton:Enable();
        end
    end)

    --character list on the left
    local characterList = CreateScrollBoxListLinearView();
    characterList:SetElementExtent(54);
    characterList:SetElementResetter(function(frame)
        frame:ClearCharacter();
    end)
    characterList:SetElementInitializer("ForeverTBDWhisperCharacterTemplate", function(frame, data)
        frame:SetCharacter(data);
    end)
    ScrollUtil.InitScrollBoxListWithScrollBar(self.CharacterScrollBox, self.CharacterScrollBar, characterList);

    --message history
    local bubblePadding = 40;
    local messageHistory = CreateScrollBoxListLinearView();
    messageHistory:SetElementExtentCalculator(function(dataIndex, elementData)
        FontStringHeightChecker:SetText(elementData.messageText);
        local height = FontStringHeightChecker:GetStringHeight();

        --if it was an alt we'll show theirname above the bubble
        --add some height to allow for this
        if (MyCharacters[elementData.sender] ~= nil) then
            height = height + 12;
        end

        return (height + bubblePadding);
    end)
    messageHistory:SetElementResetter(function(frame)
        
    end)
    messageHistory:SetElementInitializer("ForeverTBDWhisperMessageTemplate", function(frame, data)
        frame:SetMessage(data);
    end)
    ScrollUtil.InitScrollBoxListWithScrollBar(self.MessagesScrollBox, self.MessagesScrollBar, messageHistory);

    addon.CallbackRegistry:RegisterCallback(addon.Callbacks.SavedVars_OnInitialized, self.SavedVars_OnInitialized, self);
end

function ForeverTBDWhispersMixin:SavedVars_OnInitialized(...)
    --SavedVars:ResetTable("whispers");
    self.whispers = SavedVars:GetTable("whispers");
    local f, s = UnitName("player");

    --this is used to check where messages filter
    ThisCharacter = string.format("%s %s", f, s);

    --this is used to show the name for our alts when viewing chat history from different characters
    for _, character in ipairs(addon.Characters) do
        local name = character:GetName("chat"); --"first last" (with a space not a hyphen)
        if (name ~= ThisCharacter) then
            MyCharacters[name] = character:GetName("colourized");
        end
    end

    self:RefreshCharacterList();
end


function ForeverTBDWhispersMixin:OnEvent(event, ...)
    if self[event] then
        self[event](self, ...);
    end
end

function ForeverTBDWhispersMixin:HandleMessage(sender, recipient, messageText, lineID, timeStamp)
    local playerLocation = PlayerLocation:CreateFromChatLineID(lineID);
    if playerLocation then
        local _, playerClass = C_PlayerInfo.GetClass(playerLocation);
        if playerClass then
            table.insert(self.whispers, {
                sender = sender,
                recipient = recipient,
                timeStamp = timeStamp,
                messageText = messageText,
                playerClass = playerClass,
            })
        end
    end
    self:RefreshCharacterList();

    if (self.currentChatHistoryRecipient ~= nil) then
        self:LoadChatHistory(self.currentChatHistoryRecipient);
    end
end

function ForeverTBDWhispersMixin:CHAT_MSG_WHISPER(...)
    --local text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, suppressRaidIcons = ...;
    local messageText, playerName, languageName, channelName, player2Name = ...;
    local lineID = select(11, ...);
    local timestamp = time();
    self:HandleMessage(playerName, ThisCharacter, messageText, lineID, timestamp);
end

function ForeverTBDWhispersMixin:CHAT_MSG_WHISPER_INFORM(...)
    --local text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, suppressRaidIcons = ...;
    local messageText, playerName, languageName, channelName, player2Name = ...;
    --print(playerName, player2Name, messageText);
    local lineID = select(11, ...);
    local timestamp = time();
    self:HandleMessage(ThisCharacter, playerName, messageText, lineID, timestamp);
end


function ForeverTBDWhispersMixin:LoadChatHistory(playerName)
    self.currentChatHistoryRecipient = playerName;
    self.ChatHistoryRecipientName:SetText(playerName);
    if self.whispers then
        local t = {};
        for _, whisper in ipairs(self.whispers) do
            if (whisper.sender == playerName) or (whisper.recipient == playerName) then
                table.insert(t, whisper);
            end
        end
        if (#t > 1) then
            table.sort(t, function(a,b)
                return a.timeStamp < b.timeStamp;
            end)
        end
        local DataProvider = CreateDataProvider(t);
        self.MessagesScrollBox:SetDataProvider(DataProvider);
        self.MessagesScrollBox:ScrollToEnd();
    end
end


function ForeverTBDWhispersMixin:RefreshCharacterList()
    local DataProvider = CreateDataProvider();
    local playersSeen = {};
    if self.whispers then
        for _, whisper in ipairs(self.whispers) do

            --handle the inbound messages using the .sender field
            if (playersSeen[whisper.sender] == nil) and (whisper.sender ~= ThisCharacter) and (MyCharacters[whisper.sender] == nil) then
                DataProvider:Insert({
                    name = whisper.sender,
                    class = whisper.playerClass,
                    onClick = function()
                        self:LoadChatHistory(whisper.sender);
                    end,
                });
                playersSeen[whisper.sender] = true;
            end

            --for instances where we send a message before receiving one we need to reverse        
            -- if (whisper.sender == ThisCharacter) and (whisper.recipient ~= ThisCharacter) then

            --     --check we haven't loaded this chat already from a message received
            --     if (playersSeen[whisper.recipient] == nil) then
            --         DataProvider:Insert({
            --             name = whisper.recipient,
            --             class = whisper.playerClass,
            --             onClick = function()
            --                 self:LoadChatHistory(whisper.recipient);
            --             end,
            --         });
            --         playersSeen[whisper.recipient] = true;
            --     end
            -- end


        end
    end


    self.CharacterScrollBox:SetDataProvider(DataProvider);
end