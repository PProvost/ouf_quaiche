local addonName, addonNS = ...
local oUF = addonNS.oUF

local function Layout(self, unit, isSingle)
	-- Do common setup first
	addonNS.CommonUnitSetup(self, unit, isSingle)
	addonNS.AddRangeFading(self)
	addonNS.AddDebuffHighlighting(self)
	addonNS.AddReadyCheck(self)
	addonNS.AddLFDRole(self)

	-- Resize party pet
	if (self:GetAttribute("unitsuffix") == "pet") then
		self:SetSize(90,20)
	end
	
end

oUF:RegisterStyle('oUF_Quaiche - Party', Layout)

oUF:Factory(function(self)
	self:SetActiveStyle('oUF_Quaiche - Party')
	local party = self:SpawnHeader(nil, nil, 'solo,party',
		'showSolo', false,
		'showPlayer', true,
		'showParty', true,
		'yOffset', -3,
		'template', 'oUF_QuaichePartyPets',
		'oUF-initialConfigFunction', [[
			self:SetWidth(140)
			self:SetHeight(25)
		]])
	party:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOM', 145, 100)
end)
