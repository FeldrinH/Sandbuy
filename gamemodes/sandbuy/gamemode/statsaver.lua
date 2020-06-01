local stats = {}

function GetStatSaverData()
	return stats
end

concommand.Add("resetfull", function( ply, cmd, args, argString  )
	if IsValid(ply) and !CAMI.PlayerHasAccess(ply, "sandbuy.reset") then return end
	
	buylogger.LogReset("full", argString)
	
	for k,v in pairs(player.GetAll()) do
		if argString == "" or argString == v:Nick() then
			v:SetFrags(0)
			v:SetDeaths(0)
			v.HasDied = true
			v:StripWeaponsRaw()
			v:RemoveAllAmmo()
			v.NeuroPlanes_SavedWeapons = nil
			v.NeuroPlanes_ActiveWeapon = nil
			v.TotalKillMoney = 0
			v:SetMoney(hook.Run("GetStartMoney", v))
			v:Spawn()
			
			buylogger.LogStartingBailout(v, v:GetMoney(), v:GetMoney())
			
			if argString != "" then
				targetid = v:SteamID()
			end
		end
	end
	
	if argString == "" then
		stats = {}
	elseif targetid then
		stats[targetid] = nil
	end
end)

concommand.Add("resetplayers", function( ply, cmd, args, argString )
	if IsValid(ply) and !CAMI.PlayerHasAccess(ply, "sandbuy.reset") then return end
	
	buylogger.LogReset("players", argString)
	
	local targetid = nil
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
				targetid = v:SteamID()
			end
		end
	end
	
	if argString == "" then
		stats = {}
	elseif targetid then
		stats[targetid] = nil
	end
end)

concommand.Add("resetstats", function( ply, cmd, args, argString  )
	if IsValid(ply) and !CAMI.PlayerHasAccess(ply, "sandbuy.reset") then return end
	
	buylogger.LogReset("stats", argString)
	
	for k,v in pairs(player.GetAll()) do
		if argString == "" or argString == v:Nick() then
			v:SetFrags(0)
			v:SetDeaths(0)
			
			if argString != "" then
				targetid = v:SteamID()
			end
		end
	end
	
	if argString == "" then
		for k,v in pairs(stats) do
			v.frags = 0
			v.deaths = 0
		end
	elseif targetid then
		local plystats = stats[targetid]
		if plystats then
			plystats.frags = 0
			plystats.deaths = 0
		end
	end
end)

if !GetConVar("sbuy_statsaver"):GetBool() then return end

hook.Add("PlayerInitialSpawn", "LoadStats", function(ply)
	print("Initial Spawn")
	
	local plystats = stats[ply:SteamID()]
	if plystats then
		ply:SetFrags(plystats.frags)
		ply:SetDeaths(plystats.deaths)
		
		ply.DefaultMoneyOverride = plystats.money
		ply.KillstreakOverride = plystats.killstreak
		ply.TotalKillMoney = plystats.killmoney

		ply.HasDied = true
		
		hook.Call("LoadStatSaver", nil, ply, plystats)
	end
	
	print("End Initial Spawn")
end)

hook.Add("PlayerDisconnected", "SaveStats", function(ply)
	local plystats = { frags=ply:Frags(), deaths=ply:Deaths(), money=ply:GetMoney(), killstreak=ply:GetKillstreak(), killmoney=ply.TotalKillMoney }
	
	hook.Call("SaveStatSaver", nil, ply, plystats)
	
	stats[ply:SteamID()] = plystats
end)