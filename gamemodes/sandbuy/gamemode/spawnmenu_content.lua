local nobuy_color = Color( 255, 0, 0 )
local buy_color = Color( 0, 255, 0 )
local has_color = Color( 150, 150, 150 )

if !GetConVar("sbuy_debug"):GetBool() then
	local spawntabs = spawnmenu.GetCreationTabs()
	
	spawntabs["NeuroTec"] = nil
	spawntabs["VJ Base"] = nil
	spawntabs["#spawnmenu.category.npcs"] = nil
	spawntabs["#spawnmenu.category.saves"] = nil
	spawntabs["#spawnmenu.category.dupes"] = nil
end

local function MouseReleased( self, mousecode )
	DButton.OnMouseReleased( self, mousecode )
	if ( self.m_MenuClicking && mousecode == MOUSE_LEFT ) then
		self.m_MenuClicking = false
		--CloseDermaMenus()
	end
end

spawnmenu.AddContentType( "weapon", function( container, obj )

	if ( !obj.material ) then return end
	if ( !obj.nicename ) then return end
	if ( !obj.spawnname ) then return end

	local icon = vgui.Create( "ContentIcon", container )
	icon:SetContentType( "weapon" )
	icon:SetSpawnName( obj.spawnname )
	icon:SetName( obj.nicename )
	icon:SetMaterial( obj.material )
	icon:SetAdminOnly( obj.admin )
	icon:SetColor( Color( 135, 206, 250, 255 ) )
	
	local price = pricer.GetPrice( obj.spawnname, pricer.WepPrices )
	icon:SetText( pricer.GetPrintPrice(price) )
	icon:SetContentAlignment( 7 )
	if IsValid(LocalPlayer()) and LocalPlayer().GetMoney then
		icon:SetTextColor( ( LocalPlayer():HasWeapon(obj.spawnname) and has_color ) or ( pricer.CanBuy(LocalPlayer():GetMoney(), price) and buy_color ) or nobuy_color )
	else
		icon:SetTextColor( nobuy_color )
	end
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
			local wep = LocalPlayer():GetWeapon( obj.spawnname )
			if IsValid(wep) then
				if wep:GetPrimaryAmmoType() != -1 then  
					local ammo = game.GetAmmoName(wep:GetPrimaryAmmoType())
					local clip = wep:GetMaxClip1()
					local price = pricer.GetPrice(ammo, pricer.AmmoPrices) * clip
					local opt = menu:AddOption( "Buy Clip of Primary Ammo (" .. pricer.GetPrintPrice(price) .. ")", function() RunConsoleCommand("sbuy_giveammo", ammo, clip) end )
					opt.OnMouseReleased = MouseReleased
				end
				if wep:GetSecondaryAmmoType() != -1 then
					local ammo = game.GetAmmoName(wep:GetSecondaryAmmoType())
					local clip = wep:GetMaxClip2()
					local price = pricer.GetPrice(ammo, pricer.AmmoPrices) * clip
					local opt = menu:AddOption( "Buy Clip of Secondary Ammo (" .. pricer.GetPrintPrice(price) .. ")", function() end )
					opt.OnMouseReleased = MouseReleased
				end
			else
				local opt = menu:AddOption( "Need to Own Weapon to Buy Ammo" )
				opt:SetTextColor(Color(250,0,0))
				opt:SetMouseInputEnabled(false)
				opt:SetCursor("none")
			end
			menu:AddOption( "Copy to Clipboard", function() SetClipboardText( obj.spawnname ) end )
			--menu:AddOption( "Spawn Using Toolgun", function() RunConsoleCommand( "gmod_tool", "creator" ) RunConsoleCommand( "creator_type", "3" ) RunConsoleCommand( "creator_name", obj.spawnname ) end )
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

spawnmenu.AddCreationTab( "#spawnmenu.category.weapons", function()

	local ctrl = vgui.Create( "SpawnmenuContentPanel" )
	ctrl:CallPopulateHook( "PopulateWeapons" )
	
	local label = vgui.Create( "DLabel", ctrl.ContentNavBar )
	label:Dock(TOP)
	label:SetHeight(60)
	label:SetContentAlignment(5)
	label:SetFont("BigMoney")
	label:SetTextColor(Color(255,255,255))
	label:SetText("$0")
	
	if !g_SpawnMenu.MoneyLables then
		g_SpawnMenu.MoneyLables = {}
	end
	table.insert(g_SpawnMenu.MoneyLables, label)
	
	return ctrl

end, "icon16/gun.png", 10 )

spawnmenu.AddContentType( "entity", function( container, obj )

	if ( !obj.material ) then return end
	if ( !obj.nicename ) then return end
	if ( !obj.spawnname ) then return end

	local icon = vgui.Create( "ContentIcon", container )
	icon:SetContentType( "entity" )
	icon:SetSpawnName( obj.spawnname )
	icon:SetName( obj.nicename )
	icon:SetMaterial( obj.material )
	icon:SetAdminOnly( obj.admin )
	icon:SetColor( Color( 205, 92, 92, 255 ) )
	
	local price = pricer.GetPrice( obj.spawnname, pricer.EntPrices )
	icon:SetText( pricer.GetPrintPrice(price) )
	icon:SetContentAlignment( 7 )
	if IsValid(LocalPlayer()) and LocalPlayer().GetMoney then
		icon:SetTextColor( ( pricer.CanBuy(LocalPlayer():GetMoney(), price) and buy_color ) or nobuy_color )
	else
		icon:SetTextColor( nobuy_color )
	end
	icon:SetFont( ( price >= 0 and "Trebuchet24" ) or "Trebuchet18" )
	icon:SetTextInset(8,8)
	
	icon.DoClick = function()
		RunConsoleCommand( "gm_spawnsent", obj.spawnname )
		--surface.PlaySound( "ui/buttonclickrelease.wav" )
	end
	icon.OpenMenu = function( icon )

		local menu = DermaMenu()
			menu:AddOption( "Copy to Clipboard", function() SetClipboardText( obj.spawnname ) end )
			--menu:AddOption( "Spawn Using Toolgun", function() RunConsoleCommand( "gmod_tool", "creator" ) RunConsoleCommand( "creator_type", "0" ) RunConsoleCommand( "creator_name", obj.spawnname ) end )
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

spawnmenu.AddCreationTab( "#spawnmenu.category.entities", function()

	local ctrl = vgui.Create( "SpawnmenuContentPanel" )
	ctrl:CallPopulateHook( "PopulateEntities" )

	local label = vgui.Create( "DLabel", ctrl.ContentNavBar )
	label:Dock(TOP)
	label:SetHeight(60)
	label:SetContentAlignment(5)
	label:SetFont("BigMoney")
	label:SetTextColor(Color(255,255,255))
	label:SetText("$0")
	
	if !g_SpawnMenu.MoneyLables then
		g_SpawnMenu.MoneyLables = {}
	end
	table.insert(g_SpawnMenu.MoneyLables, label)
	
	return ctrl

end, "icon16/bricks.png", 20 )