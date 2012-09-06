local _, ns = ...
local oUF = ns.oUF or oUF

local function Layout(self, unit, isSingle)
	-- Do common setup first
	ns.CommonUnitSetup(self, unit, isSingle)
	ns.AddRangeFading(self)
	ns.AddDebuffHighlighting(self)
	ns.AddReadyCheck(self)
	ns.AddLFDRole(self)

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
