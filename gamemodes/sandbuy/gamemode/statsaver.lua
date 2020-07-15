local stats = {}

function GetStatSaverData()
	return stats
end

local function FindPlayerByNick(searchStr)
	if searchStr == "" then return nil end
	
	for k,v in pairs(player.GetAll()) do
		if searchStr == v:Nick() then
			return target
		end
	end
end

concommand.Add("resetfull", function( ply, cmd, args, argString  )
	if IsValid(ply) and !CAMI.PlayerHasAccess(ply, "sandbuy.reset") then return end
	
	buylogger.LogReset("full", buylogger.EscapeCSV(argString))
	
	local target = FindPlayerByNick(argString)
	
	if argString == "" then
		stats = {}
	elseif target then
		stats[target:SteamID()] = nil
	end
	
	for k,v in pairs(target and {target} or player.GetAll()) do
		v:SetFrags(0)
		v:SetDeaths(0)
		v:StripWeaponsRaw()
		v:RemoveAllAmmo()
		v.NeuroPlanes_SavedWeapons = nil
		v.NeuroPlanes_ActiveWeapon = nil
		v:SetMoney(0)
		v.TotalKillMoney = 0
		v.IsInitialSpawn = true
		v:Spawn()
	end
	
	hook.Run("ResetPlayerStats", target, "full")
end)

/*concommand.Add("resetplayers", function( ply, cmd, args, argString )
	if IsValid(ply) and !CAMI.PlayerHasAccess(ply, "sandbuy.reset") then return end
	
	local target = nil
	for k,v in pairs(player.GetAll()) do
		if argString == "" or argString == v:Nick() then
			v:SetFrags(0)
			v:SetDeaths(0)
			v:StripWeaponsRaw()
			v:RemoveAllAmmo()
			v.NeuroPlanes_SavedWeapons = nil
			v.NeuroPlanes_ActiveWeapon = nil
			v.TotalKillMoney = 0
			v:SetMoney(hook.Run("GetStartMoney", v))
			
			buylogger.LogStartingBailout(v, v:GetMoney(), v:GetMoney())
			
			if argString != "" then
				target = v
			end
		end
	end
	
	hook.Run("ResetPlayerStats", target, "players")
	
	buylogger.LogReset("players", target and buylogger.FormatPlayer(target) or argString)
	
	if argString == "" then
		stats = {}
	elseif target then
		stats[target:SteamID()] = nil
	end
end)*/

concommand.Add("resetstats", function( ply, cmd, args, argString )
	if IsValid(ply) and !CAMI.PlayerHasAccess(ply, "sandbuy.reset") then return end
	
	buylogger.LogReset("stats", buylogger.EscapeCSV(argString))
	
	local target = FindPlayerByNick(argString)
	
	if argString == "" then
		for k,v in pairs(stats) do
			v.frags = 0
			v.deaths = 0
		end
	elseif target then
		local plystats = stats[target:SteamID()]
		if plystats then
			plystats.frags = 0
			plystats.deaths = 0
		end
	end
	
	for k,v in pairs(target and {target} or player.GetAll()) do
		v:SetFrags(0)
		v:SetDeaths(0)
	end
	
	hook.Run("ResetPlayerStats", target, "stats")
end)


if !GetConVar("sbuy_statsaver"):GetBool() then 
	function StatSaverLoad(ply) end
	function StatSaverSave(ply) end
else
	function StatSaverLoad(ply)
		if ply:IsBot() then return end
	
		local plystats = stats[ply:SteamID()]
		if plystats then
			ply:SetFrags(plystats.frags)
			ply:SetDeaths(plystats.deaths)
			
			ply:SetMoney(plystats.money)
			ply:SetKillstreak(plystats.killstreak)
			ply.TotalKillMoney = plystats.killmoney

			ply.IsInitialSpawn = false
			ply.HasDied = true
			
			hook.Call("LoadStatSaver", nil, ply, plystats)
		end
	end
	
	function StatSaverSave(ply)
		if ply:IsBot() then return end
	
		local plystats = { frags=ply:Frags(), deaths=ply:Deaths(), money=ply:GetMoney(), killstreak=ply:GetKillstreak(), killmoney=ply.TotalKillMoney }
	
		hook.Call("SaveStatSaver", nil, ply, plystats)
		
		stats[ply:SteamID()] = plystats
	end
end