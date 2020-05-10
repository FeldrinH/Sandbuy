local function TranslateValuesRound(self, x, y)
	self:SetValue( math.Round( self.Scratch:GetMin() + ( x * self.Scratch:GetRange() ), self.RoundDecimals ) )

	return self.Scratch:GetFraction(), y
end

local function SandbuySettings(pnl)
	pnl:AddControl( "Header", { Description = "#utilities.sandboxsettings" } )

	local ConVarsDefault = {
		sbuy_prices = GetConVar("sbuy_prices"):GetDefault(),
		sbuy_log = "1",
		sbuy_statsaver = "1",
		sbuy_noundo = "0",
		sbuy_debug = "0",
		sbuy_bonusratio = "20",
		sbuy_startmoney = GetConVar("sbuy_startmoney"):GetDefault(),
		sbuy_defaultmoney = GetConVar("sbuy_defaultmoney"):GetDefault(),
		sbuy_killmoney = GetConVar("sbuy_killmoney"):GetDefault(),
		sbuy_levelsize = GetConVar("sbuy_levelsize"):GetDefault(),
		sbuy_levelbonus = GetConVar("sbuy_levelbonus"):GetDefault(),
		sbuy_freebuy = "0",
		sbuy_hidemoney = "0"
	}

	pnl:AddControl( "ComboBox", { MenuButton = 1, Folder = "util_sandbuy", Options = { [ "#preset.default" ] = ConVarsDefault }, CVars = table.GetKeys( ConVarsDefault ) } )
	
	local lbl = vgui.Create( "DLabel", pnl )

	lbl:SetTextColor( Color(0,0,255) )
	lbl:SetWrap( true )
	lbl:SetTextInset( 0, 0 )
	lbl:SetText( "Click here to open wiki for more information" )
	lbl:SetContentAlignment( 7 )
	lbl:SetAutoStretchVertical( true )
	lbl:DockMargin( 8, 0, 8, 8 )
	lbl:SetCursor("hand")

	function lbl:DoClick()
		gui.OpenURL("https://sandbuy.readthedocs.io/")
	end
	
	pnl:AddItem( lbl, nil )
	lbl:InvalidateLayout( true )

	
	pnl:Button( "Full reload prices (causes lag)", "reloadprices" )
	pnl:Button( "Quick reload prices", "quickloadprices" )
	
	--pnl:Button( "List available prices (in chat)", "listprices" )
	
	pnl:AddControl( "TextBox", { Label = "Load pricesets", Command = "sbuy_prices", WaitForEnter = "1" } )
	pnl:AddControl( "TextBox", { Label = "Save prices to", Command = "sbuy_saveto", WaitForEnter = "1" } )
	
	--pnl:ControlHelp( "#persistent_mode.help" ):DockMargin( 16, 4, 16, 8 )
	
	--local slider = pnl:AddControl( "Slider", { Label = "Eco Time", Command = "sbuy_ecotime", Min = 0, Max = 20 } )
	--slider.TranslateSliderValues = TranslateValuesRound
	--slider.RoundDecimals = 0
	
	local slider = pnl:AddControl( "Slider", { Label = "Bonus ratio", Command = "sbuy_bonusratio", Min = 0, Max = 100 } )
	
	slider = pnl:AddControl( "Slider", { Label = "Start money", Command = "sbuy_startmoney", Min = 0, Max = 2000 } )
	slider.TranslateSliderValues = TranslateValuesRound
	slider.RoundDecimals = -2
	slider = pnl:AddControl( "Slider", { Label = "Base money", Command = "sbuy_defaultmoney", Min = 0, Max = 2000 } )
	slider.TranslateSliderValues = TranslateValuesRound
	slider.RoundDecimals = -2
	slider = pnl:AddControl( "Slider", { Label = "Kill money", Command = "sbuy_killmoney", Min = 1, Max = 2000 } )
	slider.TranslateSliderValues = TranslateValuesRound
	slider.RoundDecimals = -2
	slider = pnl:AddControl( "Slider", { Label = "Bonus per level", Command = "sbuy_levelbonus", Min = 0, Max = 200 } )
	slider.TranslateSliderValues = TranslateValuesRound
	slider.RoundDecimals = -1
	slider = pnl:AddControl( "Slider", { Label = "Level size scaling", Command = "sbuy_levelsize", Min = 0, Max = 4000 } )
	slider.TranslateSliderValues = TranslateValuesRound
	slider.RoundDecimals = -1
	
	pnl:AddControl( "CheckBox", { Label = "Logging", Command = "sbuy_log" } )
	pnl:AddControl( "CheckBox", { Label = "Stat saver (requires restart)", Command = "sbuy_statsaver" } )
	
	pnl:AddControl( "CheckBox", { Label = "Disable undo", Command = "sbuy_noundo" } )
	pnl:AddControl( "CheckBox", { Label = "Hide money", Command = "sbuy_hidemoney" } )
	
	pnl:AddControl( "CheckBox", { Label = "Everything free", Command = "sbuy_freebuy" } )
	pnl:AddControl( "CheckBox", { Label = "Debug mode", Command = "sbuy_debug" } )
	pnl:AddControl( "CheckBox", { Label = "Autoreload prices", Command = "sbuy_autoreload" } )
end

local function ResetMenu(pnl)
	pnl:AddControl( "Header", { Description = "Reset various parts of a Sandbuy game" } )
	
	pnl:Button( "Reset stats & money & respawn players", "resetfull" )
	pnl:Button( "Reset stats & money & weapons", "resetplayers" )
	pnl:Button( "Reset stats", "resetstats" )
end

hook.Add( "PopulateToolMenu", "PopulateSandbuyConfigmenu", function()
	spawnmenu.AddToolMenuOption("Utilities", "Sandbuy Admin", "SandbuySettings", "Sandbuy Settings", "", "", SandbuySettings)
	spawnmenu.AddToolMenuOption( "Utilities", "Sandbuy Admin", "SandbuyReset", "Sandbuy Reset", "", "", ResetMenu )
end)