local parent, ns = ...
local oUF = ns.oUF

-- Icon textures for locale-neutral identification of buffs
local RENEW = "Interface\\Icons\\Spell_Holy_Renew"
local ECHO = "Interface\\Icons\\Spell_Holy_Aspiration"
local GUARDIANSPIRIT = "Interface\\Icons\\Spell_Holy_GuardianSpirit"

local width, height = 5, 4
local spacing = 2
local order = { RENEW, ECHO, GUARDIANSPIRIT }
local state = {} -- Temp table to avoid memory thrashing

local hots = {
	[RENEW] = { count = 1, color = { r=0, g=1.0, b=0 }, }, -- Green
	[ECHO] = { count = 1, color = { r=1, g=1, b=0 }, },  -- Yellow
	[GUARDIANSPIRIT] = { count = 1, color = { r=0, g=0, b=1 }, }, -- Blue
}

local Update = function(self, event, unit)
	if self.unit ~= unit then return end

	local i = 1
	state[RENEW] = 0
	state[ECHO] = 0
	state[GUARDIANSPIRIT] = 0

	while true do
		local name, _, texture, count, _, _, expirationTime, caster = UnitBuff(unit, i, true)
		local isMine = (caster == "player")
		if not name then 
			break 
		end
		if isMine and hots[texture] then
			local timeleft = expirationTime - GetTime()
			state[texture] = 1
		end
		i = i + 1
	end

	for k,v in pairs(state) do
		for i=1,hots[k].count do
			if i <= state[k] then
				self.priestHotsIndicators[k][i]:Show()
			else
				self.priestHotsIndicators[k][i]:Hide()
			end
		end
	end
end

local Enable = function(self)
	if select(2,UnitClass("player")) ~= "PRIEST" then return end

	local i,j,k
	local tex
	local anchor, anchorPoint, x, y = self.Power, "TOP", -17, -2

	self.priestHotsIndicators = {}
	for j = 1,#order do
		k = order[j]
		self.priestHotsIndicators[k] = {}
		for i = 1,hots[k].count do
			tex = self.Power:CreateTexture(nil, "OVERLAY")
			tex:SetPoint("TOPLEFT", anchor, anchorPoint, x, y)
			tex:SetTexture(hots[k].color.r, hots[k].color.g, hots[k].color.b)
			tex:SetHeight(height)
			tex:SetWidth(width)
			tex:Hide()

			anchor, anchorPoint, x, y = tex, "TOPRIGHT", spacing, 0
			table.insert(self.priestHotsIndicators[k],tex)
		end
	end

	self:RegisterEvent("UNIT_AURA", Update)
end

local Disable = function(self)
	self:UnregisterEvent("UNIT_AURA", Update)
end

oUF:AddElement('PriestHots', Update, Enable, Disable)
