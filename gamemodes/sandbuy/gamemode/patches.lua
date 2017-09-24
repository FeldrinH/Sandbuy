--local blocked_ammo = {[10]=true, [30]=true, [32]=true, [33]=true, [35]=true, [37]=true}

if GetConVar("sbuy_noundo"):GetBool() then
	undo.Do_Undo = function() end
end

hook.Remove("PlayerSpawnSENT", "BlockNuclearSEnts")
hook.Remove("PlayerGiveSWEP", "BlockNukeSWep")
hook.Remove("PlayerSpawnSWEP", "BlockNukeSpawn")

hook.Remove("PlayerSwitchWeapon", "AutoGiveAmmo")
--[[hook.Add("PlayerSwitchWeapon", "AutoGiveAmmo", function(ply, oldWpn, newWpn)
	local primary_ammo = newWpn:GetPrimaryAmmoType()
	if !blocked_ammo[primary_ammo] then
		--print("Score1", primary_ammo)
		ply:SetAmmo( 9999, primary_ammo )
	end
	
	local secondary_ammo = newWpn:GetSecondaryAmmoType()
	if !blocked_ammo[secondary_ammo] then
		--print("Score2", secondary_ammo)
		ply:SetAmmo( 9999, secondary_ammo )
	end
end)]]--

hook.Add("PlayerLoadout","NeuroPlanes_LoadWeapons", function(ply)
	if ply.NeuroPlanes_SavedWeapons then
		ply:NeuroPlanes_LoadWeapons()
		return true
	end
end)

hook.Add("PlayerCanPickupWeapon","FixPickupWhenWeaponNotMoving", function(ply, wep)
	if IsValid(wep:GetPhysicsObject()) then
		wep:GetPhysicsObject():ApplyForceCenter(Vector(0,0,50))
	end
end)

local meta = FindMetaTable( "Player" )

if !meta.StripWeaponsRaw then
	meta.StripWeaponsRaw = meta.StripWeapons
end

function meta:StripWeapons()
	--debug.Trace()
	if !self.HasDied then
		self:NeuroPlanes_SaveWeapons()
	end
	self:StripWeaponsRaw()
end

function meta:NeuroPlanes_SaveWeapons()
	local weps = {}
	for k,v in pairs(self:GetWeapons()) do
		weps[#weps+1] = {wep=v:GetClass(), clip1=v:Clip1(), clip2=v:Clip2()}
	end
	self.NeuroPlanes_SavedWeapons = weps
	
	if IsValid(self:GetActiveWeapon()) then
		self.NeuroPlanes_ActiveWeapon = self:GetActiveWeapon():GetClass()
	end
end

function meta:NeuroPlanes_LoadWeapons()
	if !self.HasDied then
		if self.NeuroPlanes_SavedWeapons != nil then
			self:StripWeaponsRaw()
			
			for k,v in pairs(self.NeuroPlanes_SavedWeapons) do
				self:Give(v.wep,true)
				local wep = self:GetWeapon(v.wep)
				if v.clip1 >= 0 then
					wep:SetClip1(v.clip1)
				end
				if v.clip2 >= 0 then
					wep:SetClip2(v.clip2)
				end
			end
		end
		
		if self.NeuroPlanes_ActiveWeapon != nil then
			self:SelectWeapon(self.NeuroPlanes_ActiveWeapon)
		end
	end
	
	self.NeuroPlanes_SavedWeapons = nil
	self.NeuroPlanes_ActiveWeapon = nil
end