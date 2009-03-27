--[[
Name: oUF_Quaiche
Author: Quaiche
Description: A custom oUF layout for QBertUI

Copyright 2008 Quaiche

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
--]]

--- Global function/symbol storage
local CreateFrame = _G.CreateFrame
local GameFontNormal = _G.GameFontNormal
local GameFontNormalSmall = _G.GameFontNormalSmall
local GetNumRaidMembers = _G.GetNumRaidMembers
local GetRaidTargetIndex = _G.GetRaidTargetIndex
local ICON_LIST = _G.ICON_LIST
local InCombatLockdown = _G.InCombatLockdown
local select = _G.select
local ToggleDropDownMenu = _G.ToggleDropDownMenu
local UnitIsConnected = _G.UnitIsConnected
local UnitIsDead = _G.UnitIsDead
local UnitIsGhost = _G.UnitIsGhost
local UnitIsTapped = _G.UnitIsTapped
local UnitIsTappedByPlayer = _G.UnitIsTappedByPlayer

--- Configuration parameters
local uiscale = 0.85
local screen_height = 1050
local group_left, group_top = 10, -25
local statusbartexture = "Interface\\AddOns\\oUF_Quaiche\\Minimalist"
local border_size = screen_height / (uiscale * 768) -- screen_height / ui scale * 768 (normalized height) = 1 pixel in logical units
local party_spacing = 2
local raid_spacing = 2
local raid_group_spacing = 8
local raid_width = 100
local healer_mode_raid_top = 85
local backdrop = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	tile = true,
	tileSize = 16,
	edgeFile = "",
	edgeSize = 0,
	border_sizes = {
		left = border_size,
		right = border_size,
		top = border_size,
		bottom = border_size,
	},
}
local runeColors = {
	[1] = {0.77, 0.12, 0.23},
	[2] = {0.77, 0.12, 0.23},
	[3] = {0.4, 0.8, 0.1},
	[4] = {0.4, 0.8, 0.1},
	[5] = {0, 0.4, 0.7},
	[6] = {0, 0.4, 0.7},
}

-- Other locals
local _, player_class = UnitClass('player')

--[[ Addon frame for events and global storage ]]--

oUF_Quaiche = CreateFrame('Frame')
oUF_Quaiche:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)

function oUF_Quaiche:RAID_ROSTER_UPDATE()
	self:CheckPartyVisibility()

	if self.healerMode then
		local max = 0
		for i = 1,MAX_RAID_MEMBERS do
			local subgroup = select(3, GetRaidRosterInfo(i))
			if  subgroup > max then max = subgroup end
		end

		local total_width = max*raid_width + (max-1)*raid_spacing
		local left = total_width / 2

		self.raidGroups[1]:SetPoint("TOPLEFT", UIParent, "TOP", -left, -healer_mode_raid_top)
	end
end

function oUF_Quaiche:SetHealerLayout()
	for i=1,NUM_RAID_GROUPS do
		local raidGroup = self.raidGroups[i]
		if i == 1 then
			raidGroup:SetPoint("TOPLEFT", group_left, group_top)
		else
			raidGroup:SetPoint("TOPLEFT", self.raidGroups[i-1], "TOPRIGHT", raid_group_spacing, 0)
		end
	end
	
	self.raidPets:ClearAllPoints()
	self.raidPets:SetPoint("TOP", UIParent, "TOP", 0, -(healer_mode_raid_top + 100))
	self.raidPets:SetAttribute("maxColumns", 8)
	self.raidPets:SetAttribute("unitsPerColumn", 5)

	self:RAID_ROSTER_UPDATE()
end

function oUF_Quaiche:SetNormalLayout()
	for i = 1, NUM_RAID_GROUPS do
		local raidGroup = self.raidGroups[i]
		if i == 1 then
			raidGroup:SetPoint("TOPLEFT", group_left, group_top)
		elseif mod(i,5) == 1 then
			raidGroup:SetPoint("TOPLEFT", self.raidGroups[i-5], "TOPRIGHT", raid_group_spacing, 0)
		else
			raidGroup:SetPoint("TOPLEFT", self.raidGroups[i-1], "BOTTOMLEFT", 0, -raid_group_spacing)
		end
	end

	self.raidPets:ClearAllPoints()
	self.raidPets:SetPoint("TOPLEFT", oUF_Quaiche.raidGroups[5], "BOTTOMLEFT", 0, -raid_group_spacing)
	self.raidPets:SetAttribute("maxColumns", 1)
	self.raidPets:SetAttribute("unitsPerColumn", 5)
