pricer = pricer or {
	DefaultMoney=800,
	KillMoney=1000,
	DeathMoney=200,
	WepPrices={default=-2,individual={}},
	AmmoPrices={default=-2,individual={}},
	VehiclePrices={default=-2,individual={}},
	EntPrices={default=-2,individual={}},
	AmmoData={}
}

pricer.ClipCount = {
	sbuy_medkit = 1
}

--[[local hl2wepammo = {
	weapon_357={p="357"},
	weapon_ar2={p="AR2", s="AR2AltFire"},
	weapon_bugbait={},
	weapon_crossbow={p="XBowBolt"},
	weapon_crowbar={},
	weapon_frag={p="Grenade"},
	weapon_physcannon={},
	weapon_pistol={p="Pistol"},
	weapon_rpg={p="RPG_Round"},
	weapon_shotgun={p="Buckshot"},
	weapon_slam={s="slam"},
	weapon_smg1={p="SMG1", s="SMG1_Grenade"},
	weapon_stunstick={},
	weapon_physgun={}
}]]--

function net.WritePriceTable(prices)
	net.WriteInt(prices.default, 32)
	
	for k,v in pairs(prices.individual) do
		net.WriteString(k)
		net.WriteInt(v, 32)
	end
	
	net.WriteString("")
end

function net.ReadPriceTable()
	local prices = {}
	
	prices.default = net.ReadInt(32)
	prices.individual = {}
	
	while true do
		local k = net.ReadString()
		if k == "" then break end
		local v = net.ReadInt(32)
		
		prices.individual[k] = v
	end

	return prices
end

local function LoadFile(filename)
	local inclfile = file.Read("gamemodes/sandbuy/prices/" .. filename, "GAME")
	if !inclfile then
		ErrorNoHalt("ERROR: No included " .. filename)
		return
	end
	local prices = util.JSONToTable(inclfile)
	if !prices then
		ErrorNoHalt("ERROR: Included " .. filename .. " invalid")
		return
	end
	
	local localfile = file.Read(filename)
	if localfile then
		local localprices = util.JSONToTable(localfile)
		if localprices then
			print("Found valid local " .. filename .. ". Adding to included one")
			
			prices.default = localprices.default or prices.default
			for k,v in pairs(localprices.individual) do
				prices.individual[k] = v
			end
		else
			print("Local " .. filename .. " invalid. Ignoring")
		end
	end
	
	return prices
end

local function LoadAmmoData()
	local ammo = LoadFile("ammo.txt")
	if !ammo then return end
	
	for k,v in pairs(ammo.individual) do
		if !isstring(k) then
			ammo.individual[tostring(k)] = v
			ammo.individual[k] = nil
		end
	end
	
	pricer.AmmoData = ammo.individual
	
	local prices = {}
	prices.default = ammo.default
	prices.individual = {}
	for k,v in pairs(ammo.individual) do
		prices.individual[k] = v.Price
		v.Price = nil
	end
	
	pricer.AmmoPrices = prices
end

function pricer.LoadPrices()
	pricer.WepPrices = LoadFile("weaponprices.txt") or pricer.WepPrices
	pricer.EntPrices = LoadFile("entityprices.txt") or pricer.EntPrices
	pricer.VehiclePrices = LoadFile("vehicleprices.txt") or pricer.VehiclePrices
	LoadAmmoData()
	
	local itemlist = list.GetForEdit("Weapon")
	for k,v in pairs(itemlist) do
		if v.AdminOnly and pricer.GetPrice(k, pricer.WepPrices) >= 0 then
			v.AdminOnly = false
		end
	end
	--[[itemlist = list.GetForEdit("SpawnableEntities")
	for k,v in pairs(itemlist) do
		if v.AdminOnly and v.Category != "Base Totem" and pricer.GetPrice(k, pricer.WepPrices) >= 0 then
			v.AdminOnly = false
		end
	end]]--
end

function pricer.SendPrices(ply ,reload)
	net.Start("newprices")
	net.WriteBool(reload)
	net.WritePriceTable(pricer.WepPrices)
	net.WritePriceTable(pricer.EntPrices)
	net.WritePriceTable(pricer.VehiclePrices)
	net.WritePriceTable(pricer.AmmoPrices)
	net.WriteTable(pricer.AmmoData)
	if ply then
		net.Send(ply)
	else
		net.Broadcast()
	end
end

--[[function pricer.GetAmmoData(class)
	local wep = weapons.GetStored(class)
	if wep then
		ammo1 = wep.Primary.Ammo
		ammo2 = wep.Secondary.Ammo
		local data = {}
		if ammo1 and game.GetAmmoID(ammo1) != -1 then
			data.ammo1 = game.GetAmmoName(game.GetAmmoID(ammo1))
			data.clip1 = wep.Primary.ClipSize
		end
		if ammo2 and game.GetAmmoID(ammo2) != -1 then
			data.ammo2 = game.GetAmmoName(game.GetAmmoID(ammo2))
			data.clip2 = wep.Secondary.ClipSize
		end
		return data
	end
	
	wep = hl2wepammo[class]
	if wep then
		return wep
	end
	
	return {}
end]]--

function pricer.GetPrice(name, prices)
	return prices.individual[name] or prices.default
end

function pricer.GetPrintPrice(price)
	if price < -1 then
		return "UNDEFINED"
	elseif price == -1 then
		return "NOT FOR SALE"
	elseif price == 0 then
		return "FREE"
	else
		return "$" .. price
	end
end

function pricer.CanBuy(money, price)
	return price >= 0 and price <= money
end