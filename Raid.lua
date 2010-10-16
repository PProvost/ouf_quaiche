local addonName, addonNS = ...
local oUF = addonNS.oUF

local function Layout(self, unit, isSingle)
	-- Do common setup first
	addonNS.CommonUnitSetup(self, unit, isSingle)

	-- Hide Blizz raid frames
	CompactRaidFrameContainer:Hide()
end

oUF:RegisterStyle('oUF_Quaiche - Raid', Layout)

oUF:Factory(function(self)
	self:SetActiveStyle('oUF_Quaiche - Raid')
	local raid = self:SpawnHeader(nil, nil, 'raid',
	'showPlayer', true,
	'showRaid', true,
	'groupBy', 'GROUP',
	'groupFilter', '1,2,3,4,5,6,7,8',
	'groupingOrder', '1,2,3,4,5,6,7,8',
	'maxColumns', 8,
	'unitsPerColumn', 5,
	'columnSpacing', 3,
	'yOffset', -3,
	'oUF-initialConfigFunction', [[
		self:SetWidth(80)
		self:SetHeight(25)
	]])
	raid:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOM', 145, 100)
end)
