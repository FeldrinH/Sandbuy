local nobuy_color = Color( 255, 0, 0 )
local nobuy_color_dark = Color( 230, 0, 0 )
local buy_color = Color( 0, 255, 0 )
local buy_color_dark = Color( 0, 160, 0 )
local has_color = Color( 150, 150, 150 )

surface.CreateFont("TrebuchetPrice24", {
	font = "Trebuchet",
	size = 24,
	weight = 400,
	antialias = true,
	additive = false
})

/*surface.CreateFont("TrebuchetPrice18", {
	font = "Trebuchet",
	size = 18,
	weight = 400,
	antialias = true,
	additive = false
})*/

surface.CreateFont("BigMoney", {
	font = "Arial",
	size = 50
})

local function GetWepName(wep)
	return (list.GetForEdit("Weapon")[wep] and list.GetForEdit("Weapon")[wep].PrintName) or wep
end

local function GetWepCategory(wep)
	return (list.GetForEdit("Weapon")[wep] and list.GetForEdit("Weapon")[wep].Category) or "Other"
end

net.Receive("weaponbought", function()
	local wep = net.ReadString()
	
	if IsValid(g_SpawnMenu) and g_SpawnMenu:IsVisible() then
		spawnmenu.UpdateSpawnlistHasWeapon(wep)
	end
end)

net.Receive("moneychanged", function()
	local money = net.ReadInt(32)
	if IsValid(g_SpawnMenu) and g_SpawnMenu:IsVisible() then
		spawnmenu.UpdateSpawnlistMoney(money)
	end
end)

local function UpdateWepPrice( icon, money )
	icon:SetTextColor( ( LocalPlayer():HasWeapon( icon:GetSpawnName() ) and has_color ) or ( pricer.CanBuy( money, icon.BuyPrice ) and buy_color ) or nobuy_color )
end
local function UpdateEntPrice( icon, money )
	icon:SetTextColor( ( pricer.CanBuy( money, icon.BuyPrice ) and buy_color ) or nobuy_color )
end
local function UpdateVehiclePrice( icon, money )
	icon:SetTextColor( ( pricer.CanBuy( money, icon.BuyPrice ) and buy_color ) or nobuy_color )
end
local function UpdateAmmoOption( opt, money )
	opt:SetTextColor( ( pricer.CanBuy( money, opt.AmmoPrice ) and buy_color_dark ) or nobuy_color_dark )
end

local function UpdatePriceLabel(icon, pricetable)
	local price = hook.Run("GetBuyPrice", LocalPlayer(), icon:GetSpawnName(), pricetable)
	local printprice = pricer.GetPrintPrice(price)
	icon.BuyPrice = price
	if icon:GetText() != printprice then
		icon:SetText(printprice)
		icon:SetFont((price >= 0 and "TrebuchetPrice24" ) or "Trebuchet18")
	end
end

