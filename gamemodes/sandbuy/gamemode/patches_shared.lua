if CLIENT then
	language.Add("Shuriken_ammo", "Shuriken")
	language.Add("SniperPenetratedRound_ammo", "Sniper Rounds")
	language.Add("AirboatGun_ammo", "High-Caliber Rounds")
	language.Add("AR2AltFire_ammo", "Plasma Orbs")
	
	cvars.AddChangeCallback("colour_a", function(cvar, oldv, newv)
		if newv != "255" then
			GetConVar("colour_a"):SetString("255")
		end
	end, "Sandbuy_BlockTranspColour")
end

hook.Remove("Think","NeuroHeadshotsClientDeathThink")
hook.Remove("PlayerDeathThink", "NeuroWeapons_HeadlessRagdollGore")
hook.Remove("PlayerDeath", "NeuroWeapons_RemoveBrokenHead")
local name, chunks = debug.getupvalue(hook.GetTable()["ScalePlayerDamage"]["NeuroWeapons_HeadshotKlonk"], 1)
if name == "Chunks" then
	table.Empty(chunks)
end

local toolwhitelist = {
	paint = true,
	colour = true,
	--ladder = true,
	material = true
}

local allowed_pickup = {
	sent_flying_bomb = true,
	sent_oldcannon_p = true,
	sent_mortar_p = true,
	prop_physics = true
}

hook.Add("PhysgunPickup", "Sandbuy_NerfPhysgun", function(ply, ent)
	if ent:IsVehicle() and !IsValid(ent:GetDriver()) then
		return
	elseif !allowed_pickup[ent:GetClass()] then
		return false
	end
end)

hook.Add("CanTool", "Sandbuy_NerfToolgun", function(ply, trace, tool)
	--print(tool)
	if !toolwhitelist[tool] then
		return false
	end
end)

game.AddAmmoType({name = "Shuriken"})

hook.Add("PostGamemodeLoaded", "Sandbuy_ChangeAmmo", function()
	local wep = weapons.GetStored("weapon_neurowep_bow")
	wep.Primary.Ammo = "XBowBolt"

	wep = weapons.GetStored("weapon_neurowep_shuriken")
	wep.Primary.Ammo = "Shuriken"

	wep = weapons.GetStored("weapon_neurowep_stickynade")
	wep.Primary.Ammo = "StickyGrenade"
	
	wep = weapons.GetStored("weapon_neurowep_50cal")
	wep.Primary.Ammo = "SniperPenetratedRound"
	
	wep = weapons.GetStored("weapon_neurowep_50cal_ap")
	wep.Primary.Ammo = "SniperPenetratedRound"
	
	wep = weapons.GetStored("weapon_neurowep_acr10")
	wep.Primary.Ammo = "SniperPenetratedRound"
	
	wep = weapons.GetStored("weapon_neurowep_m24")
	wep.Primary.Ammo = "SniperPenetratedRound"
	
	wep = weapons.GetStored("weapon_neurowep_ptrs41")
	wep.Primary.Ammo = "SniperPenetratedRound"
	
	wep = weapons.GetStored("weapon_neurowep_he44")
	wep.Primary.Ammo = "SMG1_Grenade"
end)