end

local debugf = tekDebug and tekDebug:GetFrame("oUF_Quaiche")
local function Debug(msg) if debugf then debugf:AddMessage(tostring(msg)) end end

--[[ Custom colors ]]
for powerType, value in pairs(oUF.colors.power) do
	if powerType == "RAGE" then
		oUF.colors.power[powerType] = { 0.75, 0.45, 0.25 }
	elseif powerType == "ENERGY" then
		oUF.colors.power[powerType] = { 1.0, 1.0, 0.45 }
	elseif powerType == "MANA" then
		oUF.colors.power[powerType] = { 0.25, 0.45, 0.75 }
	end
end

--[[ Right click menu handler ]]--
local menu = function(self)
	local unit = self.unit:sub(1, -2)
	local cunit = self.unit:gsub("(.)", string.upper, 1)

	if unit == "party" or unit == "partypet" then
		ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor", 0, 0)
	elseif(_G[cunit.."FrameDropDown"]) then
		ToggleDropDownMenu(1, nil, _G[cunit.."FrameDropDown"], "cursor", 0, 0)
	end
end

--[[ Colors the health bar according to current Threat Situation ]]
local ColorThreat = function(self, event, unit)
	if self.unit ~= unit then return end
	local status = UnitThreatSituation(self.unit)
	if status > 0 then
		if unit == "player" then
			local r, g, b = GetThreatStatusColor(status)
			self.Health:SetStatusBarColor(r,g,b)
		elseif status > 1 then
			self.Health:SetStatusBarColor(1,0,0)
		end
	end
end

local PostUpdatePower = function(self, event, unit, bar, min, max)
	if(min == 0 or max == 0 or not UnitIsConnected(unit)) then
		bar:SetValue(0)
	elseif(UnitIsDead(unit) or UnitIsGhost(unit)) then
		bar:SetValue(0)
	end
	ColorThreat(self, event, unit)
end

local PostCreateAuraIcon = function(self, button)
	-- Minor readjustment of the stackcount position, and the texture (to remove the border)
	local count = button.count
	count:ClearAllPoints()
	count:SetPoint"BOTTOM"
	button.icon:SetTexCoord(.07, .93, .07, .93)
end

