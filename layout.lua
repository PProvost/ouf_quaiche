--[[
Name: oUF_Quaiche
Author: Quaiche
Description: A custom oUF layout for QBertUI

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

local liboufq = LibStub:GetLibrary("LibOufQuaiche")
local _, player_class = UnitClass('player')

local uiscale = 0.85
local screen_height = 1050
local border_size = screen_height / (uiscale * 768) -- screen_height / ui scale * 768 (normalized height) = 1 pixel in logical units

local runeColors = {
	[1] = {0.77, 0.12, 0.23},
	[2] = {0.77, 0.12, 0.23},
	[3] = {0.4, 0.8, 0.1},
	[4] = {0.4, 0.8, 0.1},
	[5] = {0, 0.4, 0.7},
	[6] = {0, 0.4, 0.7},
}

local function CreateCastbarOverlay(self)
	local cb = CreateFrame("StatusBar", nil, self)
	cb:SetStatusBarTexture(liboufq.statusbartexture)
	cb:SetStatusBarColor(.75, .75, .35, 0.65)
	cb:SetAllPoints(self.Power)
	cb:SetFrameStrata("HIGH")
	self.Castbar = cb

	self.Castbar.Text = self.Castbar:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmallLeft')
	self.Castbar.Text:SetPoint('LEFT', self.Castbar, 2)

	self.PowerText = self.Power:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmallRight')
	self.PowerText:SetPoint('RIGHT', self.Power, -2)
	self:Tag(self.PowerText, "[qpower]")
end

liboufq.UnitSpecific["player"] = function(settings, self)
	-- Bigger font and custom tag for NameString
	self.NameString:SetFontObject(GameFontNormal)
	self:Tag(self.NameString, "[difficulty][smartlevel]|r [afk][name]|r")

	-- Castbar
	CreateCastbarOverlay(self)

	-- Cast latency display
	local cb = self.Castbar
	cb.SafeZone = cb:CreateTexture(nil, 'BORDER')
	cb.SafeZone:SetTexture(liboufq.statusbartexture)
	cb.SafeZone:SetVertexColor(0.75, 0.75, 0.35, 0.35)

	-- Combo points for druids and rogues only
	if player_class == "DRUID" or player_class=="ROGUE" then
		self.CPoints = {}
		local x,y = -28, 0
		for i =1,5 do
			local bullet = self.Power:CreateTexture(nil, "OVERLAY")
			bullet:SetTexture("Interface\\Addons\\oUF_Quaiche\\ComboPoint")
			bullet:SetWidth(8)
			bullet:SetHeight(8)
			bullet:SetPoint("CENTER", self.Power, "CENTER", x, y)
			x = x + 9
			self.CPoints[i] = bullet
		end
	end

	-- Global Cooldown Display
	if IsAddOnLoaded('oUF_GCD') then
		self.GCD = CreateFrame("StatusBar", nil, self)
		self.GCD:SetHeight(3)
		self.GCD:SetPoint('LEFT', self.Health, 'BOTTOMLEFT')
		self.GCD:SetPoint('RIGHT', self.Health, 'BOTTOMRIGHT')
		self.GCD:SetStatusBarTexture(liboufq.statusbartexture)
		self.GCD:SetStatusBarColor(0.55, 0.57, 0.61)
	end

	-- Support for oUF_RuneBar for DKs
	if player_class=='DEATHKNIGHT' and IsAddOnLoaded('oUF_RuneBar') then
		local width = settings["initial-width"]
		local pp_height = settings["powerbar-height"] or 6
		local half_height = pp_height/2
		local rb_width = (width-7*border_size)/6
		self.Power:SetHeight(half_height)
		self.RuneBar = {}
		for i = 1, 6 do
			self.RuneBar[i] = CreateFrame('StatusBar', nil, self)
			if(i == 1) then
				self.RuneBar[i]:SetPoint('TOPLEFT', self.Power, 'BOTTOMLEFT', 0, 0)
			else
				self.RuneBar[i]:SetPoint('LEFT', self.RuneBar[i-1], 'RIGHT', border_size, 0)
			end
			self.RuneBar[i]:SetStatusBarTexture(liboufq.statusbartexture)
			self.RuneBar[i]:SetStatusBarColor(unpack(runeColors[i]))
			self.RuneBar[i]:SetHeight(half_height)
			self.RuneBar[i]:SetParent(self.Power)
			self.RuneBar[i]:SetWidth(rb_width)
			self.RuneBar[i]:SetMinMaxValues(0, 1)
		end
	end

	-- LFD Role Icon
	local lfdRole  = self.Health:CreateTexture(nil, "OVERLAY")
	lfdRole:SetHeight(16); lfdRole:SetWidth(16)
	lfdRole:SetPoint("CENTER", self, "TOP")
	self.LFDRole = lfdRole

	-- Raid Icon Position
	self.RaidIcon:SetPoint("CENTER", self.Health, "TOP")

	-- Resting icon
	local resting = self.Power:CreateTexture(nil, "OVERLAY")
	resting:SetHeight(16)
	resting:SetWidth(16)
	resting:SetPoint("CENTER", self, "BOTTOMRIGHT")
	self.Resting = resting

	-- Combat icon
	local combat = self.Power:CreateTexture(nil, "OVERLAY")
	combat:SetHeight(16)
	combat:SetWidth(16)
	combat:SetPoint("CENTER", self, "TOPRIGHT")
	self.Combat = combat

end

liboufq.UnitSpecific["target"] = function(settings, self)
	-- Bigger font and custom tag for NameString
	self.NameString:SetFontObject(GameFontNormal)
	self:Tag(self.NameString, "[difficulty][smartlevel]|r [afk][name]|r")

	-- Auto-coloring of health bar
	self.Health.colorTapping = true
	self.Health.colorReaction = true

	-- Castbar
	CreateCastbarOverlay(self)

	-- Raid Icon Position
	self.RaidIcon:SetPoint("CENTER", self.Health, "TOP")
end

liboufq.UnitSpecific["party"] = function(settings, self)
	-- LFD Role Icon
	local lfdRole  = hp:CreateTexture(nil, "OVERLAY")
	lfdRole:SetHeight(16); lfdRole:SetWidth(16)
	lfdRole:SetPoint("CENTER", self, "RIGHT", 3)
	self.LFDRole = lfdRole

	-- Support for oUF_ReadyCheck
	local readycheck = hp:CreateTexture(nil, "OVERLAY")
	readycheck:SetHeight(12)
	readycheck:SetWidth(12)
	readycheck:SetPoint("CENTER", self, "TOPRIGHT", 0, 0)
	readycheck:Hide()
	self.ReadyCheck = readycheck

	-- Range fading on party and partypets
	if  not hide_decorations then
		self.Range = true
		self.inRangeAlpha = 1
		self.outsideRangeAlpha = .5
	end

end

local setmetatable = _G.setmetatable
oUF:RegisterStyle("Quaiche_Full", setmetatable({
	["initial-width"] = 240,
	["initial-height"] = 36,
	["powerbar-height"] = 10,
}, {__call = liboufq.CommonUnitSetup}))

oUF:RegisterStyle("Quaiche_Small", setmetatable({
	["initial-width"] = 118,
	["initial-height"] = 18,
	["powerbar-height"] = 2,
}, {__call = liboufq.CommonUnitSetup}))

--[[ STANDARD FRAMES ]]--
oUF:SetActiveStyle("Quaiche_Full") 
oUF:Spawn("player"):SetPoint("BOTTOMRIGHT", UIParent, "BOTTOM", -78.5, 177)
oUF:Spawn("target"):SetPoint("BOTTOMLEFT", UIParent, "BOTTOM", 78.5, 177)

oUF:SetActiveStyle("Quaiche_Small")
oUF:Spawn("pet"):SetPoint("TOPRIGHT", oUF.units.player, "BOTTOMRIGHT", 0, -2)
oUF:Spawn("focus"):SetPoint("TOPLEFT", oUF.units.player, "BOTTOMLEFT", 0, -2)
oUF:Spawn("focustarget"):SetPoint("TOPRIGHT", oUF.units.target, "BOTTOMRIGHT", 0, -2)
oUF:Spawn("targettarget"):SetPoint("TOPLEFT", oUF.units.target, "BOTTOMLEFT", 0, -2)

