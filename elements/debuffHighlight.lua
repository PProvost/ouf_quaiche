--[[ 
-- Modified from oUF_DebuffHighlight by Ammo
-- http://www.wowinterface.com/downloads/info8812-oUFDebuffHighlight.html
--]]

local _, ns = ...
local oUF = ns.oUF

local playerClass = select(2,UnitClass("player"))
local CanDispel = {
	PRIEST = { Magic = true, Disease = true, },
	SHAMAN = { Magic = true, Curse = true, },
	PALADIN = { Magic = true, Poison = true, Disease = true, },
	MAGE = { Curse = true, },
	DRUID = { Magic = true, Curse = true, Poison = true, }
}
local dispellist = CanDispel[playerClass] or {}
local origColors = {}
local origBorderColors = {}
local origPostUpdateAura = {}

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

local function Update(object, event, unit)
	if object.unit ~= unit  then return end
	local debuffType, texture  = GetDebuffType(unit, object.DebuffHighlightFilter)
	if debuffType then
		local color = DebuffTypeColor[debuffType] 
		if object.DebuffHighlightBackdrop or object.DebuffHighlightBackdropBorder then
			if object.DebuffHighlightBackdrop then
				object:SetBackdropColor(color.r, color.g, color.b, object.DebuffHighlightAlpha or 1)
			end
			if object.DebuffHighlightBackdropBorder then
				object:SetBackdropBorderColor(color.r, color.g, color.b, object.DebuffHighlightAlpha or 1)
			end
		elseif object.DebuffHighlightUseTexture then
			object.DebuffHighlight:SetTexture(texture)
		elseif object.DebuffHighlight.SetVertexColor then
			object.DebuffHighlight:SetVertexColor(color.r, color.g, color.b, object.DebuffHighlightAlpha or .5)
		elseif object.DebuffHighlight.SetStatusBarColor then
			object.DebuffHighlight:SetStatusBarColor(color.r, color.g, color.b, object.DebuffHighlightAlpha or .5)
		end
	else
		if object.DebuffHighlightBackdrop or object.DebuffHighlightBackdropBorder then
			local color
			if object.DebuffHighlightBackdrop then
				color = origColors[object]
				object:SetBackdropColor(color.r, color.g, color.b, color.a)
			end
			if object.DebuffHighlightBackdropBorder then
				color = origBorderColors[object]
				object:SetBackdropBorderColor(color.r, color.g, color.b, color.a)
			end
		elseif object.DebuffHighlightUseTexture then
			object.DebuffHighlight:SetTexture(nil)
		elseif object.DebuffHighlight.SetVertexColor then
			local color = origColors[object]
			object.DebuffHighlight:SetVertexColor(color.r, color.g, color.b, color.a)
		elseif object.DebuffHighlight.SetStatusBarColor then
			local color = origColors[object]
			object.DebuffHighlight:SetStatusBarColor(color.r, color.g, color.b, color.a)
		end
	end
end

local function Enable(object)
	-- if we're not highlighting this unit return
	if not object.DebuffHighlightBackdrop and not object.DebuffHighlightBackdropBorder and not object.DebuffHighlight then
		return
	end
	-- if we're filtering highlights and we're not of the dispelling type, return
	if object.DebuffHighlightFilter and not CanDispel[playerClass] then
		return
	end
	
	-- make sure aura scanning is active for this object
	object:RegisterEvent("UNIT_AURA", Update)
	
	if object.DebuffHighlightBackdrop or object.DebuffHighlightBackdropBorder then
		local r, g, b, a = object:GetBackdropColor()
		origColors[object] = { r = r, g = g, b = b, a = a}
		r, g, b, a = object:GetBackdropBorderColor()
		origBorderColors[object] = { r = r, g = g, b = b, a = a}
	elseif not object.DebuffHighlightUseTexture then -- color debuffs
		-- object.DebuffHighlight
		if object.DebuffHighlight.GetVertexColor then
			local r, g, b, a = object.DebuffHighlight:GetVertexColor()
			origColors[object] = { r = r, g = g, b = b, a = a}
		elseif object.DebuffHighlight.GetStatusBarColor then
			local r, g, b, a = object.DebuffHighlight:GetStatusBarColor()
			origColors[object] = { r = r, g = g, b = b, a = a}
		end
	end

	return true
end

local function Disable(object)
	if object.DebuffHighlightBackdrop or object.DebuffHighlightBackdropBorder or object.DebuffHighlight then
		object:UnregisterEvent("UNIT_AURA", Update)
	end
end

oUF:AddElement('DebuffHighlight', Update, Enable, Disable)

-- for i, frame in ipairs(oUF.objects) do Enable(frame) end