/*local function UpdateAmmoCanBuy(button, money)
	if !button.AmmoPrice then
		button:SetTextColor(Color(200,0,0))
		button:SetEnabled(false)
		button:SetCursor("none")
	else
		money = money or LocalPlayer():GetMoney()
		button:SetEnabled(true)
		button:SetCursor("hand")
		button:SetTextColor( ( pricer.CanBuy( money, button.AmmoPrice ) and buy_color_dark ) or nobuy_color_dark )
	end
end

local function UpdateAmmoWeapon(button, wepclass)
	local wep = LocalPlayer():GetActiveWeapon()
	
	if button.CurrentWeapon == wep then
		return
	end
	button.CurrentWeapon = wep
	
	if !IsValid(wep) then
		button:SetText( "Buy Ammo:\nNo active weapon" )
		button.AmmoPrice = false
		UpdateAmmoCanBuy(button)
		return
	end
	
	local ammotype = wep:GetPrimaryAmmoType()
	local isprimary = true
	if ammotype == -1 then
		ammotype = wep:GetSecondaryAmmoType()
		isprimary = false
	end
	if ammotype == -1 then
		button:SetText( "Buy Ammo:\nNo ammo available" )
		button.AmmoPrice = false
		UpdateAmmoCanBuy(button)
		return
	end
	
	local ammo = game.GetAmmoName(ammotype)
	local clipsize = pricer.GetClipSize(wep:GetClass()) or (isprimary and wep:GetMaxClip1()) or wep:GetMaxClip2()
	local clipcount = pricer.GetClipCount(wep:GetClass(), clipsize)
	local amount = clipsize * clipcount
	local price = hook.Run("GetBuyPrice", LocalPlayer(), ammo, "ammo")
		
	if amount == 0 or price < 0 then
		button:SetText( "Buy Ammo:\nNo ammo for sale" )
		button.AmmoPrice = false
		UpdateAmmoCanBuy(button)
		return
	end
	
	button:SetText( "Buy Ammo:\n" .. clipcount .. ( clipcount > 1 and " Clips" or " Clip") .. " for " .. pricer.GetPrintPrice(price * amount) )
	button.DoClick = function() RunConsoleCommand("sbuy_giveammo", ammo, amount) end
	button.AmmoPrice = price
	UpdateAmmoCanBuy(button)
end*/

function spawnmenu.UpdateSpawnlistMoney(money)
	if g_SpawnMenu.AmmoOptions then
		for k,v in pairs(g_SpawnMenu.AmmoOptions) do
			if IsValid(v) then
				UpdateAmmoOption(v, money)
			end
		end
	end
	if g_SpawnMenu.MoneyLables then
		for k,v in pairs(g_SpawnMenu.MoneyLables) do
			v:SetText("$" .. money)
		end
	end
	/*if g_SpawnMenu.AmmoButtons then
		for k,v in pairs(g_SpawnMenu.AmmoButtons) do
			UpdateAmmoCanBuy(v, money)
		end
	end*/
	if g_SpawnMenu.PriceIcons then
		for k,v in pairs(g_SpawnMenu.PriceIcons) do
			if !IsValid(v) then continue end
			if v:GetContentType() == "weapon" then
				UpdateWepPrice(v, money)
			elseif v:GetContentType() == "entity" then
				UpdateEntPrice(v, money)
			elseif v:GetContentType() == "vehicle" or v:GetContentType() == "simfphys_vehicles" then
				UpdateVehiclePrice(v, money)
			end
		end
	end
end

function spawnmenu.UpdateSpawnlistPrices()
	if g_SpawnMenu.PriceIcons then
		for k,v in pairs(g_SpawnMenu.PriceIcons) do
			if !IsValid(v) then continue end
			if v:GetContentType() == "weapon" then
				UpdatePriceLabel(v, "weapon")
			elseif v:GetContentType() == "entity" then
				UpdatePriceLabel(v, "entity")
			elseif v:GetContentType() == "vehicle" or v:GetContentType() == "simfphys_vehicles" then
				UpdatePriceLabel(v, "vehicle")
			end
		end
	end
end

function spawnmenu.UpdateSpawnlistHasWeapon(wep)
	if g_SpawnMenu.PriceIcons then
		for k,v in pairs(g_SpawnMenu.PriceIcons) do
			if !IsValid(v) then continue end
			if v:GetSpawnName() == wep then
				v:SetTextColor(has_color)
			end
		end
	end
end

/*function spawnmenu.UpdateSpawnlistActiveWeapon(wepclass)
	if g_SpawnMenu.AmmoButtons then
		for k,v in pairs(g_SpawnMenu.AmmoButtons) do
			UpdateAmmoWeapon(v, wepclass)
		end
	end
end*/

