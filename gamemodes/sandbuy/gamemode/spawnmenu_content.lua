local nobuy_color = Color( 255, 0, 0 )
local nobuy_color_dark = Color( 230, 0, 0 )
local buy_color = Color( 0, 255, 0 )
local buy_color_dark = Color( 0, 160, 0 )
local has_color = Color( 150, 150, 150 )

if !GetConVar("sbuy_debug") or !GetConVar("sbuy_debug"):GetBool() then
	local spawntabs = spawnmenu.GetCreationTabs()
	
	spawntabs["NeuroTec"] = nil
	spawntabs["VJ Base"] = nil
	spawntabs["#spawnmenu.category.npcs"] = nil
	spawntabs["#spawnmenu.category.saves"] = nil
	spawntabs["#spawnmenu.category.dupes"] = nil
	spawntabs["#spawnmenu.category.vehicles"] = nil
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
	icon:SetExpensiveShadow(1, Color(0,0,0))
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
				g_SpawnMenu.AmmoOptions = {}
				if wep:GetPrimaryAmmoType() != -1 then  
					local ammo = game.GetAmmoName(wep:GetPrimaryAmmoType())
					local amount = wep:GetMaxClip1() * 3
					local price = pricer.GetPrice(ammo, pricer.AmmoPrices)
					local opt = menu:AddOption( "Buy 3 Clips of Primary Ammo (" .. pricer.GetPrintPrice(price * amount) .. ")", function() RunConsoleCommand("sbuy_giveammo", ammo, amount) end )
					opt.AmmoPrice = price * amount
					opt:SetTextColor( ( pricer.CanBuy( LocalPlayer():GetMoney(), opt.AmmoPrice ) and buy_color_dark ) or nobuy_color_dark )
					opt:SetDoubleClickingEnabled(false)
					opt.OnMouseReleased = MouseReleased
					table.insert(g_SpawnMenu.AmmoOptions, opt)
					opt = menu:AddOption( "Buy 1 Primary Ammo (" .. pricer.GetPrintPrice(price) .. ")", function() RunConsoleCommand("sbuy_giveammo", ammo, 1) end )
					opt.AmmoPrice = price
					opt:SetTextColor( ( pricer.CanBuy( LocalPlayer():GetMoney(), opt.AmmoPrice ) and buy_color_dark ) or nobuy_color_dark )
					opt:SetDoubleClickingEnabled(false)
					opt.OnMouseReleased = MouseReleased
					table.insert(g_SpawnMenu.AmmoOptions, opt)
				end
				if wep:GetSecondaryAmmoType() != -1 then
					local ammo = game.GetAmmoName(wep:GetSecondaryAmmoType())
					local amount = wep:GetMaxClip2() * 3
					local price = pricer.GetPrice(ammo, pricer.AmmoPrices)
					local opt = menu:AddOption( "Buy 3 Clips of Secondary Ammo (" .. pricer.GetPrintPrice(price * amount) .. ")", function() RunConsoleCommand("sbuy_giveammo", ammo, amount) end )
					opt.AmmoPrice = price * amount
					opt:SetTextColor( ( pricer.CanBuy( LocalPlayer():GetMoney(), opt.AmmoPrice ) and buy_color_dark ) or nobuy_color_dark )
					opt:SetDoubleClickingEnabled(false)
					opt.OnMouseReleased = MouseReleased
					table.insert(g_SpawnMenu.AmmoOptions, opt)
					opt = menu:AddOption( "Buy 1 Secondary Ammo (" .. pricer.GetPrintPrice(price) .. ")", function() RunConsoleCommand("sbuy_giveammo", ammo, 1) end )
					opt.AmmoPrice = price
					opt:SetTextColor( ( pricer.CanBuy( LocalPlayer():GetMoney(), opt.AmmoPrice ) and buy_color_dark ) or nobuy_color_dark )
					opt:SetDoubleClickingEnabled(false)
					opt.OnMouseReleased = MouseReleased
					table.insert(g_SpawnMenu.AmmoOptions, opt)
				end
			else
				local opt = menu:AddOption( "Need to Own Weapon to Buy Ammo" )
				opt:SetTextColor(Color(200,0,0))
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

