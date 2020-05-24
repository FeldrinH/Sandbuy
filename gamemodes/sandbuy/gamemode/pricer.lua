pricer = pricer or {
	PriceTable = {
		weapon = {},
		ammo = {},
		vehicle = {},
		entity = {},
		custom = {},
		killreward = {},
		//clipcount = {},
		clipsize = {}
	}
}

pricer.TeamKillPenalty = 200
--pricer.ArmorPrice = 8
--pricer.LadderPrice = 50

-- Local variable for faster and more convenient access
local pricetable = pricer.PriceTable
local replplayer = nil

local function MsgRepl(text, color)
	if replplayer then
		replplayer:PrintMessage(HUD_PRINTCONSOLE, text)
	end
	
	if color then
		MsgC(color, text .. '\n')
	else
		print(text)
	end
end

local function WarningRepl(text)
	if replplayer then
		replplayer:PrintMessage(HUD_PRINTCONSOLE, text)
	end
	
	ErrorNoHalt(text .. '\n')
end

function pricer.SetSelected(func)
	for k,v in pairs(pricer.SelectedIcons) do
		local oldprice = pricer.GetPrice(v:GetSpawnName(), v.pricetype or v:GetContentType())
		local newprice = func(v:GetSpawnName(), oldprice, v)
		RunConsoleCommand("setprice", v:GetSpawnName(), newprice, v.pricetype or v:GetContentType(), GetConVar("sbuy_saveto"):GetString())
	end
end

function pricer.StartRepl(ply)
	if IsValid(ply) and !ply:IsListenServerHost() then
		replplayer = ply
	end
end

function pricer.EndRepl()
	replplayer = nil
end

function net.WritePriceTable(prices)
	for k,v in pairs(prices) do
		net.WriteString(k)
		net.WriteInt(v, 32)
	end
	
	net.WriteString("")
end

function net.WriteCategoryTable(name, cat)
	net.WriteString(name)
	
	for k,v in pairs(cat) do
		net.WriteString(k)
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

function net.ReadCategoryTable()
	local cat_lookup = {}
	
	while true do
		local k = net.ReadString()
		if k == "" then break end
		cat_lookup[k] = true
	end

	return cat_lookup
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

function pricer.ValidatePriceSetName(name)
	if !name or string.len(name) == 0 then
		return false
	elseif string.len(name) > 32 then
		return false
	elseif string.match(name, "[^%l%d_%-%.]") then
		return false
	end
	
	return true
end

local function ValidatePriceSetName(name, silent)
	if !name or string.len(name) == 0 then
		return false
	elseif string.len(name) > 32 then
		if !silent then 
			WarningRepl("WARNING: Ignoring invalid priceset name '" .. name .. "'. Name must be 32 characters or shorter")
		end
		return false
	elseif string.match(name, "[^%l%d_%-%.]") then
		if !silent then
			WarningRepl("WARNING: Ignoring invalid priceset name '" .. name .. "'. Name must contain only lowercase letters, numbers, '-', '_' and '.'")
		end
		return false
	end
	
	return true
end

local function ParsePriceString()
	MsgRepl("PRICESETS")
	
	local pricestring = GetConVar("sbuy_prices"):GetString()
	local parse = string.Split(pricestring, " ")
	for k,v in pairs(parse) do
		if !ValidatePriceSetName(v) then
			parse[k] = nil
		end
	end
	
	if replplayer then
		local overrideloaded = table.HasValue(parse, replplayer:GetInfo("sbuy_saveto"))
	end
	
	for k,v in pairs(parse) do
		local path = nil
		if file.Exists("data/prices/" .. v , "GAME") then
			path = "data/prices/" .. v .. "/"
			if #file.Find("gamemodes/sandbuy/prices/" .. v .. "/*", "GAME") > 0 then
				MsgRepl("  " .. v .. ": custom, ignoring built-in")
			else
				MsgRepl("  " .. v .. ": custom")
			end
		elseif #file.Find("gamemodes/sandbuy/prices/" .. v .. "/*", "GAME") > 0 then
			path = "gamemodes/sandbuy/prices/" .. v .. "/"
			MsgRepl("  " .. v .. ": built-in")
		else
			MsgRepl("  " .. v .. ": missing", Color(255,0,0))
		end
		
		parse[k] = {name = v, path = path}
	end
	
	if replplayer and !overrideloaded then
		MsgRepl("  Override prices '" .. replplayer:GetInfo("sbuy_saveto") .. "' not set to load", Color(255,255,0))
	end
	
	return parse