/*if !GetConVar("sbuy_debug") or !GetConVar("sbuy_debug"):GetBool() then
	local spawntabs = spawnmenu.GetCreationTabs()
	
	spawntabs["NeuroTec"] = nil
	spawntabs["VJ Base"] = nil
	spawntabs["#spawnmenu.category.npcs"] = nil
	spawntabs["#spawnmenu.category.saves"] = nil
	spawntabs["#spawnmenu.category.dupes"] = nil
	--spawntabs["#spawnmenu.category.vehicles"] = nil
end*/

local function AssembleTooltip(class, nicename)
	local swep = weapons.GetStored(class)
	if !swep then return end
	local firedata = swep.Primary
	if !firedata then return end
	
	local clip = firedata.ClipSize
	local automatic = firedata.Automatic
	
	local damage = nil
	if firedata.Damage and firedata.Damage > 0 then
		damage = firedata.Damage * (firedata.NumShots or 1)
		if swep.Base == "bobs_gun_base" or swep.Base == "bobs_scoped_base" then
			damage = damage * 1.075
		end
	end
	if swep.Damage and swep.Damage > 0 then
		damage = swep.Damage * (swep.Shots or 1)
	end
	
	local rpm = nil
	local delay = nil
	if firedata.RPM then
		rpm = firedata.RPM
		delay = 60 / rpm
	elseif firedata.Delay or swep.FireDelay then
		rpm = 60 / (firedata.Delay or swep.FireDelay)
		delay = (firedata.Delay or swep.FireDelay)
	end
	
	local dps = nil
	if damage and rpm and damage > 0 and rpm > 0 then
		if !automatic and rpm > 600 then
			dps = 10 * damage
		else
			dps = rpm / 60 * damage
		end
	end
	
	local validammo = firedata.Ammo and game.GetAmmoID(firedata.Ammo) != -1
	
	local out = nicename
	local something = false
	
	if dps and (!clip or clip > 1 or !validammo) then
		out = out .. "\nDPS: " .. math.Round(dps)
		something = true
	end
	
	if damage then
		out = out .. "\nDmg: " .. math.Round(damage)
		something = true
	end
	
	if automatic then
		if rpm and rpm > 0 and (!clip or clip > 1 or !validammo) then
			out = out .. "\nRPM: " .. math.Round(rpm)
			something = true
		end
	else
		if delay and (!clip or clip > 1 or !validammo) then
			out = out .. "\nDelay: " .. math.Round(delay, 4) .. "s"
			something = true
		end
	end
	
	if clip and clip > 0 and (something or clip > 1) and validammo then
		out = out .. "\nClip: " .. clip
	end
	
	return out
end

local function MouseReleased( self, mousecode )
	DButton.OnMouseReleased( self, mousecode )
	if ( self.m_MenuClicking && mousecode == MOUSE_LEFT ) then
		self.m_MenuClicking = false
		--CloseDermaMenus()
	end
end

local function AddMoneyLabel(ctrl)
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
end

