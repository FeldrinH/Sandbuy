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
	function meta:AddKillstreak(killcount)
		self:SetKillstreak(self:GetKillstreak() + killcount)
	end
	
	function meta:AddTotalKillMoney(bailoutmoney)
		self.TotalKillMoney = math.max(self.TotalKillMoney + bailoutmoney / GetConVar("sbuy_levelsize"):GetInt(), 0)
	end
end