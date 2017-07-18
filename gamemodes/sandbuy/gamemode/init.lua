AddCSLuaFile('shared.lua')
AddCSLuaFile('playermoney.lua')
AddCSLuaFile('pricer.lua')
AddCSLuaFile('player_class/player_sandbuy.lua')
AddCSLuaFile('cl_init.lua')
AddCSLuaFile('cl_scoreboard.lua')
AddCSLuaFile('spawnmenu_prices.lua')
AddCSLuaFile('spawnmenu_content.lua')

include('buylogger.lua')
include('shared.lua')
include('patches.lua')

DEFINE_BASECLASS("gamemode_sandbox")
local BaseBaseClass = baseclass.Get( "gamemode_base" )

--resource.AddSingleFile("data/weaponprices.txt")
--resource.AddSingleFile("data/vehicleprices.txt")
--resource.AddSingleFile("data/entityprices.txt")

util.AddNetworkString("moneychanged")
util.AddNetworkString("weaponbought")
util.AddNetworkString("newprices")

concommand.Add("reloadprices", function(ply)
	if !ply:IsAdmin() then return end

	pricer.LoadPrices()

	pricer.SendPrices(nil, true)

	print("Reloaded prices")
end)

concommand.Add("cleanprices", function(ply)
	local count = 0

	local items = list.GetForEdit("Weapon")
	for k,v in pairs(pricer.WepPrices.individual) do
		if !items[k] or !items[k].Spawnable then
			print("Weapon not spawnable: " .. k)
			count = count + 1
		end
	end
	
	if count == 0 then
		print("Prices clean")	
	else
		print(count .. " items not spawnable")
	end
end)

function GM:Initialize()
	pricer.LoadPrices()
	
	if GetConVar("sbuy_log"):GetBool() then
		buylogger.Init()
	end
	
	return BaseClass.Initialize(self)
end

function GM:ShutDown()
	buylogger.Close()
	
	return BaseClass.ShutDown(self)
end

function GM:PlayerAuthed(ply, steamid, uniqueid)
	pricer.SendPrices(ply, false)
	
	return BaseClass.PlayerAuthed(self, ply, steamid, uniqueid)
end

function GM:PlayerSpawn(ply)
	player_manager.SetPlayerClass(ply, "player_sandbuy")
	
	if ply.GetMoney and ply.HasDied and ply:GetMoney() < pricer.DefaultMoney then
		ply:SetMoney(pricer.DefaultMoney)
		ply:PrintMessage(HUD_PRINTCENTER, "You were given a bailout\n    You now have $" .. pricer.DefaultMoney)
		buylogger.LogBailout(ply, pricer.DefaultMoney)
	end
	
	return BaseBaseClass.PlayerSpawn(self, ply)
end

function GM:DoPlayerDeath(ply, attacker, dmginfo)
	ply:AddMoney(-pricer.DeathMoney)
	
	if attacker:IsValid() && attacker:IsPlayer() &&  attacker != ply then
		attacker:AddMoney(pricer.KillMoney)
		buylogger.LogKill(attacker, ply, attacker:GetMoney())
	else
		buylogger.LogDeath(ply, ply:GetMoney())
	end
	
	ply.HasDied = true
	
	return BaseClass.DoPlayerDeath(self, ply, attacker, dmginfo)
end

function GM:PlayerGiveSWEP(ply, class, swep)
	if ply:HasWeapon(class) then
		return true
	end
	
	local price = pricer.GetPrice(class, pricer.WepPrices)
	if pricer.CanBuy(ply:GetMoney(), price) then
		ply:AddMoney(-price)
		ply:PrintMessage(HUD_PRINTCENTER, "Weapon bought for $" .. price)
		ply:SendLua("surface.PlaySound('sandbuy/kaching.wav')")
		
		net.Start("weaponbought")
		net.WriteString(class)
		net.Send(ply)
		
		buylogger.LogBuy(ply, class, ply:GetMoney())
		
		return true
	elseif price >= 0 then
		ply:PrintMessage(HUD_PRINTCENTER, "Need $" .. price .. " to buy weapon")
		ply:SendLua("surface.PlaySound('sandbuy/denied.wav')")
		return false
	else
		ply:PrintMessage(HUD_PRINTCENTER, "Weapon not for sale")
		ply:SendLua("surface.PlaySound('sandbuy/denied.wav')")
		return false
	end
end

function GM:PlayerSpawnSWEP(ply, class, swep)
	local price = pricer.GetPrice(class, pricer.WepPrices)
	if pricer.CanBuy(ply:GetMoney(), price) then
		ply:AddMoney(-price)
		ply:PrintMessage(HUD_PRINTCENTER, "Weapon bought for $" .. price)
		ply:SendLua("surface.PlaySound('sandbuy/kaching.wav')")
		
		buylogger.LogBuy(ply, class, ply:GetMoney())
		
		return true
	elseif price >= 0 then
		ply:PrintMessage(HUD_PRINTCENTER, "Need $" .. price .. " to buy weapon")
		ply:SendLua("surface.PlaySound('sandbuy/denied.wav')")
		return false
	else
		ply:PrintMessage(HUD_PRINTCENTER, "Weapon not for sale")
		ply:SendLua("surface.PlaySound('sandbuy/denied.wav')")
		return false
	end
end

function GM:PlayerSpawnSENT(ply, class)
	local price = pricer.GetPrice(class, pricer.EntPrices)
	if pricer.CanBuy(ply:GetMoney(), price) then
		ply:AddMoney(-price)
		ply:PrintMessage(HUD_PRINTCENTER, "Entity bought for $" .. price)
		ply:SendLua("surface.PlaySound('sandbuy/kaching.wav')")
		
		buylogger.LogBuy(ply, class, ply:GetMoney())
		
		return true
	elseif price >= 0 then
		ply:PrintMessage(HUD_PRINTCENTER, "Need $" .. price .. " to buy entity")
		ply:SendLua("surface.PlaySound('sandbuy/denied.wav')")
		return false
	else
		ply:PrintMessage(HUD_PRINTCENTER, "Entity not for sale")
		ply:SendLua("surface.PlaySound('sandbuy/denied.wav')")
		return false
	end
end

function GM:PlayerSpawnVehicle(ply, model, class, vtable)
	return GetConVar("sbuy_debug"):GetBool() and BaseClass.PlayerSpawnVehicle(self, ply, model, class, vtable)
end

function GM:PlayerSpawnNPC(ply, class, weapon)
	return GetConVar("sbuy_debug"):GetBool() and BaseClass.PlayerSpawnNPC(self, ply, class, weapon)
end