local function AddBuyAmmoOpts(menu, wep)
	if IsValid(wep) then
		local wepclass = wep:GetClass()
		g_SpawnMenu.AmmoOptions = {}
		if wep:GetPrimaryAmmoType() != -1 then  
			local ammo = game.GetAmmoName(wep:GetPrimaryAmmoType())
			local clipcount = pricer.GetClipCount(wepclass, pricer.GetClipSize(wepclass) or wep:GetMaxClip1())
			local amount = (pricer.GetClipSize(wepclass) or wep:GetMaxClip1()) * clipcount
			local price = hook.Run("GetBuyPrice", LocalPlayer(), ammo, "ammo")
			if price >= -1 or price == -4 then
				if amount > 0 then
					local opt = menu:AddOption( "Buy " .. clipcount .. ( clipcount > 1 and " Clips" or " Clip") .. " of Primary Ammo (" .. ( price < 0 and pricer.GetPrintPrice(price) or pricer.GetPrintPrice(price * amount) ) .. ")", function() RunConsoleCommand("sbuy_giveammo", ammo, amount) end )
					opt.AmmoPrice = price * amount
					opt:SetTextColor( ( pricer.CanBuy( LocalPlayer():GetMoney(), opt.AmmoPrice ) and buy_color_dark ) or nobuy_color_dark )
					opt:SetDoubleClickingEnabled(false)
					opt.OnMouseReleased = MouseReleased
					table.insert(g_SpawnMenu.AmmoOptions, opt)
				end
				local opt = menu:AddOption( "Buy 1 Primary Ammo (" .. pricer.GetPrintPrice(price) .. ")", function() RunConsoleCommand("sbuy_giveammo", ammo, 1) end )
				opt.AmmoPrice = price
				opt:SetTextColor( ( pricer.CanBuy( LocalPlayer():GetMoney(), opt.AmmoPrice ) and buy_color_dark ) or nobuy_color_dark )
				opt:SetDoubleClickingEnabled(false)
				opt.OnMouseReleased = MouseReleased
				table.insert(g_SpawnMenu.AmmoOptions, opt)
			end
		end
		if wep:GetSecondaryAmmoType() != -1 then
			local ammo = game.GetAmmoName(wep:GetSecondaryAmmoType())
			local clipcount = pricer.GetClipCount(wepclass, pricer.GetClipSize(wepclass) or wep:GetMaxClip2())
			local amount = (pricer.GetClipSize(wepclass) or wep:GetMaxClip2()) * clipcount
			local price = hook.Run("GetBuyPrice", LocalPlayer(), ammo, "ammo")
			if price >= -1 or price == -4 then
				if amount > 0 then
					local opt = menu:AddOption( "Buy " .. clipcount .. ( clipcount > 1 and " Clips" or " Clip") .. " of Secondary Ammo (" .. ( price < 0 and pricer.GetPrintPrice(price) or pricer.GetPrintPrice(price * amount) ) .. ")", function() RunConsoleCommand("sbuy_giveammo", ammo, amount) end )
					opt.AmmoPrice = price * amount
					opt:SetTextColor( ( pricer.CanBuy( LocalPlayer():GetMoney(), opt.AmmoPrice ) and buy_color_dark ) or nobuy_color_dark )
					opt:SetDoubleClickingEnabled(false)
					opt.OnMouseReleased = MouseReleased
					table.insert(g_SpawnMenu.AmmoOptions, opt)
				end
				opt = menu:AddOption( "Buy 1 Secondary Ammo (" .. pricer.GetPrintPrice(price) .. ")", function() RunConsoleCommand("sbuy_giveammo", ammo, 1) end )
				opt.AmmoPrice = price
				opt:SetTextColor( ( pricer.CanBuy( LocalPlayer():GetMoney(), opt.AmmoPrice ) and buy_color_dark ) or nobuy_color_dark )
				opt:SetDoubleClickingEnabled(false)
				opt.OnMouseReleased = MouseReleased
				table.insert(g_SpawnMenu.AmmoOptions, opt)
			end
		end
		if table.IsEmpty(g_SpawnMenu.AmmoOptions) then
			local opt = menu:AddOption( "No ammo available for weapon" )
			opt:SetTextColor(Color(200,0,0))
			opt:SetMouseInputEnabled(false)
			opt:SetCursor("none")
		end
	else
		local opt = menu:AddOption( "Need to own a weapon to buy ammo" )
		opt:SetTextColor(Color(200,0,0))
		opt:SetMouseInputEnabled(false)
		opt:SetCursor("none")
	end
end

