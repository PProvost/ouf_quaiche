local addonName, addonNS = ...
local oUF = addonNS.oUF

-- Coords of the shard icon in the texture
local c1, c2, c3, c4 = 0.01562500, 0.28125000, 0.00781250, 0.13281250

-- Auto-fading helper functions
local casting
local UnitMaxHealth = function(unit) return unit and (not UnitIsDeadOrGhost(unit)) and (UnitHealth(unit) == UnitHealthMax(unit)) end
local UnitMaxMana = function(unit) return unit and (not UnitIsDeadOrGhost(unit)) and ((UnitPowerType(unit) ~= 1 and UnitPower(unit) == UnitPowerMax(unit)) or (UnitPower(unit) == 0)) end
local UnitCasting = function(unit) return (UnitCastingInfo(unit) ~= nil) or casting end

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

		-- Don't do anything if we're in combat, hopefully we got it right before this
		if InCombatLockdown() then return end

		if event == "UNIT_SPELLCAST_CHANNEL_START" then
			casting = true
		elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
			casting = nil
		end

		if UnitMaxHealth('player') and UnitMaxMana('player') and (not UnitExists("target"))
			and (not UnitExists("focus")) and	(not UnitCasting('player')) and (not UnitIsAFK('player'))
			and (not UnitUsingVehicle('player'))
		then
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

	f:RegisterEvent("PLAYER_ENTERING_WORLD")
	f:RegisterEvent("PLAYER_FLAGS_CHANGED")
	f:RegisterEvent("PLAYER_REGEN_DISABLED")
	f:RegisterEvent("UNIT_HEALTH")
	f:RegisterEvent("UNIT_POWER")
	f:RegisterEvent("UNIT_TARGET")
	f:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	f:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
end

local PostCastStart = function(Castbar, unit, spell, spellrank)
	Castbar.Text:SetText(spell)
end

local PostCastStop = function(Castbar, unit)
	Castbar.Text:SetText('')
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

	local info = self.Health:CreateFontString(nil, "OVERLAY")
	info:SetPoint("TOPLEFT", 2, 0)
	info:SetPoint("BOTTOMLEFT", 2, 0)
	-- info:SetWidth(16)
	info:SetJustifyH("LEFT")
	info:SetFontObject(GameFontNormal)
	-- info:SetTextColor(1.0, 0.82, 0)
	self:Tag(info, "[difficulty][level][shortclassification] ")
	self.Info = info

	self.Name:SetPoint("LEFT", info, "RIGHT")

	if unit == "player" then
		local class = select(2, UnitClass('player'))
		if class == "WARLOCK" then
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
		elseif class=="DRUID" or class=="ROGUE" then
			local cpoints = {}
			for i = 1, MAX_COMBO_POINTS do
				cpoints[i] = self.Power:CreateTexture(nil, 'OVERLAY')
				cpoints[i]:SetSize(8,9)
			end
			cpoints[3]:SetPoint("CENTER", 0, -1)
			cpoints[2]:SetPoint("RIGHT", cpoints[3], 'LEFT', -10)
			cpoints[1]:SetPoint("RIGHT", cpoints[2], 'LEFT', -10)
			cpoints[4]:SetPoint("LEFT", cpoints[3], 'RIGHT', 10)
			cpoints[5]:SetPoint("LEFT", cpoints[4], 'RIGHT', 10)
			self.CPoints = cpoints
		end

		local combat = self.Health:CreateTexture(nil, "OVERLAY")
		combat:SetPoint("RIGHT", self.PvP, "LEFT")
		combat:SetSize(16,16)
		self.Combat = combat

		local resting = self.Power:CreateTexture(nil, 'OVERLAY')
		resting:SetPoint("CENTER", self, "BOTTOMLEFT")
		resting:SetSize(16,16)
		self.Resting = resting

		local altPowerBar = CreateFrame("StatusBar", nil, self)
		altPowerBar:SetStatusBarTexture(TEXTURE)
		altPowerBar:SetPoint("TOPLEFT", self.Power, "BOTTOMLEFT")
		altPowerBar:SetPoint("TOPRIGHT", self.Power, "BOTTOMRIGHT")
		altPowerBar:SetHeight(12) 
		altPowerBar:SetStatusBarColor(0.5, 0, 0)
		self.AltPowerBar = altPowerBar

	elseif unit == "target" then
		local castbar = CreateFrame("StatusBar", nil, self)
		castbar:SetStatusBarTexture(addonNS.TEXTURE)
		castbar:SetStatusBarColor(0.65, 0.65, 0.65, .5)
		castbar:SetAllPoints(self.Power)
		castbar:SetToplevel(true)
		castbar:GetStatusBarTexture():SetHorizTile(false)
		castbar.PostChannelStart = PostCastStart
		castbar.PostCastStart = PostCastStart
		castbar.PostCastStop = PostCastStop
		castbar.PostChannelStop = PostCastStop
		self.Castbar = castbar

		local healthText = self.HealthString
		healthText:SetWidth(90)
		self:Tag(healthText, "[dead][offline][q:health][q:perhp]")

		local castbarText = castbar:CreateFontString("OVERLAY")
		castbarText:SetAllPoints()
		castbarText:SetFontObject(GameFontNormalSmall)
		self.Castbar.Text = castbarText
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

	-- Comment out the following line if you don't like the auto-fading stuff
	SetupAutoFading(self.units.player, self.units.pet, self.units.focus)
end)
