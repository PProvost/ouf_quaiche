local _, ns = ...
local oUF = ns.oUF or oUF

local function Layout(self, unit, isSingle)
	-- Do common setup first
	ns.CommonUnitSetup(self, unit, isSingle)
	ns.AddRangeFading(self)
	ns.AddDebuffHighlighting(self)
	ns.AddReadyCheck(self)

	-- Hide Blizz raid frames
	CompactRaidFrameContainer:Hide()
end

oUF:RegisterStyle('oUF_Quaiche - Raid', Layout)

oUF:Factory(function(self)
	self:SetActiveStyle('oUF_Quaiche - Raid')
	local raid = {}
	
	for group = 1, NUM_RAID_GROUPS do
		local header = self:SpawnHeader(nil, nil, 'raid',
			'showPlayer', true,
			'showParty', true,
			'showRaid', true,
			'groupFilter', tostring(group),
			'yOffset', -3,
			'oUF-initialConfigFunction', [[
				self:SetWidth(80);
				self:SetHeight(25)
			]])
		if group > 1 then
			header:SetPoint('BOTTOMLEFT', raid[group-1], 'BOTTOMRIGHT', 4, 0)
		else
			header:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOM', 145, 100)
		end
		raid[group] = header
	end
end)
