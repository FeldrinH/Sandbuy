AddCSLuaFile('shared.lua')
AddCSLuaFile('sh_cami.lua')
AddCSLuaFile('playermeta.lua')
AddCSLuaFile('pricer.lua')
AddCSLuaFile('player_class/player_sandbuy.lua')
AddCSLuaFile('cl_init.lua')
AddCSLuaFile('cl_scoreboard.lua')
AddCSLuaFile('spawnmenu_content.lua')
AddCSLuaFile('patches_shared.lua')
//AddCSLuaFile('custom_buy.lua')
AddCSLuaFile('configmenu.lua')

-- Do not reload buylogger if it is already active
if !buylogger then
	include('buylogger.lua')
end
include('shared.lua')
include('patches.lua')
include('statsaver.lua')

DEFINE_BASECLASS("gamemode_sandbox")
local BaseBaseClass = baseclass.Get( "gamemode_base" )

util.AddNetworkString("moneychanged")
util.AddNetworkString("weaponbought")
util.AddNetworkString("newprices")

CreateConVar("sbuy_freebuy", 0, FCVAR_NOTIFY, "If enabled allows all weapons and other purchasable items to be obtained for free")

cvars.AddChangeCallback("sbuy_freebuy", function(convar, old, new)
	if tobool(new) then
		buylogger.LogString("freebuy-enabled", "")
	else
		buylogger.LogString("freebuy-disabled", "")
	end
end, "Sandbuy_ToggleFreebuy")

cvars.AddChangeCallback("sbuy_log", function(convar, old, new)
	if tobool(new) then
		buylogger.Init()
	else
		buylogger.Close(true)
	end
end, "Sandbuy_ToggleLogging")

local function MsgCaller(text, ply)
	if ply and !ply:IsListenServerHost() then
		ply:PrintMessage(HUD_PRINTCONSOLE, text)
	else
		print(text)
	end
end

local function GetDeprecatedMessage(cmdname)
	return function(ply)
		ply:PrintMessage(HUD_PRINTTALK, "This command is deprecated. Please use '" .. cmdname .. "'")
	end
end

concommand.Add("logmessage", function(ply, cmd, args, argStr)
	if IsValid(ply) and !CAMI.PlayerHasAccess(ply, "sandbuy.logmessage") then return end

	buylogger.LogTimestamped("message", (IsValid(ply) and buylogger.FormatPlayer(ply) or "") .. "," .. buylogger.EscapeCSV(argStr))
end)

concommand.Add("reloadprices", function(ply)
	if IsValid(ply) and !CAMI.PlayerHasAccess(ply, "sandbuy.editprices") then return end

	pricer.StartRepl(ply)
	pricer.LoadPrices()
	pricer.EndRepl()
	
	pricer.SendPrices(nil, 1)
end)

concommand.Add("quickloadprices", function(ply)
	if IsValid(ply) and !CAMI.PlayerHasAccess(ply, "sandbuy.editprices") then return end

	pricer.StartRepl(ply)
	pricer.LoadPrices()
	pricer.EndRepl()

	pricer.SendPrices(nil, 2)
end)

-- TODO
concommand.Add("listprices", function(ply)
	if IsValid(ply) and !CAMI.PlayerHasAccess(ply, "sandbuy.editprices") then return end

	MsgCaller("CUSTOM:", ply)
	local fsc,drc = file.Find("prices/*", "DATA")
	for k,v in pairs(drc) do
		MsgCaller("  " .. v, ply)
	end
	
	MsgCaller("BUILT-IN:", ply)
	local fs,dr = file.Find("gamemodes/sandbuy/prices/*", "GAME")
	for k,v in pairs(dr) do
		MsgCaller("  " .. v, ply)
	end
end)