hook.Add( "PopulateAmmo", "AddEntityContent", function( pnlContent, tree, node )

	local Categorised = {}

	-- Add this list into the tormoil
	local Ammo = pricer.AmmoData
	for k, v in pairs( Ammo ) do

		v.SpawnName = k
		Categorised[ v.Category ] = Categorised[ v.Category ] or {}
		table.insert( Categorised[ v.Category ], v )

	end

	-- Add a tree node for each category
	for CategoryName, v in SortedPairs( Categorised ) do

		-- Add a node to the tree
		local node = tree:AddNode( CategoryName, CategoryName == "Miscellaneous" and "icon16/bricks.png" or CategoryName == "Bullets" and "icon16/gun.png" or "icon16/bomb.png" )

			-- When we click on the node - populate it using this function
		node.DoPopulate = function( self )

			-- If we've already populated it - forget it.
			if ( self.PropPanel ) then return end

			-- Create the container panel
			self.PropPanel = vgui.Create( "ContentContainer", pnlContent )
			self.PropPanel:SetVisible( false )
			self.PropPanel:SetTriggerSpawnlistChange( false )

			for k, ent in SortedPairsByMemberValue( v, "PrintName" ) do

				spawnmenu.CreateContentIcon( "ammo", self.PropPanel, {
					nicename	= ent.Name or ent.SpawnName,
					spawnname	= ent.SpawnName,
					amount		= ent.Amount,
					material	= "entities/" .. ent.Icon .. ".png",
					--admin		= ent.AdminOnly
				} )

			end

		end

		-- If we click on the node populate it and switch to it.
		node.DoClick = function( self )

			self:DoPopulate()
			pnlContent:SwitchPanel( self.PropPanel )

		end

	end

	-- Select the first node
	local FirstNode = tree:Root():GetChildNode( 0 )
	if ( IsValid( FirstNode ) ) then
		FirstNode:InternalDoClick()
	end

end )

