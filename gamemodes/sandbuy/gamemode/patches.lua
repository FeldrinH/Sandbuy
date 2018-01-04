--local blocked_ammo = {[10]=true, [30]=true, [32]=true, [33]=true, [35]=true, [37]=true}

if GetConVar("sbuy_noundo"):GetBool() then
	local allowed_undo = {
		--["Ladder"] = true,
		--["Ladder Dismount"] = true
	}
	
	if !undo.CreateRaw then
		undo.CreateRaw = undo.Create
	end
	
	undo.Create = function(uname)
		--print(uname)
		if allowed_undo[uname] then
			return undo.CreateRaw(uname)
		end
	end
end

hook.Add("PlayerCanPickupWeapon","FixPickupWhenWeaponNotMoving", function(ply, wep)
	if IsValid(wep:GetPhysicsObject()) then
		wep:GetPhysicsObject():ApplyForceCenter(Vector(0,0,50))
	end
end)

hook.Add("PlayerCanPickupWeapon","ReduceSLAMDefaultAmmo", function(ply, wep)
	if wep:GetClass() == "weapon_slam" then
		if wep.HasGivenAmmo then
			wep:Remove()
			return false
		elseif ply:HasWeapon("weapon_slam") then
			wep.HasGivenAmmo = true
			ply:GiveAmmo(1, "slam")
		
			wep:Remove()
			return false
		end
	end
end)

hook.Add("WeaponEquip","ReduceSLAMDefaultAmmo", function(wep, ply)
	if wep:GetClass() == "weapon_slam" then
		timer.Simple(0, function()
			if !IsValid(ply) or !ply:Alive() then return end
			ply:RemoveAmmo(2, "slam")
		end)
	end
end)

local allowed_freeze = {
	sent_oldcannon_p = true,
	sent_mortar_p = true
}

hook.Add("OnPhysgunFreeze", "Sandbuy_NerfPhysgun", function(wep, physobj, ent, ply)
	if !allowed_freeze[ent:GetClass()] then
		return false
	end
end)

hook.Add("PlayerLoadout","NeuroPlanes_LoadWeapons", function(ply)
	return ply:NeuroPlanes_LoadWeapons()
end)

hook.Add("OnEntityCreated", "LimitProxySpam", function(ent)
	if ent:GetClass() == "m9k_proxy" then
		local entcount = #ents.FindByClass("m9k_proxy")
		if entcount == 3 then
			PrintMessage(HUD_PRINTTALK, "[GLOBAL] Proxy Mine limit has been reached. Placing more mines is inadvisable.")
		elseif entcount > 3 then
			timer.Simple(0, function() 
				ent:Explosion()
			end)
		end
	elseif ent:GetClass() == "npc_tripmine" then
		local entcount = #ents.FindByClass("npc_tripmine")
		if entcount == 4 then
			PrintMessage(HUD_PRINTTALK, "SLAM limit has been reached. Placing more tripmines is inadvisable.")
		elseif entcount > 4 then
			ent:TakeDamage(1000, ent, ent)
		end
	end
end)

hook.Add("PlayerSwitchWeapon", "ReportProxyLimit", function( ply, oldWpn, newWpn )
	if !ply:Alive() then return end
	if newWpn:GetClass() == "m9k_proxy_mine" then
		if #ents.FindByClass("m9k_proxy") >= 3 then
			ply:PrintMessage(HUD_PRINTTALK, "Proxy Mine limit has been reached. Placing more mines is inadvisable.")
		else
			ply:PrintMessage(HUD_PRINTTALK, "Proxy Mine limit has not been reached. It is safe to place mines.")
		end
	elseif newWpn:GetClass() == "weapon_slam" then
		if #ents.FindByClass("npc_tripmine") >= 4 then
			ply:PrintMessage(HUD_PRINTTALK, "SLAM limit has been reached. Placing more tripmines is inadvisable.")
		else
			ply:PrintMessage(HUD_PRINTTALK, "SLAM limit has not been reached. It is safe to place tripmines.")
		end
	end
end)

hook.Add("OnGamemodeLoaded", "Sandbuy_ChangeAmmo", function()
	local mine_ent = scripted_ents.GetStored("sent_land_mine")
	function mine_ent.t:StartTouch( ent )
		if( self.Destroyed ) then return end
		if ( !IsValid( ent ) or ( !IsValid( self.Spawner ) ) ) then return end

		if( ent:IsPlayer() && self.Spawner:IsPlayer() ) then
			
			for k,v in pairs( player.GetAll() ) do
				
				if( self.Spawner == ent ) then
					net.Start( "NeuroTec_MissileBase_Text" )
						net.WriteInt( 3, 32 )
						net.WriteString( ent:Name() )
					net.Send( v )
				else
					net.Start( "NeuroTec_MissileBase_Text" )
						net.WriteInt( 4, 32 )
						net.WriteString( ent:Name() )
						net.WriteString( self.Spawner:Name() )
					net.Send( v )
				end
			end
		end
		
		self:EmitSound( "ambient/machines/catapult_throw.wav", 100, math.random(97,104) )
		self:EmitSound("ambient/explosions/explode_1.wav",511,100)
		
		local spawner = self.Spawner

		local p = self:GetPos() + Vector( 0,0,32 )

		if( !spawner ) then self:Remove() return end
		
		local expl = ents.Create("env_explosion")
		expl:SetKeyValue("spawnflags",128)
		expl:SetPos( p )
		expl:Spawn()
		expl:Fire("explode","",0)
		
		ParticleEffect( "ap_impact_dirt", self:GetPos(), Angle(0,0,0), nil )
		
		if ( IsValid( spawner ) ) then
			util.BlastDamage( self, spawner, p, 512, math.random( 500, 1512 ) )
		end
		
		self.Destroyed = true
		
		self:Remove()
		
		return
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
	local restoresuccess = nil
	
	if !self.HasDied and self.NeuroPlanes_SavedWeapons != nil then
		restoresuccess = true
		
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
		
		if self.NeuroPlanes_ActiveWeapon != nil then
			self:SelectWeapon(self.NeuroPlanes_ActiveWeapon)
		end
	end
	
	self.NeuroPlanes_SavedWeapons = nil
	self.NeuroPlanes_ActiveWeapon = nil
	
	return restoresuccess
end