concommand.Add("normalizeprices", function(ply)
	if IsValid(ply) and !CAMI.PlayerHasAccess(ply, "sandbuy.manageprices") then return end
	
	local fs,dr = file.Find("prices/*", "DATA")
	for k,v in pairs(dr) do
		local pfs,pdr = file.Find("prices/" .. v .. "/*", "DATA")
		for i,j in pairs(pfs) do
			if j == "categories.txt" then
				pricer.SetCategory("!!!normalizeprices!!!", "!!!normalizeprices!!!", nil, v)
			else
				pricer.SetPrice("!!!normalizeprices!!!", -3, j, v)
			end
		end
	end
	
	MsgCaller("Normalized prices", ply)
end)

concommand.Add("saveactiveprices", function(ply, cmd, args)
	if IsValid(ply) and !CAMI.PlayerHasAccess(ply, "sandbuy.editprices", nil, nil, { CommandArguments = { args[1] } }) then return end
	
	local outprices = args[1]
	if !outprices then
		MsgCaller('No priceset to save to specified', ply)
		return
	end
	
	pricer.SaveLoadedPrices(outprices)
	
	MsgCaller("Merged active prices and saved to '" .. outprices .. "'", ply)
end)

concommand.Add("changeprices", function(ply, cmd, args, argStr)
	if IsValid(ply) and !CAMI.PlayerHasAccess(ply, "sandbuy.editprices") then return end
	
	local newprices = string.Trim(argStr)
	local cvar_prices = GetConVar("sbuy_prices")
	if cvar_prices:GetString() != newprices then
		cvar_prices:SetString(newprices)
		
		pricer.StartRepl(ply)
		pricer.LoadPrices()
		pricer.EndRepl()
		
		pricer.SendPrices(nil, 1)
	end
end)

local function DoAutoReload()
	pricer.LoadPrices()
	pricer.SendPrices(nil, 3)
end

concommand.Add("setprice", function(ply, cmd, args)
	local priceset = args[4] or (ply and ply:GetInfo("sbuy_saveto"))

	if IsValid(ply) and !CAMI.PlayerHasAccess(ply, "sandbuy.editprices", nil, nil, { CommandArguments = { priceset } }) then return end

	local wep = args[1]
	local price = tonumber(args[2])
	
	if !wep or !price or !args[3] then 
		MsgCaller("Usage:  setprice [classname] [price (use -3 to unset)] [type (weapon, entity, etc.)] [priceset (defaults to value of sbuy_saveto)]", ply)
		return
	end
	
	if !pricer.ValidatePriceSetName(priceset, true) then
		MsgCaller("ERROR: Invalid priceset name: '" .. priceset .. "'", ply)
		return
	end
	if !file.Exists("prices/" .. priceset, "DATA") and #file.Find("gamemodes/sandbuy/prices/" .. priceset .. "/*", "GAME") > 0 then
		MsgCaller('ERROR: Attempt to set price on built-in priceset. If this was intentional, create copy of priceset in data/prices/ directory', ply)
		return
	end
	
	pricer.SetPrice(wep, price, args[3] .. "prices.txt", priceset)
	
	MsgCaller("New override price:  " .. wep .. ": $" .. price .. " in '" .. priceset .. "'", ply)
	
	if GetConVar("sbuy_autoreload"):GetBool() then
		timer.Create("Sandbuy_AutoReloadTimer", 0.5, 1, DoAutoReload) // Ensure that autoreload only occurs once if a lot of prices are set at once
	end
end)

