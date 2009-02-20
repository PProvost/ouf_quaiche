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

--- Configuration parameters. Use these for simple adjustments. 
local left, top = 10, -25
local powerbar_height = 3
local statusbartexture = "Interface\\AddOns\\oUF_Quaiche\\Minimalist"

local debugf = tekDebug and tekDebug:GetFrame("oUF_Quaiche")
local function Debug(...) if debugf then debugf:AddMessage(string.join(", ", ...)) end end

--- Global function/symbol storage
local CreateFrame = _G.CreateFrame
local GameFontNormal = _G.GameFontNormal
local GameFontNormalSmall = _G.GameFontNormalSmall
local GetNumRaidMembers = _G.GetNumRaidMembers
local GetNumPartyMembers = _G.GetNumPartyMembers
local GetPetHappiness = _G.GetPetHappiness
local GetRaidTargetIndex = _G.GetRaidTargetIndex
local ICON_LIST = _G.ICON_LIST
local InCombatLockdown = _G.InCombatLockdown
local RAID_CLASS_COLORS = _G.RAID_CLASS_COLORS
local RegisterUnitWatch = _G.RegisterUnitWatch
local select = _G.select
local ToggleDropDownMenu = _G.ToggleDropDownMenu
local UnitClass = _G.UnitClass
local UnitIsConnected = _G.UnitIsConnected
local UnitIsDead = _G.UnitIsDead
local UnitIsGhost = _G.UnitIsGhost
local UnitIsPlayer = _G.UnitIsPlayer
local UnitIsTapped = _G.UnitIsTapped
local UnitIsTappedByPlayer = _G.UnitIsTappedByPlayer
local UnitPowerType = _G.UnitPowerType
local UnitReaction = _G.UnitReaction
local UnregisterUnitWatch = _G.UnregisterUnitWatch

local menu = function(self)
	local unit = self.unit:sub(1, -2)
	local cunit = self.unit:gsub("(.)", string.upper, 1)

	if unit == "party" or unit == "partypet" then
		ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor", 0, 0)
	elseif(_G[cunit.."FrameDropDown"]) then
		ToggleDropDownMenu(1, nil, _G[cunit.."FrameDropDown"], "cursor", 0, 0)
	end
end

local updateColor = function(self, element, unit, func)
	local color = {}
	if UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) or not UnitIsConnected(unit) then
		element[func](element, .6, .6, .6)
	elseif UnitIsPlayer(unit) then
		color = RAID_CLASS_COLORS[select(2, UnitClass(unit))]
	else
		color.r, color.g, color.b, color.a = UnitSelectionColor(unit)
	end

	if color then 
		element[func](element, color.r, color.g, color.b)
	end
end

local updateName = function(self, event, unit)
	if(self.unit == unit) then
		self.Name:SetText(UnitName(unit))
	end
end

local updateRIcon = function(self, event)
	local index = GetRaidTargetIndex(self.unit)
	if(index) then
		self.RIcon:SetText(ICON_LIST[index].."22|t")
	else
		self.RIcon:SetText()
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
		local c = max - min
		if(c > 0) then
			bar.value:SetFormattedText("-%d", c)
		else
			bar.value:SetText(max)
		end
	end

	if(UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) or not UnitIsConnected(unit)) then
		self.Name:SetTextColor(.6, .6, .6)
		self.Power:SetStatusBarColor(.6, .6, .6)
	else
		self:UNIT_NAME_UPDATE(event, unit)
	end

	updateColor(self, bar, unit, 'SetStatusBarColor')
end

local updatePower = function(self, event, unit, bar, min, max)
	if(UnitIsDead(unit) or UnitIsGhost(unit)) then
		bar:SetValue(0)
	end

	local color = oUF.colors.power[UnitPowerType(unit)]
	if(color) then
		bar:SetStatusBarColor(unpack(color))
	else
		bar:SetStatusBarColor(48/255, 113/255, 191/255)
	end
end

local auraIcon = function(self, button)
	local count = button.count
	count:ClearAllPoints()
	count:SetPoint"BOTTOM"
	button.icon:SetTexCoord(.07, .93, .07, .93)
end

