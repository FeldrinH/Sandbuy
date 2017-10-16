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

game.AddAmmoType({name = "Shuriken"})

hook.Add("OnGamemodeLoaded", "Sandbuy_ChangeAmmo", function()
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