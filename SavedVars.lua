

local addonName, addon = ...;

--addon.Characters = {};

local SavedVars = {};

local Defaults = {
    config = {},
    characters = {},
    interactions = {},
    whispers = {},
    --journal = {},
    minimap = {},
    professionRecipes = {},
    version = 0,
}

local DefaultsToDelete = {
    "journal",
}

local DefaultConfigOptions = {
    autoVendorJunk = {
        isNew = true,
        value = false,
    },
    disableInboxGold = {
        isNew = true,
        value = false,
    },
    displayRestedFlipbook = {
        isNew = true,
        value = true,
    },
    useServerTimeForJournal = {
        isNew = true,
        value = true,
    },
    addSendMailCharacterListButton = {
        isNew = true,
        value = true,
    },
    enableDisenchantingRecipeButton = {
        isNew = true,
        value = true,
    },
}

local CharacterDefaults = {
    journal = {},
}

function SavedVars:Init(reset)
    --ForeverTBDAccount = nil;
    if (reset == true) then
        ForeverTBDAccount = nil;
        addon.Characters = {};
    end
    if (ForeverTBDAccount == nil) then
        ForeverTBDAccount = {};
    end
    for k, v in pairs(Defaults) do
        if (ForeverTBDAccount[k] == nil) then
            ForeverTBDAccount[k] = v;
        end
    end
    for _, tableName in ipairs(DefaultsToDelete) do
        ForeverTBDAccount[tableName] = nil;
    end

    for opt, val in pairs(DefaultConfigOptions) do
        if (ForeverTBDAccount.config[opt] == nil) then
            ForeverTBDAccount.config[opt] = val;
        end
    end

    self.db = ForeverTBDAccount;

    if (reset == true) then
        ForeverTBDCharacter = nil;
    end
    if (ForeverTBDCharacter == nil) then
        ForeverTBDCharacter = {}
    end
    for k, v in pairs(CharacterDefaults) do
        if (ForeverTBDCharacter[k] == nil) then
            ForeverTBDCharacter[k] = v;
        end
    end

    self.characterDb = ForeverTBDCharacter;

    local version = C_AddOns.GetAddOnMetadata(addonName, "Version");
    version = tonumber(version);
    if self.db.version < version then
        self:RunUpdate(version);
        self.db.version = version;
    end

    self:LoadCharacters();

    addon.CallbackRegistry:TriggerEvent(addon.Callbacks.SavedVars_OnInitialized);
end

function SavedVars:RunUpdate(version)

    print(string.format("[%s] Running SavedVar Updates.", addonName));

    if (version == 0.22) then
        self:ResetTable("interactions");
        print("Interaction data was reset due to data structure changes.")
    end


    print("Updating config");
    local configsToUpdate = {
        "autoVendorJunk",
        "disableInboxGold",
        "displayRestedFlipbook",
        "useServerTimeForJournal",
    };
    for _, config in ipairs(configsToUpdate) do
        self:SetConfigSeen(config);
    end




    
    --anything that needs adjusting due to data changes
    --self.db is already set at this point

    --[[
        moving profession recipes into a single table source
        this is to remove duplicates on the character data table

        using a recipeID as a key so we can quickly retrieve the recipe
        data in the schematic mixin
    ]]
    -- local recipeIdsHandled = {};
    -- local recipesKeys = {"prof1Recipes", "prof2Recipes", "cookingRecipes", "firstAidRecipes", "fishingRecipes"};
    -- for _, character in ipairs(self.db.characters) do
    --     for _, key in ipairs(recipesKeys) do
    --         if character[key] and (type(character[key]) == "table") then
    --             if type(character[key][1]) == "table" then
    --                 local recipeIDs = {}
    --                 for _, recipe in ipairs(character[key]) do
    --                     table.insert(recipeIDs, recipe.recipeID);
    --                     if recipeIdsHandled[recipe.recipeID] == nil then
    --                         self.db.professionRecipes[recipe.recipeID] = {
    --                             name = recipe.name,
    --                             hyperlink = recipe.hyperlink,
    --                             icon = recipe.icon,
    --                             maxTrivialLevel = recipe.maxTrivialLevel,
    --                         }
    --                     end
    --                 end
    --                 character[key] = recipeIDs; --update the data to a recipeID list
    --             end
    --         end
    --     end
    -- end
        
end

function SavedVars:LoadCharacters()
    addon.Characters = {};
    for _, characterData in ipairs(self.db.characters) do
        --print(characterData.name);
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
    local tempTable = {};
    if self.db.characters then
        for k, character in ipairs(self.db.characters) do
            if (character.name ~= characterName) then
                table.insert(tempTable, character);
            end
        end
    end
    self.db.characters = {};
    for _, character in ipairs(tempTable) do
        table.insert(self.db.characters, character);
    end
    self:LoadCharacters();
    addon.CallbackRegistry:TriggerEvent(addon.Callbacks.SavedVars_OnDataChanged);
