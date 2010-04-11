--[[
Name: LibOufQuaiche
Author: Quaiche
Description: Common stuff for my oUF layouts

Copyright 2010 Quaiche

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


assert(LibStub, "LibOufQuaiche requires LibStub")
assert(oUF, "LibOufQuaiche requires oUF")

--------------------------------------------------------------
-- Lib setup
local lib, oldminor = LibStub:NewLibrary("LibOufQuaiche", 1)
if not lib then return end
oldminor = oldminor or 0

--------------------------------------------------------------
-- Common configuration
local uiscale = 0.85
local screen_height = 1050
local border_size = screen_height / (uiscale * 768) -- screen_height / ui scale * 768 (normalized height) = 1 pixel in logical units
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

--------------------------------------------------------------
-- Special powerbar handling
local PostUpdatePower = function(self, event, unit, bar, min, max)
	if(min == 0 or max == 0 or not UnitIsConnected(unit)) then
		bar:SetValue(0)
	elseif(UnitIsDead(unit) or UnitIsGhost(unit)) then
		bar:SetValue(0)
	end
end

--------------------------------------------------------------
-- Right click menu handler 
local menu = function(self)
	local unit = self.unit:sub(1, -2)
	local cunit = self.unit:gsub("(.)", string.upper, 1)

	if(unit == "party" or unit == "partypet") then
		ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor", 0, 0)
	elseif(_G[cunit.."FrameDropDown"]) then
		ToggleDropDownMenu(1, nil, _G[cunit.."FrameDropDown"], "cursor", 0, 0)
	end
end

--------------------------------------------------------------
-- Custom colors
if not lib.customColors then
	for powerType, value in pairs(oUF.colors.power) do
		if powerType == "RAGE" then
			oUF.colors.power[powerType] = { 0.75, 0.45, 0.25 }
		elseif powerType == "ENERGY" then
			oUF.colors.power[powerType] = { 1.0, 1.0, 0.45 }
		elseif powerType == "MANA" then
			oUF.colors.power[powerType] = { 0.25, 0.45, 0.75 }
		end
	end
	lib.customColors = true
end


--------------------------------------------------------------
-- Common statusbar texture
lib.statusbartexture = "Interface\\AddOns\\oUF_Quaiche\\Minimalist"

--------------------------------------------------------------
-- Holder for unit specific helper functions
-- To use set a unit function from the layout
-- e.g. lib.UnitSpecific["player"] = function(settings, self) end
lib.UnitSpecific = {}

--------------------------------------------------------------
-- Main entry point
-- Common setup for all unit frames goes here
function lib.CommonUnitSetup(settings, self, unit)

	-- Stash some settings into locals
	local width = settings["initial-width"]
	local height = settings["initial-height"]
	local hideHealthText = settings["hide-health-text"]
	local pp_height = settings["powerbar-height"] or 6
	local hp_height = height - (pp_height + 2*border_size)
	local hide_decorations = settings["hide-decorations"]

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
	hp:SetStatusBarTexture(lib.statusbartexture)
	hp:SetHeight(hp_height)
	hp:SetPoint("TOP", self, "TOP", 0, -border_size)
	hp:SetPoint("LEFT", self, "LEFT", border_size, 0)
	hp:SetPoint("RIGHT", self, "RIGHT", -border_size, 0)
	hp.colorDisconnected = true
	hp.colorClass = true
	hp.colorClassPet = true
	hp.frequentUpdates = true
	self.Health = hp

	-- Health text
	if not hideHealthText then
		local hpp = hp:CreateFontString(nil, "OVERLAY")
		hpp:SetPoint("RIGHT", -2, 0)
		hpp:SetWidth(50) --unit=="target" and 100 or 50)
		hpp:SetJustifyH("RIGHT")
		hpp:SetFontObject(GameFontNormalSmall)
		hpp:SetTextColor(1, 1, 1)
		self.HealthString = hpp
		self:Tag(hpp, "[qhealth]")
	end

	-- Unit name
	local right_offset = 33
	local name = hp:CreateFontString(nil, "OVERLAY")
	name:SetPoint("LEFT", hp, "LEFT", 2, 0)
	name:SetPoint("RIGHT", hp, "RIGHT", hideHealthText and -2 or -right_offset, 0)
	name:SetPoint("TOP", hp, "TOP", 0, -2)
	name:SetPoint("BOTTOM", hp, 'BOTTOM', 0, 2)
	name:SetJustifyH("LEFT"); name:SetJustifyV("MIDDLE")
	name:SetTextColor(1, 1, 1)
	name:SetFontObject(GameFontNormalSmall)
	self:Tag(name, "[afk][pethappinesscolor][name]|r")
	self.NameString = name

	-- Powerbar
	local pp = CreateFrame("StatusBar", nil, self)
	pp:SetStatusBarTexture(lib.statusbartexture)
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

	-- Threat coloring
	local threat = self:CreateTexture(nil, "OVERLAY")
	threat:SetTexture([[Interface/Tooltips/UI-Tooltip-Background]])
	threat:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0.25, 0.25)
	threat:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", -0.25, -0.25)
	self.Threat = threat

	-- Raid icon
	local raid_icon = hp:CreateTexture(nil, "OVERLAY")
	raid_icon:SetPoint("CENTER", hp, "CENTER")
	raid_icon:SetHeight(16); raid_icon:SetWidth(16)
	self.RaidIcon = raid_icon

	-- Support for oUF_DebuffHighlight
	local dbh = hp:CreateTexture(nil, "OVERLAY")
	dbh:SetWidth(16)
	dbh:SetHeight(16)
	dbh:SetPoint("CENTER", self, "CENTER")
	self.DebuffHighlight = dbh
	self.DebuffHighlightUseTexture = true -- use the spell texture for the debuff
	self.DebuffHighlightFilter = true -- only show it if I can remove it

	-- Support for oUF_CombatFeedback
	local cbft = hp:CreateFontString(nil, "OVERLAY")
	cbft:SetPoint("CENTER", hp, "CENTER")
	cbft:SetFontObject(GameFontNormal)
	self.CombatFeedbackText = cbft

	if not hide_decorations then
		-- Leader icon
		local leader = hp:CreateTexture(nil, "OVERLAY")
		leader:SetHeight(12)
		leader:SetWidth(12)
		leader:SetPoint("CENTER", self, "TOPLEFT")
		self.Leader = leader

		-- PvP icon
		local pvp = hp:CreateTexture(nil, "OVERLAY")
		pvp:SetHeight(16)
		pvp:SetWidth(16)
		pvp:SetPoint("CENTER", self, "TOPRIGHT")
		self.PvP = pvp
	end

	-- Raid Icon
	local raid_icon = hp:CreateTexture(nil, "OVERLAY")
	raid_icon:SetPoint("CENTER", hp, "CENTER")
	raid_icon:SetHeight(16); raid_icon:SetWidth(16)
	self.RaidIcon = raid_icon


	-- Call any unit specific setup that is configured
	local unit = unit or "party"
	if lib.UnitSpecific[unit] then
		return lib.UnitSpecific[unit](settings, self)
	end
	return self
end

