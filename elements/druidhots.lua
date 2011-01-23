local parent, ns = ...
local oUF = ns.oUF

-- Icon textures for locale-neutral identification of buffs
local LIFEBLOOM = "Interface\\Icons\\INV_Misc_Herb_Felblossom"
local REGROWTH = "Interface\\Icons\\Spell_Nature_ResistNature"
local REJUVENATION = "Interface\\Icons\\Spell_Nature_Rejuvenation"
local WILDGROWTH = "Interface\\Icons\\Ability_Druid_Flourish"

local width, height = 4, 3
local offsetX, offsetY = 3, -2
local spacing = 2
local order = { LIFEBLOOM, REJUVENATION, REGROWTH, WILDGROWTH }
local state = {} -- Temp table to avoid memory thrashing

local hots = {
	[LIFEBLOOM] = { count = 3, color = { r=0, g=1.0, b=0 }, },
	[REGROWTH] = { count = 1, color = { r=0, g=0, b=1 }, },
	[REJUVENATION] = { count = 1, color = { r=1, g=1, b=0 }, },
	[WILDGROWTH] = { count = 1, color = { r=1, g=0.5, b=0 }, },
}

local Update = function(self, event, unit)
	if self.unit ~= unit then return end

	local i = 1
	state[LIFEBLOOM] = 0
	state[REGROWTH] = 0
	state[REJUVENATION] = 0
	state[WILDGROWTH] = 0

	while true do
		local name, _, texture, count, _, _, expirationTime, caster = UnitBuff(unit, i, true)
		local isMine = (caster == "player")
		if not name then 
			break 
		end
		if isMine and hots[texture] then
			local timeleft = expirationTime - GetTime()
			if texture == LIFEBLOOM then
				state[texture] = count
			else
				state[texture] = 1
			end
		end
		i = i + 1
	end

	for k,v in pairs(state) do
		for i=1,hots[k].count do
			if i <= state[k] then
				self.druidHotsIndicators[k][i]:Show()
			else
				self.druidHotsIndicators[k][i]:Hide()
			end
		end
	end
end

local Enable = function(self)
	if select(2,UnitClass("player")) ~= "DRUID" then return end

	local i,j,k
	local tex
	local anchor, anchorPoint, x, y = self.Health, "TOPLEFT", offsetX, offsetY

	self.druidHotsIndicators = {}
	for j = 1,#order do
		k = order[j]
		self.druidHotsIndicators[k] = {}
		for i = 1,hots[k].count do
			tex = self.Health:CreateTexture(nil, "OVERLAY")
			tex:SetPoint("TOPLEFT", anchor, anchorPoint, x, y)
			tex:SetTexture(hots[k].color.r, hots[k].color.g, hots[k].color.b)
			tex:SetHeight(height)
			tex:SetWidth(width)
			tex:Hide()

			anchor, anchorPoint, x, y = tex, "TOPRIGHT", spacing, 0
			table.insert(self.druidHotsIndicators[k],tex)
		end
	end

	self:RegisterEvent("UNIT_AURA", Update)
end

local Disable = function(self)
	self:UnregisterEvent("UNIT_AURA", Update)
end

oUF:AddElement('DruidHots', Update, Enable, Disable)
