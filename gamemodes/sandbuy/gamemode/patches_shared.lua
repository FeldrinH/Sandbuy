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
local scaledamage = hook.GetTable()["ScalePlayerDamage"]
if scaledamage and scaledamage["NeuroWeapons_HeadshotKlonk"] then
	local name, chunks = debug.getupvalue(scaledamage["NeuroWeapons_HeadshotKlonk"], 1)
	if name == "Chunks" then
		table.Empty(chunks)
	end
end

local weaponoverrides = {
	tfa_cso_dragoncannon = "Explosives",
	tfa_cso_m79 = "Explosives",
	tfa_cso_m79_gold = "Explosives",
	tfa_cso_milkorm32 = "Explosives",
	tfa_cso_fglauncher = "Explosives",
	tfa_cso_mosin = "Sniper Rifles",
	tfa_cso_kbkart2000 = "Sub-Machine Guns",
	tfa_cso_m60g = "Machine Guns",
	tfa_cso_m60 = "Machine Guns",
	tfa_cso_m249_xmas = "Machine Guns",
	tfa_cso_m249camo = "Machine Guns",
	tfa_cso_aeolis = "Machine Guns",
	tfa_cso_cameragun = "Machine Guns",
	tfa_cso_negev = "Machine Guns",
	tfa_cso_avalanche = "Machine Guns",
	tfa_cso_k3 = "Machine Guns",
	tfa_cso_ultimax100 = "Machine Guns", --?
	tfa_cso_balrog7 = "Machine Guns",
	tfa_cso_m134_vulcan = "Machine Guns",
	tfa_cso_mk48_expert = "Machine Guns",
	tfa_cso_m249ep = "Machine Guns",
	tfa_cso_m2 = "Machine Guns",
	tfa_cso_hk121_custom = "Machine Guns",
	tfa_cso_m249 = "Machine Guns",
	tfa_cso_turbulent7 = "Machine Guns",
	tfa_cso_m2_v6 = "Machine Guns",
	tfa_cso_m2_v8 = "Machine Guns",
	tfa_cso_m60craft = "Machine Guns",
	tfa_cso_mg3xmas = "Machine Guns",
	tfa_cso_mg42 = "Machine Guns",
	tfa_cso_mk48 = "Machine Guns",
	tfa_cso_mk48_master = "Machine Guns",
	tfa_cso_charger7 = "Machine Guns",
	tfa_cso_m60_v6 = "Machine Guns",
	tfa_cso_skull8 = "Machine Guns", --???
	tfa_cso_thanatos7 = "Machine Guns",
	tfa_cso_mg3g = "Machine Guns",
	tfa_cso_m60_v8 = "Machine Guns",
	tfa_cso_mg3 = "Machine Guns",
	tfa_cso_m249ex = "Machine Guns", --?
	tfa_cso_skull6 = "Machine Guns", --???
	tfa_cso_mg36 = "Machine Guns", ---???
	tfa_cso_mg36_xmas = "Machine Guns" ---???
}

local categoryoverrides = {
	["Rifle"] = "Assault Rifles",
	["Carbine"] = "Assault Rifles",
	["Weapon"] = "Melee",
	["Dual Guns"] = "Sub-Machine Guns",
	["Dual Sub-Machine Guns"] = "Sub-Machine Guns",
	["Dual Pistols"] = "Pistols & Revolvers",
	["Grenade"] = "Explosives",
	["Revolver"] = "Pistols & Revolvers",
	["Pistol"] = "Pistols & Revolvers"
}

local toolwhitelist = {
	paint = true,
	colour = true,
	--ladder = true,
	material = true
}

local allowed_pickup = {
	sent_flying_bomb = true,
	sent_oldcannon_p = true,
	sent_mortar_p = true
}

hook.Add("PhysgunPickup", "Sandbuy_NerfPhysgun", function(ply, ent)
	--if ent:IsVehicle() and !IsValid(ent:GetDriver()) then
	--	return
	if !allowed_pickup[ent:GetClass()] then
		return false
	end
end)

hook.Add("CanTool", "Sandbuy_NerfToolgun", function(ply, trace, tool)
	--print(tool)
	if !toolwhitelist[tool] then
		return false
	end
end)

local function ModifyWeapon(wepclass, modfunc)
	local wep = weapons.GetStored(wepclass)
	if wep then
		modfunc(wep)
	end
end

game.AddAmmoType({name = "Shuriken"})

hook.Add("PostGamemodeLoaded", "Sandbuy_ChangeAmmo", function()
	ModifyWeapon("weapon_neurowep_bow", function(wep)
		wep.Primary.Ammo = "XBowBolt"
	end)
	ModifyWeapon("weapon_neurowep_shuriken", function(wep)
		wep.Primary.Ammo = "Shuriken"
	end)
	ModifyWeapon("weapon_neurowep_stickynade", function(wep)
		wep.Primary.Ammo = "StickyGrenade"
	end)
	ModifyWeapon("weapon_neurowep_50cal", function(wep)
		wep.Primary.Ammo = "SniperPenetratedRound"
	end)
	ModifyWeapon("weapon_neurowep_50cal_ap", function(wep)
		wep.Primary.Ammo = "SniperPenetratedRound"
	end)
	ModifyWeapon("weapon_neurowep_acr10", function(wep)
		wep.Primary.Ammo = "SniperPenetratedRound"
	end)
	ModifyWeapon("weapon_neurowep_m24", function(wep)
		wep.Primary.Ammo = "SniperPenetratedRound"
	end)
	ModifyWeapon("weapon_neurowep_ptrs41", function(wep)
		wep.Primary.Ammo = "SniperPenetratedRound"
	end)
	ModifyWeapon("weapon_neurowep_he44", function(wep)
		wep.Primary.Ammo = "SMG1_Grenade"
	end)
	
	for k,v in pairs(list.GetForEdit("Weapon")) do
		if v.Category == "TFA CS:O" then
			local weptype = weapons.Get(v.ClassName):GetType()
			v.Category = "CS:O " .. (weaponoverrides[v.ClassName] or categoryoverrides[weptype] or (weptype .. "s"))
		end
	end
end)