local function AddAmmoButton(ctrl)
	local button = vgui.Create( "DButton", ctrl.ContentNavBar )
	button:Dock(TOP)
	button:SetHeight(50)
	button:SetContentAlignment(5)
	button:SetFont("TrebuchetPrice24")
	button:SetDoubleClickingEnabled(false)
	button:SetText("Buy Ammo")
	
	button.DoClick = function()
		RunConsoleCommand("buyheldammo")
	end
	button.DoRightClick = function()
		local menu = DermaMenu()
		local wep = LocalPlayer():GetActiveWeapon()
		AddBuyAmmoOpts(menu, wep)
		menu:Open()
	end
	
	if !g_SpawnMenu.AmmoButtons then
		g_SpawnMenu.AmmoButtons = {}
	end
	table.insert(g_SpawnMenu.AmmoButtons, button)
end

local function Derma_StringRequestSmall( strTitle, strText, strDefaultText, fnEnter, fnCancel, strButtonText, strButtonCancelText )

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
	
	if IsValid( g_SpawnMenu ) then
		g_SpawnMenu:HangOpen( true )
	end
	
	return Window

end

vgui.GetControlTable("DLabel").OnMousePressed = function( self, mousecode )

	if ( self:GetDisabled() ) then return end

	if ( mousecode == MOUSE_LEFT && !dragndrop.IsDragging() && self.m_bDoubleClicking ) then

		if ( self.LastClickTime && SysTime() - self.LastClickTime < 0.2 ) then

			self:DoDoubleClickInternal()
			self:DoDoubleClick()
			return

		end

		self.LastClickTime = SysTime()

	end

	self:MouseCapture( true )
	self.Depressed = true
	self:OnDepressed()
	self:InvalidateLayout( true )

	--
	-- Tell DragNDrop that we're down, and might start getting dragged!
	--
	self:DragMousePress( mousecode )

end

hook.Add( "SpawnlistOpenGenericMenu", "SpawnlistOpenGenericMenu", function( canvas )
	local selected = canvas:GetSelectedChildren()

	local menu = DermaMenu()
	menu:AddOption( "Delete", function()
		for k, v in pairs( selected ) do
			v:Remove()
		end

		hook.Run( "SpawnlistContentChanged" )
	end )
	menu:AddSpacer()
	menu:AddOption( "Mark in Lua", function()
		pricer.SelectedIcons = selected
	end )
	menu:AddSpacer()
	menu:AddOption( "Set price", function()
		Derma_StringRequestSmall("Set price (" .. GetConVar("sbuy_saveto"):GetString() .. ")", "New price:", "", function(text)
			local saveto = GetConVar("sbuy_saveto"):GetString()
			local newprice = tonumber(text)
			if newprice == nil then
				chat.AddText(Color(255,0,0), "Invalid price: '" .. text .. "'")
				return
			end
			
			for k,v in pairs( selected ) do
				RunConsoleCommand("setprice", v:GetSpawnName(), newprice, v.pricetype or v:GetContentType(), saveto)
				v:SetText(string.Split(v:GetText(), " ")[1] .. " (" .. pricer.GetPrintPrice(newprice) .. ")")
				v:SetFont("Trebuchet18")
			end
		end, nil, "Set", "Cancel")
	end )

	menu:Open()
end )

spawnmenu.AddCreationTab( "#spawnmenu.content_tab", function()

	local ctrl = vgui.Create( "SpawnmenuContentPanel" )

	AddMoneyLabel(ctrl)
	AddAmmoButton(ctrl)
	
	ctrl.OldSpawnlists = ctrl.ContentNavBar.Tree:AddNode( "#spawnmenu.category.browse", "icon16/cog.png" )

	ctrl:EnableModify()
	hook.Call( "PopulatePropMenu", GAMEMODE )
	ctrl:CallPopulateHook( "PopulateContent" )

	ctrl.OldSpawnlists:MoveToFront()
	ctrl.OldSpawnlists:SetExpanded( true )

	return ctrl

end, "icon16/application_view_tile.png", -10 )