concommand.Add("setcategory", function(ply, cmd, args)
	local category = args[1]
	local priceset = args[4] or (ply and ply:GetInfo("sbuy_saveto"))

	if IsValid(ply) and !CAMI.PlayerHasAccess(ply, "sandbuy.editprices", nil, nil, { CommandArguments = { priceset, category } }) then return end

	local class = args[2]
	local valuenum = tonumber(args[3])
	
	if !category or !class or !valuenum or !priceset then
		MsgCaller("Usage:  setcategory [category] [classname] [value (use -3 to unset)] [priceset (defaults to value of sbuy_saveto)]", ply)
		return
	end
	
	if !pricer.ValidatePriceSetName(priceset, true) then
		MsgCaller("ERROR: Invalid priceset name: '" .. priceset .. "'", ply)
		return
	end
	if !file.Exists("prices/" .. priceset, "DATA") and #file.Find("gamemodes/sandbuy/prices/" .. priceset .. "/*", "GAME") > 0 then
		MsgCaller('ERROR: Attempt to set category value on built-in priceset. If this was intentional, create copy of priceset in data/prices/ directory', ply)
		return
	end
	
	local value = valuenum >= 0 and valuenum or nil
	
	pricer.SetCategory(category, class, value, priceset)
	
	if value then
		MsgCaller("Set category value:  " .. class .. ": " .. value .. " in category " .. category .. " in priceset '" .. priceset .. "'", ply)
	else
		MsgCaller("Unset category value:  " .. class .. " in category " .. category .. " in priceset '" .. priceset .. "'", ply)
	end
	
	if GetConVar("sbuy_autoreload"):GetBool() then
		timer.Create("Sandbuy_AutoReloadTimer", 0.5, 1, DoAutoReload) // Ensure that autoreload only occurs once if a lot of prices are set at once
	end
end)

concommand.Add("addsourceweapon", function(ply, cmd, args)
	if !IsValid(ply) or !CAMI.PlayerHasAccess(ply, "sandbuy.editprices") then return end
	
	local sourcewep = ply:GetActiveWeapon()
	if !IsValid(sourcewep) then
		MsgCaller("Please hold valid weapon to set as source weapon", ply)
		return
	end
	sourcewep = sourcewep:GetClass()
	
	if args[1] then
		local wep = args[1]
		
		pricer.SetPrice(wep, sourcewep, "sourceweapons.txt", ply:GetInfo("sbuy_saveto"))
		
		MsgCaller("New source weapon " .. wep .. " -> " .. sourcewep .. "   " .. ply:GetInfo("sbuy_saveto"), ply)
	else
		hook.Add("PlayerDeath", "AddSourceWeapon", function(dply, infl, atk)
			if !IsValid(infl) or infl:IsPlayer() or dply != ply then return end
			
			local wep = infl:GetClass()
			
			pricer.SetPrice(wep, sourcewep, "sourceweapons.txt", ply:GetInfo("sbuy_saveto"))
		
			MsgCaller("New source weapon " .. wep .. " -> " .. sourcewep .. "   " .. ply:GetInfo("sbuy_saveto"), ply)
		
			hook.Remove("PlayerDeath", "AddSourceWeapon")
		end)
		
		MsgCaller("Please kill yourself with weapon", ply)
	end
end)

