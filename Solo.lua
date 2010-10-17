local addonName, addonNS = ...
local oUF = addonNS.oUF

-- Coords of the shard icon in the texture
local c1, c2, c3, c4 = 0.01562500, 0.28125000, 0.00781250, 0.13281250

-- Auto-fading helper functions
local UnitMaxHealth = function(unit) return unit and (not UnitIsDeadOrGhost(unit)) and (UnitHealth(unit) == UnitHealthMax(unit)) end
local UnitMaxMana = function(unit) return unit and (not UnitIsDeadOrGhost(unit)) and ((UnitPowerType(unit) ~= 1 and UnitPower(unit) == UnitPowerMax(unit)) or (UnitPower(unit) == 0)) end
local UnitCasting = function(unit) return (UnitCastingInfo(unit) ~= nil) --[[or oUF_Quaiche.casting]] end

local function OnEvent(self, event, ...)
	if event == "PLAYER_REGEN_DISABLED" then
		-- Show it always if we're entering into combat
		self.player:Enable()
		self.pet:Enable()
		self.focus:Enable()
	else
		-- One of our other events fired, run the check to see if it should be visible
		local event_unit = ...
		if event_unit ~= 'player' then return end

		if UnitMaxHealth('player')
			and UnitMaxMana('player')
			and (not UnitExists("target"))
			and (not UnitExists("focus"))
			and	(not UnitCasting('player')) then 
			self.player:Disable()
			self.pet:Disable()
			self.focus:Disable()
		else
			self.player:Enable()
			self.pet:Enable()
			self.focus:Enable()
		end
	end

end

local function SetupAutoFading(player, pet, focus)
	local f = CreateFrame("Frame")
	f.player = player
	f.pet = pet
	f.focus = focus

	f:SetScript("OnEvent", OnEvent)

	f:RegisterEvent("PLAYER_REGEN_DISABLED")
	f:RegisterEvent("UNIT_HEALTH")
	f:RegisterEvent("UNIT_POWER")
	f:RegisterEvent("UNIT_TARGET")
	f:RegisterEvent("UNIT_SPELLCAST_START")
	f:RegisterEvent("UNIT_SPELLCAST_STOP")
end

local function Layout_Full(self, unit, isSingle)
	addonNS.CommonUnitSetup(self, unit, isSingle)

	-- Tweak the size a bit
	self.Power:SetHeight(10)
	self:SetSize(220, 32)

	-- Big font for health and name
	self.HealthString:SetWidth(50)
	self.HealthString:SetFontObject(GameFontNormal)
	self.Name:SetFontObject(GameFontNormal)

	if unit == "player" then
		if select(2, UnitClass('player')) == "WARLOCK" then
			-- Warlock Soul Shards
			local shards = {}
			for i = 1, SHARD_BAR_NUM_SHARDS do
				shards[i] = self.Power:CreateTexture(nil, 'OVERLAY')
				shards[i]:SetTexture("Interface\\PlayerFrame\\UI-WarlockShard")
				shards[i]:SetTexCoord(c1, c2, c3, c4)
				shards[i]:SetSize(12,12)
			end
			shards[2]:SetPoint("CENTER")
			shards[1]:SetPoint("RIGHT", shards[2], 'LEFT', -10)
			shards[3]:SetPoint("LEFT", shards[2], 'RIGHT', 10)
			self.SoulShards = shards
		end
	end
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
	self:Spawn('player'):SetPoint('CENTER', UIParent, 'CENTER', -120, -140)
	self:Spawn('target'):SetPoint('CENTER', UIParent, 'CENTER', 120, -140)

	self:SetActiveStyle('oUF_Quaiche - Half')
	self:Spawn("pet"):SetPoint("BOTTOMRIGHT", self.units.player, "TOPRIGHT", 0, 2)
	self:Spawn("focus"):SetPoint("BOTTOMLEFT", self.units.player, "TOPLEFT", 0, 2)
	self:Spawn("focustarget"):SetPoint("BOTTOMRIGHT", self.units.target, "TOPRIGHT", 0, 2)
	self:Spawn("targettarget"):SetPoint("BOTTOMLEFT", self.units.target, "TOPLEFT", 0, 2)

	SetupAutoFading(self.units.player, self.units.pet, self.units.focus)

end)

