AddCSLuaFile('shared.lua')
AddCSLuaFile('playermeta.lua')
AddCSLuaFile('pricer.lua')
AddCSLuaFile('player_class/player_sandbuy.lua')
AddCSLuaFile('cl_init.lua')
AddCSLuaFile('cl_scoreboard.lua')
AddCSLuaFile('spawnmenu_content.lua')
AddCSLuaFile('patches_shared.lua')
AddCSLuaFile('configmenu.lua')

include('buylogger.lua')
include('shared.lua')
include('patches.lua')
include('statsaver.lua')

DEFINE_BASECLASS("gamemode_sandbox")
local BaseBaseClass = baseclass.Get( "gamemode_base" )

util.AddNetworkString("moneychanged")
util.AddNetworkString("weaponbought")
util.AddNetworkString("newprices")
util.AddNetworkString("newseasonals")

CreateConVar("freebuy", 0, FCVAR_NOTIFY)
cvars.AddChangeCallback("freebuy", function(convar, old, new)
	if !tobool(new) then
		buylogger.Init()
	else
		buylogger.Close(true)
	end
end, "Sandbuy_Freebuy")

local function GetDeprecatedMessage(cmdname)
	return function(ply)
		ply:PrintMessage(HUD_PRINTTALK, "This command is deprecated. Please use '" .. cmdname .. "'")
	end
end

concommand.Add("reloadprices", function(ply)
	if IsValid(ply) and !ply:IsAdmin() then return end

	pricer.LoadPrices()

	pricer.SendPrices(nil, 1)
end)

concommand.Add("quickloadprices", function(ply)
	if IsValid(ply) and !ply:IsAdmin() then return end

	pricer.LoadPrices()

	pricer.SendPrices(nil, 2)
end)

-- TODO
concommand.Add("listprices", function(ply)
	print("CUSTOM:")
	local fsc,drc = file.Find("prices/*", "DATA")
	for k,v in pairs(drc) do
		print("  " .. v)
	end
	
	print("BUILT-IN:")
	local fs,dr = file.Find("gamemodes/sandbuy/prices/*", "GAME")
	for k,v in pairs(dr) do
		print("  " .. v)
	end
end)

concommand.Add("normalizeprices", function(ply)
	if IsValid(ply) and !ply:IsAdmin() then return end
	
	local fs,dr = file.Find("prices/*", "DATA")
	for k,v in pairs(dr) do
		local pfs,pdr = file.Find("prices/" .. v .. "/*", "DATA")
		for i,j in pairs(pfs) do
			if j == "categories.txt" then continue end
			pricer.SetPrice("!!!normalizeprices!!!", -3, j, v)
		end
	end
	
	print("Normalized prices")
end)

concommand.Add("setcategoryprice", function(ply, cmd, args)
	if IsValid(ply) and !ply:IsAdmin() then return end
	
	local category = args[1]
	if !pricer.CategoriesList[category] then
		ply:PrintMessage(HUD_PRINTCONSOLE, "Invalid category: " .. category)
		return
	end
	
	local price = tonumber(args[2])
	if !price then
		hook.Remove("ApplyPriceModifiers", "CategoryOverride_" .. category)

		print("Removed category price:", category)
	else
		hook.Add("OnPricesLoaded", "CategoryOverride_" .. category, function()
			pricer.ApplyModifier(pricer.CategoriesList[category], {"weapon", "entity", "vehicle", "ammo"}, function() return price end)
		end)
		
		print("New category price:", category, "$" .. price)
	end
end)

concommand.Add("setoverrideprice", function(ply, cmd, args)
	if IsValid(ply) and !ply:IsAdmin() then return end

	local wep = args[1]
	local price = tonumber(args[2])
	
	if !wep or !price or !args[3] then 
		print("Usage:  setoverrideprice [classname] [price] [type]")
		return
	end
	
	pricer.SetPrice(wep, price, args[3] .. "prices.txt")
	
	print("New override price:", wep, "$" .. price, "", GetConVar("sbuy_overrides"):GetString())
end)

