

local addonName, addon = ...;

addon.Characters = {};

local SavedVars = {};

local Defaults = {
    config = {},
    characters = {},
    interactions = {},
    whispers = {},
}

function SavedVars:Init(reset)
    --ForeverTBDAccount = nil;
    if (reset) then
        ForeverTBDAccount = nil;
    end
    if (ForeverTBDAccount == nil) then
        ForeverTBDAccount = {};
    end
    for k, v in pairs(Defaults) do
        if (ForeverTBDAccount[k] == nil) then
            ForeverTBDAccount[k] = v;
        end
    end
    self.db = ForeverTBDAccount;

    self:LoadCharacters();

    addon.CallbackRegistry:TriggerEvent(addon.Callbacks.SavedVars_OnInitialized);
end

function SavedVars:LoadCharacters()
    for _, characterData in ipairs(self.db.characters) do
        local character = addon.Character:CreateFromData(characterData);
        table.insert(addon.Characters, character);
    end
end

function SavedVars:FindCharacterByPredicate(func)
    for k, character in ipairs(addon.Characters) do
        --run the function on the character data table
        if func(character.data) == true then
            return character;
        end
    end
end

function SavedVars:DeleteCharacter(characterName)
    if self.db.characters then
        local indexToDelete;
        for k, character in ipairs(self.db.characters) do
            if (character.name == characterName) then
                indexToDelete = k;
            end
        end
        if (indexToDelete ~= nil) then
            table.remove(self.db.characters, indexToDelete);
            addon.CallbackRegistry:TriggerEvent(addon.Callbacks.SavedVars_OnDataChanged);
        end
    end
end

function SavedVars:NewCharacter()
    table.insert(self.db.characters, {});
    local character = addon.Character:CreateFromData(self.db.characters[#self.db.characters]);
    table.insert(addon.Characters, character);
    return character;
end

function SavedVars:GetAllCharacters()
    
end


function SavedVars:Set(key, value)
    if self.db and self.db.config then
        self.db.config[key] = value;
    end
end

function SavedVars:Get(key)
    if self.db and self.db.config then
        return self.db.config[key];
    end
end

function SavedVars:GetTable(tableName)
    if self.db then
        return self.db[tableName];
    end
end

function SavedVars:ResetTable(tableName, newTable)
    if self.db and self.db[tableName] then
        self.db[tableName] = newTable or {};
    end
end

addon.SavedVars = SavedVars;