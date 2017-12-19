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
include('statsaver.lua')

DEFINE_BASECLASS("gamemode_sandbox")
local BaseBaseClass = baseclass.Get( "gamemode_base" )

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

concommand.Add("setcategoryprice", function(ply, cmd, args)
	if !ply:IsAdmin() then return end
	
	local category = args[1]
	if !pricer.Categories[category] then
		ply:PrintMessage(HUD_PRINTCONSOLE, "Invalid category: " .. category)
		return
	end
	
	local price = tonumber(args[2])
	if !price then
		hook.Remove("ApplyPriceModifiers", "CategoryOverride_" .. category)

		print("Removed category price:", category)
	else
		local function ReturnPrice() 
			return price
		end
	
		hook.Add("ApplyPriceModifiers", "CategoryOverride_" .. category, function()
			pricer.ApplyModifier(category, pricer.WepPrices, ReturnPrice)
			pricer.ApplyModifier(category, pricer.EntPrices, ReturnPrice)
			pricer.ApplyModifier(category, pricer.VehiclePrices, ReturnPrice)
			pricer.ApplyModifier(category, pricer.AmmoPrices, ReturnPrice)
		end)
		
		print("New category price:", category, "$" .. price)
	end
end)

concommand.Add("sbuy_setoverrideprice", function(ply, cmd, args)
	if !ply:IsAdmin() then return end

	local wep = args[1]
	local price = tonumber(args[2])
	local filename = args[3] .. "prices.txt"
	
	if !wep or !price or !args[3] then return end
	
	local localfile = file.Read(filename)
	local pricetable = localfile and util.JSONToTable(localfile) or {individual={}}
	
	pricetable.individual[wep] = price

	file.Write(filename, util.TableToJSON(pricetable, true))
	
	print("New override price:", wep, "$" .. price)
end)

concommand.Add("sbuy_giveammo", function(ply, cmd, args)
	local ammo = args[1]
	local amount = tonumber(args[2])
	
	if !gamemode.Call("PlayerGiveAmmo", ply, ammo, amount) then return end
	
	ply:GiveAmmo(amount, ammo, false)
end)

--[[concommand.Add("sbuy_givearmor", function(ply, cmd, args)
	local amount = tonumber(args[1])
	if !amount then return end
	local amount = math.min(amount, 100 - ply:Armor())
	if amount <= 0 then return end
	
	if pricer.ArmorPrice * amount > ply:GetMoney() then
		amount = math.floor(ply:GetMoney() / pricer.ArmorPrice)
		if amount < 1 then
			amount = 1
		end
	end
	
	local price = pricer.ArmorPrice * amount
	
	if price <= ply:GetMoney() then
		ply:AddMoney(-price)
		ply:SetArmor(ply:Armor() + amount)
		
		ply:PrintMessage(HUD_PRINTCENTER, "Armor bought for $" .. price)
		ply:SendLua("surface.PlaySound('sandbuy/kaching.wav')")
	else
		ply:PrintMessage(HUD_PRINTCENTER, "Need $" .. price .. " to buy armor")
		ply:SendLua("surface.PlaySound('sandbuy/denied.wav')")
	end
end)]]--

local function GiveHeldAmmo(ply, cmd, args)
	local wep = ply:GetActiveWeapon()
	if !IsValid(wep) then return end
	
	local isprimary = true
	local ammo = wep:GetPrimaryAmmoType()
	if ammo == -1 or args[2] == "secondary" then
		ammo = wep:GetSecondaryAmmoType()
		isprimary = false
		if ammo == -1 then return end
	end
	ammo = game.GetAmmoName(ammo)
	
	local amount = 1
	if pricer.GetPrice(ammo, pricer.AmmoPrices) < 0 then
		--Ammo not for sale
	elseif args[1] == nil or args[1] == "smart" then
		amount = pricer.ClipSize[wep:GetClass()] or (isprimary and wep:GetMaxClip1()) or wep:GetMaxClip2()
		if (amount > 0) and (pricer.GetPrice(ammo, pricer.AmmoPrices) * amount > ply:GetMoney()) then
			amount = math.floor(ply:GetMoney() / pricer.GetPrice(ammo, pricer.AmmoPrices))
		end
		if amount < 1 then
			amount = 1
		end
	elseif args[1] == "clip" then
		amount = pricer.ClipSize[wep:GetClass()] or (isprimary and wep:GetMaxClip1()) or wep:GetMaxClip2()
	elseif args[1] == "max" then
		amount = math.floor(ply:GetMoney() / pricer.GetPrice(ammo, pricer.AmmoPrices))
		if amount < 1 then
			amount = 1
		end
	elseif tonumber(args[1]) != nil then
		amount = tonumber(args[1])
	end
	
	if !gamemode.Call("PlayerGiveAmmo", ply, ammo, amount) then return end
	
	ply:GiveAmmo(amount, ammo, false)
