local addonName, addonNS = ...

local oUF = addonNS.oUF or oUF
assert(oUF, "oUF not loaded")

--------------------------------------------------------------
-- Common configuration
local uiscale = 0.85
local screen_height = 1050


--------------------------------------------------------------
-- Debuff display stuff
local CanDispel = {
	PRIEST = { Magic = true, Disease = true, },
	SHAMAN = { Magic = true, Curse = true, },
	PALADIN = { Magic = true, Poison = true, Disease = true, },
	MAGE = { Curse = true, },
	DRUID = { Magic = true, Curse = true, Poison = true, }
}
local playerClass = select(2,UnitClass("player"))
local dispellist = CanDispel[playerClass] or {}

--------------------------------------------------------------
-- Custom colors
local colors = setmetatable({
	health = {.45, .73, .27},
	power = setmetatable({
		['MANA'] 		= { 0.27, 0.53, 0.73 },
		['RAGE'] 		= { 0.73, 0.27, 0.27 },
		['ENERGY'] 	= { 1.00, 1.00, 0.45 },
	}, {__index = oUF.colors.power}),
}, {__index = oUF.colors})

--------------------------------------------------------------
-- Custom tags
local siValue = function(val)
	if(val >= 1e6) then
		return ('%.1f'):format(val / 1e6).."m" --:gsub('%.', 'm')
	elseif(val >= 1e4) then
		return ("%.1f"):format(val / 1e3).."k" --:gsub('%.', 'k')
	else
		return val
	end
end

local tags = oUF.Tags.Methods or oUF.Tags
local tagevents = oUF.TagEvents or oUF.Tags.Events

tags['q:health'] = function(unit)
	if(not UnitIsConnected(unit) or UnitIsDead(unit) or UnitIsGhost(unit)) then return end

	local min, max = UnitHealth(unit), UnitHealthMax(unit)
	if(min ~= 0 and min ~= max) then
		return '-' .. siValue(max - min)
	else
		return siValue(min)
	end
end
tagevents['q:health'] = tagevents.missinghp

tags['q:afk'] = function(unit)
	return UnitIsAFK(unit) and "|cFF990000" or nil
end
tagevents['q:afk'] = "PLAYER_FLAGS_CHANGED"

tags["q:health2"] = function(unit) 
	if(not UnitIsConnected(unit) or UnitIsDead(unit) or UnitIsGhost(unit)) then return end

	local min, max = UnitHealth(unit), UnitHealthMax(unit)
	if(not UnitIsFriend('player', unit)) then
		return siValue(min)
	elseif(min ~= 0 and min ~= max) then
		return '-' .. siValue(max - min)
	else
		return max
	end
end
tagevents["q:health2"] = tagevents.missinghp

tags['q:perhp'] = function(unit)
	local m = UnitHealthMax(unit)
	local h = UnitHealth(unit)
	if h==m then return "" end

	local result = 0
	if(m > 0) then
		result = math.floor(h/m*100+.5)
	end
	return " ("..result.."%)"	
end
tagevents['q:perhp'] = "UNIT_HEALTH UNIT_MAXHEALTH"

--------------------------------------------------------------
-- Right click menu handler 
local menu = function(self)
	local unit = self.unit:sub(1, -2)
	local cunit = self.unit:gsub("(.)", string.upper, 1)

	if cunit == "Vehicle" then
		cunit = "Pet"
	end

	if(unit == "party" or unit == "partypet") then
		ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor", 0, 0)
	elseif(_G[cunit.."FrameDropDown"]) then
		ToggleDropDownMenu(1, nil, _G[cunit.."FrameDropDown"], "cursor", 0, 0)
	end
end

--------------------------------------------------------------
-- Helper functions
local function GetDebuffType(unit, filter)
	if not UnitCanAssist("player", unit) then return nil end
	local i = 1
	while true do
		local _, _, texture, _, debufftype = UnitAura(unit, i, "HARMFUL")
		if not texture then break end
		if debufftype and not filter or (filter and dispellist[debufftype]) then
			return debufftype, texture
		end
		i = i + 1
	end
end

local function UpdateDebuffStatus(self, event, unit)
	-- Dispellable-debuff coloring
	if self.unit ~= unit then return end
	local debuffType, texture  = GetDebuffType(unit, true)
	if debuffType then
		local color = DebuffTypeColor[debuffType] 
		self.Health:SetStatusBarColor(color.r, color.g, color.b, color.a or 0.5)
	end
end

--------------------------------------------------------------
-- Special oUF pseudo-events
local PostUpdateHealth = function(Health, unit, min, max)
	if(UnitIsDead(unit)) then
		Health:SetValue(0)
	elseif(UnitIsGhost(unit)) then
		Health:SetValue(0)
	end

	UpdateDebuffStatus(Health:GetParent(), "UNIT_AURA", unit)
end

local PostUpdatePower = function(Power, unit, min, max)
	local Health = Power:GetParent().Health
	if(min == 0 or max == 0 or not UnitIsConnected(unit)) then
		Power:SetValue(0)
	elseif(UnitIsDead(unit) or UnitIsGhost(unit)) then
		Power:SetValue(0)
	end
end

local RAID_TARGET_UPDATE = function(self, event)
	local index = GetRaidTargetIndex(self.unit)
	if(index) then
		self.RIcon:SetText(ICON_LIST[index].."22|t")
	else
		self.RIcon:SetText()
	end
end

--------------------------------------------------------------
-- Common statusbar texture
local TEXTURE = [[Interface\AddOns\oUF_Quaiche\textures\minimalist]]
addonNS.TEXTURE = TEXTURE

