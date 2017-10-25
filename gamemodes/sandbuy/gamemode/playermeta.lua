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
		return math.floor(math.sqrt(0.25 + self.TotalKillMoney / (GetConVar("sbuy_killmoney"):GetInt() / 2 * GetConVar("sbuy_levelsize"):GetFloat())) - 0.5) * GetConVar("sbuy_levelbonus"):GetInt()
	end
end