buylogger = buylogger or {Active=false}

local logfile = nil
local eventcount = 0

function buylogger.Init()
	if buylogger.Active then return end

	local filename = os.date("buylogs/%Y.%m.%d-%H.%M-", os.time()) .. game.GetMap() .. ".txt"
	if !file.Exists("buylogs", "DATA") then
		file.CreateDir("buylogs")
	end
	
	if logfile then
		buylogger.LogTimestamped("logging-enabled", "")
	else
		logfile = file.Open(filename, "a", "DATA")
		buylogger.LogTimestamped("logging-started", game.GetMap())
	end
	
	buylogger.Active = true
end

function buylogger.Close()
	if !logfile then return end
	
	buylogger.Active = false
	
	buylogger.LogTimestamped("logging-ended", "")
	logfile:Close()
	logfile = nil
end

local function GetLogTime()
	return math.Round(CurTime(), 1)
end

function buylogger.FormatPlayer(ply)
	return ply.BuylogID
end
local FormatPlayer = buylogger.FormatPlayer

function buylogger.FormatActor(ent)
	if IsValid(ent) then
		return ent.BuylogID or ent:GetClass()
	else
		return ''
	end
end
local FormatActor = buylogger.FormatActor

function buylogger.EscapeCSV(s)
	if string.find(s, '[,"]') then
		s = '"' .. string.gsub(s, '"', '""') .. '"'
	end
	return s
end

function buylogger.LogKill(ply, victim, wepname, newmoney, delta, ispenalty)
	if buylogger.Active then
		logfile:Write(GetLogTime() .. (ispenalty and ",kill-penalty," or ",kill,") .. FormatPlayer(ply) .. "," .. FormatActor(victim) .. "," .. newmoney .. "," .. delta .. "," .. wepname .. "\n")
	end
end

function buylogger.LogDeath(ply, atk, wepname, newmoney, delta)
	if buylogger.Active then
		--if ply == atk then atk = nil end
		logfile:Write(GetLogTime() .. ",death," .. FormatPlayer(ply) .. "," .. FormatActor(atk) .. "," .. newmoney .. "," .. delta .. "," .. wepname .. "\n")
		eventcount = eventcount + 1
		if eventcount > 30 then
			eventcount = 0
			logfile:Flush()
		end
	end
end

function buylogger.LogDestroy(ply, vehclass, newmoney, delta)
	if buylogger.Active then
		logfile:Write(GetLogTime() .. ",destroy," .. FormatPlayer(ply) .. "," .. vehclass .. "," .. newmoney .. "," .. delta .. "\n")
	end
end

function buylogger.LogBuy(ply, class, buytype, newmoney, delta, amount)
	if buylogger.Active then
		logfile:Write(GetLogTime() .. ",buy-" .. buytype .. "," .. FormatPlayer(ply) .. "," .. class .. "," .. newmoney .. "," .. delta .. "," .. (amount or 1) .. "\n")
		eventcount = eventcount + 1
		if eventcount > 30 then
			eventcount = 0
			logfile:Flush()
		end
	end
end

function buylogger.LogBailout(ply, newmoney, delta)
	if buylogger.Active then
		logfile:Write(GetLogTime() .. ",bailout," .. FormatPlayer(ply) .. ",," .. newmoney .. "," .. delta .. "\n")
	end
end

function buylogger.LogStartingBailout(ply, newmoney, delta)
	if buylogger.Active then
		logfile:Write(GetLogTime() .. ",bailout-start," .. FormatPlayer(ply) .. ",," .. newmoney .. "," .. delta .. "\n")
	end
end

function buylogger.LogReset(resettype, resettarget)
	if buylogger.Active then
		logfile:Write(GetLogTime() .. ",reset-" .. resettype .. "," .. resettarget .. "\n")
	end
end

function buylogger.LogString(log_type, message)
	if buylogger.Active then
		logfile:Write(GetLogTime() .. "," .. log_type .. "," .. message .. "\n")
	end
end

function buylogger.LogTimestamped(log_type, message)
	if logfile then
		logfile:Write(GetLogTime() .. "," .. log_type .. "," .. os.date("%Y-%m-%dT%H:%M:%S", os.time()) .. "," .. message .. "\n")
		logfile:Flush()
	end
end

function buylogger.LogJoin(ply)
	buylogger.LogTimestamped("join", FormatPlayer(ply) .. "," .. buylogger.EscapeCSV(ply:Nick()) .. "," .. ply:SteamID())
end

function buylogger.LogLeave(ply)
	buylogger.LogTimestamped("leave", FormatPlayer(ply) .. "," .. ply:Nick() .. "," .. ply:SteamID())
end