DeriveGamemode( "sandbox" )

// TODO: printdebug( .. )

CreateConVar("sbuy_autoreload", 1, FCVAR_REPLICATED + (SERVER and FCVAR_ARCHIVE or 0), "Enables automatic reloading of prices when setting prices in-game")

include("sh_cami.lua")
include("playermeta.lua")
include("pricer.lua")
include("player_class/player_sandbuy.lua")
include("patches_shared.lua")

DEFINE_BASECLASS( "gamemode_sandbox" )

GM.Name = "Sandbuy"
GM.Author = "FeldrinH"
GM.IsSandboxDerived = true

CAMI.RegisterPrivilege({ Name = "sandbuy.editprices", MinAccess = "admin" })
CAMI.RegisterPrivilege({ Name = "sandbuy.manageprices", MinAccess = "superadmin" })
CAMI.RegisterPrivilege({ Name = "sandbuy.useadminitems", MinAccess = "admin" })
CAMI.RegisterPrivilege({ Name = "sandbuy.reset", MinAccess = "admin" })
CAMI.RegisterPrivilege({ Name = "sandbuy.logmessage", MinAccess = "admin" })

function GM:GetBuyPrice(ply, class, priceset)
	return pricer.GetPrice(class, priceset) or -2
end

hook.Add("PostGamemodeLoaded", "Sanbuy_ClearAdminOnly", function()
	local itemlist = list.GetForEdit("Weapon")
	for k,v in pairs(itemlist) do
		if v.AdminOnly then
			v.AdminOnly = nil
		end
	end
	itemlist = list.GetForEdit("SpawnableEntities")
	for k,v in pairs(itemlist) do
		v.AdminOnly = nil
		if scripted_ents.GetStored(k) then
			scripted_ents.GetStored(k).t.AdminOnly = nil
		end
	end
end)