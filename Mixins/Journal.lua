

local addonName, addon = ...;

local SavedVars = addon.SavedVars;
--local ThisCharacter;
local activityLocalePrefix = "journalActivity_";
local JOURNAL_LIMIT = 262000;


local ActivityIcons = {
    QUEST_ACCEPTED = "Crosshair_Quest_32",
    QUEST_TURNED_IN = "Crosshair_Questturnin_32",
    TAXI_FLIGHT = "Crosshair_Taxi_32",
    ZONE_CHANGED_NEW_AREA = "gamepad-radial-icon-trackingoptions-up",
    PLAYER_LEVEL_UP = "gamepad-radial-icon-viewbuffs",
}

local function GetActivityIconAndFormattedString(activity)

    local info = {strsplit(":", activity)};

    if (info[1] == "QUEST_ACCEPTED") then
        return ActivityIcons[info[1]], addon.locales[activityLocalePrefix..info[1]]:format(info[2]);
    end
    if (info[1] == "TAXI_FLIGHT") then
        return ActivityIcons[info[1]], addon.locales[activityLocalePrefix..info[1]]:format(info[2]);
    end
    if (info[1] == "ZONE_CHANGED_NEW_AREA") then
        return ActivityIcons[info[1]], addon.locales[activityLocalePrefix..info[1]]:format(info[2]);
    end
    if (info[1] == "PLAYER_LEVEL_UP") then
        return ActivityIcons[info[1]], addon.locales[activityLocalePrefix..info[1]]:format(info[2]);
    end

    if info[1] == "QUEST_TURNED_IN" then
        local xp, money = 0, "";
        if tonumber(info[3]) then
            xp = tonumber(info[3])
        end
        if tonumber(info[4]) then
            money = C_CurrencyInfo.GetCoinTextureString(tonumber(info[4]))
        end
        return ActivityIcons[info[1]], string.format("Turned in quest: %s\nReceived %d XP and %s gold.", info[2], xp, money);
    end

end






ForeverTBDJourneyEntryMixin = {};

function ForeverTBDJourneyEntryMixin:OnLoad()
    self.Background:SetAlpha(0.1);
end

function ForeverTBDJourneyEntryMixin:OnEnter()
    self.Background:SetAlpha(0.05);
    if self.questID then

        GameTooltip:SetOwner(self, "ANCHOR_NONE");
        --ForeverGameTooltip_AddQuest(self.questID, false)

        GameTooltip:SetHyperlink("|Hquest:"..self.questID);
        --GameTooltip:Show();
        --DevTools_Dump({C_TaskQuest.GetQuestInfoByQuestID(self.questID);})

        --GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT");
        --GameTooltip_SetTitle(GameTooltip, QuestUtils_GetQuestName(self.questID), nil, false);
        --GameTooltip_AddQuest(self)
        GameTooltip_AddQuestRewardsToTooltip(GameTooltip, self.questID) --, style, context)

        GameTooltip:ClearAllPoints();
        GameTooltip:SetPoint("TOPRIGHT", self:GetParent(), "TOPLEFT", -14, 30);
        GameTooltip:Show();
    end
end

function ForeverTBDJourneyEntryMixin:OnLeave()
    self.Background:SetAlpha(0.1);
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent);
end

function ForeverTBDJourneyEntryMixin:SetEntry(entry)

    local journalEntry = C_EncodingUtil.DeserializeCBOR(entry)

    local iconAtlas, activityText = GetActivityIconAndFormattedString(journalEntry.activity)

    --self.Character:SetText(journalEntry.character);
    self.Icon:SetAtlas(iconAtlas);
    self.Activity:SetText(activityText)
    self.Zone:SetText(journalEntry.zone);
    self.Coords:SetText(string.format("[%0.1f:%0.1f]", journalEntry.x, journalEntry.y))
    self.TimeStamp:SetText(date("%H:%M:%S   %d-%m-%y", journalEntry.timeStamp));

    if journalEntry.questID then
        self.questID = journalEntry.questID;
    else
        self.questID = nil;
    end