spawnmenu.AddContentType( "weapon", function( container, obj )

	if ( !obj.material ) then return end
	if ( !obj.nicename ) then return end
	if ( !obj.spawnname ) then return end

	local icon = vgui.Create( "ContentIcon", container )
	icon:SetContentType( "weapon" )
	icon:SetSpawnName( obj.spawnname )
	icon:SetName( obj.nicename )
	icon:SetTooltip( AssembleTooltip(obj.spawnname, obj.nicename) or obj.nicename )
	icon:SetMaterial( obj.material )
	//icon:SetAdminOnly( obj.admin )
	icon:SetColor( Color( 135, 206, 250, 255 ) )
	
	local price = hook.Run("GetBuyPrice", LocalPlayer(), obj.spawnname, "weapon")
	icon.BuyPrice = price
	icon:SetText( pricer.GetPrintPrice(price) )
	icon:SetContentAlignment( 7 )
	if IsValid(LocalPlayer()) and LocalPlayer().GetMoney then
		icon:SetTextColor( ( LocalPlayer():HasWeapon(obj.spawnname) and has_color ) or ( pricer.CanBuy(LocalPlayer():GetMoney(), price) and buy_color ) or nobuy_color )
	else
		icon:SetTextColor( nobuy_color )
	end
	icon:SetFont( ( price >= 0 and "TrebuchetPrice24" ) or "Trebuchet18" )
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
			AddBuyAmmoOpts(menu, wep)
			menu:AddSpacer()
			menu:AddOption( "Copy to Clipboard", function() SetClipboardText( obj.spawnname ) end )
			--menu:AddOption( "Spawn Using Toolgun", function() RunConsoleCommand( "gmod_tool", "creator" ) RunConsoleCommand( "creator_type", "3" ) RunConsoleCommand( "creator_name", obj.spawnname ) end )
			if CAMI.PlayerHasAccess(ply, "sandbuy.editprices") then
				menu:AddOption( "Set price", function()
					local oldprice = hook.Run("GetBuyPrice", LocalPlayer(), obj.spawnname, 'weapon')
					Derma_StringRequestSmall("Set price (" .. GetConVar("sbuy_saveto"):GetString() .. ")", "New price:", oldprice, function(text)
						local newprice = tonumber(text)
						if newprice == nil then
							chat.AddText(Color(255,0,0), "Invalid price: '" .. text .. "'")
							return
						end
						
						RunConsoleCommand("setprice", obj.spawnname, newprice, "weapon", GetConVar("sbuy_saveto"):GetString())
						
						icon:SetText(pricer.GetPrintPrice(oldprice) .. " (" .. pricer.GetPrintPrice(newprice) .. ")")
						icon:SetFont("Trebuchet18")
					end, nil, "Set", "Cancel")
				end )
			end
			--menu:AddOption( "Delete", function() icon:Remove() hook.Run( "SpawnlistContentChanged", icon ) end )
		menu:Open()

	end
	
	if !g_SpawnMenu.PriceIcons then
		g_SpawnMenu.PriceIcons = {}
	end
	table.insert(g_SpawnMenu.PriceIcons, icon)
	
	if ( IsValid( container ) ) then
		container:Add( icon )
	end

	return icon

end )

