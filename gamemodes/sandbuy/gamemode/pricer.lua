pricer = pricer or {
	WepPrices={default=-2,individual={}},
	AmmoPrices={default=-2,individual={}},
	VehiclePrices={default=-2,individual={}},
	EntPrices={default=-2,individual={}},
	Categories={},
	KillRewards={individual={}}
}

pricer.TeamKillPenalty = 200
--pricer.ArmorPrice = 8
--pricer.LadderPrice = 50

pricer.ClipCount = {
}

pricer.ClipSize = {
	sbuy_medkit = 20,
	sbuy_armorkit = 10,
	weapon_rpg = 1
}

pricer.WepEnts = {
	--TODO: Add weapons
}

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

function table.ListToLookupTable(vlist)
	local ltable = {}
	for k,v in pairs(vlist) do
		ltable[v] = true
	end
	return ltable
end

function table.LookupTableToList(ltable)
	local vlist = {}
	for k,v in pairs(ltable) do
		if v then
			table.insert(vlist, k)
		end
	end
	return vlist
end

function table.LookupTableNormalize(ltable)
	for k,v in pairs(ltable) do
		if v and v != 0 then
			ltable[k] = true
		else
			ltable[k] = nil
		end
	end
end

local function ValidatePriceSetName(name)
	if string.len(name) == 0 then
		return false
	elseif string.len(name) > 32 then
		ErrorNoHalt("WARNING: Ignoring invalid priceset name '" .. name .. "'. Name must be 32 characters or shorter")
		return false
	elseif string.match(name, "[^%l%d_-]") then
		ErrorNoHalt("WARNING: Ignoring invalid priceset name '" .. name .. "'. Name must contain only lowercase letters, numbers, '-' and '_'")
		return false
	end
	
	return true
end

local function ParsePriceString()
	print("PRICESETS")
	
	local pricestring = GetConVar("sbuy_prices"):GetString()
	local parse = string.Split(pricestring, " ")
	for k,v in pairs(parse) do
		if !ValidatePriceSetName(v) then
			parse[k] = nil
		end
	end
	
	for k,v in pairs(parse) do
		local path = nil
		if #file.Find("gamemodes/sandbuy/prices/" .. v .. "/*", "GAME") > 0 then
			path = "gamemodes/sandbuy/prices/" .. v .. "/"
			if file.Exists("data/prices/" .. v, "GAME") then
				MsgC(Color(255,255,0), "  " .. v .. ": built-in, ignoring custom\n")
			else
				print("  " .. v .. ": built-in")
			end
		elseif file.Exists("data/prices/" .. v , "GAME") then
			path = "data/prices/" .. v .. "/"
			print("  " .. v .. ": custom")
		else
			MsgC(Color(255,0,0), "  " .. v .. ": missing\n")
		end
		
		parse[k] = {name = v, path = path}
	end
	
	return parse
end

local function LoadFile(filename, categories)
	print(string.upper(string.StripExtension(filename)))
	
	local prices = categories and {} or {default=-2,individual={}}
	
	for num,set in pairs(pricer.PriceString) do
		if !set.path then continue end
		
		local loadname = set.path .. filename
		local loadfile = file.Read(loadname, "GAME")
		if loadfile then
			local loadprices = util.JSONToTable(loadfile)
			if loadprices then
				if categories then
					for kc,vc in pairs(loadprices) do
						if prices[kc] then
							for k,v in pairs(vc) do
								prices[kc][k] = v
							end
						else
							prices[kc] = vc
						end
					end
					
					print("  " .. set.name .. ": " .. table.concat(table.GetKeys(loadprices), ", "))
				else
					for k,v in pairs(loadprices.individual) do
						if v == -4 then
							if (prices.individual[k] or -2) >= -1 then
								v = -1
							else
								v = -2
							end
						end
						prices.individual[k] = v
					end
					
					print("  " .. set.name .. ": " .. table.Count(loadprices.individual))
				end
			else
				MsgC(Color(255,0,0), "  " .. set.name .. ": <invalid>\n")
			end
		end
	end
	
	return prices