spawnmenu.AddContentType( "ammo", function( container, obj )

	if ( !obj.material ) then return end
	if ( !obj.nicename ) then return end
	if ( !obj.spawnname ) then return end
	if ( !obj.amount ) then return end

	local icon = vgui.Create( "ContentIcon", container )
	icon:SetContentType( "ammo" )
	icon:SetSpawnName( obj.spawnname )
	icon.AmmoAmount = obj.amount
	icon:SetName( obj.nicename .. " (" .. obj.amount .. ")" )
	icon:SetMaterial( obj.material )
	icon:SetAdminOnly( obj.admin )
	icon:SetColor( Color( 135, 206, 250, 255 ) )
	
	local singleprice = pricer.GetPrice( obj.spawnname, pricer.AmmoPrices )
	local price = singleprice * obj.amount
	icon:SetText( pricer.GetPrintPrice(price) )
	icon:SetContentAlignment( 7 )
	if IsValid(LocalPlayer()) and LocalPlayer().GetMoney then
		icon:SetTextColor( ( pricer.CanBuy(LocalPlayer():GetMoney(), price) and buy_color ) or nobuy_color )
	else
		icon:SetTextColor( nobuy_color )
	end
	icon:SetFont( ( price >= 0 and "Trebuchet24" ) or "Trebuchet18" )
	icon:SetExpensiveShadow(1, Color(0,0,0))
	icon:SetTextInset(8,8)
	
	--[[local label = vgui.Create("DLabel", icon)
	label:DockMargin(8,8,8,8)
	label:Dock(FILL)
	label:SetText(obj.amount .. "x")
	label:SetContentAlignment( 9 )
	if IsValid(LocalPlayer()) and LocalPlayer().GetMoney then
		label:SetTextColor( ( pricer.CanBuy(LocalPlayer():GetMoney(), price) and buy_color ) or nobuy_color )
	else
		label:SetTextColor( nobuy_color )
	end
	label:SetFont( "Trebuchet24" )
	label:SetExpensiveShadow(1, Color(0,0,0))
	icon.AmountLabel = label]]--
	
	icon.DoClick = function()
		RunConsoleCommand( "sbuy_giveammo", obj.spawnname, obj.amount )
		--surface.PlaySound( "ui/buttonclickrelease.wav" )
	end

	--icon.DoMiddleClick = function()
		--RunConsoleCommand( "gm_spawnswep", obj.spawnname )
		--surface.PlaySound( "ui/buttonclickrelease.wav" )
	--end

	icon.OpenMenu = function( icon )

		local menu = DermaMenu()
			local opt = menu:AddOption( "Buy 1 (" .. pricer.GetPrintPrice(singleprice) .. ")", function() RunConsoleCommand( "sbuy_giveammo", obj.spawnname, 1 ) end )
			opt:SetTextColor( ( pricer.CanBuy( LocalPlayer():GetMoney(), singleprice ) and buy_color ) or nobuy_color )
			opt.AmmoPrice = singleprice
			opt:SetDoubleClickingEnabled(false)
			opt.OnMouseReleased = MouseReleased
			g_SpawnMenu.PrimaryAmmoOption = opt
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

spawnmenu.AddCreationTab( "Ammo", function()

	local ctrl = vgui.Create( "SpawnmenuContentPanel" )
	ctrl:CallPopulateHook( "PopulateAmmo" )
	
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

end, "icon16/bomb.png", 11 )

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
	icon:SetExpensiveShadow(1, Color(0,0,0))
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

spawnmenu.AddContentType( "vehicle", function( container, obj )

	if ( !obj.material ) then return end
	if ( !obj.nicename ) then return end
	if ( !obj.spawnname ) then return end

	local icon = vgui.Create( "ContentIcon", container )
	icon:SetContentType( "vehicle" )
	icon:SetSpawnName( obj.spawnname )
	icon:SetName( obj.nicename )
	icon:SetMaterial( obj.material )
	icon:SetAdminOnly( obj.admin )
	icon:SetColor( Color( 0, 0, 0, 255 ) )
	
	local price = pricer.GetPrice( obj.spawnname, pricer.VehiclePrices )
	icon:SetText( pricer.GetPrintPrice(price) )
	icon:SetContentAlignment( 7 )
	if IsValid(LocalPlayer()) and LocalPlayer().GetMoney then
		icon:SetTextColor( ( pricer.CanBuy(LocalPlayer():GetMoney(), price) and buy_color ) or nobuy_color )
	else
		icon:SetTextColor( nobuy_color )
	end
	icon:SetFont( ( price >= 0 and "Trebuchet24" ) or "Trebuchet18" )
	icon:SetExpensiveShadow(1, Color(0,0,0))
	icon:SetTextInset(8,8)
	
	icon.DoClick = function()
		RunConsoleCommand( "gm_spawnvehicle", obj.spawnname )
		--surface.PlaySound( "ui/buttonclickrelease.wav" )
	end
	icon.OpenMenu = function( icon )

		local menu = DermaMenu()
			menu:AddOption( "Copy to Clipboard", function() SetClipboardText( obj.spawnname ) end )
			--menu:AddOption( "Spawn Using Toolgun", function() RunConsoleCommand( "gmod_tool", "creator" ) RunConsoleCommand( "creator_type", "1" ) RunConsoleCommand( "creator_name", obj.spawnname ) end )
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

--[[spawnmenu.AddCreationTab( "#spawnmenu.category.vehicles", function()

	local ctrl = vgui.Create( "SpawnmenuContentPanel" )
	ctrl:CallPopulateHook( "PopulateVehicles" )
	
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

end, "icon16/car.png", 50 )]]--

spawnmenu.AddContentType( "simfphys_vehicles", function( container, obj )
	if not obj.material then return end
	if not obj.nicename then return end
	if not obj.spawnname then return end

	local icon = vgui.Create( "ContentIcon", container )
	icon:SetContentType( "simfphys_vehicles" )
	icon:SetSpawnName( obj.spawnname )
	icon:SetName( obj.nicename )
	icon:SetMaterial( obj.material )
	icon:SetAdminOnly( obj.admin )
	icon:SetColor( Color( 0, 0, 0, 255 ) )
	
	local price = pricer.GetPrice( obj.spawnname, pricer.VehiclePrices )
	icon:SetText( pricer.GetPrintPrice(price) )
	icon:SetContentAlignment( 7 )
	if IsValid(LocalPlayer()) and LocalPlayer().GetMoney then
		icon:SetTextColor( ( pricer.CanBuy(LocalPlayer():GetMoney(), price) and buy_color ) or nobuy_color )
	else
		icon:SetTextColor( nobuy_color )
	end
	icon:SetFont( ( price >= 0 and "Trebuchet24" ) or "Trebuchet18" )
	icon:SetExpensiveShadow(1, Color(0,0,0))
	icon:SetTextInset(8,8)
	
	icon.DoClick = function()
		RunConsoleCommand( "simfphys_spawnvehicle", obj.spawnname )
		--surface.PlaySound( "ui/buttonclickrelease.wav" )
	end
	icon.OpenMenu = function( icon )

		local menu = DermaMenu()
			menu:AddOption( "Copy to Clipboard", function() SetClipboardText( obj.spawnname ) end )
			--menu:AddSpacer()
			--menu:AddOption( "Delete", function() icon:Remove() hook.Run( "SpawnlistContentChanged", icon ) end )
		menu:Open()

	end
	
	if price >= 0 then
		if !g_SpawnMenu.PriceIcons then
			g_SpawnMenu.PriceIcons = {}
		end
		table.insert(g_SpawnMenu.PriceIcons, icon)
	end
	
	if IsValid( container ) then
		container:Add( icon )
	end

	return icon

end )

spawnmenu.AddCreationTab( "simfphys", function()

	local ctrl = vgui.Create( "SpawnmenuContentPanel" )
	ctrl:CallPopulateHook( "SimfphysPopulateVehicles" )
	
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

end, "icon16/car.png", 50 )