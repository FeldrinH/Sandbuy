local function SandbuySettings(pnl)
	pnl:AddControl( "Header", { Description = "#utilities.sandboxsettings" } )

	local ConVarsDefault = {
		sbuy_prices = "base standard overrides",
		sbuy_overrides = "overrides",
		sbuy_log = "1",
		sbuy_statsaver = "1",
		sbuy_noundo = "1",
		sbuy_debug = "0",
		sbuy_defaultmoney = "1000",
		sbuy_killmoney = "1000",
		sbuy_levelsize = "2",
		sbuy_levelbonus = "100",
		freebuy = "0"
	}

	pnl:AddControl( "ComboBox", { MenuButton = 1, Folder = "util_sandbuy", Options = { [ "#preset.default" ] = ConVarsDefault }, CVars = table.GetKeys( ConVarsDefault ) } )
	
	local lbl = vgui.Create( "DLabel", pnl )

	lbl:SetTextColor( Color(0,0,255) )
	lbl:SetWrap( true )
	lbl:SetTextInset( 0, 0 )
	lbl:SetText( "Open wiki for more information" )
	lbl:SetContentAlignment( 7 )
	lbl:SetAutoStretchVertical( true )
	lbl:DockMargin( 8, 0, 8, 8 )
	lbl:SetCursor("hand")

	function lbl:DoClick() -- Defines what should happen when the label is clicked
		gui.OpenURL("https://github.com/FeldrinH/Sandbuy/wiki")
	end
	
	pnl:AddItem( lbl, nil )
	lbl:InvalidateLayout( true )

	
	pnl:AddControl( "TextBox", { Label = "Load Prices", Command = "sbuy_prices", WaitForEnter = "1" } )
	pnl:AddControl( "TextBox", { Label = "Override Prices", Command = "sbuy_overrides", WaitForEnter = "1" } )
	--pnl:ControlHelp( "#persistent_mode.help" ):DockMargin( 16, 4, 16, 8 )
	
	pnl:AddControl( "Slider", { Label = "Base Money", Command = "sbuy_defaultmoney", Min = 0, Max = 2000 } )
	pnl:AddControl( "Slider", { Label = "Kill Money", Command = "sbuy_killmoney", Min = 1, Max = 2000 } )
	pnl:AddControl( "Slider", { Label = "Bonus Per Level", Command = "sbuy_levelbonus", Min = 0, Max = 200 } )
	pnl:AddControl( "Slider", { Type = "float", Label = "Kills Required Per Level", Command = "sbuy_levelsize", Min = 1, Max = 5 } )
	
	pnl:AddControl( "CheckBox", { Label = "Free Weapons", Command = "freebuy" } )
	
	pnl:AddControl( "CheckBox", { Label = "Logging (requires restart)", Command = "sbuy_log" } )
	pnl:AddControl( "CheckBox", { Label = "Stat Saver (requires restart)", Command = "sbuy_statsaver" } )
	pnl:AddControl( "CheckBox", { Label = "Disable Undo (requires restart)", Command = "sbuy_noundo" } )
	pnl:AddControl( "CheckBox", { Label = "Debug Mode (requires restart)", Command = "sbuy_debug" } )
end

local function ResetMenu(pnl)
	pnl:AddControl( "Header", { Description = "Reset various parts of a Sandbuy game" } )
	
	pnl:Button( "Reset stats & respawn players", "resetfull" )
	pnl:Button( "Reset stats & weapons", "resetplayers" )
	pnl:Button( "Reset stats", "resetstats" )
end

hook.Add( "PopulateToolMenu", "PopulateSandbuyConfigmenu", function()
	spawnmenu.AddToolMenuOption("Utilities", "Admin", "SandbuySettings", "Sandbuy Settings", "", "", SandbuySettings)
	spawnmenu.AddToolMenuOption( "Utilities", "Admin", "SandbuyReset", "Sandbuy Reset", "", "", ResetMenu )
end)