--------------------------------------------------------------
-- Adds Range fading the given unit frame
function addonNS.AddRangeFading(self, ...)
	local range = {
		insideAlpha = 1.0,
		outsideAlpha = 0.5,
	}
	self.Range = range
end

function addonNS.AddDebuffHighlighting(self, ...)
	-- self.DebuffHighlight = self.Health
	-- self.DebuffHighlightFilter = true
end

function addonNS.AddReadyCheck(self, ...)
	local readyCheck = self.Health:CreateTexture(nil, 'OVERLAY')
	readyCheck:SetSize(24,24)
	readyCheck:SetPoint("CENTER", self, "CENTER")
	self.ReadyCheck = readyCheck
end

function addonNS.AddLFDRole(self)
	local lfdRole = self:CreateTexture(nil, 'OVERLAY')
	lfdRole:SetSize(16, 16)
	lfdRole:SetPoint("RIGHT", self, "LEFT", -4)
	self.LFDRole = lfdRole
end

--------------------------------------------------------------
-- Common setup for all unit frames
function addonNS.CommonUnitSetup(self, unit, isSingle)

	-- Layout parameters
	local powerbarHeight = 6

	-- General menu and event setup
	self.menu = menu
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)
	self:RegisterForClicks("AnyDown")

	-- Powerbar
	local power = CreateFrame("StatusBar", nil, self)
	power:SetStatusBarTexture(TEXTURE)
	power.frequentUpdates = true
	power.colorDisconnected = true
	power.colorPower = true
	power.colorTapping = true
	power:SetPoint("LEFT")
	power:SetPoint("RIGHT")
	power:SetPoint("BOTTOM")
	power:SetHeight(powerbarHeight) 
	power.PostUpdate = PostUpdatePower
	self.Power = power

	-- Healthbar
	local health = CreateFrame("StatusBar", nil, self)
	health:SetStatusBarTexture(TEXTURE)
	health:SetPoint("TOP")
	health:SetPoint("LEFT")
	health:SetPoint("RIGHT")
	health:SetPoint("BOTTOM", power, "TOP")
	health.colorDisconnected = true
	health.colorClass = true
	health.colorClassPet = true
	health.colorSmooth = true
	health.colorTapping = true
	health.frequentUpdates = true
	health.PostUpdate = PostUpdateHealth
	self.Health = health

	-- Health Background
	local healthBackground = health:CreateTexture(nil, "BORDER")
	healthBackground:SetAllPoints(self)
	healthBackground:SetTexture(0, 0, 0, .5)
	health.bg = healthBackground

	-- Health text
	local healthText = health:CreateFontString(nil, "OVERLAY")
	healthText:SetPoint("RIGHT", -2, 0)
	healthText:SetWidth(30) --unit=="target" and 100 or 50)
	healthText:SetJustifyH("RIGHT")
	healthText:SetFontObject(GameFontNormalSmall)
	healthText:SetTextColor(1, 1, 1)
	self.HealthString = healthText
	self:Tag(healthText, "[dead][offline][q:health]")

	-- Heal Predictors
	local myHealPredictor = CreateFrame('StatusBar', nil, self.Health)
	myHealPredictor:SetPoint('TOPLEFT', health:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
	myHealPredictor:SetPoint('BOTTOMLEFT', health:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
	myHealPredictor:SetStatusBarTexture(TEXTURE)
	myHealPredictor:SetStatusBarColor(0, 1, 0.5, 0.25)

	local otherHealPredictor = CreateFrame('StatusBar', nil, self.Health)
	otherHealPredictor:SetPoint('TOPLEFT', myHealPredictor:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
	otherHealPredictor:SetPoint('BOTTOMLEFT', myHealPredictor:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
	otherHealPredictor:SetStatusBarTexture(TEXTURE)
	otherHealPredictor:SetStatusBarColor(0, 1, 0, 0.25)

	self.QHealPrediction = {
		myBar = myHealPredictor,
		otherBar = otherHealPredictor,
		maxOverflow = 1,
	}

	-- Unit name
	local name = health:CreateFontString(nil, "OVERLAY")
	name:SetPoint("TOP")
	name:SetPoint("BOTTOM")
	name:SetPoint("LEFT", health, "LEFT", 4)
	name:SetPoint("RIGHT", healthText, 'LEFT', -2)
	name:SetJustifyH("LEFT"); 
	name:SetTextColor(1, 1, 1)
	name:SetFontObject(GameFontNormalSmall)
	self:Tag(name, '[q:afk][name]')
	self.Name = name

	-- Leader icon
	local leader = health:CreateTexture(nil, "OVERLAY")
	leader:SetSize(16,16)
	leader:SetPoint("CENTER", self, "TOPLEFT", 4)
	self.Leader = leader

	-- Master Looter Icon
	local masterLooter = self:CreateTexture(nil, 'OVERLAY')
	masterLooter:SetSize(16,16)
	masterLooter:SetPoint("LEFT", leader, "RIGHT", 2)

	-- PvP icon
	local pvp = health:CreateTexture(nil, "OVERLAY")
	pvp:SetSize(16,16)
	pvp:SetPoint("CENTER", self, "TOPRIGHT")
	self.PvP = pvp

	-- Raid Icon
	local raid_icon = health:CreateTexture(nil, "OVERLAY")
	raid_icon:SetPoint("CENTER", health, "CENTER")
	raid_icon:SetSize(16, 16)
	self.RaidIcon = raid_icon

	-- Hook up events
	--[[
	self:RegisterEvent('UNIT_NAME_UPDATE', UpdateName)
	table.insert(self.__elements, UpdateName)
	]]

	-- Hook up the debuff highlighting
	self:RegisterEvent("UNIT_AURA", UpdateDebuffStatus)

	-- Hook  up custom colors
	self.colors = colors

	return self
end

