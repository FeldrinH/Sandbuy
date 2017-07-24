surface.CreateFont("BigMoney", {font="Arial", size=50})

local nobuy_color = Color( 255, 0, 0 )
local buy_color = Color( 0, 255, 0 )
local has_color = Color( 150, 150, 150 )

local function UpdateWepPrice( icon, money )
	icon:SetTextColor( ( LocalPlayer():HasWeapon( icon:GetSpawnName() ) and has_color ) or ( pricer.CanBuy( money, pricer.GetPrice( icon:GetSpawnName(), pricer.WepPrices ) ) and buy_color ) or nobuy_color )
end
local function UpdateEntPrice( icon, money )
	icon:SetTextColor( ( pricer.CanBuy( money, pricer.GetPrice( icon:GetSpawnName(), pricer.EntPrices ) ) and buy_color ) or nobuy_color )
end
local function UpdateVehiclePrice( icon, money )
	icon:SetTextColor( ( pricer.CanBuy( money, pricer.GetPrice( icon:GetSpawnName(), pricer.VehiclePrices ) ) and buy_color ) or nobuy_color )
end
local function UpdateAmmoPrice( icon, money )
	local iconcolor = ( pricer.CanBuy( money, pricer.GetPrice( icon:GetSpawnName(), pricer.AmmoPrices ) * icon.AmmoAmount ) and buy_color ) or nobuy_color
	icon:SetTextColor( iconcolor )
	icon.AmountLabel:SetTextColor( iconcolor )
end
local function UpdateAmmoOption( opt, money )
	opt:SetTextColor( ( pricer.CanBuy( money, opt.AmmoPrice ) and buy_color ) or nobuy_color )
end

function spawnmenu.UpdateSpawnlistMoney(money)
	if IsValid(g_SpawnMenu.PrimaryAmmoOption) then
		UpdateAmmoOption(g_SpawnMenu.PrimaryAmmoOption, money)
	end
	if IsValid(g_SpawnMenu.SecondaryAmmoOption) then
		UpdateAmmoOption(g_SpawnMenu.SecondaryAmmoOption, money)
	end
	if g_SpawnMenu.MoneyLables then
		for k,v in pairs(g_SpawnMenu.MoneyLables) do
			v:SetText("$" .. money)
		end
	end
	if g_SpawnMenu.PriceIcons then
		for k,v in pairs(g_SpawnMenu.PriceIcons) do
			if v:GetContentType() == "weapon" then
				UpdateWepPrice(v, money)
			elseif v:GetContentType() == "entity" then
				UpdateEntPrice(v, money)
			elseif v:GetContentType() == "vehicle" or v:GetContentType() == "simfphys_vehicles" then
				UpdateVehiclePrice(v, money)
			elseif v:GetContentType() == "ammo" then
				UpdateAmmoPrice(v, money)
			end
		end
	end
end

function spawnmenu.UpdateSpawnlistHasWeapon(wep)
	if g_SpawnMenu.PriceIcons then
		for k,v in pairs(g_SpawnMenu.PriceIcons) do
			if v:GetSpawnName() == wep then
				v:SetTextColor( has_color )
			end
		end
	end
end