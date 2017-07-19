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
	pricer.EntPrices = net.ReadPriceTable()
	--pricer.VehiclePrices = net.ReadPriceTable()
	pricer.AmmoPrices = net.ReadPriceTable()
	
	if !GetConVar("sbuy_debug"):GetBool() then
		local itemlist = list.GetForEdit("Weapon")
		for k,v in pairs(itemlist) do
			v.Spawnable = pricer.GetPrice(k, pricer.WepPrices) > -2
		end
		
		itemlist = list.GetForEdit("SpawnableEntities")
		for k,v in pairs(itemlist) do
			if pricer.GetPrice(k, pricer.EntPrices) <= -2 then
				itemlist[k] = nil
			end
		end
	end
	
	if reload then
		RunConsoleCommand("spawnmenu_reload")
	end
end)