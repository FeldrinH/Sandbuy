include("shared.lua")
include("cl_scoreboard.lua")
include("spawnmenu_content.lua")
include("configmenu.lua")

DEFINE_BASECLASS("gamemode_sandbox")

CreateConVar("sbuy_saveto", "overrides", FCVAR_ARCHIVE + FCVAR_USERINFO, "Priceset to save prices to when setting prices in-game")

surface.CreateFont("DollarSignFont", {
	font = "Roboto Light",
	size = 32,
	weight = 1000,
	antialias = true,
	additive = true
})

surface.CreateFont("KillstreakCaption", {
	font = "Roboto Bold",
	size = 32,
	shadow = true,
	antialias = true
})

surface.CreateFont("KillstreakFont", {
	font = "Roboto Black",
	size = 100,
	antialias = true,
	shadow = true
})

surface.CreateFont("DeathMessageFont", {
	font = "Roboto",
	size = 64
})

surface.CreateFont("DeathMessageFontSmall", {
	font = "Roboto",
	size = 48
})

local bg_color = Color(0, 0, 0, 76)
local text_color = Color(255, 235, 20)
local streak_color = Color(255, 255, 255)

local curmoney = -1
local curstreak = -1

local lastmoney = -1
local lastwidth = 0

local laststreak = -1
local streaktext = ""

local hoffset = math.floor(ScrH() * 696 / 768) - 56
local voffset = math.ceil(ScrW() * 25 / 1366)
local hoffsetstreak = math.floor(ScrH() * 700 / 768) - 56
local voffsetstreak = math.ceil(ScrW() * 1330 / 1366)

local deathmessage_killer = nil
local deathmessage_health = 0
local deathmessage_armor = 0
local deathmessage_text = ""
local deathmessage_killstreak = ""

local deathmessage_overrides = {
	["76561198076382343"] = "You were claimed by ", -- Martin
	["76561198315916037"] = "You were conquered by ", -- Napoleon
	["76561198033567884"] = "You were claimed in the name of the Cult by ", -- Egert
	["76561198100147578"] = "You were kräked by " -- kräk
}

local function AddSandbuyNotifier(hookname)
	hook.Add(hookname, "Sandbuy_ShowHelp", function()
		if IsValid(LocalPlayer()) then
			print("----- Welcome to Sandbuy! -----  (" .. hookname .. ")") 
			hook.Remove(hookname, "Sandbuy_ShowHelp")
			
			for i = 1,BUTTON_CODE_LAST do
				local kb = input.LookupKeyBinding(i) or ""
				if string.find(kb, "buyheldammo") or string.find(kb, "sbuy_giveprimaryammo") then return end
			end
			
			chat.AddText(Color(0,255,0), "----- Welcome to Sandbuy! -----")
			chat.AddText(Color(100,255,100), "Type ", Color(130,130,255), "bind g buyheldammo", Color(100,255,100), " in debug console to bind buying ammo for your weapon to G (or another key of your choosing)")
			chat.AddText(Color(100,255,100), "See https://github.com/FeldrinH/Sandbuy/wiki for more info")
		end
	end)
end

AddSandbuyNotifier("HUDPaint")
AddSandbuyNotifier("OnSpawnMenuClose")

