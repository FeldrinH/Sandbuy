local meta = FindMetaTable("Player")

if CLIENT then
	function meta:GetMoney()
		return self:GetDTInt(0)
	end
end

function meta:AddMoney(delta)
	self:SetMoney(self:GetMoney() + delta)
end

if SERVER then
	function meta:GetBailoutBonus()
		return math.floor(math.sqrt(0.25 + self.TotalKillMoney / 1500) - 0.5) * 50
	end
end