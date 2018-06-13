AddCSLuaFile()

DEFINE_BASECLASS( "player_sandbox" )

local PLAYER = {}

PLAYER.DropWeaponOnDie = true

function PLAYER:SetupDataTables()
	self.Player:NetworkVar("Int", 0, "Money")
	
	if SERVER then
		self.Player:NetworkVarNotify("Money", function(ply, name, old, new)
			--print(ply, "Money Changed Sent")
			net.Start("moneychanged")
			net.WriteInt(new, 32)
			net.Send(ply)
		end)
		
		self.Player:SetMoney(self.Player.DefaultMoneyOverride or GetConVar("sbuy_defaultmoney"):GetInt())
		self.Player.DefaultMoneyOverride = nil
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
