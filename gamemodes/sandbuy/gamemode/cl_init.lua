include("shared.lua")
include("cl_scoreboard.lua")
include("spawnmenu_prices.lua")
include("spawnmenu_content.lua")

DEFINE_BASECLASS("gamemode_sandbox")

--[[local HiddenCategories = {["M9K"] = true}

function GM:PreGamemodeLoaded()	
	return BaseClass.PreGamemodeLoaded(self)
end]]--

function GM:OnSpawnMenuOpen()
	if IsValid(g_SpawnMenu) then
		spawnmenu.UpdateSpawnlistMoney(LocalPlayer():GetMoney())
	end

	return BaseClass.OnSpawnMenuOpen(self)
end

net.Receive("moneychanged", function(len)
	local money = net.ReadInt(32)
	if IsValid(g_SpawnMenu) and g_SpawnMenu:IsVisible() then
		spawnmenu.UpdateSpawnlistMoney(money)
	end
end)

net.Receive("weaponbought", function(len)
	local wep = net.ReadString()
	if IsValid(g_SpawnMenu) and g_SpawnMenu:IsVisible() then
		spawnmenu.UpdateSpawnlistHasWeapon(wep)
	end
end)

net.Receive("newprices", function(len)
	print("Prices received", len)
	
	local reload = net.ReadBool()
	
	pricer.WepPrices = net.ReadPriceTable()
	
	if !GetConVar("sbuy_debug"):GetBool() then
		for k,v in pairs(list.GetForEdit("Weapon")) do
			v.Spawnable = pricer.GetPrice(v.ClassName, pricer.WepPrices) > -2
		end
	end
	
	if reload then
		RunConsoleCommand("spawnmenu_reload")
	end
end)