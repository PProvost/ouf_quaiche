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

local function Hex(r, g, b)
	if type(r) == "table" then
		if r.r then r, g, b = r.r, r.g, r.b else r, g, b = unpack(r) end
	end
	return string.format("|cff%02x%02x%02x", r*255, g*255, b*255)
end

oUF.Tags["[afk]"] = function(u) return UnitIsAFK(u) and "|cFF990000" or nil end
oUF.TagEvents["[afk]"] = "UNIT_NAME_UPDATE UNIT_LEVEL PLAYER_FLAGS_CHANGED"

oUF.Tags["[shorthealth]"] = function(u) 
	local value = UnitHealth(u)
	if(value >= 1e6) then
		return ('%.1fm'):format(value / 1e6):gsub('%.?0+([km])$', '%1')
	elseif(value >= 1e4) then
		return ('%.1fk'):format(value / 1e3):gsub('%.?0+([km])$', '%1')
	else
		return value
	end
end
oUF.TagEvents["[shorthealth]"] = "UNIT_HEALTH UNIT_MAXHEALTH"

oUF.Tags["[smarthealth]"] = function(u) return (UnitHealthMax(u) > UnitHealth(u)) and "-"..oUF.Tags["[missinghp]"](u) or oUF.Tags["[shorthealth]"](u) end
oUF.TagEvents["[smarthealth]"] = "UNIT_HEALTH UNIT_MAXHEALTH"

oUF.Tags["[qhealth]"] = function(unit)
	local dead, offline = oUF.Tags["[dead]"](unit), oUF.Tags["[offline]"](unit)
	if dead then return dead end
	if offline then return offline end
	if unit=="pet" or unit=="focus" or unit=="targettarget" or unit=="focustarget" then return oUF.Tags["[perhp]"](unit).."%" end
	if unit=="target" then return oUF.Tags["[shorthealth]"](unit) .. " (" .. oUF.Tags["[perhp]"](unit) .. "%)" end
	return oUF.Tags["[smarthealth]"](unit)
end
oUF.TagEvents["[qhealth]"] = "UNIT_HEALTH UNIT_MAXHEALTH"

oUF.Tags["[qpower]"] = function(unit)
	local curpp, maxpp = oUF.Tags["[curpp]"](unit), oUF.Tags["[maxpp]"](unit)
	if (not UnitIsDead(unit)) and UnitIsConnected(unit) and (UnitPower(unit) < UnitPowerMax(unit)) then
		return curpp.."/"..maxpp
	end
end
oUF.TagEvents["[qpower]"] = "UNIT_ENERGY UNIT_FOCUS UNIT_MANA UNIT_RAGE UNIT_RUNIC_POWER UNIT_MAXENERGY UNIT_MAXFOCUS UNIT_MAXMANA UNIT_MAXRAGE UNIT_MAXRUNIC_POWER"

-- converted haste's happiness stuff into text coloring
oUF.Tags["[pethappinesscolor]"] = function(u)
	local happiness = GetPetHappiness()
	if(happiness == 1) then
		return Hex(0.375, 0.5625, 05)
	elseif(happiness == 2) then
		return Hex(0.1875, 0.375, 0)
	elseif(happiness == 3) then
		return Hex(0, 0.1875, 0)
	end
end
oUF.TagEvents["[pethappinesscolor]"] = "UNIT_HAPPINESS"