spawnmenu.AddCreationTab( "#spawnmenu.category.weapons", function()

	local ctrl = vgui.Create( "SpawnmenuContentPanel" )
	
	AddMoneyLabel(ctrl)
	AddAmmoButton(ctrl)
	
	ctrl:EnableSearch( "weapons", "PopulateWeapons" )
	ctrl:CallPopulateHook( "PopulateWeapons" )
	
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
	//icon:SetAdminOnly( obj.admin )
	icon:SetColor( Color( 205, 92, 92, 255 ) )
	
	local price = hook.Run("GetBuyPrice", LocalPlayer(), obj.spawnname, "entity" )
	icon.BuyPrice = price
	icon:SetText( pricer.GetPrintPrice(price) )
	icon:SetContentAlignment( 7 )
	if IsValid(LocalPlayer()) and LocalPlayer().GetMoney then
		icon:SetTextColor( ( pricer.CanBuy(LocalPlayer():GetMoney(), price) and buy_color ) or nobuy_color )
	else
		icon:SetTextColor( nobuy_color )
	end
	icon:SetFont( ( price >= 0 and "TrebuchetPrice24" ) or "Trebuchet18" )
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
			if CAMI.PlayerHasAccess(ply, "sandbuy.editprices") then
				menu:AddOption( "Set price", function()
					Derma_StringRequestSmall("Set price (" .. GetConVar("sbuy_saveto"):GetString() .. ")", "New price:", price, function(text)
						local newprice = tonumber(text)
						if newprice == nil then
							chat.AddText(Color(255,0,0), "Invalid price: '" .. text .. "'")
							return
						end
						
						RunConsoleCommand("setprice", obj.spawnname, newprice, "entity", GetConVar("sbuy_saveto"):GetString())
						
						icon:SetText(pricer.GetPrintPrice(price) .. " (" .. pricer.GetPrintPrice(newprice) .. ")")
						icon:SetFont("Trebuchet18")
					end, nil, "Set", "Cancel")
				end )
			end
			--menu:AddSpacer()
			--menu:AddOption( "Delete", function() icon:Remove() hook.Run( "SpawnlistContentChanged", icon ) end )
		menu:Open()

	end

	if !g_SpawnMenu.PriceIcons then
		g_SpawnMenu.PriceIcons = {}
	end
	table.insert(g_SpawnMenu.PriceIcons, icon)
	
	if ( IsValid( container ) ) then
		container:Add( icon )
	end

	return icon

end )

spawnmenu.AddCreationTab( "#spawnmenu.category.entities", function()

	local ctrl = vgui.Create( "SpawnmenuContentPanel" )
	
	AddMoneyLabel(ctrl)
	
	ctrl:EnableSearch( "entities", "PopulateEntities" )
	ctrl:CallPopulateHook( "PopulateEntities" )
	
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
	//icon:SetAdminOnly( obj.admin )
	icon:SetColor( Color( 0, 0, 0, 255 ) )
	
	local price = hook.Run("GetBuyPrice", LocalPlayer(), obj.spawnname, "vehicle" )
	icon.BuyPrice = price
	icon:SetText( pricer.GetPrintPrice(price) )
	icon:SetContentAlignment( 7 )
	if IsValid(LocalPlayer()) and LocalPlayer().GetMoney then
		icon:SetTextColor( ( pricer.CanBuy(LocalPlayer():GetMoney(), price) and buy_color ) or nobuy_color )
	else
		icon:SetTextColor( nobuy_color )
	end
	icon:SetFont( ( price >= 0 and "TrebuchetPrice24" ) or "Trebuchet18" )
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
			if CAMI.PlayerHasAccess(ply, "sandbuy.editprices") then
				menu:AddOption( "Set price", function()
					Derma_StringRequestSmall("Set price (" .. GetConVar("sbuy_saveto"):GetString() .. ")", "New price:", price, function(text)
						local newprice = tonumber(text)
						if newprice == nil then
							chat.AddText(Color(255,0,0), "Invalid price: '" .. text .. "'")
							return
						end
						
						RunConsoleCommand("setprice", obj.spawnname, newprice, "vehicle", GetConVar("sbuy_saveto"):GetString())
						
						icon:SetText(pricer.GetPrintPrice(price) .. " (" .. pricer.GetPrintPrice(newprice) .. ")")
						icon:SetFont("Trebuchet18")
					end, nil, "Set", "Cancel")
				end )
			end
			--menu:AddSpacer()
			--menu:AddOption( "Delete", function() icon:Remove() hook.Run( "SpawnlistContentChanged", icon ) end )
		menu:Open()

	end

	if !g_SpawnMenu.PriceIcons then
		g_SpawnMenu.PriceIcons = {}
	end
	table.insert(g_SpawnMenu.PriceIcons, icon)
	
	if ( IsValid( container ) ) then
		container:Add( icon )
	end

	return icon

end )

