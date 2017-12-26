--local blocked_ammo = {[10]=true, [30]=true, [32]=true, [33]=true, [35]=true, [37]=true}

if GetConVar("sbuy_noundo"):GetBool() then
	local allowed_undo = {
		["Ladder"] = true,
		["Ladder Dismount"] = true
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
	if wep:GetClass() == "weapon_slam" and ply:HasWeapon("weapon_slam") then
		if wep.HasGivenAmmo == nil then
			wep.HasGivenAmmo = true
			ply:GiveAmmo(1, "slam")
		end
		
		wep:Remove()
		return false
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

-- Bad temporary paying system. Move later
hook.Add("CanTool", "Sandbuy_TweakLadderTool", function(ply, trace, tool)
	if tool == "ladder" then
		if trace.HitSky then return false end
		
		local price = pricer.LadderPrice
		local tool = ply:GetTool()
		if tool:GetStage() != 0 and debug.getinfo(3, "S").linedefined == 208 then
			if ply:GetMoney() >= price then
				ply:AddMoney(-price)
				buylogger.LogBuy(ply, "ladder", "tool", ply:GetMoney(), -price)
				
				ply:PrintMessage(HUD_PRINTCENTER, "Ladder bought for $" .. price)
				ply:SendLua("surface.PlaySound('sandbuy/kaching.wav')")
				
				return
			else
				tool:SetStage(0)
				tool:ClearObjects()
				
				ply:PrintMessage(HUD_PRINTCENTER, "Need $" .. price .. " to buy ladder")
				ply:SendLua("surface.PlaySound('sandbuy/denied.wav')")
				
				return false
			end
		end
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

timer.Remove("ladder_SaveData")

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