local UnitFactory = function(settings, self, unit)
	-- Stash some settings into locals
	local width = settings["initial-width"]
	local height = settings["initial-height"]
	local hideHealthText = settings["hide-health-text"]
	local pp_height = settings["powerbar-height"] or 6
	local hp_height = height - (pp_height + 2*border_size)

	Debug(hideHealthText)

	-- General menu and event setup
	self.menu = menu
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)
	self:RegisterForClicks("anyup")
	self:SetAttribute("*type2", "menu")

	-- Backdrop makes a border
	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0,0,0,1)

	-- Healthbar
	local hp = CreateFrame("StatusBar", nil, self)
	hp:SetStatusBarTexture(statusbartexture)
	hp:SetHeight(hp_height)
	hp:SetPoint("TOP", self, "TOP", 0, -border_size)
	hp:SetPoint("LEFT", self, "LEFT", border_size, 0)
	hp:SetPoint("RIGHT", self, "RIGHT", -border_size, 0)
	hp.colorDisconnected = true
	hp.colorClass = true
	hp.colorClassPet = true
	if unit and string.match(unit,"target") then 
		hp.colorTapping = true
		hp.colorReaction = true
	end
	self.Health = hp

	-- Health text
	if not hideHealthText then
		local hpp = hp:CreateFontString(nil, "OVERLAY")
		hpp:SetPoint("RIGHT", -2, 0)
		hpp:SetWidth(unit=="target" and 100 or 50)
		hpp:SetJustifyH("RIGHT")
		hpp:SetFontObject(GameFontNormalSmall)
		hpp:SetTextColor(1, 1, 1)
		self:Tag(hpp, "[qhealth]")
	end

	-- Unit name
	local right_offset = (unit=="player" or unit=="target") and 65 or 33
	local name = hp:CreateFontString(nil, "OVERLAY")
	name:SetPoint("LEFT", hp, "LEFT", 2, 0)
	name:SetPoint("RIGHT", hp, "RIGHT", hideHealthText and -2 or -right_offset, 0)
	name:SetPoint("TOP", hp, "TOP", 0, -2)
	name:SetPoint("BOTTOM", hp, 'BOTTOM', 0, 2)
	name:SetJustifyH("LEFT"); name:SetJustifyV("MIDDLE")
	name:SetTextColor(1, 1, 1)
	if unit == "player" or unit == "target" then
		name:SetFontObject(GameFontNormal)
		self:Tag(name, "[difficulty][smartlevel]|r [afk][name]|r")
	else
		name:SetFontObject(GameFontNormalSmall)
		self:Tag(name, "[afk][pethappinesscolor][name]|r")
	end

	-- Powerbar
	local pp = CreateFrame("StatusBar", nil, self)
	pp:SetStatusBarTexture(statusbartexture)
	pp:SetStatusBarColor( unpack(oUF.colors.power["MANA"]) )
	pp:SetHeight(pp_height) 
	pp:SetPoint("LEFT", self, "LEFT", border_size, 0)
	pp:SetPoint("RIGHT", self, "RIGHT", -border_size, 0)
	pp:SetPoint("TOP", hp, "BOTTOM")
	pp.colorTapping = true
	pp.colorDisconnected = true
	pp.colorPower = true
	self.Power = pp
	self.PostUpdatePower = PostUpdatePower

	-- Castbar
	if unit == "player" or unit == "target" then
		local cb = CreateFrame("StatusBar", nil, self)
		cb:SetStatusBarTexture(statusbartexture)
		cb:SetStatusBarColor(.75, .75, .35, 0.65)
		cb:SetAllPoints(pp)
		cb:SetFrameStrata("HIGH")
		self.Castbar = cb

		self.Castbar.Text = self.Castbar:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmallLeft')
		self.Castbar.Text:SetPoint('CENTER', self.Castbar)
	end
	
	-- Latency display on player only
	if unit == "player" then
		local cb = self.Castbar
		cb.SafeZone = cb:CreateTexture(nil, 'BORDER')
		cb.SafeZone:SetTexture(statusbartexture)
		cb.SafeZone:SetVertexColor(0.75, 0.75, 0.35, 0.35)
	end

	-- Combo Points
	if unit == "player" then
		self.CPoints = {}
		local x,y = -28, 0
		for i =1,5 do
			local bullet = pp:CreateTexture(nil, "OVERLAY")
			bullet:SetTexture("Interface\\Addons\\oUF_Quaiche\\ComboPoint")
			bullet:SetWidth(8)
			bullet:SetHeight(8)
			bullet:SetPoint("CENTER", pp, "CENTER", x, y)
			x = x + 9
			self.CPoints[i] = bullet
		end
	end

	-- Auras
	if unit == "player" or unit =="target" then
		local buffs = CreateFrame("Frame", nil, self)
		buffs.size = (width/12)-2   -- 12 per row
		buffs.num = 36 -- 3 rows
		buffs:SetHeight((buffs.size+2)*3)
		buffs:SetWidth(width)
		buffs:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
		buffs.initialAnchor = "TOPLEFT"
		buffs["growth-x"] = "RIGHT"
		buffs["growth-y"] = "DOWN"
		buffs.spacing = 2
		self.Buffs = buffs

		local debuffs = CreateFrame("Frame", nil, self)
		debuffs.size = (width/12)-2 -- 12 per row
		debuffs.num = 24 -- 2 rows
		debuffs:SetHeight((buffs.size+2)*3)
		debuffs:SetWidth(width)
		debuffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 2)
		debuffs.showDebuffType = true
		debuffs.initialAnchor = "BOTTOMLEFT"
		debuffs.spacing = 2
		debuffs["growth-x"] = "RIGHT"
		debuffs["growth-y"] = "UP"
		if unit == "target" then debuffs.onlyShowPlayer = true end
		self.Debuffs = debuffs

		self.PostCreateAuraIcon = PostCreateAuraIcon
	end

	-- Threat coloring
	if not(unit and string.match(unit,"target")) then 
		self.PostUpdateHealth = ColorThreat -- This will let us recolor the bar after oUF colors it
		self:RegisterEvent('UNIT_THREAT_LIST_UPDATE', ColorThreat) -- To catch it even earlier than damage
		self:RegisterEvent('UNIT_THREAT_SITUATION_UPDATE', ColorThreat)
	end

	-- Support for oUF_CombatFeedback
	local cbft = hp:CreateFontString(nil, "OVERLAY")
	cbft:SetPoint("CENTER", hp, "CENTER")
	cbft:SetFontObject(GameFontNormal)
	self.CombatFeedbackText = cbft

	-- Support for oUF_ReadyCheck
	local readycheck = hp:CreateTexture(nil, "OVERLAY")
	readycheck:SetHeight(12)
	readycheck:SetWidth(12)
	readycheck:SetPoint("CENTER", self, "TOPRIGHT", 0, 0)
	readycheck:Hide()
	self.ReadyCheck = readycheck

	-- Support for oUF_DebuffHighlight
	local dbh = hp:CreateTexture(nil, "OVERLAY")
	dbh:SetWidth(16)
	dbh:SetHeight(16)
	dbh:SetPoint("CENTER", self, "CENTER")
	self.DebuffHighlight = dbh
	self.DebuffHighlightUseTexture = true -- use the spell texture for the debuff
	self.DebuffHighlightFilter = true -- only show it if I can remove it

	-- Support for oUF_RuneBar
	if unit=="player" and IsAddOnLoaded('oUF_RuneBar') and player_class == 'DEATHKNIGHT' then
		local half_height = pp_height/2
		local rb_width = (width-7*border_size)/6
		pp:SetHeight(half_height)
		self.RuneBar = {}
		for i = 1, 6 do
			self.RuneBar[i] = CreateFrame('StatusBar', nil, self)
			if(i == 1) then
				self.RuneBar[i]:SetPoint('TOPLEFT', pp, 'BOTTOMLEFT', 0, 0)
			else
				self.RuneBar[i]:SetPoint('LEFT', self.RuneBar[i-1], 'RIGHT', border_size, 0)
			end
			self.RuneBar[i]:SetStatusBarTexture(statusbartexture)
			self.RuneBar[i]:SetStatusBarColor(unpack(runeColors[i]))
			self.RuneBar[i]:SetHeight(half_height)
			self.RuneBar[i]:SetParent(pp)
			self.RuneBar[i]:SetWidth(rb_width)
			self.RuneBar[i]:SetMinMaxValues(0, 1)
		end
	end

	-- Leader icon
	local leader = hp:CreateTexture(nil, "OVERLAY")
	leader:SetHeight(12)
	leader:SetWidth(12)
	leader:SetPoint("CENTER", self, "TOPLEFT")
	self.Leader = leader

	-- Raid icon
	local raid_icon = hp:CreateTexture(nil, "OVERLAY")
	if unit == "player" or unit =="target" then
		raid_icon:SetPoint("CENTER", hp, "TOP")
	else
		raid_icon:SetPoint("CENTER", hp, "CENTER")
	end
	raid_icon:SetHeight(16); raid_icon:SetWidth(16)
	self.RaidIcon = raid_icon

	if unit == "player" then -- player gets resting and combat
		local resting = pp:CreateTexture(nil, "OVERLAY")
		resting:SetHeight(12)
		resting:SetWidth(12)
		resting:SetPoint("CENTER", self, "BOTTOMRIGHT")
		self.Resting = resting

		local combat = pp:CreateTexture(nil, "OVERLAY")
		combat:SetHeight(12)
		combat:SetWidth(12)
		combat:SetPoint("CENTER", self, "TOPRIGHT")
		self.Combat = combat
	end

	-- Range fading on party and partypets
	if (not unit) or string.match(unit, "partypet") then
		self.Range = true
		self.inRangeAlpha = 1
		self.outsideRangeAlpha = .5
	end

	return self
