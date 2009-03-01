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
local aura_size = 20
local border_size = screen_height / (uiscale * 768) -- screen_height / ui scale * 768 (normalized height) = 1 pixel in logical units
local party_spacing = 3
local raid_spacing = 3
local raid_group_spacing = 6
local aura_size = 20
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

do --[[ Custom colors ]]
	for powerType, value in pairs(oUF.colors.power) do
		if powerType == "RAGE" then
			oUF.colors.power[powerType] = { 0.75, 0.45, 0.25 }
		elseif powerType == "ENERGY" then
			oUF.colors.power[powerType] = { 1.0, 1.0, 0.45 }
		elseif powerType == "MANA" then
			oUF.colors.power[powerType] = { 0.25, 0.45, 0.75 }
		end
	end
end

local menu = function(self)
	local unit = self.unit:sub(1, -2)
	local cunit = self.unit:gsub("(.)", string.upper, 1)

	if unit == "party" or unit == "partypet" then
		ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor", 0, 0)
	elseif(_G[cunit.."FrameDropDown"]) then
		ToggleDropDownMenu(1, nil, _G[cunit.."FrameDropDown"], "cursor", 0, 0)
	end
end

local updateName = function(self, event, unit)
	if self.unit ~= unit then return end

	local nameString = UnitName(unit) or "Unknown"
	if UnitIsAFK(unit) then
		nameString = "|cFF990000" .. nameString .. "|r"
	end

	if unit=="target" or unit=="player" then -- prepend the name with level and classification
		local suffix = ""
		local level = UnitLevel(unit)
		if level == -1 then level = "??" end
		local classification = UnitClassification(unit)
		if classification == "rareelite" then suffix = "++" end
		if classification == "rare" then suffix = "r" end
		if classification == "elite" then suffix = "+" end
		nameString = " |cFF999999" .. level .. suffix .. "|r " .. nameString
	end

	self.Name:SetText(nameString)
end

local updateRIcon = function(self, event)
	local index = GetRaidTargetIndex(self.unit)
	if(index) then
		self.RIcon:SetText(ICON_LIST[index].."22|t")
	else
		self.RIcon:SetText()
	end
end

local function ShortValue(value)
	if(value >= 1e6) then
		return ('%.1fm'):format(value / 1e6):gsub('%.?0+([km])$', '%1')
	elseif(value >= 1e4) then
		return ('%.1fk'):format(value / 1e3):gsub('%.?0+([km])$', '%1')
	else
		return value
	end
end

local updateHealth = function(self, event, unit, bar, min, max)
	if(UnitIsDead(unit)) then
		bar:SetValue(0)
		bar.value:SetText("Dead")
	elseif(UnitIsGhost(unit)) then
		bar:SetValue(0)
		bar.value:SetText("Ghost")
	elseif(not UnitIsConnected(unit)) then
		bar.value:SetText("Offline")
	else
		if unit=="pet" or unit=="focus" or unit=="targettarget" or unit=="focustarget" then
			bar.value:SetFormattedText("%d%%", (min/max)*100)
		elseif unit=="target" then
			bar.value:SetFormattedText("%s (%d%%)", ShortValue(min), (min/max)*100)
		else
			local c = max - min
			if(c > 0) then
				bar.value:SetFormattedText("-%d", c)
			else
				bar.value:SetText(ShortValue(max))
			end
		end
	end

	if(UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) or not UnitIsConnected(unit)) then
		self.Name:SetTextColor(.6, .6, .6)
	end
	updateName(self, event, unit)
end

local PostUpdatePower = function(self, event, unit, bar, min, max)
	if(min == 0 or max == 0 or not UnitIsConnected(unit)) then
		bar:SetValue(0)
	elseif(UnitIsDead(unit) or UnitIsGhost(unit)) then
		bar:SetValue(0)
	end
end

local PostCreateAuraIcon = function(self, button)
	local count = button.count
	count:ClearAllPoints()
	count:SetPoint"BOTTOM"
	button.icon:SetTexCoord(.07, .93, .07, .93)
end

