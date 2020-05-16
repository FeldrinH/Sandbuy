buylogger = buylogger or {Active=false}

function buylogger.Init()
	if buylogger.Active then return end

	local filename = os.date("buylogs/%Y.%m.%d-%H.%M-", os.time()) .. game.GetMap() .. ".txt"
	if !file.Exists("buylogs", "DATA") then
		file.CreateDir("buylogs")
	end
	
	if buylogger.File then
		buylogger.LogTimestamped("logging-enabled", "")
	else
		if !file.Exists(filename, "DATA") then
			file.Write(filename, "action,time,player,target,newmoney,deltamoney,killweapon\n")
		end
		buylogger.File = file.Open(filename, "a", "DATA")
		buylogger.LogTimestamped("logging-started", game.GetMap())
	end
	
	buylogger.Active = true
end

function buylogger.Close()
	if !buylogger.File then return end
	
	buylogger.Active = false
	
	buylogger.LogTimestamped("logging-ended", "")
	buylogger.File:Close()
	buylogger.File = nil
end

local function GetLogTime()
	return math.Round(CurTime(), 1)
end

function buylogger.LogKill(ply, victim, wepname, newmoney, delta)
	if buylogger.Active then
		buylogger.File:Write(GetLogTime() .. ",kill," .. ply:Nick() .. "," .. (victim:IsPlayer() and victim:Nick() or victim:GetClass()).. "," .. newmoney .. "," .. delta .. "," .. wepname .. "\n")
	end
end

function buylogger.LogDeath(ply, atk, wepname, newmoney, delta)
	if buylogger.Active then
		--if ply == atk then atk = nil end
		buylogger.File:Write(GetLogTime() .. ",death," .. ply:Nick() .. "," .. (IsValid(atk) and atk:IsPlayer() and atk:Nick() or "") .. "," .. newmoney .. "," .. delta .. "," .. wepname .. "\n")
	end
end

function buylogger.LogDestroy(ply, veh, newmoney, delta)
	if buylogger.Active then
		buylogger.File:Write(GetLogTime() .. ",destroy," .. ply:Nick() .. "," .. veh:GetClass() .. "," .. newmoney .. "," .. delta .. "\n")
	end
end

function buylogger.LogBuy(ply, class, buytype, newmoney, delta)
	if buylogger.Active then
		buylogger.File:Write(GetLogTime() .. ",buy-" .. buytype .. "," .. ply:Nick() .. "," .. class .. "," .. newmoney .. "," .. delta .. "\n")
		if buytype != "ammo" then
			buylogger.File:Flush()
		end
	end
end

function buylogger.LogBailout(ply, newmoney, delta)
	if buylogger.Active then
		buylogger.File:Write(GetLogTime() .. ",bailout," .. ply:Nick() .. ",," .. newmoney .. "," .. delta .. "\n")
	end
end

function buylogger.LogStartingBailout(ply, newmoney, delta)
	if buylogger.Active then
		buylogger.File:Write(GetLogTime() .. ",bailout-start," .. ply:Nick() .. ",," .. newmoney .. "," .. delta .. "\n")
	end
end

function buylogger.LogReset(resettype, resettarget)
	if buylogger.Active then
		buylogger.File:Write(GetLogTime() .. ",reset-" .. resettype .. "," .. resettarget .. "\n")
	end
end

function buylogger.LogString(log_type, message)
	if buylogger.Active then
		buylogger.File:Write(GetLogTime() .. "," .. log_type .. "," .. GetLogTime() .. "," .. message .. "\n")
	end
end

function buylogger.LogTimestamped(log_type, message)
	if buylogger.File then
		buylogger.File:Write(GetLogTime() .. "," .. log_type .. "," .. message .. "," .. os.date("%H:%M:%S %d.%m.%Y", os.time()) .. "\n")
	end
end

function buylogger.LogJoin(ply)
	buylogger.LogTimestamped("join", ply:Nick())
end

function buylogger.LogLeave(ply)
	buylogger.LogTimestamped("leave", ply:Nick())
end