end

local setmetatable = _G.setmetatable
oUF:RegisterStyle("Quaiche_Full", setmetatable({
	["initial-width"] = 240,
	["initial-height"] = 36,
	["powerbar-height"] = 10,
}, {__call = UnitFactory}))

oUF:RegisterStyle("Quaiche_Small", setmetatable({
	["initial-width"] = 95,
	["initial-height"] = 18,
	["powerbar-height"] = 2,
}, {__call = UnitFactory}))

oUF:RegisterStyle("Quaiche_Party", setmetatable({
	["initial-width"] = 125,
	["initial-height"] = 25,
	["powerbar-height"] = 5,
}, {__call = UnitFactory}))

oUF:RegisterStyle("Quaiche_PartyPets", setmetatable({
	["initial-width"] = 85,
	["initial-height"] = 25,
	["powerbar-height"] = 5,
	["hide-health-text"] = true,
}, {__call = UnitFactory}))

oUF:RegisterStyle("Quaiche_Raid", setmetatable({
	["initial-width"] = raid_width,
	["initial-height"] = 18,
	["powerbar-height"] = 2,
}, {__call = UnitFactory}))

oUF:RegisterStyle("Quaiche_RaidPets", setmetatable({
	["initial-width"] = 75,
	["initial-height"] = 18,
	["powerbar-height"] = 2,
	["hide-health-text"] = true,
}, {__call = UnitFactory}))

