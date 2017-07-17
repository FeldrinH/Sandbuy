pricer = pricer or {DefaultMoney=800, KillMoney=1000, DeathMoney=200, WepPrices={default=-2,individual={}}, VehiclePrices={default=-2,individual={}}, EntPrices={default=-2,individual={}}}

function pricer.LoadPrices()
	local WepPrices = util.JSONToTable(file.Read("gamemodes/sandbuy/prices/weaponprices.txt", "GAME"))
	if !WepPrices then
		error("Invalid weaponprices.txt")
	else
		pricer.WepPrices = WepPrices
	end
	--pricer.VehiclePrices = util.JSONToTable(file.Read("vehicleprices.txt"))
	--pricer.EntPrices = util.JSONToTable(file.Read("entityprices.txt"))
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