concommand.Add("sbuy_giveammo", function(ply, cmd, args)
	local ammo = args[1]
	local amount = tonumber(args[2])
	
	if !hook.Run("PlayerGiveAmmo", ply, ammo, amount) then return end
	
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

local usagestr = "Usage: buyheldammo [amount of ammo to buy or 0 for weapon clip size (default 0)] [primary/secondary/auto (default auto)] [maximum money to spend (default 500)] "
local function GiveHeldAmmo(ply, cmd, args)
	local wep = ply:GetActiveWeapon()
	if !IsValid(wep) then return end
	
	local amountarg = args[1] or 0
	local typearg = args[2] or "auto"
	local limitarg = args[3] or 500
	
	local limit = tonumber(limitarg)
	if !limit or limit <= 0 then
		ply:PrintMessage(HUD_PRINTTALK, "Invalid price limit: '" .. limitarg .. "'")
		ply:PrintMessage(HUD_PRINTTALK, usagestr)
		return
	end
	
	local maxamount = tonumber(amountarg)
	if !maxamount or maxamount < 0 then
		ply:PrintMessage(HUD_PRINTTALK, "Invalid ammo amount: '" .. limitarg .. "'")
		ply:PrintMessage(HUD_PRINTTALK, usagestr)
		return
	end
	
	local isprimary = true
	local ammo = -1
	if typearg == "auto" then
		ammo = wep:GetPrimaryAmmoType()
		if ammo == -1 then
			ammo = wep:GetSecondaryAmmoType()
			isprimary = false
		end
	elseif typearg == "primary" then
		ammo = wep:GetPrimaryAmmoType()
	elseif typearg == "secondary" then
		ammo = wep:GetSecondaryAmmoType()
		isprimary = false
	else
		ply:PrintMessage(HUD_PRINTTALK, "Invalid ammo type: '" .. typearg .. "'")
		ply:PrintMessage(HUD_PRINTTALK, usagestr)
		return
	end
	
	if ammo == -1 then 
		--ply:PrintMessage(HUD_PRINTCONSOLE, "No suitable ammo found for weapon")
		return
	end
	ammo = game.GetAmmoName(ammo)
	local ammoprice = hook.Run("GetBuyPrice", ply, ammo, "ammo")
	
	local amount = 1
	if ammoprice >= 0 then
		if maxamount == 0 then
			amount = pricer.GetClipSize(wep:GetClass()) or (isprimary and wep:GetMaxClip1()) or wep:GetMaxClip2()
		else
			amount = maxamount
		end
		
		limit = math.min(limit, ply:GetMoney())
		if (amount > 0) and (ammoprice * amount > limit) and !GetConVar("sbuy_freebuy"):GetBool() then
			amount = math.floor(limit / ammoprice)
		end
		if amount < 1 then
			amount = 1
		end
	end
	
	if !hook.Run("PlayerGiveAmmo", ply, ammo, amount) then return end
	
	ply:GiveAmmo(amount, ammo, false)
end

concommand.Add("buyheldammo", GiveHeldAmmo)

-- DEPRECATED
concommand.Add("sbuy_giveprimaryammo", GiveHeldAmmo)--GetDeprecatedMessage("buyheldammo"))
concommand.Add("sbuy_giveheldammo", GetDeprecatedMessage("buyheldammo")) 

concommand.Add("showstats", function(ply, cmd, args)
	if !IsValid(ply) then return end

	ply:PrintMessage(HUD_PRINTTALK, "Kills: " .. ply:Frags() .. "  Deaths: " .. ply:Deaths())
	ply:PrintMessage(HUD_PRINTTALK, "KDR: " .. math.Round(ply:Frags() / ply:Deaths(), 2))
	local bailout = hook.Run("GetBailout", ply)
	local bailoutlevel = math.floor(math.sqrt(0.25 + math.max(ply.TotalKillMoney or 0, 0) * 2) - 0.5)
	ply:PrintMessage(HUD_PRINTTALK, "Bailout: $" .. bailout .. " ($" .. GetConVar("sbuy_defaultmoney"):GetInt() .. "+$" .. bailoutlevel * GetConVar("sbuy_levelbonus"):GetInt() .. ")")
	ply:PrintMessage(HUD_PRINTTALK, "$" .. math.ceil(((bailoutlevel + 2) * (bailoutlevel+1) / 2 - ply.TotalKillMoney) * GetConVar("sbuy_levelsize"):GetInt()) .. " until next bailout increase")
end)

function GM:PostGamemodeLoaded()
	pricer.LoadPrices()
	
	return BaseClass.PostGamemodeLoaded(self)
end

function GM:Initialize()
	if GetConVar("sbuy_log"):GetBool() then
		buylogger.Init()
	end
	
	return BaseClass.Initialize(self)
end

function GM:ShutDown()
	buylogger.Close()
	
	return BaseClass.ShutDown(self)
end

function GM:GetBuylogID(ply)
	return buylogger.EscapeCSV(ply:Nick())
	/*local steamid = ply:SteamID()
	if string.StartWith(steamid, "STEAM_") then
		return string.sub(steamid, 7)
	else
		return steamid .. ":" .. ply:AccountID()
	end*/