end









ForeverTBDJournalMixin = {}

local events = {
    "QUEST_ACCEPTED",
    "QUEST_TURNED_IN",
    --"QUEST_REMOVED",
    "QUEST_AUTOCOMPLETE",
    "ZONE_CHANGED_NEW_AREA",
    "UI_INFO_MESSAGE",
    "PLAYER_CONTROL_GAINED",
    "PLAYER_CONTROL_LOST",
    "PLAYER_ENTERING_WORLD",
    "PLAYER_LEVEL_UP",
    "CHAT_MSG_LOOT",
    
}

function ForeverTBDJournalMixin:OnLoad()
    for _, event in ipairs(events) do
        self:RegisterEvent(event);
    end
    addon.CallbackRegistry:RegisterCallback(addon.Callbacks.SavedVars_OnInitialized, self.SavedVars_OnInitialized, self);

    hooksecurefunc("TakeTaxiNode", function(id)
        local taxiNodeName = TaxiNodeName(id);
        local activityString = string.format("TAXI_FLIGHT:%s", taxiNodeName);
        self:InsertEntry(activityString);
    end)

    --ignore any events firing during loading
    self.trackEvents = false;

    --ForeverTBDJourneyEntryTemplate
    local journalList = CreateScrollBoxListLinearView(1, 1, 1, 1, 1);
    journalList:SetElementExtent(38);
    journalList:SetElementResetter(function(frame)
    
    end)
    journalList:SetElementInitializer("ForeverTBDJourneyEntryTemplate", function(frame, elementData)
        frame:SetEntry(elementData);
    end)
    ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, journalList);
    
    self.filters = {}
end

function ForeverTBDJournalMixin:LoadJournal(filter)
    
    if filter then
        self.filters[filter.key] = filter.func;
    end

    --code the filters when you've finished the ui
    local t = {};
    local isMatch;
    if next(self.filters) ~= nil then
        for _, entry in ipairs(self.journal) do
            isMatch = true;
            for _, func in pairs(self.filters) do
                if func(entry) ~= true then
                    isMatch = false;
                end
            end
            if (isMatch == true) then
                table.insert(t, entry);
            end
        end
        self.dataProvider = CreateDataProvider(t);
    else
        self.dataProvider = CreateDataProvider(self.journal);
    end
    
    self.ScrollBox:SetDataProvider(self.dataProvider);
end

function ForeverTBDJournalMixin:PLAYER_ENTERING_WORLD(...)
    local isInitial, isReload = ...;
    if isInitial or isReload then
        self.trackEvents = true;
        self:UnregisterEvent("PLAYER_ENTERING_WORLD");
    end
    --print("PLAYER_ENTERING_WORLD", time());
end

function ForeverTBDJournalMixin:OnEvent(event, ...)
    if (event == "PLAYER_ENTERING_WORLD") then
        self.pewTime = time();
        self[event](self, ...);
        return;
    end
    if (event == "PLAYER_CONTROL_GAINED") then
        self:PLAYER_CONTROL_GAINED(...)
        return;
    end
    if (self.trackEvents == false) then
        --print("no tracking")
        return;
    end
    if self[event] then
        self[event](self, ...);
    end
end

function ForeverTBDJournalMixin:SavedVars_OnInitialized()
    --SavedVars:ResetTable("journal", {});
    self.journal = SavedVars:GetTable("journal", true);

    self:LoadJournal();

    local journalSize = #self.journal;
    if (journalSize >= JOURNAL_LIMIT) then
        
    end
end

--[[
    During flight path journeys, you fly over zones
    we don't want to capture those events.

    Disable event captures during flight path.
]]
function ForeverTBDJournalMixin:PLAYER_CONTROL_LOST(...)
    self.trackEvents = false;
    --print("settign tracking off");
