patcher = patcher or {}

--local blocked_ammo = {[10]=true, [30]=true, [32]=true, [33]=true, [35]=true, [37]=true}

local function UpdateUndo(cvarname, old, new)
	if tobool(new) then
		local allowed_undo = {
			--["Ladder"] = true,
			--["Ladder Dismount"] = true
		}
		
		undo.Create = function(uname)
			--print(uname)
			if allowed_undo[uname] then
				return undo.CreateRaw(uname)
			end
		end
	else
		undo.Create = undo.CreateRaw
	end
end

if !undo.CreateRaw then
	undo.CreateRaw = undo.Create
end
UpdateUndo(nil, nil, GetConVar("sbuy_noundo"):GetString())
cvars.AddChangeCallback("sbuy_noundo", UpdateUndo, "undodisable")

hook.Remove("PlayerSwitchWeapon","TFABashFixZoom")

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

--[[hook.Add("OnPhysgunFreeze", "Sandbuy_NerfPhysgun", function(wep, physobj, ent, ply)
	if !allowed_freeze[ent:GetClass()] then
		return false
	end
end)]]

hook.Add("PlayerLoadout","NeuroPlanes_LoadWeapons", function(ply)
	return ply:NeuroPlanes_LoadWeapons()
end)

local mines_class = {}
local mines_weapon = {}

function patcher.RegisterMine(entity_class, weapon_class, print_name, get_owner_func, detonate_func)
	local dat = { name = print_name, ent = entity_class, wep = weapon_class, ownerf = get_owner_func, detonatef = detonate_func }
	mines_class[entity_class] = dat
	mines_weapon[weapon_class] = dat
end

function patcher.UnregisterMine(entity_class)
	local weapon_class = mines_class[entity_class].wep
	mines_class[entity_class] = nil
	mines_weapon[weapon_class] = nil
end

local function FindPredictedOwner(ent, dat)
	local pos = ent:GetPos()
	local closest = nil
	local dist = 40000
	for k,v in pairs(player.GetAll()) do
		if pos:DistToSqr(v:GetPos()) < dist and v:GetActiveWeapon():GetClass() == dat.wep then
			closest = v
			dist = pos:DistToSqr(v:GetPos())
		end
	end
	return closest
end

local function FindOldMine(ply, class)
	for k,v in pairs(ents.FindByClass(class)) do
		if v.PredictedOwner == ply then return v end
	end
end

hook.Add("OnEntityCreated", "LimitProxySpam", function(ent)
	if mines_class[ent:GetClass()] then
		local dat = mines_class[ent:GetClass()]
		
		timer.Simple(0, function()
			if !IsValid(ent) then return end
		
			local predictedowner = dat.ownerf(ent, dat)
			if !IsValid(predictedowner) then print("WARNING: No owner found for mine " .. tostring(ent)) return end
			
			local oldproxy = FindOldMine(predictedowner, dat.ent)
			if IsValid(oldproxy) then
				dat.detonatef(oldproxy, dat)
			end
			
			ent.PredictedOwner = predictedowner
		end)
	end
end)

hook.Add("PlayerSwitchWeapon", "ReportProxyLimit", function( ply, oldWpn, newWpn )
	if !ply:Alive() then return end
	if mines_weapon[newWpn:GetClass()] then
		local dat = mines_weapon[newWpn:GetClass()]
		if IsValid(FindOldMine(ply, dat.ent)) then
			ply:PrintMessage(HUD_PRINTTALK, "You have a " .. dat.name .. " deployed. Placing another one will destroy the previous " .. dat.name .. ".")
		end
	end
end)

patcher.RegisterMine("m9k_proxy", "m9k_proxy_mine", "proxy", FindPredictedOwner, function(ent) 
	ent:Explosion()
end)
patcher.RegisterMine("npc_tripmine", "weapon_slam", "SLAM", FindPredictedOwner, function(ent) 
	ent:TakeDamage(1000, ent, ent)
end)

hook.Add("OnGamemodeLoaded", "Sandbuy_ChangeAmmo", function()
	local mine_ent = scripted_ents.GetStored("sent_land_mine")
	if !mine_ent then return end
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

hook.Add("DoPlayerDeath", "KillCountingFix", function(ply, atk, dmginfo)
	if IsValid( atk ) && atk:IsVehicle() && IsValid( atk:GetDriver() ) then
		atk = atk:GetDriver()
		
		if atk == ply then
			atk:AddFrags( -1 )
		else
			atk:AddFrags( 1 )
		end
	end
	
	if atk:IsPlayer() and ply:Team() != TEAM_UNASSIGNED and ply:Team() == atk:Team() and ply != atk then
		atk:AddFrags(-2)
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