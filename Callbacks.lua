

local addonName, addon = ...;

addon.Callbacks = {
    SavedVars_OnInitialized = "SAVED_VARS_INIT",
    SavedVars_OnDataChanged = "SAVED_VARS_DATA_CHANGED",
    SavedVars_OnConfigChanged = "SAVED_VARS_CONFIG_CHANGED",

    Character_OnChanged = "CHARACTER_CHANGED",
    
    Tradeskill_OnSelected = "TRADESKILL_SELECTED",

    Whisper_OnChatHistoryDeleted = "WHISPER_DELETE_CHAT_HISTORY",
}

local callbacks = {};

for k, v in pairs(addon.Callbacks) do
    table.insert(callbacks, v);
end

addon.CallbackRegistry = CreateFromMixins(CallbackRegistryMixin)
addon.CallbackRegistry:OnLoad()
addon.CallbackRegistry:GenerateCallbackEvents(callbacks);

--move this later
addon.SecondsFormatter = CreateFromMixins(SecondsFormatterMixin)
addon.SecondsFormatter:Init(1, 1, false, false)



--move this later
addon.Api = {}

function addon.Api.GetLocation(formatCoords)
    local mapID = C_Map.GetBestMapForUnit("player");
    if (mapID) then
        local zone = C_Map.GetMapInfo(mapID);
        local position = C_Map.GetPlayerMapPosition(mapID, "player");
        if position then
            if (formatCoords == true) then
                return zone.name, string.format("%0.3f", position.x) * 100, string.format("%0.3f", position.y) * 100;
            else
                return zone.name, position.x, position.y;
            end

        else
            if IsInInstance() then
                local name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceID, instanceGroupSize, lfgDungeonID = GetInstanceInfo();
                if name and instanceID and (instanceType ~= "none") then
                    return name, 0, 0;
                end
            end
        end
    end
end

function addon.Api.GetServerGameTime()
    local nowTable = date("*t", C_DateAndTime.GetServerTimeLocal())
    local hour, minute = GetGameTime();
    nowTable.hour = hour;
    now = time(nowTable);
    return now;
end