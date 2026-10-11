

local addonName, addon = ...;

local SavedVars = addon.SavedVars;

ForeverJournalMixin = {}

local events = {
    "QUEST_ACCEPTED",
    "QUEST_COMPLETE",
    "QUEST_AUTOCOMPLETE",
    "ZONE_CHANGED",
    "UI_INFO_MESSAGE",
}

function ForeverJournalMixin:Init()
    for _, event in ipairs(events) do
        self:RegisterEvent(event);
    end
    self.journal = SavedVars:GetTable("journal");
end

function ForeverJournalMixin:OnEvent()
    
end