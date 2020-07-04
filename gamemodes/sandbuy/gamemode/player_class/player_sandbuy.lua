AddCSLuaFile()

DEFINE_BASECLASS( "player_sandbox" )

local PLAYER = {}

if SERVER then
	PLAYER.DropWeaponOnDie = GetConVar("sbuy_dropweapon"):GetBool()
end
PLAYER.TeammateNoCollide = false

if SERVER then
	cvars.AddChangeCallback("sbuy_dropweapon", function(convar, old, new)
		local newbool = tobool(new)
		PLAYER.DropWeaponOnDie = newbool
		for k,v in pairs(player.GetAll()) do
			v:ShouldDropWeapon(newbool)
		end
	end, "Sandbuy_ToggleDropWeapon")
end

function PLAYER:SetupDataTables()
	self.Player:NetworkVar("Int", 0, "Money")
	self.Player:NetworkVar("Int", 1, "Killstreak")
	
	if SERVER then
		self.Player:NetworkVarNotify("Money", function(ply, name, old, new)
			--print(ply, "Money Changed Sent")
			net.Start("moneychanged")
			net.WriteInt(new, 32)
			net.Send(ply)
		end)
		
		self.Player:SetMoney(0)
		self.Player:SetKillstreak(0)
	end

	return BaseClass.SetupDataTables(self)
end

function PLAYER:Loadout()
	self.Player:RemoveAllAmmo()
end

function PLAYER:Spawn()
	BaseClass.Spawn(self)
	
	self.Player:SetCanZoom(false)
end

player_manager.RegisterClass( "player_sandbuy", PLAYER, "player_sandbox" )
