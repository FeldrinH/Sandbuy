if CLIENT then
	language.Add("Shuriken_ammo", "Shuriken")
	language.Add("SniperPenetratedRound_ammo", "Sniper Rounds")
	language.Add("AirboatGun_ammo", "High-Caliber Rounds")
	language.Add("AR2AltFire_ammo", "Plasma Orbs")
end

game.AddAmmoType({name = "Shuriken"})

hook.Add("OnGamemodeLoaded", "Sandbuy_ChangeAmmo", function()
	local wep = weapons.GetStored("weapon_neurowep_bow")
	wep.Primary.Ammo = "XBowBolt"

	wep = weapons.GetStored("weapon_neurowep_shuriken")
	wep.Primary.Ammo = "Shuriken"

	--wep = weapons.GetForEdit("weapon_neurowep_stickynade")
	--wep.Primary.Ammo = "StickyGrenade"
end)