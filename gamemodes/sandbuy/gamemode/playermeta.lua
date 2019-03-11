local meta = FindMetaTable("Player")

if CLIENT then
	function meta:GetMoney()
		return self:GetDTInt(0)
	end
end

function meta:AddMoney(delta)
	self:SetMoney(math.max(self:GetMoney() + delta, 0))
end

if SERVER then
	function meta:AddKillStreak(killcount)
		self.KillStreak = self.KillStreak + killcount
		if !self:Alive() then
			self:SendLua("GAMEMODE:SetDeathMessage(nil," .. self.KillStreak .. ")")
		end
	end

	function meta:GetBailoutBonus()
		return math.floor(math.sqrt(0.25 + self.TotalKillMoney * 2 / self:GetLevelSize()) - 0.5) * self:GetLevelBonus()
	end
	
	function meta:GetBailout()
		return (self.OverrideDefaultMoney or GetConVar("sbuy_defaultmoney"):GetInt()) + self:GetBailoutBonus()
	end
	
	function meta:GetKillMoney()
		return self.OverrideKillMoney or GetConVar("sbuy_killmoney"):GetInt()
	end
	
	function meta:GetLevelBonus()
		return self.OverrideLevelBonus or GetConVar("sbuy_levelbonus"):GetInt()
	end
	
	function meta:GetLevelSize()
		return self.OverrideLevelSize or GetConVar("sbuy_levelsize"):GetFloat()
	end
end