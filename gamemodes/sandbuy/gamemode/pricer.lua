pricer = pricer or {DefaultMoney=800, KillMoney=1000, DeathMoney=200, WepPrices={default=-2,individual={}}, VehiclePrices={default=-2,individual={}}, EntPrices={default=-2,individual={}}}

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
	local file = file.Read("gamemodes/sandbuy/prices/" .. filename, "GAME")
	if !file then
		ErrorNoHalt("ERROR: No included " .. filename)
		return
	end
	local prices = util.JSONToTable(file)
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

function pricer.LoadPrices()
	pricer.WepPrices = LoadFile("weaponprices.txt") or pricer.WepPrices
	--pricer.VehiclePrices = LoadFile("vehicleprices.txt") or pricer.VehiclePrices
	--pricer.EntPrices = LoadFile("entityprices.txt") or pricer.EntPrices
end

function pricer.GetPrice(name, prices)
	return prices.individual[name] or prices.default
end

function pricer.GetPrintPrice(price)
	if price < -1 then
		return "UNDEFINED"
	elseif price == -1 then
		return "NOT FOR SALE"
	else
		return "$" .. price
	end
end

function pricer.CanBuy(money ,price)
	return price >= 0 and price <= money
end