--[[ STANDARD FRAMES ]]--
oUF:SetActiveStyle("Quaiche_Full") 
oUF:Spawn("player"):SetPoint("CENTER", UIParent, -150, -145)
oUF:Spawn("target"):SetPoint("CENTER", UIParent, 150, -145)

oUF:SetActiveStyle("Quaiche_Small")
oUF:Spawn("focus"):SetPoint("TOPRIGHT", oUF.units.player, "TOPLEFT", -2, 0)
oUF:Spawn("pet"):SetPoint("BOTTOMRIGHT", oUF.units.player, "BOTTOMLEFT", -2, 0)
oUF:Spawn("focustarget"):SetPoint("TOPLEFT", oUF.units.target, "TOPRIGHT", 2, 0)
oUF:Spawn("targettarget"):SetPoint("BOTTOMLEFT", oUF.units.target, "BOTTOMRIGHT", 2, 0)

--[[ PARTY FRAMES ]]--
oUF:SetActiveStyle("Quaiche_Party") 
local party = oUF:Spawn("header", "oUF_Party")
party:SetPoint("TOPLEFT", group_left, group_top)
party:SetAttribute("showParty", true)
party:SetAttribute("yOffset", -party_spacing)
party:Show()

oUF:SetActiveStyle("Quaiche_PartyPets") 
local partypets = oUF:Spawn("header", "oUF_PartyPets", "SecureGroupPetHeaderTemplate")
partypets:SetPoint("TOPLEFT", party, "TOPRIGHT", party_spacing, 0)
partypets:SetAttribute("showParty", true)
partypets:SetAttribute("showRaid", false)
partypets:SetAttribute("yOffset", -party_spacing)
partypets:SetAttribute("hide-health-text", true)
partypets:Show()

--[[ RAID FRAMES ]]--
oUF:SetActiveStyle("Quaiche_Raid")
oUF_Quaiche.raidGroups = {}
local raid = {}
for i = 1, NUM_RAID_GROUPS do
	local raidGroup = oUF:Spawn("header", "oUF_Raid" .. i)
	raidGroup:SetAttribute("groupFilter", tostring(i))
	raidGroup:SetAttribute("showraid", true)
	raidGroup:SetAttribute("yOffset", -raid_spacing)
	table.insert(oUF_Quaiche.raidGroups, raidGroup)
	raidGroup:Show()
end

oUF:SetActiveStyle("Quaiche_RaidPets")
local raidpets = oUF:Spawn("header", "oUF_PartyPets", "SecureGroupPetHeaderTemplate")
raidpets:SetAttribute("showParty", false)
raidpets:SetAttribute("showRaid", true)
raidpets:SetAttribute("xOffset", raid_spacing)
raidpets:SetAttribute("yOffset", -raid_spacing)
raidpets:SetAttribute("groupFilter", "1,2,3,4,5,6,7,8")
raidpets:Show()
oUF_Quaiche.raidPets = raidpets