concommand.Add("addsourceweapon", function(ply, cmd, args)
	if IsValid(ply) and !ply:IsAdmin() then return end
	
	local sourcewep = ply:GetActiveWeapon()
	if !IsValid(sourcewep) then
		print("Please hold valid weapon to set as source weapon")
		return
	end
	sourcewep = sourcewep:GetClass()
	
	if args[1] then
		local wep = args[1]
		
		pricer.SetPrice(wep, sourcewep, "sourceweapons.txt")
		
		print("New source weapon " .. wep .. " -> " .. sourcewep, "", GetConVar("sbuy_overrides"):GetString())
	else
		hook.Add("PlayerDeath", "AddSourceWeapon", function(dply, infl, atk)
			if !IsValid(infl) or infl:IsPlayer() or dply != ply then return end
			
			local wep = infl:GetClass()
			
			pricer.SetPrice(wep, sourcewep, "sourceweapons.txt")
		
			print("New source weapon " .. wep .. " -> " .. sourcewep, "", GetConVar("sbuy_overrides"):GetString())
		
			hook.Remove("PlayerDeath", "AddSourceWeapon")
		end)
		
		print("Please kill yourself with weapon")
	end
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

local function PrintHeldAmmoUsage(ply)
	--TODO
end

local function GiveHeldAmmo(ply, cmd, args)
	local wep = ply:GetActiveWeapon()
	if !IsValid(wep) then return end
	
	local amountarg = args[1] or "smart"
	local typearg = args[2] or "primary"
	local limitarg = args[3] or 1000
	
	local limit = tonumber(limitarg)
	if !limit then
		ply:PrintMessage(HUD_PRINTCONSOLE, "Invalid price limit: '" .. limitarg .. "'")
		return
	end
	if limit == 0 or limit > ply:GetMoney() then
		limit = ply:GetMoney()
	end
	
	local isprimary = true
	local ammo = -1
	if typearg == "primary" then
		ammo = wep:GetPrimaryAmmoType()
		if ammo == -1 then
			ammo = wep:GetSecondaryAmmoType()
			isprimary = false
		end
	elseif typearg == "secondary" then
		ammo = wep:GetSecondaryAmmoType()
		isprimary = false
	else
		ply:PrintMessage(HUD_PRINTCONSOLE, "Invalid ammo type: '" .. typearg .. "'")
		return
	end
	if ammo == -1 then 
		--ply:PrintMessage(HUD_PRINTCONSOLE, "No suitable ammo found for weapon")
		return
	end
	ammo = game.GetAmmoName(ammo)
	local ammoprice = pricer.GetPrice(ammo, "ammo")
	
	local amount = 1
	if ammoprice < 0 then
		--Ammo not for sale
	elseif amountarg == "smart" then
		amount = pricer.GetClipSize(wep:GetClass()) or (isprimary and wep:GetMaxClip1()) or wep:GetMaxClip2()
		if (amount > 0) and (ammoprice * amount > limit) and !GetConVar("freebuy"):GetBool() then
			amount = math.floor(limit / ammoprice)
		end
		if amount < 1 then
			amount = 1
		end
	elseif amountarg == "clip" then
		amount = pricer.GetClipSize(wep:GetClass()) or (isprimary and wep:GetMaxClip1()) or wep:GetMaxClip2()
	elseif amountarg == "max" then
		amount = math.floor(limit / ammoprice)
		if amount < 1 then
			amount = 1
		end
	elseif tonumber(args[1]) != nil then
		amount = tonumber(args[1])
	else
		ply:PrintMessage(HUD_PRINTCONSOLE, "Invalid amount: '" .. amountarg .. "'")
		return
	end
	
	if !gamemode.Call("PlayerGiveAmmo", ply, ammo, amount) then return end
	
	ply:GiveAmmo(amount, ammo, false)
end

concommand.Add("buyheldammo", GiveHeldAmmo)

-- DEPRECATED
concommand.Add("sbuy_giveprimaryammo", GiveHeldAmmo)--GetDeprecatedMessage("buyheldammo"))
concommand.Add("sbuy_giveheldammo", GetDeprecatedMessage("buyheldammo")) 

concommand.Add("givemoney", function(ply, cmd, args)
	if true then ply:PrintMessage(HUD_PRINTTALK, "Money sharing disabled") return end
	
	local target = nil
	if args[2] then
		for k,v in pairs(player.GetAll()) do 
			if v:Nick() == args[2] then
				target = v
				break
			end
		end
	else
		target = ply:GetEyeTrace().HitEntity
	end
	if !IsValid(target) or !target:IsPlayer() then return end
	if ply:GetPos():Distance(target:GetPos()) > 500 then ply:PrintMessage(HUD_PRINTTALK, "Player too far") return end
	
	local amount = tonumber(args[1])
	if !amount or amount < 0 then ply:PrintMessage(HUD_PRINTTALK, "Invalid amount") return end
	if ply:GetMoney() < amount then
		amount = ply:GetMoney()
	end
	
	ply:AddMoney(-amount)
	target:AddMoney(amount)
	
	ply:PrintMessage(HUD_PRINTTALK, "Given " .. target:Nick() .. " $" .. amount)
	target:PrintMessage(HUD_PRINTCENTER, "You were given $" .. amount .. " by " .. ply:Nick())
end)