end

function SavedVars:NewCharacter()
    table.insert(self.db.characters, {});
    local character = addon.Character:CreateFromData(self.db.characters[#self.db.characters]);
    table.insert(addon.Characters, character);
    return character;
end

function SavedVars:GetAllCharacters(dataKey)
    if dataKey then
        local t = {};
        for _, character in ipairs(addon.Characters) do
            table.insert(t, character.data[dataKey]);
        end
        return t;
    end
end


function SavedVars:SetConfig(key, value)
    if self.db and self.db.config then
        self.db.config[key].value = value;
        addon.CallbackRegistry:TriggerEvent(addon.Callbacks.SavedVars_OnConfigChanged, key, value);
    end
end
function SavedVars:SetConfigSeen(key)
    if self.db and self.db.config then
        self.db.config[key].isNew = false;
    end
end

function SavedVars:GetConfig(key)
    if self.db and self.db.config then
        return self.db.config[key];
    end
end

function SavedVars:GetTable(tableName, isCharacter)
    if (isCharacter == true) then
        return self.characterDb[tableName];
    else
        return self.db[tableName];
    end
end

function SavedVars:ResetTable(tableName, newTable, isCharacter)
    if (isCharacter == true) then
        if self.characterDb and self.characterDb[tableName] then
            self.characterDb[tableName] = newTable or {};
        end
    else
        if self.db and self.db[tableName] then
            self.db[tableName] = newTable or {};
        end
    end
end





--function SavedVars:UpdateProfessionRecipes(recipeIDs, recipeData)
function SavedVars:UpdateProfessionRecipes(professionID, categoryData)
    -- if self.db then
    --     if #recipeIDs == #recipeData then
    --         for index, recipeID in ipairs(recipeIDs) do
    --             self.db.professionRecipes[recipeID] = recipeData[index];
    --         end
    --     end
    -- end

    --print("SavedVars", professionID)

    if self.db then
        if (self.db.professionRecipes[professionID] == nil) then
            self.db.professionRecipes[professionID] = {};
            --print("SavedVars > added professionID table")
        end

        for categoryID, info in pairs(categoryData) do
            if (self.db.professionRecipes[professionID][categoryID] == nil) then
                self.db.professionRecipes[professionID][categoryID] = info;
                --print("SavedVars > added cateogryID table", info.name)

            else
                for recipeID, recipeData in pairs(info.recipes) do
                    self.db.professionRecipes[professionID][categoryID].recipes[recipeID] = recipeData;
                end
                --print("SavedVars > looped recipes")
            end
        end
    end
end

function SavedVars:GetProfessionCategories(professionID)
    if self.db and self.db.professionRecipes and self.db.professionRecipes[professionID] then
        return self.db.professionRecipes[professionID];
    end
end

function SavedVars:GetRecipeCategoryInfo(recipeID)
    if self.db and self.db.professionRecipes then
        for professionID, categories in pairs(self.db.professionRecipes) do
            for cateogryID, info in pairs(categories) do
                if info.recipes and info.recipes[recipeID] then
                    return cateogryID, info;
                end
            end
        end
    end
end

function SavedVars:GetRecipeProfessionID(recipeID)
    if self.db and self.db.professionRecipes then
        for professionID, categories in pairs(self.db.professionRecipes) do
            for cateogryID, info in pairs(categories) do
                if info.recipes and info.recipes[recipeID] then
                    return professionID;
                end
            end
        end
    end
end

function SavedVars:FindRecipeByID(recipeID)
    if self.db and self.db.professionRecipes then
        for professionID, categories in pairs(self.db.professionRecipes) do
            for cateogryID, info in pairs(categories) do
                if info.recipes and info.recipes[recipeID] then
                    return info.recipes[recipeID];
                end
            end
        end
    end
end

function SavedVars:FindRecipeByName(name, returnOnlyRecipeIDs)
    if self.db and self.db.professionRecipes then
        local ret = {};
        name = name:lower();
        local lowerName;
        for professionID, categories in pairs(self.db.professionRecipes) do
            for cateogryID, info in pairs(categories) do
                if info.recipes then
                    for recipeID, recipeData in pairs(info.recipes) do
                        lowerName = recipeData.name:lower();
                        if (lowerName:find(name, nil, true)) then
                            if (returnOnlyRecipeIDs == true) then
                                table.insert(ret, recipeID);
                            else
                                ret[recipeID] = recipeData;
                            end
                        end
                    end
                end
            end
        end
        -- for recipeID, recipeData in pairs(self.db.professionRecipes) do
        --     lowerName = recipeData.name:lower();
        --     if (lowerName:find(name, nil, true)) then
        --         if (returnOnlyRecipeIDs == true) then
        --             table.insert(ret, recipeID);
        --         else
        --             ret[recipeID] = recipeData;
        --         end
        --     end
        -- end
        return ret;
    end
end






addon.SavedVars = SavedVars;