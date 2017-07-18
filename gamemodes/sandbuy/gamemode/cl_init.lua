include("shared.lua")
include("cl_scoreboard.lua")
include("spawnmenu_prices.lua")

DEFINE_BASECLASS("gamemode_sandbox")

--[[local HiddenCategories = {["M9K"] = true}

function GM:PreGamemodeLoaded()	
	return BaseClass.PreGamemodeLoaded(self)
end]]--

function GM:OnSpawnMenuOpen()
	if IsValid(g_SpawnMenu) then
		spawnmenu.UpdateSpawnlistMoney(LocalPlayer():GetMoney())
	end

	return BaseClass.OnSpawnMenuOpen(self)
end

net.Receive("moneychanged", function(len)
	local money = net.ReadInt(32)
	if IsValid(g_SpawnMenu) and g_SpawnMenu:IsVisible() then
		spawnmenu.UpdateSpawnlistMoney(money)
	end
end)

net.Receive("weaponbought", function(len)
	local wep = net.ReadString()
	if IsValid(g_SpawnMenu) and g_SpawnMenu:IsVisible() then
		spawnmenu.UpdateSpawnlistHasWeapon(wep)
	end
end)

net.Receive("newprices", function(len)
	print("Prices received", len)
	
	local reload = net.ReadBool()
	
	pricer.WepPrices = net.ReadPriceTable()
	
	if !GetConVar("sbuy_debug"):GetBool() then
		for k,v in pairs(list.GetForEdit("Weapon")) do
			v.Spawnable = pricer.GetPrice(v.ClassName, pricer.WepPrices) > -2
		end
	end
	
	if reload then
		RunConsoleCommand("spawnmenu_reload")
	end
end)

spawnmenu.AddContentType( "weapon", function( container, obj )

	if ( !obj.material ) then return end
	if ( !obj.nicename ) then return end
	if ( !obj.spawnname ) then return end

	local price = pricer.GetPrice( obj.spawnname, pricer.WepPrices )
	
	local icon = vgui.Create( "ContentIcon", container )
	icon:SetContentType( "weapon" )
	icon:SetSpawnName( obj.spawnname )
	icon:SetName( obj.nicename )
	icon:SetMaterial( obj.material )
	icon:SetAdminOnly( obj.admin )
	icon:SetColor( Color( 135, 206, 250, 255 ) )
	icon:SetText( pricer.GetPrintPrice(price) )
	icon:SetContentAlignment( 7 )
	if IsValid(LocalPlayer()) and LocalPlayer().GetMoney then
		icon:SetTextColor( ( LocalPlayer():HasWeapon(obj.spawnname) and Color( 150, 150, 150 ) ) or ( pricer.CanBuy(LocalPlayer():GetMoney(), price) and Color( 0, 255, 0 ) ) or Color( 255, 0, 0 ) )
	else
		icon:SetTextColor( Color( 255, 0, 0 ) )
	end
	--icon:SetTextColor( ( price >= 0 and Color( 255, 255, 255 ) ) or Color( 255, 0, 0 ) )
	icon:SetFont( ( price >= 0 and "Trebuchet24" ) or "Trebuchet18" )
	icon:SetTextInset(8,8)
	
	icon.DoClick = function()

		RunConsoleCommand( "gm_giveswep", obj.spawnname )
		--surface.PlaySound( "ui/buttonclickrelease.wav" )

	end

	icon.DoMiddleClick = function()

		RunConsoleCommand( "gm_spawnswep", obj.spawnname )
		--surface.PlaySound( "ui/buttonclickrelease.wav" )

	end

	icon.OpenMenu = function( icon )

		local menu = DermaMenu()
			menu:AddOption( "Copy to Clipboard", function() SetClipboardText( obj.spawnname ) end )
			menu:AddOption( "Spawn Using Toolgun", function() RunConsoleCommand( "gmod_tool", "creator" ) RunConsoleCommand( "creator_type", "3" ) RunConsoleCommand( "creator_name", obj.spawnname ) end )
			menu:AddSpacer()
			menu:AddOption( "Delete", function() icon:Remove() hook.Run( "SpawnlistContentChanged", icon ) end )
		menu:Open()

	end
	
	if price >= 0 then
		if !g_SpawnMenu.PriceIcons then
			g_SpawnMenu.PriceIcons = {}
		end
		table.insert(g_SpawnMenu.PriceIcons, icon)
	end
	
	if ( IsValid( container ) ) then
		container:Add( icon )
	end

	return icon

end )