end

local function LoadFile(filename, categories)
	MsgRepl(string.upper(string.StripExtension(filename)))
	
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
					
					MsgRepl("  " .. set.name .. ": " .. table.concat(table.GetKeys(loadprices), ", "))
				elseif loadprices["<FILTER>"] then
					for k,v in pairs(prices) do
						if !loadprices[k] then
							prices[k] = nil
						end
					end
					
					MsgRepl("  " .. set.name .. " (filter): " .. table.Count(loadprices) - 1)
				elseif loadprices["<OVERLAY>"] then
					for k,v in pairs(loadprices) do
						if (prices[k] or -2) >= -1 then
							prices[k] = v
						end
					end
					
					MsgRepl("  " .. set.name .. " (overlay): " .. table.Count(loadprices) - 1)
				else
					for k,v in pairs(loadprices) do
						prices[k] = v
					end
					
					MsgRepl("  " .. set.name .. ": " .. table.Count(loadprices))
				end
			else
				MsgRepl("  " .. set.name .. ": <invalid>", Color(255,0,0))
			end
		end
	end
	
	for k,v in pairs(prices) do
		if v == -2 then
			prices[k] = nil
		end
	end

	return prices
end

local function LoadCategories()
	local cats_lookup = LoadFile("categories.txt", true)
		
	for k,v in pairs(cats_lookup) do
		table.LookupTableNormalize(v)
	end
	
	return cats_lookup
end

local function LoadAmmoPrices()
	local prices = LoadFile("ammoprices.txt")
	
	for k,v in pairs(prices) do
		if !isstring(k) then
			prices[tostring(k)] = v
			prices[k] = nil
		end
	end
	
	return prices
end

if CLIENT then
	function pricer.ModifySelected(func)
		
		
	end
end

function pricer.ApplyModifier(items, pricesets, modifier)
	for i,j in pairs(pricesets) do
		for k,v in pairs(items) do
			if pricer.GetPrice(v, j) >= 0 then
				pricer.PriceTable[j][v] = modifier(pricer.GetPrice(v, j), v)
			end
		end
	end
end

--[[function pricer.PrintModifier(category, prices, modifier)
	for k,v in pairs(pricer.CategoriesLookup[category]) do
		if pricer.GetPrice(k, prices) >= 0 then
			print('"' .. k .. '": ' .. modifier(pricer.GetPrice(k, prices)) .. ',')
		end
	end
end]]

function pricer.SavePriceTable(filename, prices)
	if table.IsEmpty(prices) then 
		if file.Exists(filename, "DATA") then
			file.Delete(filename)
		end
		return
	end

	local wfile = file.Open(filename, "w", "DATA")
	
	wfile:Write("{")
	local isfirst = true
	for k,v in SortedPairs(prices) do
		wfile:Write((isfirst and "\n\t\"" or ",\n\t\"") .. k .. "\": " .. v)
		isfirst = false
	end
	wfile:Write("\n}")
	
	wfile:Close()
end

function pricer.SaveTextTable(filename, prices)
	if table.IsEmpty(prices) then 
		if file.Exists(filename, "DATA") then
			file.Delete(filename)
		end
		return
	end

	local wfile = file.Open(filename, "w", "DATA")
	
	wfile:Write("{")
	local isfirst = true
	for k,v in SortedPairs(prices) do
		wfile:Write((isfirst and "\n\t\"" or ",\n\t\"" ).. k .. "\": \"" .. v .. "\"")
		isfirst = false
	end
	wfile:Write("\n}")
	
	wfile:Close()
end

function pricer.SaveLoadedPrices(priceset)
	local dirpath = "prices/" .. priceset .. "/"
	if !file.Exists("prices/" .. priceset, "DATA") then
		file.CreateDir("prices/" .. priceset)
	end
	
	pricer.SavePriceTable(dirpath .. 'weaponprices.txt', pricetable.weapon)
	pricer.SavePriceTable(dirpath .. 'entityprices.txt', pricetable.entity)
	pricer.SavePriceTable(dirpath .. 'vehicleprices.txt', pricetable.vehicle)
	pricer.SavePriceTable(dirpath .. 'ammoprices.txt', pricetable.ammo)
	pricer.SavePriceTable(dirpath .. 'customprices.txt', pricetable.custom)
	
	//pricer.SavePriceTable(dirpath .. 'clipcount.txt', pricetable.clipcount)
	pricer.SavePriceTable(dirpath .. 'clipsize.txt', pricetable.clipsize)
	
	pricer.SavePriceTable(dirpath .. 'killrewards.txt', pricetable.killreward)
	pricer.SaveTextTable(dirpath .. 'sourceweapons.txt', pricer.SourceWeapon)
	
	-- TODO: Save categories
