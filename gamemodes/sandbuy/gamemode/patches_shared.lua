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

hook.Remove("Think", "NeuroHeadshotsClientDeathThink")
hook.Remove("PlayerDeathThink", "NeuroWeapons_HeadlessRagdollGore")
hook.Remove("PlayerDeath", "NeuroWeapons_RemoveBrokenHead")
local scaledamage = hook.GetTable()["ScalePlayerDamage"]
if scaledamage and scaledamage["NeuroWeapons_HeadshotKlonk"] then
	local name, chunks = debug.getupvalue(scaledamage["NeuroWeapons_HeadshotKlonk"], 1)
	if name == "Chunks" then
		table.Empty(chunks)
	end
end

hook.Remove( "PostDrawEffects", "RenderWidgets" )
hook.Remove( "PlayerTick", "TickWidgets" )

local weaponoverrides = {
	tfa_cso_dragoncannon = "Launchers & Explosives",
	tfa_cso_m79 = "Launchers & Explosives",
	tfa_cso_m79_gold = "Launchers & Explosives",
	tfa_cso_milkorm32 = "Launchers & Explosives",
	tfa_cso_fglauncher = "Launchers & Explosives",
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
	tfa_cso_mg36_xmas = "Machine Guns", ---???
	tfa_cso_howitzer = "Launchers & Explosives",
	tfa_cso_katyusha = "Launchers & Explosives",
	tfa_cso_tank = "Launchers & Explosives",
	tfa_cso_v2rocket = "Launchers & Explosives",
	tfa_cso_at4 = "Launchers & Explosives",
	tfa_cso_at4ex = "Launchers & Explosives",
	tfa_cso_rpg7 = "Launchers & Explosives",
	tfa_cso_rpg7_v6 = "Launchers & Explosives",
	tfa_cso_rpg7_v8 = "Launchers & Explosives",
	tfa_cso_speargun = "Designated Marksman Rifles",
	tfa_cso_speargun_v6 = "Designated Marksman Rifles",
	tfa_cso_stinger = "Designated Marksman Rifles",
	tfa_cso_dualtacknife = "Melee weapons",
	tfa_cso_tacticalknife = "Melee weapons",
	tfa_cso_tritacknife = "Melee weapons"
}

local categoryoverrides = {
	["Rifle"] = "Assault Rifles",
	["Carbine"] = "Assault Rifles",
	["Weapon"] = "Melee weapons",
	["Dual Guns"] = "Sub-Machine Guns",
	["Dual Sub-Machine Guns"] = "Sub-Machine Guns",
	["Dual Pistols"] = "Pistols & Revolvers",
	["Grenade"] = "Launchers & Explosives",
	["Revolver"] = "Pistols & Revolvers",
	["Pistol"] = "Pistols & Revolvers",
	["melee weapon"] = "Melee weapons"
}

local toolwhitelist = {
	paint = true,
	colour = true,
	--ladder = true,
	material = true,
	simfphyswheeleditor = true
}

local allowed_pickup = {
	sent_flying_bomb = true,
	sent_oldcannon_p = true,
	sent_mortar_p = true
}

hook.Add("PhysgunPickup", "Sandbuy_NerfPhysgun", function(ply, ent)
	if ent:IsVehicle() and !IsValid(ent:GetDriver()) then
		return
	elseif !allowed_pickup[ent:GetClass()] then
		return false
	end
end)

hook.Add("CanTool", "Sandbuy_NerfToolgun", function(ply, trace, tool)
	if ply:IsSuperAdmin() then return end
	
	print(tool)
	if IsValid(trace.Entity) and trace.Entity:IsPlayer() then
		return false
	end
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
	ModifyWeapon("bobs_gun_base", function(wep)
		--print(wep, "BOB'S GOING DOWN")
		function wep:Reload()
				if not IsValid(self) then return end if not IsValid(self.Owner) then return end
			   
				if self.Owner:IsNPC() then
						self.Weapon:DefaultReload(ACT_VM_RELOAD)
				return end
			   
				if self.Owner:KeyDown(IN_USE) then return end
			   
				if self.Silenced then
						self.Weapon:DefaultReload(ACT_VM_RELOAD_SILENCED)
				else
						self.Weapon:DefaultReload(ACT_VM_RELOAD)
				end
			   
				if !self.Owner:IsNPC() then
						if self.Owner:GetViewModel() == nil then self.ResetSights = CurTime() + 3 else
						self.ResetSights = CurTime() + self.Owner:GetViewModel():SequenceDuration()
						end
				end
			   
				if SERVER and self.Weapon != nil then
				if ( self.Weapon:Clip1() < self.Primary.ClipSize ) and !self.Owner:IsNPC() then
				-- //When the current clip < full clip and the rest of your ammo > 0, then
						self.Owner:SetFOV( 0, 0.3 )
						-- //Zoom = 0
						self:SetIronsights(false)
						-- //Set the ironsight to false
						self.Weapon:SetNWBool("Reloading", true)
				end
				local waitdammit = (self.Owner:GetViewModel():SequenceDuration())
				timer.Simple(waitdammit + .1,
						function()
						if self.Weapon == nil then return end
						if not IsValid(self.Owner) then return end
						self.Weapon:SetNWBool("Reloading", false)
						if self.Owner:KeyDown(IN_ATTACK2) and self.Weapon:GetClass() == self.Gun then
								if CLIENT then return end
								if self.Scoped == false then
										self.Owner:SetFOV( self.Secondary.IronFOV, 0.3 )
										self.IronSightsPos = self.SightsPos                                     -- Bring it up
										self.IronSightsAng = self.SightsAng                                     -- Bring it up
										self:SetIronsights(true, self.Owner)
										self.DrawCrosshair = false
								else return end
						elseif self.Owner:KeyDown(IN_SPEED) and self.Weapon:GetClass() == self.Gun then
								if self.Weapon:GetNextPrimaryFire() <= (CurTime() + .03) then
										self.Weapon:SetNextPrimaryFire(CurTime()+0.3)                   -- Make it so you can't shoot for another quarter second
								end
								self.IronSightsPos = self.RunSightsPos                                  -- Hold it down
								self.IronSightsAng = self.RunSightsAng                                  -- Hold it down
								self:SetIronsights(true, self.Owner)                                    -- Set the ironsight true
								self.Owner:SetFOV( 0, 0.3 )
						else return end
						end)
				end
		end
	end)

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
	
	ModifyWeapon("tfa_cso_gungnir_nrm", function(wep)
		wep.Primary.Ammo = "AirboatGun"
	end)
	ModifyWeapon("tfa_cso_gungnir", function(wep)
		wep.Primary.Ammo = "AirboatGun"
	end)
	
	for k,v in pairs(list.GetForEdit("Weapon")) do
		if v.Category == "TFA CS:O" then
			local weptype = weapons.Get(v.ClassName):GetType()
			if weptype and string.find(string.lower(weptype), "grade ", 1, true) then
				weptype = string.sub(weptype, select(2, string.find(string.lower(weptype), "grade ", 1, true))+1)
				weptype = string.Trim(weptype, "Transcendence Grade ")
			end
			if (weptype or weaponoverrides[v.ClassName]) then
				v.Category = "CS:O " .. (weaponoverrides[v.ClassName] or categoryoverrides[weptype] or (weptype .. "s"))
			end
		end
	end
	
	hook.Remove( "PostDrawEffects", "RenderWidgets" )
	hook.Remove( "PlayerTick", "TickWidgets" )
end)