local style = function(settings, self, unit)
	-- Stash some settings into locals
	local width = settings["initial-width"]
	local height = settings["initial-height"]
	local pp_height = settings["powerbar-height"] or 6
	local hp_height = height - (pp_height + 2*border_size)

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
	self.PostUpdateHealth = updateHealth

	-- Unit name
	local name = hp:CreateFontString(nil, "OVERLAY")
	name:SetPoint("LEFT", hp, "LEFT", 2, 0)
	local right_offset = (unit=="player" or unit=="target") and 65 or 33
	name:SetPoint("RIGHT", hp, "RIGHT", -right_offset, 0)
	name:SetPoint("TOP", hp, "TOP", 0, -2)
	name:SetPoint("BOTTOM", hp, 'BOTTOM', 0, 2)
	name:SetJustifyH("LEFT")
	name:SetJustifyV("MIDDLE")
	name:SetFontObject(GameFontNormalSmall)
	name:SetTextColor(1, 1, 1)
	self.Name = name
	self:RegisterEvent("UNIT_NAME_UPDATE", updateName)
	self:RegisterEvent("UNIT_LEVEL", updateName)
	self:RegisterEvent("PLAYER_FLAGS_CHANGED", updateName) -- Fire updateName for AFK and DND changes

	-- Healthbar text
	local hpp = hp:CreateFontString(nil, "OVERLAY")
	hpp:SetPoint("RIGHT", -2, 0)
	hpp:SetWidth(unit=="target" and 100 or 50)
	hpp:SetJustifyH("RIGHT")
	hpp:SetFontObject(GameFontNormalSmall)
	hpp:SetTextColor(1, 1, 1)
	hp.value = hpp

	-- Hide raid and party pets
	if not unit and self:GetAttribute("unitsuffix") == "pet" then
		hpp:Hide()
		name:SetPoint("RIGHT", hp, "RIGHT", -2)
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

		-- Latency display on player only
		if unit == "player" then
			cb.SafeZone = cb:CreateTexture(nil, 'BORDER')
			cb.SafeZone:SetTexture(statusbartexture)
			cb.SafeZone:SetVertexColor(0.75, 0.75, 0.35, 0.35)
		end

		self.Castbar = cb
	end

	if unit == "player" or unit=="target" then
		self.Castbar.Text = self.Castbar:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmallLeft')
		self.Castbar.Text:SetPoint('CENTER', self.Castbar)
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
	if unit == "player" then
		local debuffs = CreateFrame("Frame", nil, self)
		debuffs:SetHeight(height)
		debuffs:SetWidth(width)
		debuffs:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
		debuffs.showDebuffType = true
		debuffs.size = aura_size
		debuffs.initialAnchor = "TOPLEFT"
		debuffs.spacing = 2
		debuffs["growth-x"] = "RIGHT"
		debuffs["growth-y"] = "DOWN"
		self.Debuffs = debuffs
	end

	if unit == "target" then
		local buffs = CreateFrame("Frame", nil, self)
		buffs:SetHeight(height)
		buffs:SetWidth(width/2)
		buffs:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
		buffs.size = aura_size
		buffs.num = 15
		-- buffs.filter = "RAID"
		buffs.initialAnchor = "TOPLEFT"
		buffs["growth-x"] = "RIGHT"
		buffs["growth-y"] = "DOWN"
		buffs.spacing = 2
		self.Buffs = buffs

		local debuffs = CreateFrame("Frame", nil, self)
		debuffs:SetHeight(height)
		debuffs:SetWidth(width/2)
		debuffs:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -2)
		debuffs.showDebuffType = true
		debuffs.size = aura_size
		debuffs.onlyShowPlayer = true
		debuffs.num = 15
		debuffs.initialAnchor = "TOPRIGHT"
		debuffs.spacing = 2
		debuffs["growth-x"] = "LEFT"
		debuffs["growth-y"] = "DOWN"
		self.Debuffs = debuffs
	end

	-- Support for oUF_Banzai
	if unit == "player" then
		self.ignoreBanzai = true
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

	-- Leader icon
	local leader = hp:CreateTexture(nil, "OVERLAY")
	leader:SetHeight(12)
	leader:SetWidth(12)
	leader:SetPoint("CENTER", self, "TOPLEFT")
	leader:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
	self.Leader = leader

	-- Raid icon
	local raid_icon = hp:CreateFontString(nil, "OVERLAY")
	raid_icon:SetPoint("CENTER", hp, "TOP")
	raid_icon:SetJustifyH("CENTER")
	raid_icon:SetFontObject(GameFontNormalSmall)
	raid_icon:SetTextColor(1, 1, 1)
	self.RIcon = raid_icon
	self:RegisterEvent("RAID_TARGET_UPDATE", updateRIcon)
	table.insert(self.__elements, updateRIcon)

	if unit == "player" then -- player gets resting and combat
		local resting = pp:CreateTexture(nil, "OVERLAY")
		resting:SetHeight(12)
		resting:SetWidth(12)
		resting:SetPoint("CENTER", self, "BOTTOMRIGHT")
		resting:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
		resting:SetTexCoord(0.09, 0.43, 0.08, 0.42)
		self.Resting = resting

		local combat = pp:CreateTexture(nil, "OVERLAY")
		combat:SetHeight(12)
		combat:SetWidth(12)
		combat:SetPoint("CENTER", self, "TOPRIGHT")
		combat:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
		combat:SetTexCoord(0.57, 0.90, 0.08, 0.41)
		self.Combat = combat
	end

	-- Range fading on party and partypets
	if (not unit) or string.match(unit, "partypet") then
		self.Range = true
		self.inRangeAlpha = 1
		self.outsideRangeAlpha = .5
	end

	self.PostCreateAuraIcon = PostCreateAuraIcon

	return self
