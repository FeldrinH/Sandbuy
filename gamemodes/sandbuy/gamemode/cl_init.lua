include("shared.lua")
include("cl_scoreboard.lua")
include("spawnmenu_prices.lua")
include("spawnmenu_content.lua")

DEFINE_BASECLASS("gamemode_sandbox")

surface.CreateFont("DollarSignFont", {
	font = "Roboto Light",
	size = 32,
	weight = 1000,
	antialias = true,
	additive = true
})

local bg_color = Color(0, 0, 0, 76)
local text_color = Color(255, 235, 20)

local lastmoney = -1
local lastwidth = 0

local hoffset = math.floor(ScrH() * 696 / 768) - 56
local voffset = math.ceil(ScrW() * 25 / 1366)

function GM:HUDPaint()
	BaseClass.HUDPaint(self)
	
	if GetConVarNumber("cl_drawhud") == 0 then return end
	
	if gamemode.Call("HUDShouldDraw", "CHudHealth") and LocalPlayer():Alive() and LocalPlayer():GetObserverMode() == OBS_MODE_NONE then
		local curmoney = LocalPlayer():GetMoney()
		
		if curmoney != lastmoney then
			surface.SetFont("HudNumbers")
			lastwidth = surface.GetTextSize(curmoney) + 32
			lastmoney = curmoney
		end
		--
		draw.RoundedBox(5, voffset, hoffset - 5, lastwidth, 44, bg_color)
		draw.SimpleText(curmoney, "HudNumbers", voffset + 23, hoffset, text_color)
		draw.SimpleText("$", "DollarSignFont", voffset + 7, hoffset, text_color)
	end
end

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
	print("Prices received " .. len .. "/524264 " .. math.Round(len / 524264 * 100) .. "%")
	
	local reload = net.ReadBool()
	
	pricer.WepPrices = net.ReadPriceTable()
	pricer.EntPrices = net.ReadPriceTable()
	pricer.VehiclePrices = net.ReadPriceTable()
	pricer.AmmoPrices = net.ReadPriceTable()
	--pricer.AmmoData = net.ReadTable()
	
	if !GetConVar("sbuy_debug") or !GetConVar("sbuy_debug"):GetBool() then
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
		
		itemlist = list.GetForEdit("Vehicles")
		for k,v in pairs(itemlist) do
			if pricer.GetPrice(k, pricer.VehiclePrices) <= -2 then
				itemlist[k] = nil
			end
		end
		
		itemlist = list.GetForEdit("simfphys_vehicles")
		for k,v in pairs(itemlist) do
			if pricer.GetPrice(k, pricer.VehiclePrices) <= -2 then
				itemlist[k] = nil
			end
		end
	end
	
	if reload then
		RunConsoleCommand("spawnmenu_reload")
	end
end)