end

local function LoadCategories()
	local cats_lookup = LoadFile("categories.txt", true)
	if !cats_lookup then return end
	
	local cats_list = {}
	
	for k,v in pairs(cats_lookup) do
		table.LookupTableNormalize(v)
		cats_list[k] = table.LookupTableToList(v)
	end
	
	return cats_lookup, cats_list
end

local function LoadAmmoPrices()
	local prices = LoadFile("ammoprices.txt")
	if !prices then return end
	
	for k,v in pairs(prices.individual) do
		if !isstring(k) then
			prices.individual[tostring(k)] = v
			prices.individual[k] = nil
		end
	end
	
	return prices
end

function pricer.ApplyModifier(category, prices, modifier)	
	for k,v in pairs(pricer.CategoriesList[category]) do
		if pricer.GetPrice(v, prices) >= 0 then
			prices.individual[v] = modifier(pricer.GetPrice(v, prices), v)
		end
	end
end

function pricer.PrintModifier(category, prices, modifier)
	for k,v in pairs(pricer.CategoriesList[category]) do
		if pricer.GetPrice(v, prices) >= 0 then
			print('"' .. v .. '": ' .. modifier(pricer.GetPrice(k, prices)) .. ',')
		end
	end
end

function pricer.SetPrice(wep, price, filename, priceset)
	if priceset == nil then
		priceset = GetConVar("sbuy_overrides"):GetString()
	end
	
	if !file.Exists("prices/" .. priceset, "DATA") then
		file.CreateDir("prices/" .. priceset)
	end
	
	local filepath = "prices/" .. priceset .. "/" .. filename
	
	local localfile = file.Read(filepath)
	local pricetable = localfile and util.JSONToTable(localfile) or {individual={}}
	
	if price == -3 then
		pricetable.individual[wep] = nil
	else
		pricetable.individual[wep] = price
	end

	file.Write(filepath, util.TableToJSON(pricetable, true))
end

function pricer.LoadPrices()
	print("------PRICES------")

	pricer.PriceString = ParsePriceString()

	pricer.WepPrices = LoadFile("weaponprices.txt") or pricer.WepPrices
	pricer.EntPrices = LoadFile("entityprices.txt") or pricer.EntPrices
	pricer.VehiclePrices = LoadFile("vehicleprices.txt") or pricer.VehiclePrices
	pricer.AmmoPrices = LoadAmmoPrices() or pricer.AmmoPrices
	
	local cats_lookup, cats_list = LoadCategories()
	pricer.CategoriesLookup = cats_lookup or pricer.CategoriesLookup
	pricer.CategoriesList = cats_list or pricer.CategoriesList
	
	pricer.KillRewards = LoadFile("killrewards.txt") or pricer.KillRewards
	
	hook.Run("ApplyPriceModifiers")
	
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
	
	print()
	print("Reloaded prices")
	print("------------------")
end

function pricer.SendPrices(ply, reload)
	net.Start("newprices")
	net.WriteBool(reload)
	net.WritePriceTable(pricer.WepPrices)
	net.WritePriceTable(pricer.EntPrices)
	net.WritePriceTable(pricer.VehiclePrices)
	net.WritePriceTable(pricer.AmmoPrices)
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

function pricer.GetKillReward(wep)
	return pricer.KillRewards.individual[wep] or 1
end

function pricer.GetClipCount(wep, clip)
	return pricer.ClipCount[wep] or (clip < 3 and 3) or 1
end

function pricer.InCategory(class, category)
	return (pricer.CategoriesLookup[category] or {})[class]
end

function pricer.GetPrice(name, prices)
	return prices.individual[name] or prices.default
end

function pricer.GetPrintPrice(price)
	if price == -4 then
		return "BLOCK"
	elseif price == -3 then
		return "RESET"
	elseif price < -1 then
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