end

local setmetatable = _G.setmetatable
oUF:RegisterStyle("Quaiche_Full", setmetatable({
	["initial-width"] = 200,
	["initial-height"] = 32,
	["powerbar-height"] = 8,
}, {__call = style}))

oUF:RegisterStyle("Quaiche_Half", setmetatable({
	["initial-width"] = 95,
	["initial-height"] = 20,
	["powerbar-height"] = 4,
}, {__call = style}))

oUF:RegisterStyle("Quaiche_Party", setmetatable({
	["initial-width"] = 125,
	["initial-height"] = 25,
}, {__call = style}))

oUF:RegisterStyle("Quaiche_Raid", setmetatable({
	["initial-width"] = 115,
	["initial-height"] = 18,
	["powerbar-height"] = 2,
}, {__call = style}))

--[[ STANDARD FRAMES ]]--
oUF:SetActiveStyle("Quaiche_Full") 
oUF:Spawn("player"):SetPoint("CENTER", UIParent, -180, -145)
oUF:Spawn("target"):SetPoint("CENTER", UIParent, 180, -145)

oUF:SetActiveStyle("Quaiche_Half")
oUF:Spawn("focus"):SetPoint("BOTTOMRIGHT", oUF.units.player, "TOPRIGHT", 0, 5)
oUF:Spawn("pet"):SetPoint("BOTTOMLEFT", oUF.units.player, "TOPLEFT", 0, 5)
oUF:Spawn("targettarget"):SetPoint("BOTTOMRIGHT", oUF.units.target, "TOPRIGHT", 0, 5)
oUF:Spawn("focustarget"):SetPoint("BOTTOMLEFT", oUF.units.target, "TOPLEFT", 0, 5)

oUF:SetActiveStyle("Quaiche_Party") 
local party = oUF:Spawn("header", "oUF_Party")
party:SetPoint("TOPLEFT", group_left, group_top)
party:SetAttribute("template", "oUF_QuaichePartyPets")
party:SetAttribute("showParty", true)
party:SetAttribute("yOffset", -party_spacing)
party:Show()

oUF:SetActiveStyle("Quaiche_Raid")
local raid = {}
for i = 1, NUM_RAID_GROUPS do
	local raidGroup = oUF:Spawn("header", "oUF_Raid" .. i)
	raidGroup:SetAttribute("groupFilter", tostring(i))
	raidGroup:SetAttribute("showraid", true)
	raidGroup:SetAttribute("yOffset", -raid_spacing)
	raidGroup:SetAttribute("point", "TOP")
	raidGroup:SetAttribute("template", "oUF_QuaicheRaidPets")
	table.insert(raid, raidGroup)
	if i == 1 then
		raidGroup:SetPoint("TOPLEFT", group_left, group_top)
	else
		raidGroup:SetPoint("TOPLEFT", raid[i-1], "BOTTOMLEFT", 0, -raid_group_spacing)	
	end
	raidGroup:Show()
end

-- Private frame for events and whatnot
local frame = CreateFrame('Frame')

-- General purpose event dispatcher
frame:SetScript("OnEvent", function(self, event, ...) 
	if self[event] then 
		return self[event](self, event, ...) 
	end 
end)

-- Timer function for the alpha checker
local total = 0
local freq = 0.15
frame:SetScript("OnUpdate", function(self, elapsed)
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
local UnitCasting = function(unit) return UnitCastingInfo(unit) ~= nil end
	
function frame:CheckFrameAlphas()
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
function frame:CheckPartyVisibility() 
	if(InCombatLockdown()) then
		self:RegisterEvent('PLAYER_REGEN_ENABLED') -- defer this until OOC
	else
		self:UnregisterEvent('PLAYER_REGEN_DISABLED') -- just in case
		if GetNumRaidMembers() > 0 then
			party:Hide()
		else
			party:Show()
		end
	end
end
frame.PLAYER_LOGIN = frame.CheckPartyVisibility
frame.RAID_ROSTER_UPDATE = frame.CheckPartyVisibility
frame.PARTY_LEADER_CHANGED = frame.CheckPartyVisibility
frame.PARTY_MEMBERS_CHANGED = frame.CheckPartyVisibility
frame.PLAYER_REGEN_ENABLED = frame.CheckPartyVisibility
frame.PLAYER_REGEN_DISABLED = frame.CheckPartyVisibility

-- Register all events
frame:RegisterEvent('PLAYER_LOGIN')
frame:RegisterEvent('RAID_ROSTER_UPDATE')
frame:RegisterEvent('PARTY_LEADER_CHANGED')
frame:RegisterEvent('PARTY_MEMBERS_CHANGED')