end

concommand.Add("sbuy_giveheldammo", GiveHeldAmmo)
concommand.Add("sbuy_giveprimaryammo", GiveHeldAmmo) --Deprecate later

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
	buylogger.LogJoin(ply)
	
	ply.TotalKillMoney = ply.TotalKillMoney or 0
	
	BaseClass.PlayerInitialSpawn(self, ply)
end

function GM:PlayerDisconnected(ply)
	buylogger.LogLeave(ply)
	
	BaseClass.PlayerDisconnected(self, ply)
end

function GM:PlayerSpawn(ply)
	player_manager.SetPlayerClass(ply, "player_sandbuy")
	
	local bailoutamount = ply:GetBailout()
	
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
		if ply:Team() != TEAM_UNASSIGNED and ply:Team() == killer:Team() then
			killer:AddMoney(-pricer.TeamKillPenalty)
			buylogger.LogKill(killer, ply, weapon, killer:GetMoney(), -pricer.TeamKillPenalty)
			ply:AddMoney(deltamoney)
			deltamoney = 0
		else
			local killmoney = GetConVar("sbuy_killmoney"):GetInt() + deltamoney
			killer:AddMoney(killmoney)
			buylogger.LogKill(killer, ply, weapon, killer:GetMoney(), killmoney)
			killer.TotalKillMoney = killer.TotalKillMoney + killmoney
		end
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
	if amount <= 0 then return false end
	
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
	return false--BaseClass.PlayerSpawnProp(self, ply, model)
end

function GM:PlayerSpawnNPC(ply, class, weapon)
	return GetConVar("sbuy_debug"):GetBool() and BaseClass.PlayerSpawnNPC(self, ply, class, weapon)
end

function GM:PlayerSpawnedSENT(ply, ent)
	local price = pricer.GetPrice(ent:GetClass(), pricer.EntPrices)
	if price > 0 and pricer.InCategory(ent:GetClass(), "machines") then
		ent.DestroyReward = math.floor(price * 0.5)
	end
	
	return BaseClass.PlayerSpawnedSENT(self, ply, ent)
end

function GM:PlayerSpawnedVehicle(ply, ent)
	local price = pricer.GetPrice(ent.VehicleName, pricer.VehiclePrices)
	if price > 0 then
		ent.DestroyReward = math.floor(price * 0.5)
	end
	
	return BaseClass.PlayerSpawnedVehicle(self, ply, ent)
end

function GM:EntityTakeDamage(target, dmg)
	if target.DestroyReward then
		local atk = dmg:GetAttacker()
		if IsValid(atk) and atk:IsPlayer() then
			target.DestroyRewardPlayer = atk
			target.DestroyRewardTime = CurTime()
		end
	end
	
	return BaseClass.EntityTakeDamage(self, target, dmg)
end

function GM:EntityRemoved(ent)
	if ent.DestroyReward and IsValid(ent.DestroyRewardPlayer) and CurTime() - ent.DestroyRewardTime <= 0.5 then
		ent.DestroyRewardPlayer:AddMoney(ent.DestroyReward)
		buylogger.LogDestroy(ent.DestroyRewardPlayer, ent, ent.DestroyRewardPlayer:GetMoney(), ent.DestroyReward)
	end
	
	return BaseClass.EntityRemoved(self, ent)
end