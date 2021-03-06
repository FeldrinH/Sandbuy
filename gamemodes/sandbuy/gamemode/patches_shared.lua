patcher = patcher or {}

local ammooverrides = {}
function patcher.AddAmmoOverride(wepclass, primary, secondary)
	ammooverrides[wepclass] = {p = primary, s = secondary}
end

local function ModifyWeapon(wepclass, modfunc)
	local wep = weapons.GetStored(wepclass)
	if wep then
		modfunc(wep)
	end
end
patcher.ModifyWeapon = ModifyWeapon

local function ModifyEntity(wepclass, modfunc)
	local wep = scripted_ents.GetStored(wepclass)
	if wep and wep.t then
		modfunc(wep.t)
	end
end
patcher.ModifyEntity = ModifyEntity

//include('custom_buy.lua')

game.AddAmmoType({name = "Shuriken"})
game.AddAmmoType({name = "Molotov"})
game.AddAmmoType({name = "TearGas"})

if CLIENT then
	language.Add("Shuriken_ammo", "Shuriken")
	language.Add("Molotov_ammo", "Molotov")
	language.Add("TearGas_ammo", "Tear Gas Grenades")
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
	hook.Add("ScalePlayerDamage", "NeuroWeapons_HeadshotKlonk", function( ply, hitgroup, dmginfo )
		
		if( ply:HasGodMode() ) then return end 
		
		if( GetConVarNumber("neuroweapons_headshotsound") == 0 ) then return end 
		local atk = dmginfo:GetAttacker()
		if !IsValid(atk) then return end
		local damage = dmginfo:GetDamage() 
		local PlayerGear = ply.NeuroArmor
		local stoptheshow, damagescale = ply:IsHitgroupProtected( hitgroup, dmginfo ) 
		local dist = ( ply:GetPos() - atk:GetPos() ):Length()
		-- print( dist, damage )
		
		ply.LastHitgroupHit = hitgroup 
		ply.LastDamageTaken = damage 
		if( SERVER ) then 
		
			ply:NeuroWeapons_SendBloodyScreen()
			if( atk:IsPlayer() && ( atk:GetPos() - ply:GetPos() ):Length() < 72 ) then 
				
				atk:NeuroWeapons_SendBloodyScreen()
			end 
			
		end 
		
		if( stoptheshow ) then 
			
			dmginfo:ScaleDamage( damagescale )
			
			return
			
		end 
		if ( hitgroup == HITGROUP_HEAD ) then
			
			-- ply:SetNWBool("HeadshotIcon", true )	
			ply.HeadshotIcon = true 
		
		end 
	end )
end

local adjustmouse = hook.GetTable()["AdjustMouseSensitivity"]
if adjustmouse and adjustmouse["NeuroTanksAdjustSensitivity"] then
	hook.Add("AdjustMouseSensitivity", "NeuroTanksAdjustSensitivity", function(default_sensitivity)
		local ply = LocalPlayer()
		local tank = ply:GetScriptedVehicle()
		
		if tank.VehicleType && ( tank.VehicleType == VEHICLE_TANK || tank.VehicleType == STATIC_GUN ) then
			local thirdperson = tank.MouseScale3rdPerson or 0.295
			local firstperson = tank.MouseScale1stPerson or 0.15
			
			if GetConVarNumber("sensitivity", 0) > 15 then
				thirdperson = thirdperson / GetConVarNumber("sensitivity", 0 )
				firstperson = firstperson / GetConVarNumber("sensitivity", 0 )
			end
			
			if GetConVarNumber("jet_cockpitview", 0) > 0 then
				return firstperson
			else
				return thirdperson
			end
		end
	end)
end
if adjustmouse and adjustmouse["AdjustNavalZoomSensitvity"] then
	hook.Add("AdjustMouseSensitivity","AdjustNavalZoomSensitvity", function(sens)
		local ply = LocalPlayer()
		
		if ply.zoomValue && IsValid( ply:GetScriptedVehicle() ) && ply:GetScriptedVehicle().IsMicroCruiser then
			ply.sensitivityFraction = ply.zoomValue / DEFAULT_ZOOM
			return math.Clamp( ply.sensitivityFraction, 0, 1 )
		end
	end)
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

hook.Add("CanProperty", "Sandbuy_NerfProperties", function(ply, property, ent)
	if ply:IsSuperAdmin() and GetConVar("sbuy_debug"):GetBool() then return end

	if !pricer.InCategory(property, 'allowedproperty') then
		print(property)
		return false
	end
end)

