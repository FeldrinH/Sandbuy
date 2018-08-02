pricer = pricer or {
	WepPrices={},
	AmmoPrices={},
	VehiclePrices={},
	EntPrices={},
	Categories={},
	KillRewards={}
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
	for k,v in pairs(prices) do
		net.WriteString(k)
		net.WriteInt(v, 32)
	end
	
	net.WriteString("")
end

function net.ReadPriceTable()
	local prices = {}
	
	while true do
		local k = net.ReadString()
		if k == "" then break end
		local v = net.ReadInt(32)
		
		prices[k] = v
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
	
	local overrideloaded = table.HasValue(parse, GetConVar("sbuy_overrides"):GetString())
	
	for k,v in pairs(parse) do
		local path = nil
		if file.Exists("data/prices/" .. v , "GAME") then
			path = "data/prices/" .. v .. "/"
			if file.Exists("data/prices/" .. v, "GAME") then
				print("  " .. v .. ": custom, ignoring built-in")
			else
				print("  " .. v .. ": custom")
			end
		elseif #file.Find("gamemodes/sandbuy/prices/" .. v .. "/*", "GAME") > 0 then
			path = "gamemodes/sandbuy/prices/" .. v .. "/"
			print("  " .. v .. ": built-in")
		else
			MsgC(Color(255,0,0), "  " .. v .. ": missing\n")
		end
		
		parse[k] = {name = v, path = path}
	end
	
	if !overrideloaded then
		MsgC(Color(255,255,0), "  Override prices '" .. GetConVar("sbuy_overrides"):GetString() .. "' not set to load\n")
	end
	
	return parse
end

local function LoadFile(filename, categories)
	print(string.upper(string.StripExtension(filename)))
	
	local prices = {}
	
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
				elseif loadprices["<FILTER>"] then
					for k,v in pairs(prices) do
						if !loadprices[k] then
							prices[k] = nil
						end
					end
					
					print("  " .. set.name .. " (filter): " .. table.Count(loadprices))
				else
					for k,v in pairs(loadprices) do
						if v == -4 then
							if (prices[k] or -2) >= -1 then
								v = -1
							else
								v = -2
							end
						end
						prices[k] = v
					end
					
					print("  " .. set.name .. ": " .. table.Count(loadprices))
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
	
	for k,v in pairs(prices) do
		if !isstring(k) then
			prices[tostring(k)] = v
			prices[k] = nil
		end
	end
	
	return prices
end

function pricer.ApplyModifier(category, prices, modifier)	
	for k,v in pairs(pricer.CategoriesList[category]) do
		if pricer.GetPrice(v, prices) >= 0 then
			prices[v] = modifier(pricer.GetPrice(v, prices), v)
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

function pricer.SavePriceTable(filename, prices)
	local sortedprices = {}
	for k,v in pairs(prices) do
		table.insert(sortedprices, {wep = k, price = v})
	end
	table.sort(sortedprices, function(a, b) return tostring(a.wep) < tostring(b.wep) end)
	
	local wfile = file.Open(filename, "w", "DATA")
	
	wfile:Write("{\n")
	for k,v in ipairs(sortedprices) do
		if next(sortedprices, k) == nil then
			wfile:Write("\t\"" .. v.wep .. "\": " .. v.price .. "\n")
		else
			wfile:Write("\t\"" .. v.wep .. "\": " .. v.price .. ",\n")
		end
	end
	wfile:Write("}")
	
	wfile:Close()
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
	local pricetable = localfile and util.JSONToTable(localfile) or {}
	
	if price == -3 then
		pricetable[wep] = nil
	else
		pricetable[wep] = price
	end

	pricer.SavePriceTable(filepath, pricetable)
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
		if v.AdminOnly and pricer.GetPrice(k, pricer.WepPrices) > 0 then
			v.AdminOnly = nil
		end
	end
	itemlist = list.GetForEdit("SpawnableEntities")
	for k,v in pairs(itemlist) do
		if v.AdminOnly and pricer.GetPrice(k, pricer.EntPrices) > 0 then
			v.AdminOnly = nil
		end
	end
	
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
	return pricer.KillRewards[wep] or 1
end

function pricer.GetClipCount(wep, clip)
	return pricer.ClipCount[wep] or (clip < 3 and 3) or 1
end

function pricer.InCategory(class, category)
	return (pricer.CategoriesLookup[category] or {})[class]
end

function pricer.GetPrice(name, prices)
	return prices[name] or -2
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