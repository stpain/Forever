

local addonName, addon = ...;

ForeverTBDSideTabMixin = {}

function ForeverTBDSideTabMixin:OnLoad()
    SidePanelTabButtonMixin.OnLoad(self);

    self:SetScript("OnShow", function()
        local x, y = self:GetSize();
        self.Icon:SetSize(x-2, y-2);
    end)

    if self.iconTexture then
        self.Icon:SetTexture(self.iconTexture);
    end

    if self.iconAtlas then
        self.Icon:SetAtlas(self.iconAtlas, true);
    end

	self:SetCustomOnMouseUpHandler(function(tab, button, upInside)
		if button == "LeftButton" and upInside then
			--EventRegistry:TriggerEvent("Legacy.SelectPage", tab:GetID());
		end
	end);
end




ForeverTBDDropdownButtonMixin = {}

function ForeverTBDDropdownButtonMixin:OnLoad()
    if (self.defaultText) then
        self.Text:SetText(self.defaultText);
    end
end



ForeverTBDSearchBoxMixin = {}

function ForeverTBDSearchBoxMixin:OnLoad()
    
end



ForeverTBDProfessionListButtonMixin = {}

local professions = {
    [171] = "Profession-overview-Card-Alchemy",
    [164] = "Profession-overview-Card-Blacksmithing",
    [333] = "Profession-overview-Card-Enchanting",
    [202] = "Profession-overview-Card-Engineering",
    [165] = "Profession-overview-Card-Leatherworking",
    [197] = "Profession-overview-Card-Tailoring",
    --[185] = "Profession-overview-Card-Research",
    --[356] = "Profession-overview-Card-Research",
    --[129] = "Profession-overview-Card-Research",
    [182] = "Profession-overview-Card-Herbalism",
    [186] = "Profession-overview-Card-Mining",
    [393] = "Profession-overview-Card-Skinning",
}
function ForeverTBDProfessionListButtonMixin:SetBackground()
    if professions[self:GetID()] then
        self.Background:SetAtlas(professions[self:GetID()]);
    else
        self.Background:SetAtlas("Profession-overview-Card")
    end
end