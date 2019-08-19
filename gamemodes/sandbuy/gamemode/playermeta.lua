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
end