end

function GM:PlayerAuthed(ply, steamid, uniqueid)
	ply.BuylogID = hook.Run("GetBuylogID", ply)

	pricer.SendPrices(ply, 0)
	
	return BaseClass.PlayerAuthed(self, ply, steamid, uniqueid)
end

function GM:PlayerInitialSpawn(ply)
	ply.IsInitialSpawn = true
	
	ply.BuylogID = hook.Run("GetBuylogID", ply)

	buylogger.LogJoin(ply)

	ply.TotalKillMoney = ply.TotalKillMoney or 0
	
	BaseClass.PlayerInitialSpawn(self, ply)
end

function GM:PlayerDisconnected(ply)
	StatSaverSave(ply)

	buylogger.LogLeave(ply)
	
	BaseClass.PlayerDisconnected(self, ply)
end

function GM:PlayerSay(ply, text, teamonly)
	buylogger.LogString(teamonly and "chat-team" or "chat", buylogger.FormatPlayer(ply) .. "," .. buylogger.EscapeCSV(text))
	return BaseClass.PlayerSay(self, ply, text, teamonly)
end

function GM:PlayerSpawn(ply)
	player_manager.SetPlayerClass(ply, "player_sandbuy")
	
	BaseBaseClass.PlayerSpawn(self, ply)
	
	if ply.IsInitialSpawn then
		StatSaverLoad(ply)
	end
	
	if ply.IsInitialSpawn then
		ply.IsInitialSpawn = false
		
		local startamount = hook.Run("GetStartMoney", ply)
		if ply.GetMoney then
			buylogger.LogBailout(ply, startamount, startamount - ply:GetMoney(), true)
			ply:SetMoney(startamount)
		end
	end
	
	if ply.HasDied then
		ply:SetKillstreak(0)
	
		local bailoutamount = hook.Run("GetBailout", ply)
		if ply.GetMoney and ply:GetMoney() < bailoutamount then
			buylogger.LogBailout(ply, bailoutamount, bailoutamount - ply:GetMoney())
			ply:SetMoney(bailoutamount)
			ply:PrintMessage(HUD_PRINTCENTER, "You were given a bailout\n    You now have $" .. bailoutamount)
		else
			buylogger.LogBailoutNone(ply, ply:GetMoney())
		end
	end
	
	ply.HasDied = false
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
	
	hook.Run("HandlePlayerDeath", ply, killer, weapon, weaponname)
	
	ply.HasDied = true
	
	ply:SendLua("GAMEMODE:SetDeathMessage(Entity(" .. killer:EntIndex() .. "))")
	
	return BaseClass.PlayerDeath(self, ply, inflictor, attacker)
end

function GM:HandlePlayerDeath(ply, killer, weapon, weaponname)
	local deltamoney = nil
	if killer != ply then
		deltamoney = hook.Run("GetDeathMoney", ply, killer, weapon, weaponname)
	end
	
	if killer:IsValid() && killer:IsPlayer() then
		local killmoney = hook.Run("GetKillMoney", ply, killer, weapon, weaponname)
		
		local rewardmoney = hook.Run("GetKillPenalty", ply, killer, killmoney, deltamoney, weapon, weaponname)
		local ispenalty = true
		
		if rewardmoney == nil then
			rewardmoney = hook.Run("GetKillReward", ply, killer, killmoney, deltamoney, weapon, weaponname)
			ispenalty = false
			killer:AddKillstreak(1)
		end
		
		killer:AddMoney(rewardmoney)
		killer:AddTotalKillMoney(rewardmoney)
		buylogger.LogKill(killer, ply, weaponname, killer:GetMoney(), rewardmoney, ispenalty)
	end
	
	if deltamoney == nil then
		deltamoney = hook.Run("GetDeathMoney", ply, killer, weapon, weaponname)
	end
	ply:AddMoney(-deltamoney)
	buylogger.LogDeath(ply, killer, weaponname, ply:GetMoney(), -deltamoney)
