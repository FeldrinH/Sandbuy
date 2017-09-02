local stats = {}

concommand.Add("resetstats", function( ply )
	if !ply:IsAdmin() and ply:Nick() != "FeldrinH" then return end
	
	for k,v in pairs(player.GetAll()) do
		v:SetFrags(0)
		v:SetDeaths(0)
		v.HasDied = true
		v:StripWeaponsRaw()
		v:RemoveAllAmmo()
		v:SetMoney(pricer.DefaultMoney)
		v.TotalKillMoney = 0
		v:Spawn()
	end
	
	stats = {}
	
	buylogger.LogReset(pricer.DefaultMoney)
end)

if !GetConVar("sbuy_statsaver"):GetBool() then return end

hook.Add("PlayerInitialSpawn", "LoadStats", function(ply)
	local plystats = stats[ply:SteamID()]
	if plystats then
		ply:SetFrags(plystats.frags)
		ply:SetDeaths(plystats.deaths)
		
		ply.HasDied = plystats.hasdied
		ply.LastDeathSuicide = plystats.lastdeathsuicide
		
		ply.StatSaver_RestoreWeapons = true
		
		ply.DefaultMoneyOverride = plystats.money
		ply.TotalKillMoney = plystats.killmoney
	end
end)

hook.Add("PlayerLoadout", "LoadSandbuyWeapons", function(ply)
	if ply.StatSaver_RestoreWeapons then
		ply.StatSaver_RestoreWeapons = nil
		
		local plystats = stats[ply:SteamID()]
		if plystats then
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
	
	local plystats = { frags=ply:Frags(), deaths=ply:Deaths(), hasdied=ply.HasDied, lastdeathsuicide=ply.LastDeathSuicide, money=ply:GetMoney(), killmoney=ply.TotalKillMoney, weps=weps, ammo=ammo }
	if ply:Alive() and IsValid(ply:GetActiveWeapon()) then
		plystats.activewep = ply:GetActiveWeapon():GetClass()
	end
	
	stats[ply:SteamID()] = plystats
end)