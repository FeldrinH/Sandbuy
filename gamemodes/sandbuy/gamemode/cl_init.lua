include("shared.lua")
include("cl_scoreboard.lua")
include("spawnmenu_content.lua")

DEFINE_BASECLASS("gamemode_sandbox")

surface.CreateFont("DollarSignFont", {
	font = "Roboto Light",
	size = 32,
	weight = 1000,
	antialias = true,
	additive = true
})

surface.CreateFont("DeathMessageFont", {
	font = "Roboto",
	size = 64
})

surface.CreateFont("DeathMessageFontSmall", {
	font = "Roboto",
	size = 48
})

local bg_color = Color(0, 0, 0, 76)
local text_color = Color(255, 235, 20)

local lastmoney = -1
local lastwidth = 0

local hoffset = math.floor(ScrH() * 696 / 768) - 56
local voffset = math.ceil(ScrW() * 25 / 1366)

local deathmessage_killer = nil
local deathmessage_health = 0
local deathmessage_armor = 0
local deathmessage_text = ""

local deathmessage_overrides = {
	["76561198076382343"] = "You were claimed by ",
	["76561198315916037"] = "You and your family were killed by "
}

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
		
		draw.RoundedBox(5, voffset, hoffset - 5, lastwidth, 44, bg_color)
		draw.SimpleText(curmoney, "HudNumbers", voffset + 23, hoffset, text_color)
		draw.SimpleText("$", "DollarSignFont", voffset + 7, hoffset, text_color)
	end
	
	if !LocalPlayer():Alive() then
		if IsValid(deathmessage_killer) then
			if deathmessage_health > 0 then
				if deathmessage_health != deathmessage_killer:Health() then
					deathmessage_health = deathmessage_killer:Health()
				end
				if deathmessage_armor != deathmessage_killer:Armor() then
					deathmessage_armor = deathmessage_killer:Armor()
				end
			end
			
			draw.SimpleTextOutlined(deathmessage_text, "DeathMessageFont", ScrW()/2, ScrH()/2 - 140, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 2, Color(0,0,0))
			if deathmessage_health <= 0 then
				draw.SimpleTextOutlined("who did not survive", "DeathMessageFontSmall", ScrW()/2, ScrH()/2 - 80, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 2, Color(0,0,0))
			else
				draw.SimpleTextOutlined("who survived with " .. deathmessage_health .. " health" .. (deathmessage_armor > 0 and (" and " .. deathmessage_armor .. " armor") or ""), "DeathMessageFontSmall", ScrW()/2, ScrH()/2 - 80, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 2, Color(0,0,0))
			end
		else
			draw.SimpleTextOutlined(deathmessage_text, "DeathMessageFont", ScrW()/2, ScrH()/2 - 140, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 2, Color(0,0,0))
		end
	end
end

function GM:SetDeathMessage(killer)
	if IsValid(killer) and killer:IsPlayer() then
		if killer == LocalPlayer() then
			deathmessage_killer = nil
			deathmessage_text = "You killed yourself"
		else
			deathmessage_killer = killer
			deathmessage_health = killer:Health()
			deathmessage_armor = killer:Armor()
			deathmessage_text = (deathmessage_overrides[killer:SteamID64()] or  "You were killed by ") .. killer:Nick()
		end
	else
		deathmessage_killer = nil
		deathmessage_text = "You died"
	end
end

function GM:OnSpawnMenuOpen()
	if IsValid(g_SpawnMenu) then
		spawnmenu.UpdateSpawnlistMoney(LocalPlayer():GetMoney())
	end

	return BaseClass.OnSpawnMenuOpen(self)
end

net.Receive("newprices", function(len)
	print("Prices received " .. len .. "/524264 " .. math.Round(len / 524264 * 100) .. "%")
	
	local reload = net.ReadBool()
	
	pricer.WepPrices = net.ReadPriceTable()
	pricer.EntPrices = net.ReadPriceTable()
	pricer.VehiclePrices = net.ReadPriceTable()
	pricer.AmmoPrices = net.ReadPriceTable()
	
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