end

function ForeverTBDJournalMixin:PLAYER_CONTROL_GAINED(...)
    self.trackEvents = true;
    --print("settign tracking on");
end

function ForeverTBDJournalMixin:PLAYER_LEVEL_UP(...)
    local newLevel = ...;
    local activityString = string.format("PLAYER_LEVEL_UP:%d", newLevel)
    self:InsertEntry(activityString);
end

function ForeverTBDJournalMixin:QUEST_ACCEPTED(...)
    local questID = ...;
    local questTitle = C_QuestLog.GetTitleForQuestID(questID);
    local activityString = string.format("QUEST_ACCEPTED:%s", questTitle);
    self:InsertEntry(activityString, questID);
end

function ForeverTBDJournalMixin:QUEST_TURNED_IN(...)
    local questID, xpReward, moneyReward = ...;
    local questTitle = C_QuestLog.GetTitleForQuestID(questID);
    local activityString = string.format("QUEST_TURNED_IN:%s:%d:%d", questTitle, xpReward, moneyReward);
    self:InsertEntry(activityString, questID);
end

function ForeverTBDJournalMixin:QUEST_REMOVED(...)
    local questID = ...;
    local questTitle = C_QuestLog.GetTitleForQuestID(questID);
    local activityString = string.format("QUEST_REMOVED:%s", questTitle);
    self:InsertEntry(activityString);
end

function ForeverTBDJournalMixin:CHAT_MSG_LOOT(...)
    if (1 == 1) then
        return
    end

    --WIP

    local msg, playerName = ...;
    local itemLink = msg:match("(|Hitem:.-|h.-|h)");
    print(itemLink, playerName);
    local f, l = UnitName("player");
    if string.format("%s %s", f, l) == playerName then
        print("was me");
        local item = Item:CreateFromItemLink(itemLink);
        item:ContinueOnItemLoad(function()
            if (item:GetItemQuality() > 3) then --grey/junk=0, white=1, green=2, blue=3, purples=4, legos=5

            end
        end)
    end
end

function ForeverTBDJournalMixin:ZONE_CHANGED_NEW_AREA()

    --this event is problematic at login
    --PEW not happened, ignore this event
    if (self.pewTime == nil) then
        return;
    end
    --PEW was recent, player hasn't travelled anywhere
    --10 seconds should be reasonable before any meaningful travelling happens
    if self.pewTime and ((time() - self.pewTime) < 10) then
        return;
    end
    
    
    --print("ZONE_CHANGED_NEW_AREA", time());
    local newZone = GetZoneText();
    if (newZone == nil) or (newZone == "") then
        return;
    end
    local activityString = string.format("ZONE_CHANGED_NEW_AREA:%s", newZone);
    self:InsertEntry(activityString);

    --print("ZONE_CHANGED_NEW_AREA", time());
end

function ForeverTBDJournalMixin:InsertEntry(activity, questID)
    --print("insert Entry")
    if (self.journal) then
        local zone, x, y = addon.Api.GetLocation(true);
        if zone == nil then
            --print("no zone info, exit journal entry")
            --return;
            zone, x, y = "Unknown Zone", 0, 0;
        end

        --DevTools_Dump({activity})

        local now;
        local shouldUseServerTimeForJournal = SavedVars:GetConfig("useServerTimeForJournal");
        if (shouldUseServerTimeForJournal.value == true) then
            now = addon.Api.GetServerGameTime();
        else
            now = time();
        end

        local journalEntry = {
            --character = ThisCharacter,
            activity = activity,
            x = x,
            y = y,
            zone = zone,
            timeStamp = now,
            questID = questID, --could be nil
        }

        local cborJournalEntry = C_EncodingUtil.SerializeCBOR(journalEntry);
        table.insert(self.journal, 1, cborJournalEntry);
        self.dataProvider:InsertAtIndex(cborJournalEntry, 1);
    end
end