AddCSLuaFile('shared.lua')
AddCSLuaFile('playermeta.lua')
AddCSLuaFile('pricer.lua')
AddCSLuaFile('player_class/player_sandbuy.lua')
AddCSLuaFile('cl_init.lua')
AddCSLuaFile('cl_scoreboard.lua')
AddCSLuaFile('spawnmenu_prices.lua')
AddCSLuaFile('spawnmenu_content.lua')
AddCSLuaFile('patches_shared.lua')

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

concommand.Add("sbuy_giveammo", function(ply, cmd, args)
	local ammo = args[1]
	local amount = args[2]
	
	if !gamemode.Call("PlayerGiveAmmo", ply, ammo, amount) then return end
	
	ply:GiveAmmo(amount, ammo, false)
end)

concommand.Add("sbuy_giveprimaryammo", function(ply, cmd, args)
	local wep = ply:GetActiveWeapon()
	if !IsValid(wep) then return end
	
	local ammo = wep:GetPrimaryAmmoType()
	local amount = args[1] or pricer.ClipSize[wep:GetClass()] or wep:GetMaxClip1()
	if ammo == -1 then
		ammo = wep:GetSecondaryAmmoType()
		amount = args[1] or pricer.ClipSize[wep:GetClass()] or wep:GetMaxClip2()
		if ammo == -1 then return end
	end
	
	if args[1] == "max" then
		amount = math.floor(ply:GetMoney() / pricer.GetPrice(game.GetAmmoName(ammo), pricer.AmmoPrices))
	end
	
	if amount <= 0 then return end
	
	if !gamemode.Call("PlayerGiveAmmo", ply, game.GetAmmoName(ammo), amount) then return end
	
	ply:GiveAmmo(amount, ammo, false)
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

function GM:PlayerInitialSpawn(ply)
	ply.TotalKillMoney = ply.TotalKillMoney or 0
	
	BaseClass.PlayerInitialSpawn(self, ply)
end

function GM:PlayerSpawn(ply)
	player_manager.SetPlayerClass(ply, "player_sandbuy")
	
	local bailoutamount = pricer.DefaultMoney
	if !ply.LastDeathSuicide then
		bailoutamount = pricer.DefaultMoney + ply:GetBailoutBonus()
	end
	
	if ply.GetMoney and ply.HasDied and ply:GetMoney() < bailoutamount then
		buylogger.LogBailout(ply, bailoutamount, bailoutamount - ply:GetMoney())
		ply:SetMoney(bailoutamount)
		ply:PrintMessage(HUD_PRINTCENTER, "You were given a bailout\n    You now have $" .. bailoutamount)
	end
	
	BaseBaseClass.PlayerSpawn(self, ply)
	
	ply.HasDied = false
end

function GM:PlayerDeath(ply, inflictor, attacker)
	local deltamoney = math.ceil(ply:GetMoney() * 0.2)
	ply:AddMoney(-deltamoney)
	
	local weapon = inflictor
	local killer = attacker
	
	if ( IsValid( killer ) && killer:IsVehicle() && IsValid( killer:GetDriver() ) ) then
		killer = killer:GetDriver()
	end
	
	if !IsValid(weapon) && IsValid(killer) then
		weapon = killer
	end

	if IsValid(weapon) && weapon == killer && (weapon:IsPlayer() || weapon:IsNPC()) then
		weapon = weapon:GetActiveWeapon()
		if !IsValid(weapon) then weapon = killer end
	end
	
	if killer:IsValid() && killer:IsPlayer() && killer != ply then
		killer:AddMoney(deltamoney + 1000)
		buylogger.LogKill(killer, ply, weapon, killer:GetMoney(), deltamoney + 1000)
		killer.TotalKillMoney = killer.TotalKillMoney + 1000 + deltamoney
		ply.LastDeathSuicide = false
	else
		ply.LastDeathSuicide = true
	end
	buylogger.LogDeath(ply, killer, weapon, ply:GetMoney(), -deltamoney)
	
	ply.HasDied = true
	
	return BaseClass.PlayerDeath(self, ply, inflictor, attacker)
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
		
		buylogger.LogBuy(ply, class, "weapon", ply:GetMoney(), -price)
		
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
		
		buylogger.LogBuy(ply, class, "weapon-drop", ply:GetMoney(), -price)
		
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

function GM:PlayerGiveAmmo(ply, ammo, amount)
	local price = pricer.GetPrice(ammo, pricer.AmmoPrices) * amount
	if pricer.CanBuy(ply:GetMoney(), price) then
		ply:AddMoney(-price)
		ply:PrintMessage(HUD_PRINTCENTER, "Ammo bought for $" .. price)
		ply:SendLua("surface.PlaySound('sandbuy/kaching.wav')")
		
		buylogger.LogBuy(ply, ammo, "ammo", ply:GetMoney(), -price)
		
		return true
	elseif price >= 0 then
		ply:PrintMessage(HUD_PRINTCENTER, "Need $" .. price .. " to buy ammo")
		ply:SendLua("surface.PlaySound('sandbuy/denied.wav')")
		return false
	else
		ply:PrintMessage(HUD_PRINTCENTER, "Ammo type not for sale")
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
		
		buylogger.LogBuy(ply, class, "entity", ply:GetMoney(), -price)
		
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
	local price = pricer.GetPrice(class, pricer.VehiclePrices)
	if pricer.CanBuy(ply:GetMoney(), price) then
		ply:AddMoney(-price)
		ply:PrintMessage(HUD_PRINTCENTER, "Vehicle bought for $" .. price)
		ply:SendLua("surface.PlaySound('sandbuy/kaching.wav')")
		
		buylogger.LogBuy(ply, class, "vehicle", ply:GetMoney(), -price)
		
		return true
	elseif price >= 0 then
		ply:PrintMessage(HUD_PRINTCENTER, "Need $" .. price .. " to buy vehicle")
		ply:SendLua("surface.PlaySound('sandbuy/denied.wav')")
		return false
	else
		ply:PrintMessage(HUD_PRINTCENTER, "Vehicle not for sale")
		ply:SendLua("surface.PlaySound('sandbuy/denied.wav')")
		return false
	end
end

function GM:PlayerSpawnProp(ply, model)
	return false
end

function GM:PlayerSpawnNPC(ply, class, weapon)
	return GetConVar("sbuy_debug"):GetBool() and BaseClass.PlayerSpawnNPC(self, ply, class, weapon)
end