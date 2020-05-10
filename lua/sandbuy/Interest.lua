concommand.Add("givemoney", function(ply, cmd, args)
	local target = nil
	if args[2] then
		for k,v in pairs(player.GetAll()) do 
			if v:Nick() == args[2] then
				target = v
				break
			end
		end
	else
		target = ply:GetEyeTrace().HitEntity
	end
	if !IsValid(target) or !target:IsPlayer() then return end
	if ply:GetPos():Distance(target:GetPos()) > 500 then ply:PrintMessage(HUD_PRINTTALK, "Player too far") return end
	
	local amount = tonumber(args[1])
	if !amount or amount < 0 then ply:PrintMessage(HUD_PRINTTALK, "Invalid amount") return end
	if ply:GetMoney() < amount then
		amount = ply:GetMoney()
	end
	
	ply:AddMoney(-amount)
	target:AddMoney(amount)
	
	ply:PrintMessage(HUD_PRINTTALK, "Given " .. target:Nick() .. " $" .. amount)
	target:PrintMessage(HUD_PRINTCENTER, "You were given $" .. amount .. " by " .. ply:Nick())
end)

concommand.Add("deposit", function(ply, cmd, args)
	if !ply:Alive() or ply.IsAFK  then
		ply:PrintMessage(HUD_PRINTTALK, "Not allowed to deposit while dead or AFK")
		return
	end
	
	local amount = tonumber(args[1])
	if !amount or amount < 0 then ply:PrintMessage(HUD_PRINTTALK, "Invalid amount") return end
	if ply:GetMoney() < amount then
		amount = ply:GetMoney()
	end
	
	ply:PrintMessage(HUD_PRINTTALK, "About to deposit $" .. amount .. ". Stand still for 5 seconds to complete deposit.")
	
	local depositid = "DepositTime_" .. ply:SteamID()
	timer.Create(depositid, 0.5, 10, function()
		if !ply:GetVelocity():IsZero() then
			timer.Remove(depositid)
			ply:PrintMessage(HUD_PRINTTALK, "Deposit cancelled.")
			return
		end
	
		if timer.RepsLeft(depositid) <= 0 then
			if ply:GetMoney() < amount then
				amount = ply:GetMoney()
			end
		
			ply:AddMoney(-amount)
			ply.Deposit = (ply.Deposit or 0) + amount
			
			ply:PrintMessage(HUD_PRINTTALK, "Deposited $" .. amount .. ". You now have $" .. ply.Deposit .. " in bank")
			
			hook.Remove("Think", depositid)
		end
	end)
end)

concommand.Add("withdraw", function(ply, cmd, args)
	if !ply:Alive() or ply.IsAFK then
		ply:PrintMessage(HUD_PRINTTALK, "Not allowed to withdraw while dead or AFK")
		return
	end
	
	local amount = tonumber(args[1])
	if !amount or amount < 0 then ply:PrintMessage(HUD_PRINTTALK, "Invalid amount") return end
	if (ply.Deposit or 0) < amount then
		amount = ply.Deposit or 0
	end
	
	ply:AddMoney(amount)
	ply.Deposit = (ply.Deposit or 0) - amount
	
	ply:PrintMessage(HUD_PRINTTALK, "Withdrawn $" .. amount .. ". You now have $" .. ply.Deposit .. " in bank")
end)

local function GetTax(ply)
	local running = ply.Deposit or 0
	return math.floor(running * math.min(running / 200000, 0.5))
end

local function GetInterest(ply)
	return math.floor((ply.Deposit or 0) * 0.05)
end

hook.Add("HandlePlayerDeath", "Sandbuy_BankTax", function(ply, killer, weapon, weaponname)
	local tax = GetTax(ply)
	ply.Deposit = (ply.Deposit or 0) - tax
	ply.LastTax = tax
end)

hook.Add("GetKillReward", "Sandbuy_BankTax", function(ply, killer, killmoney, deltamoney, weapon, weaponname)
	return killmoney + deltamoney + ply.LastTax
end)

concommand.Add("bank", function(ply, cmd, args)
	local interest = GetInterest(ply)
	
	ply:PrintMessage(HUD_PRINTTALK, "You have $" .. (ply.Deposit or 0) .. " in bank")
	ply:PrintMessage(HUD_PRINTTALK, "On death you would lose $" .. GetTax(ply))
	ply:PrintMessage(HUD_PRINTTALK, "Earning $" .. GetInterest(ply) .. " interest next minute")
end)

concommand.Add("allbank", function(ply, cmd, args)
	if !ply:IsSuperAdmin() then return end

	for k,v in SortedPairsByMemberValue(player.GetAll(), "Deposit", true) do
		ply:PrintMessage(HUD_PRINTTALK, v:Nick() .. " has $" .. (v.Deposit or 0) .. " in bank")
	end
end)

timer.Create("Sandbuy_BankInterest", 60, 0, function()
	for k,v in pairs(player.GetAll()) do
		if v:Alive() and !v.IsAFK then
			local interest = GetInterest(v)
			v.Deposit = (v.Deposit or 0) + interest
			
			v:PrintMessage(HUD_PRINTTALK, "You earned $" .. interest .. " interest. You now have $" .. v.Deposit .. " in bank")
		else
			v:PrintMessage(HUD_PRINTTALK, "You do not earn interest while dead or AFK")
		end
	end
end)

hook.Add("LoadStatSaver", "Bank_Store", function(ply, stats)
	ply.Deposit = math.max(stats.deposit or 0, ply.Deposit or 0)
end)

hook.Add("SaveStatSaver", "Bank_Store", function(ply, stats)
	stats.deposit = ply.Deposit
end)