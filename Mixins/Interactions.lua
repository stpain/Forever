

local addonName, addon = ...;

local SavedVars = addon.SavedVars;


local InteractionEnums = {
    GroupQuest = 1,
    Dungeon = 2,
    Campfire = 3,

}

local InteractionsManager = {};

local events = {
    "PLAYER_ENTERING_WORLD",
    "GROUP_ROSTER_UPDATE",
}

function InteractionsManager:Init()

end











addon.InteractionsManager = InteractionsManager;