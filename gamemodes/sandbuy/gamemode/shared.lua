DeriveGamemode( "sandbox" )

include("playermoney.lua")
include("pricer.lua")
include("player_class/player_sandbuy.lua")

DEFINE_BASECLASS( "gamemode_sandbox" )

GM.Name = "Sandbuy"
GM.Author = "FeldrinH"
GM.IsSandboxDerived = true