

local addonName, addon = ...;


local Character = {};

function Character:GetName(format)
    if (format == nil) then
        return self.data.name;

    elseif (format == "chat") then
        local name = string.gsub(self.data.name, "-", " ");
        return name;

    elseif (format == "colourized") then
        local _, class = GetClassInfo(self.data.classID);
        if class then
            return RAID_CLASS_COLORS[class]:WrapTextInColorCode(self.data.name);
        end
    end
end

function Character:SetName(name)
    local isNew = false;
    if (self.data.name ~= name) then
        isNew = true;
    end
    self.data.name = name;
    if (isNew == true) then
        addon.CallbackRegistry:TriggerEvent(addon.Callbacks.Character_OnChanged);
    end
end

function Character:GetSex()
    return self.data.sex;
end

function Character:SetSex(sex)
    local isNew = false;
    if (self.data.sex ~= sex) then
        isNew = true;
    end
    self.data.sex = sex;
    if (isNew == true) then
        addon.CallbackRegistry:TriggerEvent(addon.Callbacks.Character_OnChanged);
    end
end

function Character:GetRaceID()
    return self.data.raceID;
end

function Character:SetRaceID(raceID)
    local isNew = false;
    if (self.data.raceID ~= raceID) then
        isNew = true;
    end
    self.data.raceID = raceID;
    if (isNew == true) then
        addon.CallbackRegistry:TriggerEvent(addon.Callbacks.Character_OnChanged);
    end
end

function Character:GetFaction()
    return self.data.faction;
end

function Character:SetFaction(faction)
    local isNew = false;
    if (self.data.faction ~= faction) then
        isNew = true;
    end
    self.data.faction = faction;
    if (isNew == true) then
        addon.CallbackRegistry:TriggerEvent(addon.Callbacks.Character_OnChanged);
    end
end

function Character:GetClassID()
    return self.data.classID;
end

function Character:SetClassID(classID)
    local isNew = false;
    if (self.data.classID ~= classID) then
        isNew = true;
    end
    self.data.classID = classID;
    if (isNew == true) then
        addon.CallbackRegistry:TriggerEvent(addon.Callbacks.Character_OnChanged);
    end
end

function Character:GetLevel()
    return self.data.level;
end

function Character:SetLevel(level)
    local isNew = false;
    if (self.data.level ~= level) then
        isNew = true;
    end
    self.data.level = level;
    if (isNew == true) then
        addon.CallbackRegistry:TriggerEvent(addon.Callbacks.Character_OnChanged);
    end
end

function Character:GetMoney()
    return self.data.money;
end

function Character:SetMoney(money)
    local isNew = false;
    if (self.data.money ~= money) then
        isNew = true;
    end
    self.data.money = money;
    if (isNew == true) then
        addon.CallbackRegistry:TriggerEvent(addon.Callbacks.Character_OnChanged);
    end
end

function Character:SetLoginTime(time)
    local isNew = false;
    if (self.data.loginTime ~= time) then
        isNew = true;
    end
    self.data.loginTime = time;
    if (isNew == true) then
        addon.CallbackRegistry:TriggerEvent(addon.Callbacks.Character_OnChanged);
    end
end

function Character:GetLogoutTime()
    return self.data.logoutTime;
end

function Character:SetLogoutTime(time)
    local isNew = false;
    if (self.data.logoutTime ~= time) then
        isNew = true;
    end
    self.data.logoutTime = time;
    if (isNew == true) then
        addon.CallbackRegistry:TriggerEvent(addon.Callbacks.Character_OnChanged);
    end
end

function Character:GetLoginTime()
    return self.data.loginTime;
end

function Character:WipeProfession(slot)
    self.data[slot] = nil;
    self.data[string.format("%sRecipes", slot)] = nil;
    addon.CallbackRegistry:TriggerEvent(addon.Callbacks.Character_OnChanged);
end

function Character:SetProfession(slot, data)
    --1=name 3=skillLevel 4=maxSkillLevel
    local isNew = false;
    if (self.data[slot] == nil) then
        isNew = true;
    end
    if (self.data[slot] ~= nil) then
        if (self.data[slot][1] ~= data[1]) or (self.data[slot][3] ~= data[3]) or (self.data[slot][4] ~= data[4]) then
            isNew = true;
        end
    end
    self.data[slot] = data;
    if (isNew == true) then
        addon.CallbackRegistry:TriggerEvent(addon.Callbacks.Character_OnChanged);
    end
end

function Character:GetProfession(slot)
    return self.data[slot] or {};
end

function Character:GetProfessionID(slot)
    if self.data[slot] then
        return self.data[slot][7] or nil;
    end
end

function Character:GetProfessionKey(professionID)
    local keys = { "prof1", "prof2", "cooking", "fishing", "firstAid" };
    for _, key in ipairs(keys) do
        if self.data[key] and self.data[key][7] and (self.data[key][7] == professionID) then
            return key;
        end
    end
end

-- function Character:AddRecipe(slot, recipe)
--     if self.data[slot]
-- end

function Character:SetProfessionRecipes(slot, recipes)
    local isNew = false;
    local key = string.format("%sRecipes", slot);
    if self.data[key] and (#self.data[key] ~= #recipes) then
        isNew = true;
    end
    self.data[key] = recipes;
    if (isNew == true) then
        addon.CallbackRegistry:TriggerEvent(addon.Callbacks.Character_OnChanged);
    end
end

function Character:GetProfessionRecipes(slot)
    local key = string.format("%sRecipes", slot);
    return self.data[key] or {};
end

function Character:SearchRecipes(searchTerm)
    local ret = {};
    local keys = { "prof1Recipes", "prof2Recipes", "cookingRecipes", "fishingRecipes", "firstAidRecipes" };
    for _, key in ipairs(keys) do
        if self.data[key] then
            for _, recipe in ipairs(self.data[key]) do
                if (searchTerm == recipe.recipeID) then
                    table.insert(ret, recipe);
                end
                if (string.find(recipe.name, searchTerm, nil, true)) then
                    table.insert(ret, recipe);
                end
            end
        end
    end
    return ret;
end

function Character:SetXP(xp, xpMax)
    local isNew = false;
    if (self.data.xp ~= xp) then
        isNew = true;
    end
    self.data.xp = xp;
    self.data.xpMax = xpMax;
    if (isNew == true) then
        addon.CallbackRegistry:TriggerEvent(addon.Callbacks.Character_OnChanged);
    end
end

function Character:GetXP()
    return self.data.xp, self.data.xpMax;
end

function Character:SetHome(home)
    local isNew = false;
    if (self.data.home ~= home) then
        isNew = true;
    end
    self.data.home = home;
    if (isNew == true) then
        addon.CallbackRegistry:TriggerEvent(addon.Callbacks.Character_OnChanged);
    end
end

function Character:GetHome()
    return self.data.home;
end

function Character:SetLocation(location)
    local isNew = false;
    if (self.data.location ~= location) then
        isNew = true;
    end
    self.data.location = location;
    if (isNew == true) then
        addon.CallbackRegistry:TriggerEvent(addon.Callbacks.Character_OnChanged);
    end
end

function Character:GetLocation()
    return self.data.location;
end










function Character:CreateFromData(data)
    return Mixin({data=data,}, self);
end

function Character:CreateEmpty()
    return Mixin({data={},}, self);
end


addon.Character = Character;