function GM:HUDPaint()
	BaseClass.HUDPaint(self)
	
	if GetConVarNumber("cl_drawhud") == 0 then return end
	
	if hook.Call("HUDShouldDraw", gmod.GetGamemode(), "CHudHealth") and LocalPlayer():Alive() and LocalPlayer():GetObserverMode() == OBS_MODE_NONE then
		curmoney = LocalPlayer():GetMoney()
		
		if curmoney != lastmoney then
			surface.SetFont("HudNumbers")
			lastwidth = surface.GetTextSize(curmoney) + 32
			lastmoney = curmoney
		end
		
		draw.RoundedBox(5, voffset, hoffset - 5, lastwidth, 44, bg_color)
		draw.SimpleText(curmoney, "HudNumbers", voffset + 23, hoffset, text_color)
		draw.SimpleText("$", "DollarSignFont", voffset + 7, hoffset, text_color)
		
		curstreak = LocalPlayer():GetKillstreak()
		
		if curstreak != laststreak then
			streaktext = curstreak .. "X"
			laststreak = curstreak
		end
		
		if curstreak > 0 then
			draw.SimpleText("KILLSTREAK", "KillstreakCaption", voffsetstreak, hoffsetstreak - 100, streak_color, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
			draw.SimpleText(streaktext, "KillstreakFont", voffsetstreak, hoffsetstreak, streak_color, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
		end
	end
	
	if !LocalPlayer():Alive() then
		if IsValid(deathmessage_killer) then
			if deathmessage_health > 0 then
				if deathmessage_health != deathmessage_killer:Health() then
					deathmessage_health = deathmessage_killer:Health()
				end
				if deathmessage_armor != deathmessage_killer:Armor() then
					deathmessage_armor = deathmessage_killer:Armor()
				end
			end
			
			draw.SimpleTextOutlined(deathmessage_text, "DeathMessageFont", ScrW()/2, ScrH()/2 - 140, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 2, Color(0,0,0))
			if deathmessage_health <= 0 then
				draw.SimpleTextOutlined("who did not survive", "DeathMessageFontSmall", ScrW()/2, ScrH()/2 - 80, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 2, Color(0,0,0))
			else
				draw.SimpleTextOutlined("who survived with " .. deathmessage_health .. " health" .. (deathmessage_armor > 0 and (" and " .. deathmessage_armor .. " armor") or ""), "DeathMessageFontSmall", ScrW()/2, ScrH()/2 - 80, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 2, Color(0,0,0))
			end
			draw.SimpleTextOutlined(deathmessage_killstreak, "DeathMessageFontSmall", ScrW()/2, ScrH()/2 + 20, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 2, Color(0,0,0))
		else
			draw.SimpleTextOutlined(deathmessage_text, "DeathMessageFont", ScrW()/2, ScrH()/2 - 140, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 2, Color(0,0,0))
			draw.SimpleTextOutlined(deathmessage_killstreak, "DeathMessageFontSmall", ScrW()/2, ScrH()/2 - 20, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 2, Color(0,0,0))
		end
		
	end
end

function GM:SetDeathMessage(killer)
	deathmessage_killstreak = "Your killstreak: " .. LocalPlayer():GetKillstreak() .. "x"
	if killer == nil then return end
	if IsValid(killer) and killer:IsPlayer() then
		if killer == LocalPlayer() then
			deathmessage_killer = nil
			deathmessage_text = "You killed yourself"
		else
			deathmessage_killer = killer
			deathmessage_health = killer:Health()
			deathmessage_armor = killer:Armor()
			deathmessage_text = (deathmessage_overrides[killer:SteamID64()] or  "You were killed by ") .. killer:Nick()
		end
	else
		deathmessage_killer = nil
		deathmessage_text = "You died"
	end
end

function GM:OnSpawnMenuOpen()
	if IsValid(g_SpawnMenu) then
		spawnmenu.UpdateSpawnlistMoney(LocalPlayer():GetMoney())
	end

	return BaseClass.OnSpawnMenuOpen(self)
end

/*function GM:PlayerSwitchWeapon( ply, oldWeapon, newWeapon )
	print(newWeapon)
	if IsValid(g_SpawnMenu) and g_SpawnMenu:IsVisible() then
		timer.Simple(0.01, function()
			print(LocalPlayer():GetActiveWeapon())
			spawnmenu.UpdateSpawnlistActiveWeapon()
		end)
	end

	return BaseClass.PlayerSwitchWeapon( self, ply, oldWeapon, newWeapon )
end*/

local function Derma_AmountRequestSmall( strTitle, strText, strDefaultText, fnEnter, fnCancel, strButtonText, strButtonCancelText )

	local Window = vgui.Create( "DFrame" )
	Window:SetTitle( strTitle )
	Window:SetDraggable( true )
	Window:ShowCloseButton( true )
	Window:SetDrawOnTop( true )

	local InnerPanel = vgui.Create( "DPanel", Window )
	InnerPanel:SetPaintBackground( false )

	local Text = vgui.Create( "DLabel", InnerPanel )
	Text:SetText( strText )
	Text:SizeToContents()
	Text:SetContentAlignment( 5 )
	Text:SetTextColor( color_white )

	local TextEntry = vgui.Create( "DTextEntry", InnerPanel )
	TextEntry:SetNumeric( true )
	TextEntry:SetText( strDefaultText or "" )
	TextEntry.OnEnter = function() Window:Close() fnEnter( TextEntry:GetValue() ) end

	local ButtonPanel = vgui.Create( "DPanel", Window )
	ButtonPanel:SetTall( 30 )
	ButtonPanel:SetPaintBackground( false )

	local Button = vgui.Create( "DButton", ButtonPanel )
	Button:SetText( strButtonText or "OK" )
	Button:SizeToContents()
	Button:SetTall( 20 )
	Button:SetWide( Button:GetWide() + 20 )
	Button:SetPos( 5, 5 )
	Button.DoClick = function() Window:Close() fnEnter( TextEntry:GetValue() ) end

	local ButtonCancel = vgui.Create( "DButton", ButtonPanel )
	ButtonCancel:SetText( strButtonCancelText or "Cancel" )
	ButtonCancel:SizeToContents()
	ButtonCancel:SetTall( 20 )
	ButtonCancel:SetWide( Button:GetWide() + 20 )
	ButtonCancel:SetPos( 5, 5 )
	ButtonCancel.DoClick = function() Window:Close() if ( fnCancel ) then fnCancel( TextEntry:GetValue() ) end end
	ButtonCancel:MoveRightOf( Button, 5 )

	ButtonPanel:SetWide( Button:GetWide() + 5 + ButtonCancel:GetWide() + 10 )

	local w, h = Text:GetSize()
	w = math.max( w, 200 )

	Window:SetSize( w + 50, h + 25 + 75 + 10 )
	Window:Center()

	InnerPanel:StretchToParent( 5, 25, 5, 45 )

	Text:StretchToParent( 5, 5, 5, 35 )

	TextEntry:StretchToParent( 5, nil, 5, nil )
	TextEntry:AlignBottom( 5 )

	TextEntry:RequestFocus()
	TextEntry:SelectAllText( true )

	ButtonPanel:CenterHorizontal()
	ButtonPanel:AlignBottom( 8 )

	Window:MakePopup()
	--Window:DoModal()
	
	return Window

end

concommand.Add("givemoney_dialog", function(ply, cmd, args)
	local target = nil
	if args[1] then
		for k,v in pairs(player.GetAll()) do 
			if v:Nick() == args[1] then
				target = v
				break
			end
		end
	else
		target = ply:GetEyeTrace().HitEntity
	end
	if !IsValid(target) or !target:IsPlayer() then return end
	targetname = target:Nick()
	
	Derma_AmountRequestSmall("Give money to " .. targetname, "Amount:", 0, function(amount)
		RunConsoleCommand("givemoney", amount, targetname)
	end, nil, "Give", "Cancel")
end)

local function CopyItems(listname)
	local itemcopy = list.GetForEdit(listname .. "Backup")
	if #itemcopy != 0 then return end
	
	local itemlist = list.GetForEdit(listname)
	for k,v in pairs(itemlist) do
		itemcopy[k] = v
	end
end

local function FilterItems(listname, priceset, isdebug)
	local itemlist = list.GetForEdit(listname)
	local itemcopy = list.GetForEdit(listname .. "Backup")
	for k,v in pairs(itemcopy) do
		local price = hook.Run("GetBuyPrice", LocalPlayer(), k, priceset)
		if price <= -2 and price != -4 and !isdebug then
			itemlist[k] = nil
		else
			itemlist[k] = v
		end
	end
end

net.Receive("newprices", function(len)
	print("Prices received " .. len .. "/524264 " .. math.Round(len / 524264 * 100) .. "%")
	
	local reload = net.ReadUInt(2)
	if reload == 1 then
		print("Full reload")
	elseif reload == 2 then
		print("Quick reload")
	elseif reload == 3 then
		print('Prices only reload')
	else
		print("Initial load")
	end
	
	pricer.PriceTable.weapon = net.ReadPriceTable()
	pricer.PriceTable.entity = net.ReadPriceTable()
	pricer.PriceTable.vehicle = net.ReadPriceTable()
	pricer.PriceTable.ammo = net.ReadPriceTable()
	pricer.PriceTable.custom = net.ReadPriceTable()
	
	if reload != 3 then
		//pricer.PriceTable.clipcount = net.ReadPriceTable()
		pricer.PriceTable.clipsize = net.ReadPriceTable()

		pricer.CategoriesLookup = {}
		while true do
			local catname = net.ReadString()
			if catname == "" then
				break
			end
			pricer.CategoriesLookup[catname] = net.ReadCategoryTable()
		end
	end

	if reload == 2 or reload == 3 then
		spawnmenu.UpdateSpawnlistPrices()
	else
		CopyItems("SpawnableEntities")
		CopyItems("Vehicles")
		CopyItems("simfphys_vehicles")
		
		local isdebug = GetConVar("sbuy_debug") and GetConVar("sbuy_debug"):GetBool()
		
		local itemlist = list.GetForEdit("Weapon")
		for k,v in pairs(itemlist) do
			if v.SpawnableBackup == nil then
				v.SpawnableBackup = v.Spawnable or false
			end
			local price = hook.Run("GetBuyPrice", LocalPlayer(), k, "weapon")
			v.Spawnable = v.SpawnableBackup and (price > -2 or price == -4 or isdebug)
		end
		
		FilterItems("SpawnableEntities", "entity", isdebug)
		FilterItems("Vehicles", "vehicle", isdebug)
		FilterItems("simfphys_vehicles", "vehicle", isdebug)
	end

	if reload == 1 then
		RunConsoleCommand("spawnmenu_reload")
	end
end)