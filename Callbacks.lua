

local addonName, addon = ...;

addon.Callbacks = {
    SavedVars_OnInitialized = "SAVED_VARS_INIT",
    SavedVars_OnDataChanged = "SAVED_VARS_DATA_CHANGED",

    Character_OnChanged = "CHARACTER_CHANGED",
    
    Tradeskill_OnSelected = "TRADESKILL_SELECTED",
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