local style = function(settings, self, unit)

	-- Stash some settings into locals
	local hp_height = settings["initial-height"] - powerbar_height 
	local pp_height = settings["initial-height"] - hp_height
	local width = settings["initial-width"]
	local hideHealthText = settings["hide-health-text"]

	-- General menu and event setup
	self.menu = menu
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)
	self:RegisterForClicks"anyup"
	self:SetAttribute("*type2", "menu")

	-- Healthbar
	local hp = CreateFrame("StatusBar", nil, self)
	hp:SetStatusBarTexture(statusbartexture)
	hp:SetStatusBarColor(.25, .25, .35)
	hp:SetHeight(hp_height)
	hp:SetPoint("TOP")
	hp:SetPoint("LEFT")
	hp:SetPoint("RIGHT")
	self.Health = hp
	self.OverrideUpdateHealth = updateHealth

	-- Healthbar background
	local hpbg = hp:CreateTexture(nil, "BORDER")
	hpbg:SetAllPoints(hp)
	hpbg:SetTexture(0, 0, 0, .5)
	hp.bg = hpbg

	-- Healthbar text
	local hpp = hp:CreateFontString(nil, "OVERLAY")
	hpp:SetPoint("RIGHT", -3, 0)
	hpp:SetWidth(40)
	hpp:SetJustifyH("RIGHT")
	hpp:SetFontObject(GameFontNormalSmall)
	hpp:SetTextColor(1, 1, 1)
	hp.value = hpp

	-- Powerbar
	local pp = CreateFrame("StatusBar", nil, self)
	pp:SetStatusBarTexture(statusbartexture)
	pp:SetStatusBarColor(.25, .25, .35)
	pp:SetHeight(pp_height) 
	pp:SetPoint("LEFT")
	pp:SetPoint("RIGHT")
	pp:SetPoint("TOP", hp, "BOTTOM")
	self.Power = pp
	self.OverrideUpdatePower = updatePower

	-- Power bar background
	local ppbg = pp:CreateTexture(nil, "BORDER")
	ppbg:SetAllPoints(pp)
	ppbg:SetTexture(0, 0, 0, .5)
	pp.bg = ppbg

	-- Unit name
	local name = hp:CreateFontString(nil, "OVERLAY")
	name:SetPoint("LEFT", hp, "LEFT", 3, 0)
	name:SetWidth(width - 40)
	name:SetJustifyH("LEFT")
	name:SetFontObject(GameFontNormalSmall)
	name:SetTextColor(1, 1, 1)
	self.Name = name
	self.UNIT_NAME_UPDATE = updateName

	-- Hide health text if partypet or raid frame
	Debug("unit="..tostring(unit), "hideHealtText=" .. tostring(hideHealthText))
	if hideHealthText then
		hpp:Hide()
		name:SetPoint("RIGHT", hp, "RIGHT", -3, 0)
		name:SetJustifyH("CENTER")
	end

	-- Support for oUF_AFK
	local afkIcon = hp:CreateTexture(nil, "OVERLAY")
	afkIcon:SetPoint("CENTER", name, "CENTER")
	afkIcon:SetWidth(16)
	afkIcon:SetHeight(16)
	afkIcon:Hide()
	self.AFKIcon = afkIcon

	-- Support for oUF_CombatFeedback
	local cbft = hp:CreateFontString(nil, "OVERLAY")
	cbft:SetPoint("CENTER", self, "CENTER")
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
	leader:SetPoint("CENTER", hp, "TOPLEFT", 0, 0)
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

	-- Range fading on party and partypets
	if (not unit) or string.match(unit, "partypet") then
		self.Range = true
		self.inRangeAlpha = 1
		self.outsideRangeAlpha = .5
	end

	self.PostCreateAuraIcon = auraIcon

	return self
end

local setmetatable = _G.setmetatable
oUF:RegisterStyle("Quaiche", setmetatable({
	["initial-width"] = 104,
	["initial-height"] = 24,
}, {__call = style}))

oUF:RegisterStyle("Quaiche_Raid", setmetatable({
	["initial-width"] = 50,
	["initial-height"] = 20,
	["hide-health-text"] = true,
}, {__call = style}))

--[[ STANDARD FRAMES ]]--

oUF:SetActiveStyle("Quaiche") 

local player = oUF:Spawn("player")
player:SetPoint("TOPLEFT", left, top)
player:SetAttribute("showSolo", false)
player:SetAttribute("showParty", true)
player:SetAttribute("showRaid", true)
UnregisterUnitWatch(player)
player:Hide()

local party = oUF:Spawn("header", "oUF_Party")
party:SetPoint("TOPLEFT", player, "BOTTOMLEFT", 0, -6)
party:SetAttribute("template", "oUF_QuaichePartyPets")
party:SetAttribute("showParty", true)
party:SetAttribute("yOffset", -4)
party:Show()

local focus = oUF:Spawn("focus")
focus:SetPoint("CENTER", 200, 285)

local tot = oUF:Spawn("targettarget")
tot:SetPoint("CENTER", 0, -145)

--[[ RAID FRAMES ]]--

oUF:SetActiveStyle("Quaiche_Raid")

local raid = {}
for i = 1, NUM_RAID_GROUPS do
	local raidGroup = oUF:Spawn("header", "oUF_Raid" .. i)
	raidGroup:SetAttribute("groupFilter", tostring(i))
	raidGroup:SetAttribute("showraid", true)
	raidGroup:SetAttribute("yOffset", -4)
	raidGroup:SetAttribute("point", "TOP")
	table.insert(raid, raidGroup)
	if i == 1 then
		raidGroup:SetPoint("TOPLEFT", player, "BOTTOMLEFT", 0, -6)
	else
		raidGroup:SetPoint("TOPLEFT", raid[i-1], "TOPRIGHT", 4, 0)	
	end
	raidGroup:Show()
end

local function EventHandler(self, event)
	if(InCombatLockdown()) then
		self:RegisterEvent('PLAYER_REGEN_ENABLED')
	else
		self:UnregisterEvent('PLAYER_REGEN_DISABLED')

		-- Hide player if playing solo
		if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 and player:IsVisible() then
			UnregisterUnitWatch(player)
			player:Hide()
		elseif (not player:IsVisible()) and (GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0) then
			player:Show()
			RegisterUnitWatch(player)
		end

		-- Hide party in raid
		if GetNumRaidMembers() > 0 then
			party:Hide()
		else
			party:Show()
		end
	end
end

local eventFrame = CreateFrame('Frame')
eventFrame:RegisterEvent('PLAYER_LOGIN')
eventFrame:RegisterEvent('RAID_ROSTER_UPDATE')
eventFrame:RegisterEvent('PARTY_LEADER_CHANGED')
eventFrame:RegisterEvent('PARTY_MEMBERS_CHANGED')
eventFrame:SetScript('OnEvent', EventHandler)

