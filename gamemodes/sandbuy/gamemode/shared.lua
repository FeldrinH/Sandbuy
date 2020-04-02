DeriveGamemode( "sandbox" )

include("playermeta.lua")
include("pricer.lua")
include("player_class/player_sandbuy.lua")
include("patches_shared.lua")

DEFINE_BASECLASS( "gamemode_sandbox" )

GM.Name = "Sandbuy"
GM.Author = "FeldrinH"
GM.IsSandboxDerived = true

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