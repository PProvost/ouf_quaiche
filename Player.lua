local addonName, addonNS = ...
local oUF = addonNS.oUF

local function Layout_Full(self, unit, isSingle)
	addonNS.CommonUnitSetup(self, unit, isSingle)

	self.Power:SetHeight(10)
	self:SetSize(220, 32)

	self.HealthString:SetWidth(50)
	self.HealthString:SetFontObject(GameFontNormal)
	self.Name:SetFontObject(GameFontNormal)
end
oUF:RegisterStyle('oUF_Quaiche - Full', Layout_Full)

local function Layout_Half(self, unit, isSingle)
	addonNS.CommonUnitSetup(self, unit, isSingle)

	self.Power:SetHeight(2)
	self:SetSize(108, 18)
end
oUF:RegisterStyle('oUF_Quaiche - Half', Layout_Half)

oUF:Factory(function(self)

	self:SetActiveStyle('oUF_Quaiche - Full')
	self:Spawn('player'):SetPoint('CENTER', UIParent, 'CENTER', -120, -150)
	self:Spawn('target'):SetPoint('CENTER', UIParent, 'CENTER', 120, -150)

	self:SetActiveStyle('oUF_Quaiche - Half')
	self:Spawn("pet"):SetPoint("BOTTOMRIGHT", self.units.player, "TOPRIGHT", 0, 2)
	self:Spawn("focus"):SetPoint("BOTTOMLEFT", self.units.player, "TOPLEFT", 0, 2)
	self:Spawn("focustarget"):SetPoint("BOTTOMRIGHT", self.units.target, "TOPRIGHT", 0, 2)
	self:Spawn("targettarget"):SetPoint("BOTTOMLEFT", self.units.target, "TOPLEFT", 0, 2)

end)