spawnmenu.AddCreationTab( "#spawnmenu.category.vehicles", function()

	local ctrl = vgui.Create( "SpawnmenuContentPanel" )
	
	AddMoneyLabel(ctrl)
	
	ctrl:EnableSearch( "vehicles", "PopulateVehicles" )
	ctrl:CallPopulateHook( "PopulateVehicles" )
	
	return ctrl

end, "icon16/car.png", 50 )

spawnmenu.AddContentType( "simfphys_vehicles", function( container, obj )
	if not obj.material then return end
	if not obj.nicename then return end
	if not obj.spawnname then return end

	local icon = vgui.Create( "ContentIcon", container )
	icon:SetContentType( "simfphys_vehicles" )
	icon.pricetype = "vehicle"
	icon:SetSpawnName( obj.spawnname )
	icon:SetName( obj.nicename )
	icon:SetMaterial( obj.material )
	//icon:SetAdminOnly( obj.admin )
	icon:SetColor( Color( 0, 0, 0, 255 ) )
	
	local price = hook.Run("GetBuyPrice", LocalPlayer(), obj.spawnname, "vehicle")
	icon.BuyPrice = price
	icon:SetText( pricer.GetPrintPrice(price) )
	icon:SetContentAlignment( 7 )
	if IsValid(LocalPlayer()) and LocalPlayer().GetMoney then
		icon:SetTextColor( ( pricer.CanBuy(LocalPlayer():GetMoney(), price) and buy_color ) or nobuy_color )
	else
		icon:SetTextColor( nobuy_color )
	end
	icon:SetFont( ( price >= 0 and "TrebuchetPrice24" ) or "Trebuchet18" )
	icon:SetExpensiveShadow(1, Color(0,0,0))
	icon:SetTextInset(8,8)
	
	icon.DoClick = function()
		RunConsoleCommand( "simfphys_spawnvehicle", obj.spawnname )
		--surface.PlaySound( "ui/buttonclickrelease.wav" )
	end
	icon.OpenMenu = function( icon )

		local menu = DermaMenu()
			menu:AddOption( "Copy to Clipboard", function() SetClipboardText( obj.spawnname ) end )
			if CAMI.PlayerHasAccess(ply, "sandbuy.editprices") then
				menu:AddOption( "Set price", function()
					Derma_StringRequestSmall("Set price (" .. GetConVar("sbuy_saveto"):GetString() .. ")", "New price:", price, function(text)
						local newprice = tonumber(text)
						if newprice == nil then
							chat.AddText(Color(255,0,0), "Invalid price: '" .. text .. "'")
							return
						end
						
						RunConsoleCommand("setprice", obj.spawnname, newprice, "vehicle", GetConVar("sbuy_saveto"):GetString())
						
						icon:SetText(pricer.GetPrintPrice(price) .. " (" .. pricer.GetPrintPrice(newprice) .. ")")
						icon:SetFont("Trebuchet18")
					end, nil, "Set", "Cancel")
				end )
			end
			--menu:AddSpacer()
			--menu:AddOption( "Delete", function() icon:Remove() hook.Run( "SpawnlistContentChanged", icon ) end )
		menu:Open()

	end
	
	if !g_SpawnMenu.PriceIcons then
		g_SpawnMenu.PriceIcons = {}
	end
	table.insert(g_SpawnMenu.PriceIcons, icon)
	
	if IsValid( container ) then
		container:Add( icon )
	end

	return icon

end )

spawnmenu.AddCreationTab( "simfphys", function()

	local ctrl = vgui.Create( "SpawnmenuContentPanel" )
	ctrl:CallPopulateHook( "SimfphysPopulateVehicles" )
	
	AddMoneyLabel(ctrl)
	
	return ctrl

end, "icon16/car.png", 50 )