oUF_Quaiche:SetNormalLayout()

-- Timer function for the alpha checker
local total = 0
local freq = 0.15
oUF_Quaiche:SetScript("OnUpdate", function(self, elapsed)
  total = total + elapsed
    if total >= freq then
			self:CheckFrameAlphas()
      total = 0
    end
end)

-- Alpha condition check functions
local UnitMaxHealth = function(unit) return unit and not UnitIsDeadOrGhost(unit) and UnitHealth(unit) == UnitHealthMax(unit) end
local UnitMaxMana = function(unit) 
	return unit and not UnitIsDeadOrGhost(unit) and ((UnitPowerType(unit) ~= 1 and UnitPower(unit) == UnitPowerMax(unit)) or (UnitPower(unit) == 0))
end
local UnitCasting = function(unit) return UnitCastingInfo(unit) ~= nil or oUF_Quaiche.casting end
	
function oUF_Quaiche:CheckFrameAlphas()
	if UnitMaxHealth("player") and UnitMaxMana("player") and
		UnitMaxHealth("pet") and UnitMaxMana("pet") and
		not UnitCasting("player") and
		not UnitExists("target") and
		not InCombatLockdown() and
		not UnitIsAFK("player") then
			oUF.units.player:SetAlpha(0)
			oUF.units.pet:SetAlpha(0)
	else
		oUF.units.player:SetAlpha(1)
		oUF.units.pet:SetAlpha(1)
	end
end

-- Check Party Visibility Helper function and event handlers
function oUF_Quaiche:CheckPartyVisibility() 
	if(InCombatLockdown()) then
		self:RegisterEvent('PLAYER_REGEN_ENABLED') -- defer this until OOC
	else
		self:UnregisterEvent('PLAYER_REGEN_DISABLED') -- just in case
		if GetNumRaidMembers() > 0 then
			party:Hide()
			partypets:Hide()
		else
			party:Show()
			partypets:Show()
		end
	end
end
oUF_Quaiche.PLAYER_LOGIN = oUF_Quaiche.CheckPartyVisibility
oUF_Quaiche.PARTY_LEADER_CHANGED = oUF_Quaiche.CheckPartyVisibility
oUF_Quaiche.PARTY_MEMBERS_CHANGED = oUF_Quaiche.CheckPartyVisibility
oUF_Quaiche.PLAYER_REGEN_ENABLED = oUF_Quaiche.CheckPartyVisibility
oUF_Quaiche.PLAYER_REGEN_DISABLED = oUF_Quaiche.CheckPartyVisibility

function oUF_Quaiche:UNIT_SPELLCAST_CHANNEL_STOP()
	self.casting = false
end

function oUF_Quaiche:UNIT_SPELLCAST_CHANNEL_START()
	self.casting = true
end

-- Register all events
oUF_Quaiche:RegisterEvent('PLAYER_LOGIN')
oUF_Quaiche:RegisterEvent('RAID_ROSTER_UPDATE')
oUF_Quaiche:RegisterEvent('PARTY_LEADER_CHANGED')
oUF_Quaiche:RegisterEvent('PARTY_MEMBERS_CHANGED')
oUF_Quaiche:RegisterEvent('UNIT_SPELLCAST_CHANNEL_START')
oUF_Quaiche:RegisterEvent('UNIT_SPELLCAST_CHANNEL_STOP')

function oUF_Quaiche:SwapRaidLayout()
	self.healerMode = not self.healerMode
	if self.healerMode then
		self:SetHealerLayout()
	else
		self:SetNormalLayout()
	end
end

SLASH_OUFQUAICHE1 = "/quaiche"
SLASH_OUFQUAICHE2 = "/qua"
SlashCmdList.OUFQUAICHE = function(msg)
	if GetNumRaidMembers() > 0 then
		oUF_Quaiche:SwapRaidLayout()
	else
		print("|cFF33FF99oUF_Quaiche|r: You are not in a raid")
	end
end

