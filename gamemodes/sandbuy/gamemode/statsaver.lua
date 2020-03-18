local stats = {}

function GetStatSaverData()
	return stats
end

concommand.Add("resetfull", function( ply, cmd, args, argString  )
	if IsValid(ply) and !ply:IsAdmin() then return end
	
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
			v:SetMoney(GetConVar("sbuy_startmoney"):GetInt())
			v:Spawn()
			
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
	
	buylogger.LogReset("full", GetConVar("sbuy_startmoney"):GetInt())
end)

concommand.Add("resetplayers", function( ply, cmd, args, argString )
	if IsValid(ply) and !ply:IsAdmin() then return end
	
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
			v:SetMoney(GetConVar("sbuy_startmoney"):GetInt())
			
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
	
	buylogger.LogReset("players", GetConVar("sbuy_startmoney"):GetInt())
end)

concommand.Add("resetstats", function( ply, cmd, args, argString  )
	if IsValid(ply) and !ply:IsAdmin() then return end
	
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
	
	buylogger.LogReset("stats", "")
end)

if !GetConVar("sbuy_statsaver"):GetBool() then return end

hook.Add("PlayerInitialSpawn", "LoadStats", function(ply)
	print("Initial Spawn")
	
	local plystats = stats[ply:SteamID()]
	if plystats then
		ply:SetFrags(plystats.frags)
		ply:SetDeaths(plystats.deaths)
		
		ply.HasDied = plystats.hasdied
		
		ply.StatSaver_RestoreWeapons = true
		
		ply.DefaultMoneyOverride = plystats.money
		ply.KillstreakOverride = plystats.killstreak
		ply.TotalKillMoney = plystats.killmoney
	end
	
	print("End Initial Spawn")
end)

hook.Add("PlayerLoadout", "LoadSandbuyWeapons", function(ply)
	if ply.StatSaver_RestoreWeapons then
		ply.StatSaver_RestoreWeapons = nil
		
		local plystats = stats[ply:SteamID()]
		print("Restoring weapons")
		if plystats then
			PrintTable(plystats.weps)
			for k,v in pairs(plystats.weps) do
				ply:Give(v.wep, true)
				local wep = ply:GetWeapon(v.wep)
				if v.clip1 >= 0 then
					wep:SetClip1(v.clip1)
				end
				if v.clip2 >= 0 then
					wep:SetClip2(v.clip2)
				end
			end
			
			for k,v in pairs(plystats.ammo) do
				ply:SetAmmo(v, k)
			end
			
			if plystats.activewep != nil then
				ply:SelectWeapon(plystats.activewep)
			end
			
			return true
		end
	end
end)

hook.Add("PlayerDisconnected", "SaveStats", function(ply)
	local weps = {}
	local ammo = {}
	if ply:Alive() then
		for k,v in pairs(ply:GetWeapons()) do
			weps[#weps+1] = {wep=v:GetClass(), clip1=v:Clip1(), clip2=v:Clip2()}
			
			if v:GetPrimaryAmmoType() != -1 then
				ammo[v:GetPrimaryAmmoType()] = ply:GetAmmoCount(v:GetPrimaryAmmoType())
			end
			if v:GetSecondaryAmmoType() != -1 then
				ammo[v:GetSecondaryAmmoType()] = ply:GetAmmoCount(v:GetSecondaryAmmoType())
			end
		end
	end
	
	local plystats = { nick=ply:Nick(), frags=ply:Frags(), deaths=ply:Deaths(), hasdied=ply.HasDied, money=ply:GetMoney(), killstreak=ply:GetKillstreak(), killmoney=ply.TotalKillMoney, weps=weps, ammo=ammo }
	if ply:Alive() and IsValid(ply:GetActiveWeapon()) then
		plystats.activewep = ply:GetActiveWeapon():GetClass()
	end
	
	stats[ply:SteamID()] = plystats
end)