end

function GM:GetKillMoney(victim, killer, weapon, weaponname)
	return GetConVar("sbuy_killmoney"):GetInt() * pricer.GetKillReward(weaponname)
end

function GM:GetDeathMoney(victim, killer, weapon, weaponname)
	return math.ceil(victim:GetMoney() * GetConVar("sbuy_bonusratio"):GetFloat() / 100)
end

function GM:GetKillReward(victim, killer, killmoney, deltamoney, weapon, weaponname)
	return killmoney + deltamoney
end

function GM:GetKillPenalty(victim, killer, killmoney, deltamoney, weapon, weaponname)
	if victim == killer then
		return -killmoney
	elseif victim:Team() != TEAM_UNASSIGNED and victim:Team() == killer:Team() then
		return -GetConVar("sbuy_killmoney"):GetInt() / 2
	end
end

function GM:GetBailout(ply)
	return GetConVar("sbuy_defaultmoney"):GetInt() + math.floor(math.sqrt(0.25 + math.max(ply.TotalKillMoney or 0, 0) * 2) - 0.5) * GetConVar("sbuy_levelbonus"):GetInt()
end

function GM:GetDestroyReward(ply, ent, price, markedasvehicle)
	return markedasvehicle and math.floor(price * 0.5) or nil
end

-- If ply == nil, this should return a generic default value for startmoney
function GM:GetStartMoney(ply)
	return GetConVar("sbuy_startmoney"):GetInt()
end

function GM:ScalePlayerDamage(ply, hitgroup, dmginfo)
	if hitgroup == HITGROUP_HEAD then
		dmginfo:ScaleDamage(4)
	end

	if hitgroup == HITGROUP_LEFTARM ||
		 hitgroup == HITGROUP_RIGHTARM ||
		 hitgroup == HITGROUP_LEFTLEG ||
		 hitgroup == HITGROUP_RIGHTLEG then
		dmginfo:ScaleDamage(0.375)
	end
	
	if hitgroup == HITGROUP_GEAR then
		dmginfo:ScaleDamage(0.5)
	end
end

-- Amount is optional and defaults to 1
function GM:DoBuy(ply, price, class, buy_type, str_buy, str_needmoney, str_denied, amount)
	if price == -5 then
		ply:PrintMessage(HUD_PRINTCENTER, "Bad!")
		ply:SendLua("surface.PlaySound('sandbuy/denied.wav')")
		return false
	elseif price == -4 then
		if CAMI.PlayerHasAccess(ply, "sandbuy.useadminitems") then
			ply:SendLua("surface.PlaySound('sandbuy/kaching.wav')")
			return true
		else
			ply:PrintMessage(HUD_PRINTCENTER, "You need to be an admin to use this!")
			ply:SendLua("surface.PlaySound('sandbuy/denied.wav')")
			return false
		end
	end
	
	if GetConVar("sbuy_freebuy"):GetBool() then
		if price >= 0 or (GetConVar("sbuy_debug"):GetBool() and ply:IsSuperAdmin()) then
			ply:PrintMessage(HUD_PRINTCENTER, string.format(str_buy, price))
			ply:SendLua("surface.PlaySound('sandbuy/kaching.wav')")
			return true
		else
			ply:SendLua("surface.PlaySound('sandbuy/denied.wav')")
			return false
		end
	end
	
	if pricer.CanBuy(ply:GetMoney(), price) then
		ply:AddMoney(-price)
		ply:PrintMessage(HUD_PRINTCENTER, string.format(str_buy, price))
		ply:SendLua("surface.PlaySound('sandbuy/kaching.wav')")
		
		buylogger.LogBuy(ply, class, buy_type, ply:GetMoney(), -price, amount)
		
		return true
	elseif price >= 0 then
		ply:PrintMessage(HUD_PRINTCENTER, string.format(str_needmoney, price))
		ply:SendLua("surface.PlaySound('sandbuy/denied.wav')")
		return false
	else
		ply:PrintMessage(HUD_PRINTCENTER, str_denied)
		ply:SendLua("surface.PlaySound('sandbuy/denied.wav')")
		return false
	end