hook.Add("CanEditVariable", "Sandbuy_NerfProperties", function(ent, ply, variable, val)
	if ply:IsSuperAdmin() and GetConVar("sbuy_debug"):GetBool() then return end

	if !pricer.InCategory(ent:GetClass(), 'allowededit') then
		return false
	end
end)

patcher.AddAmmoOverride("weapon_neurowep_bow", "XBowBolt")
patcher.AddAmmoOverride("weapon_neurowep_shuriken", "Shuriken")
patcher.AddAmmoOverride("weapon_neurowep_stickynade", "StickyGrenade")
patcher.AddAmmoOverride("weapon_neurowep_50cal", "SniperPenetratedRound")
patcher.AddAmmoOverride("weapon_neurowep_50cal_ap", "SniperPenetratedRound")
patcher.AddAmmoOverride("weapon_neurowep_acr10", "SniperPenetratedRound")
patcher.AddAmmoOverride("weapon_neurowep_m24", "SniperPenetratedRound")
patcher.AddAmmoOverride("weapon_neurowep_ptrs41", "SniperPenetratedRound")
patcher.AddAmmoOverride("weapon_neurowep_he44", "SMG1_Grenade")
patcher.AddAmmoOverride("weapon_neurowep_molotov", "Molotov")
patcher.AddAmmoOverride("weapon_neurowep_teargas", "TearGas")

patcher.AddAmmoOverride("tfa_cso_gungnir_nrm", "AirboatGun")
patcher.AddAmmoOverride("tfa_cso_gungnir", "AirboatGun")

hook.Add("PostGamemodeLoaded", "Sandbuy_ChangeAmmo", function()
	if CLIENT then
		ModifyWeapon("weapon_neurowep_base", function(wep)
			function wep:AdjustMouseSensitivity()
				return -1
			end
		end)

		ModifyEntity("cw_attpack_base", function(ent)
			local baseFont = "CW_HUD72"
			local up = Vector(0, 0, 15)
			local white, black, green = Color(255, 255, 255, 255), Color(0, 0, 0, 255), Color(215, 255, 160, 255)
			local gray = Color(180, 180, 180, 255)
			local drawShadowText = draw.ShadowText
			local surfaceSetDrawColor = surface.SetDrawColor
			local surfaceDrawRect = surface.DrawRect
			
			function ent:Draw()
				self:DrawModel()
				
				if not self.halfHorizontalSize then
					return
				end
				
				local ply = LocalPlayer()
				
				self.inRange = not (ply:GetPos():Distance(self:GetPos()) > self.displayDistance)
				
				if not self.inRange then
					return
				end
				
				local eyeAng = EyeAngles()
				eyeAng.p = 0
				eyeAng.y = eyeAng.y - 90
				eyeAng.r = 90
				
				cam.Start3D2D(self:GetPos() + up, eyeAng, 0.05)
					local r, g, b, a = self:getTopPartColor()
					surfaceSetDrawColor(r, g, b, a)
					surfaceDrawRect(-self.halfHorizontalSize, -self.basePos, self.horizontalSize, self.verticalFontSize)
					
					surfaceSetDrawColor(0, 0, 0, 150)
					surfaceDrawRect(-self.halfHorizontalSize, -self.blackBarPos, self.horizontalSize, self.verticalSize - 10)
					
					drawShadowText(self:getMainText(), baseFont, 0, self.arraySize * -self.verticalFontSize, white, black, 2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
					
					for k, v in ipairs(self.attachmentNames) do
						if ply.CWAttachments[v.name] then
							drawShadowText(v.display, baseFont, 0, v.vertPos, self:getNoAttachmentColor(), black, 2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
						else
							drawShadowText(v.display, baseFont, 0, v.vertPos, self:getAttachmentColor(), black, 2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
						end
					end
				cam.End3D2D()
			end
		end)
	end

	ModifyWeapon("fas2_m67", function(wep)
		wep.Primary.DefaultClip = 1
	end)
	
	ModifyWeapon("fas2_m79", function(wep)
		wep.ExtraMags = 0
		wep.Primary.DefaultClip = 3
	end)
	
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
	
	for k,v in pairs(ammooverrides) do
		ModifyWeapon(k, function(wep)
			if v.p then
				wep.Primary.Ammo = v.p
			end
			if v.s then
				wep.Secondary.Ammo = v.s
			end
		end)
	end
	function patcher.AddAmmoOverride(wepclass, primary, secondary)
		error('patcher.AddAmmoOverride does not work after gamemode has been loaded')
	end
	
	for k,v in pairs(weapons.GetList()) do
		if v.FirstDeployTime and v.FirstDeployTime > 0.45 then
			v.FirstDeployTime = 0.45
		end
	end
	
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