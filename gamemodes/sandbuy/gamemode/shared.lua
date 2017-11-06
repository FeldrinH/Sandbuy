DeriveGamemode( "sandbox" )

include("playermeta.lua")
include("pricer.lua")
include("player_class/player_sandbuy.lua")
include("patches_shared.lua")

DEFINE_BASECLASS( "gamemode_sandbox" )

GM.Name = "Sandbuy"
GM.Author = "FeldrinH"
GM.IsSandboxDerived = true