end

function GM:PlayerGiveSWEP(ply, class, swep)
	if !ply:Alive() then return false end
	
	if ply:HasWeapon(class) then
		return true
	end
	
	local price = hook.Run("GetBuyPrice", ply, class, "weapon")
	local didbuy = hook.Run("DoBuy", ply, price, class, 'weapon', "Weapon bought for $%i", "Need $%i to buy weapon", "Weapon not for sale")
	if didbuy then
		net.Start("weaponbought")
		net.WriteString(class)
		net.Send(ply)
	end

	return didbuy
end

function GM:PlayerSpawnSWEP(ply, class, swep)
	if !ply:Alive() or !BaseClass.PlayerSpawnSWEP(self, ply, class, swep) then return false end
	
	local price = hook.Run("GetBuyPrice", ply, class, "weapon")
	return hook.Run("DoBuy", ply, price, class, 'weapon-drop', "Weapon bought for $%i", "Need $%i to buy weapon", "Weapon not for sale") 
end

function GM:PlayerGiveAmmo(ply, ammo, amount)
	if !ply:Alive() then return false end
	if amount <= 0 then return false end

	local price = hook.Run("GetBuyPrice", ply, ammo, "ammo") * amount
	return hook.Run("DoBuy", ply, price, ammo, 'ammo', "Ammo bought for $%i", "Need $%i to buy ammo", "Ammo type not for sale", amount)
end

function GM:PlayerSpawnSENT(ply, class)
	if !ply:Alive() or !BaseClass.PlayerSpawnSENT(self, ply, class) then return false end
	
	local price = hook.Run("GetBuyPrice", ply, class, "entity")
	return hook.Run("DoBuy", ply, price, class, 'entity', "Entity bought for $%i", "Need $%i to buy entity", "Entity not for sale")
end

function GM:PlayerSpawnVehicle(ply, model, class, vtable)
	if !ply:Alive() or !BaseClass.PlayerSpawnVehicle(self, ply, model, class, vtable) then return false end
	
	local price = hook.Run("GetBuyPrice", ply, class, "vehicle")
	return hook.Run("DoBuy", ply, price, class, 'vehicle', "Vehicle bought for $%i", "Need $%i to buy vehicle", "Vehicle not for sale")
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
	local price = hook.Run("GetBuyPrice", ply, ent:GetClass(), "entity")
	local destroyreward = hook.Run("GetDestroyReward", ply, ent, price, pricer.InCategory(ent:GetClass(), "machines"))
	if destroyreward != nil then
		ent.DestroyReward = destroyreward
	end
	
	return BaseClass.PlayerSpawnedSENT(self, ply, ent)
end

function GM:PlayerSpawnedVehicle(ply, ent)
	local price = hook.Run("GetBuyPrice", ply, ent.VehicleName, "vehicle")
	local destroyreward = hook.Run("GetDestroyReward", ply, ent, price, true)
	if destroyreward != nil then
		ent.DestroyReward = destroyreward
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
	if ent.DestroyReward and IsValid(ent.DestroyRewardPlayer) and CurTime() - ent.DestroyRewardTime <= 1 then
		ent.DestroyRewardPlayer:AddMoney(ent.DestroyReward)
		ent.DestroyRewardPlayer:AddTotalKillMoney(ent.DestroyReward)
		buylogger.LogDestroy(ent.DestroyRewardPlayer, ent:GetClass(), ent.DestroyRewardPlayer:GetMoney(), ent.DestroyReward)
	end
	
	return BaseClass.EntityRemoved(self, ent)
end