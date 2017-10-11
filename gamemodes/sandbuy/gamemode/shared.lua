DeriveGamemode( "sandbox" )

include("playermeta.lua")
include("pricer.lua")
include("player_class/player_sandbuy.lua")
include("patches_shared.lua")

DEFINE_BASECLASS( "gamemode_sandbox" )

GM.Name = "Sandbuy"
GM.Author = "FeldrinH"
GM.IsSandboxDerived = true

local toolwhitelist = {
	paint = true,
	ladder = true
}

function GM:CanTool(ply, trace, tool)
	--print(tool)
	return toolwhitelist[tool] and BaseClass.CanTool(self, ply, trace, tool) or false
end