end

function pricer.SetPrice(wep, price, filename, priceset, istext)
	if priceset == nil then
		error("No priceset specified")
	end
	
	if filename == "categories.txt" then
		error("Incorrect function for setting category values. Use pricer.SetCategory.")
	end
	
	if !file.Exists("prices/" .. priceset, "DATA") then
		if #file.Find("gamemodes/sandbuy/prices/" .. priceset .. "/*", "GAME") > 0 then
			error("Attempt to set price on built-in priceset. If this was intentional, create copy of priceset in data/prices/ directory")
		end
		file.CreateDir("prices/" .. priceset)
	end
	
	local filepath = "prices/" .. priceset .. "/" .. filename
	
	local localfile = file.Read(filepath)
	local pricetable = {}
	if localfile then
		pricetable = util.JSONToTable(localfile)
		if !pricetable then
			error("Failed to parse existing prices for " .. filepath)
		end
		if filename == "ammoprices.txt" then
			for k,v in pairs(pricetable) do
				if !isstring(k) then
					pricetable[tostring(k)] = v
					pricetable[k] = nil
				end
			end
		end
	end
	
	if price == -3 then
		pricetable[wep] = nil
	else
		pricetable[wep] = price
	end

	if istext then
		pricer.SaveTextTable(filepath, pricetable)
	else
		pricer.SavePriceTable(filepath, pricetable)
	end
	
	hook.Call("PostSetPrice", nil, wep, price, filename, priceset)
end

function pricer.LoadPrices()
	MsgRepl("------PRICES------")

	pricer.PriceString = ParsePriceString()

	pricetable.weapon = LoadFile("weaponprices.txt")
	pricetable.entity = LoadFile("entityprices.txt")
	pricetable.vehicle = LoadFile("vehicleprices.txt")
	pricetable.ammo = LoadAmmoPrices()
	
	pricetable.custom = LoadFile('customprices.txt')
	
	//pricetable.clipcount = LoadFile('clipcount.txt')
	pricetable.clipsize = LoadFile('clipsize.txt')
	
	pricetable.killreward = LoadFile("killrewards.txt")
	
	pricer.SourceWeapon = LoadFile("sourceweapons.txt")
	pricer.CategoriesLookup = LoadCategories()
	
	hook.Call("OnPricesLoaded")
	
	MsgRepl("")
	MsgRepl("Reloaded prices")
	MsgRepl("------------------")
end

function pricer.SendPrices(ply, reload)
	net.Start("newprices")
	net.WriteUInt(reload, 2)
	net.WritePriceTable(pricetable.weapon)
	net.WritePriceTable(pricetable.entity)
	net.WritePriceTable(pricetable.vehicle)
	net.WritePriceTable(pricetable.ammo)
	net.WritePriceTable(pricetable.custom)

	if reload != 3 then
		//net.WritePriceTable(pricetable.clipcount)
		net.WritePriceTable(pricetable.clipsize)
		for k,v in pairs(pricer.CategoriesLookup) do
			if k != "machines" then
				net.WriteCategoryTable(k, v)
			end
		end
		net.WriteString("")
	end
	
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
	return pricetable.killreward[wep] or 1
end

function pricer.GetSourceWeapon(wep)
	return pricer.SourceWeapon[wep] or wep
end

function pricer.GetClipCount(wep, clip)
	return (clip < 2 and 2) or 1
end

function pricer.GetClipSize(wep)
	return pricetable.clipsize[wep]
end

function pricer.InCategory(class, category)
	return (pricer.CategoriesLookup[category] or {})[class]
end

function pricer.GetPrice(name, priceset)
	return pricetable[priceset][name] or -2
end

function pricer.GetPrintPrice(price)
	if price == -5 then
		return "BAD"
	elseif price == -4 then
		return "ADMIN"
	elseif price == -3 then
		return "RESET"
	elseif price == -2 then
		return "UNDEFINED"
	elseif price == -1 then
		return "NOT FOR SALE"
	elseif price < 0 then
		return "INVALID"
	elseif price == 0 then
		return "FREE"
	else
		return "$" .. price
	end
end

function pricer.CanBuy(money, price)
	return price >= 0 and price <= money
end