GM.SeasonalWeapons = {}

local latestseasonals = {}
local seasonalindex = 0
local function GetUniqueSeasonal()
	local seasonalslist = pricer.CategoriesList.seasonals or {}
	seasonalindex = seasonalindex + 1
	while true do
		local new = seasonalslist[math.random(#seasonalslist)]
		if !latestseasonals[new] or latestseasonals[new] < seasonalindex - 10 then
			latestseasonals[new] = seasonalindex
			return new
		end
	end
end

local function GetOptimalSeasonal(richest)
	local new = nil
	for i = 1,3 do
		new = GetUniqueSeasonal()
		if pricer.GetPrice(new, "weapon") < richest then
			return new
		end
	end
	return new
end

local function UpdateSeasonals()
	local richest = 0
	for k,v in pairs(player.GetAll()) do
		if v:GetMoney() > richest then
			richest = v:GetMoney()
		end
	end
	--print("R: " .. richest)

	table.Empty(GAMEMODE.SeasonalWeapons)
	for i = 1,2 do
		GAMEMODE.SeasonalWeapons[GetOptimalSeasonal(richest)] = 2
	end
	
	--PrintTable(GAMEMODE.SeasonalWeapons)
	
	net.Start("newseasonals")
	net.WriteTable(GAMEMODE.SeasonalWeapons)
	net.Broadcast()
end

concommand.Add("sbuy_updateseasonals", function(ply) 
	if IsValid(ply) and !ply:IsAdmin() then return end
	UpdateSeasonals()
end)

local function GiveEcoMoneyAll()
	for k,v in pairs(player.GetAll()) do
		GAMEMODE:GiveEcoMoney(v)
	end
end

--[[cvars.AddChangeCallback("sbuy_ecotime", function(cvar, old, new)
	if tonumber(new) == 0 then
		timer.Remove("Sandbuy_Eco")
	else
		if timer.Exists("Sandbuy_Eco") then
			timer.Adjust("Sandbuy_Eco", tonumber(new), 0, GiveEcoMoneyAll)
		else
			timer.Create("Sandbuy_Eco", tonumber(new), 0, GiveEcoMoneyAll)
		end
	end
end, "Sbuy_EcoUpdate")]]--

function GM:Initialize()
	pricer.LoadPrices()
	
	if GetConVar("sbuy_log"):GetBool() then
		buylogger.Init()
	end
	
	--timer.Create("Sandbuy_UpdateSeasonalWeapons", 600, 0 , UpdateSeasonals)
	--timer.Simple(5, UpdateSeasonals)
	
	return BaseClass.Initialize(self)
end

function GM:ShutDown()
	local t1 = SysTime()
	buylogger.Close()
	local t2 = SysTime()
	
	print("--")
	print("--")
	print("--")
	print("Flushed buylog")
	print("Time:", t2 - t1)
	print("--")
	print("--")
	print("--")
	
	return BaseClass.ShutDown(self)
end

function GM:PlayerAuthed(ply, steamid, uniqueid)
	pricer.SendPrices(ply, 0)
	
	net.Start("newseasonals")
	net.WriteTable(GAMEMODE.SeasonalWeapons)
	net.Send(ply)
	
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
	print("Spawn")
	
	player_manager.SetPlayerClass(ply, "player_sandbuy")
	
	BaseBaseClass.PlayerSpawn(self, ply)
	
	if ply.HasDied then
		ply:SetKillstreak(0)
	
		local bailoutamount = gamemode.Call("GetBailout", ply)
	
		if ply.GetMoney and ply:GetMoney() < bailoutamount then
			buylogger.LogBailout(ply, bailoutamount, bailoutamount - ply:GetMoney())
			ply:SetMoney(bailoutamount)
			ply:PrintMessage(HUD_PRINTCENTER, "You were given a bailout\n    You now have $" .. bailoutamount)
		--elseif ply.DefaultMoneyOverride and ply.DefaultMoneyOverride < bailoutamount then
		--	buylogger.LogBailout(ply, bailoutamount, bailoutamount - ply.DefaultMoneyOverride)
		--	ply.DefaultMoneyOverride = bailoutamount
		--	ply:PrintMessage(HUD_PRINTCENTER, "You were given a bailout\n    You now have $" .. bailoutamount)
		end
	end
	
	ply.HasDied = false
	
	print("End Spawn")
end

function GM:PlayerDeath(ply, inflictor, attacker)
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
	
	local weaponname = ""
	if IsValid(weapon) then
		weaponname = weapon:GetClass()
	end
	if killer == weapon and killer != ply and IsValid(killer) and killer:IsPlayer() then
		weaponname = "helicopter_gun_generic"
	end
	print(inflictor, attacker, weapon, killer, "[" .. weaponname .. "]")
	
	gamemode.Call("HandlePlayerDeath", ply, killer, weapon, weaponname)
	
	ply.HasDied = true
	
	ply:SendLua("GAMEMODE:SetDeathMessage(Entity(" .. killer:EntIndex() .. "))")
	
	return BaseClass.PlayerDeath(self, ply, inflictor, attacker)
end

function GM:HandlePlayerDeath(ply, killer, weapon, weaponname)
	local deltamoney = gamemode.Call("GetKillBonus", ply, killer, weapon, weaponname)
	
	if killer:IsValid() && killer:IsPlayer() && killer != ply then
		if ply:Team() != TEAM_UNASSIGNED and ply:Team() == killer:Team() then
			killer:AddMoney(-pricer.TeamKillPenalty)
			buylogger.LogKill(killer, ply, weaponname, killer:GetMoney(), -pricer.TeamKillPenalty)
		else
			//deltamoney = 
			local killmoney = gamemode.Call("GetKillReward", ply, killer, weapon, weaponname) + deltamoney
			
			killer:AddMoney(killmoney)
			killer.TotalKillMoney = killer.TotalKillMoney + gamemode.Call("GetNormalizedKillReward", killmoney, ply, killer, weapon, weaponname)
			killer:AddKillstreak(1)
			buylogger.LogKill(killer, ply, weaponname, killer:GetMoney(), killmoney)
		end
	end
	ply:AddMoney(-deltamoney)
	--if killer == ply then
	--	ply.TotalKillMoney = math.max(ply.TotalKillMoney - 1 - deltamoney / ply:GetKillMoney(), 0)
	--end
	buylogger.LogDeath(ply, killer, weaponname, ply:GetMoney(), -deltamoney)
end

function GM:GetKillBonus(ply, killer, weapon, weaponname)
	return math.ceil(ply:GetMoney() * GetConVar("sbuy_bonusratio"):GetFloat() / 100)
end

function GM:GetKillReward(ply, killer, weapon, weaponname)
	return GetConVar("sbuy_killmoney"):GetInt() * pricer.GetKillReward(weaponname)
end

function GM:GetNormalizedKillReward(killmoney, ply, killer, weapon, weaponname)
	return killmoney / GetConVar("sbuy_killmoney"):GetInt()
end

function GM:GetBuyPrice(ply, class, priceset)
	return pricer.GetPrice(class, priceset)
end

function GM:GetBailout(ply)
	return GetConVar("sbuy_defaultmoney"):GetInt() + math.floor(math.sqrt(0.25 + (ply.TotalKillMoney or 0) * 2 / GetConVar("sbuy_levelsize"):GetFloat()) - 0.5) * GetConVar("sbuy_levelbonus"):GetInt()
end

function GM:GiveEcoMoney(ply)
	local ecoamount = ply:GetBailout()

	if ply.GetMoney and !ply.IsAFK and ply:Alive() then
		ply:AddMoney(ecoamount)
		buylogger.LogBailout(ply, ply:GetMoney(), ecoamount)
	end
end

function GM:PlayerGiveSWEP(ply, class, swep)
	if !ply:Alive() then return false end
	
	if ply:HasWeapon(class) then
		return true
	end
	
	local price = gamemode.Call("GetBuyPrice", ply, class, "weapon")
	
	if price == -5 then
		ply:PrintMessage(HUD_PRINTCENTER, "Bad!")
		ply:SendLua("surface.PlaySound('sandbuy/denied.wav')")
		return false
	end
	
	if GetConVar("freebuy"):GetBool() then
		if price >= 0 or GetConVar("sbuy_debug"):GetBool() then
			ply:SendLua("surface.PlaySound('sandbuy/kaching.wav')")
			
			net.Start("weaponbought")
			net.WriteString(class)
			net.Send(ply)
			
			return true
		else
			ply:SendLua("surface.PlaySound('sandbuy/denied.wav')")
			return false
		end
	end
	
	if pricer.CanBuy(ply:GetMoney(), price) then
		ply:AddMoney(-price)
		ply:PrintMessage(HUD_PRINTCENTER, "Weapon bought for $" .. price)
		ply:SendLua("surface.PlaySound('sandbuy/kaching.wav')")
		
		net.Start("weaponbought")
		net.WriteString(class)
		net.WriteBool(false)
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
	if !ply:Alive() or !BaseClass.PlayerSpawnSWEP(self, ply, class, swep) then return false end
	
	local price = gamemode.Call("GetBuyPrice", ply, class, "weapon")
	
	if price == -5 then
		ply:PrintMessage(HUD_PRINTCENTER, "Bad!")
		ply:SendLua("surface.PlaySound('sandbuy/denied.wav')")
		return false
	end
	
	if GetConVar("freebuy"):GetBool() then
		if price >= 0 or GetConVar("sbuy_debug"):GetBool() then
			ply:SendLua("surface.PlaySound('sandbuy/kaching.wav')")
			return true
		else
			ply:SendLua("surface.PlaySound('sandbuy/denied.wav')")
			return false
		end
	end
	
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
	if !ply:Alive() then return false end
	if amount <= 0 then return false end

	local price = pricer.GetPrice(ammo, "ammo") * amount
	
	if GetConVar("freebuy"):GetBool() then
		if price >= 0 or GetConVar("sbuy_debug"):GetBool() then
			ply:SendLua("surface.PlaySound('sandbuy/kaching.wav')")
			return true
		else
			ply:SendLua("surface.PlaySound('sandbuy/denied.wav')")
			return false
		end
	end
	
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
	if !ply:Alive() or !BaseClass.PlayerSpawnSENT(self, ply, class) then return false end
	
	local price = gamemode.Call("GetBuyPrice", ply, class, "entity")
	
	if price == -5 then
		ply:PrintMessage(HUD_PRINTCENTER, "Bad!")
		ply:SendLua("surface.PlaySound('sandbuy/denied.wav')")
		return false
	end
	
	if GetConVar("freebuy"):GetBool() then
		if price >= 0 or GetConVar("sbuy_debug"):GetBool() then
			ply:SendLua("surface.PlaySound('sandbuy/kaching.wav')")
			return true
		else
			ply:SendLua("surface.PlaySound('sandbuy/denied.wav')")
			return false
		end
	end
	
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
	if !ply:Alive() or !BaseClass.PlayerSpawnVehicle(self, ply, model, class, vtable) then return false end
	
	local price = gamemode.Call("GetBuyPrice", ply, class, "vehicle")
	
	if price == -5 then
		ply:PrintMessage(HUD_PRINTCENTER, "Bad!")
		ply:SendLua("surface.PlaySound('sandbuy/denied.wav')")
		return false
	end
	
	if GetConVar("freebuy"):GetBool() then
		if price >= 0 or GetConVar("sbuy_debug"):GetBool() then
			ply:SendLua("surface.PlaySound('sandbuy/kaching.wav')")
			return true
		else
			ply:SendLua("surface.PlaySound('sandbuy/denied.wav')")
			return false
		end
	end
	
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
	return GetConVar("sbuy_debug"):GetBool() and BaseClass.PlayerSpawnProp(self, ply, model)
end

function GM:PlayerSpawnNPC(ply, class, weapon)
	return GetConVar("sbuy_debug"):GetBool() and BaseClass.PlayerSpawnNPC(self, ply, class, weapon)
end

function GM:PlayerSpawnRagdoll(ply, model)
	return GetConVar("sbuy_debug"):GetBool() and BaseClass.PlayerSpawnRagdoll(self, ply, model)
end

function GM:PlayerSpawnObject(ply, model, skin)
	return GetConVar("sbuy_debug"):GetBool() and BaseClass.PlayerSpawnObject(self, ply, model, skin)
end

function GM:PlayerSpawnedSENT(ply, ent)
	local price = gamemode.Call("GetBuyPrice", ply, ent:GetClass(), "entity")
	if price > 0 and pricer.InCategory(ent:GetClass(), "machines") then
		ent.DestroyReward = math.floor(price * 0.5)
	end
	
	return BaseClass.PlayerSpawnedSENT(self, ply, ent)
end

function GM:PlayerSpawnedVehicle(ply, ent)
	local price = gamemode.Call("GetBuyPrice", ply, ent.VehicleName, "vehicle")
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