buylogger = buylogger or {Active=false}

function buylogger.Init()
	if !file.Exists("buylog.txt", "DATA") then
		file.Write("buylog.txt", "action,player,target,newmoney,killweapon\n")
	end
	
	buylogger.File = file.Open("buylog.txt", "a", "DATA")
	buylogger.File:Write(os.date("%H:%M:%S %d.%m.%Y", os.time()) .. " " .. game.GetMap() .. " --LOGGING STARTED--\n")
	buylogger.Active = true
end

function buylogger.Close()
	if buylogger.Active then
		buylogger.Active = false
		buylogger.File:Write(os.date("%H:%M:%S %d.%m.%Y", os.time()) .. " --LOGGING ENDED--\n")
		buylogger.File:Close()
	end
end

function buylogger.LogKill(ply, victim, wep, newmoney, delta)
	if buylogger.Active then
		buylogger.File:Write("kill," .. ply:Nick() .. "," .. victim:Nick() .. "," .. newmoney .. "," .. delta .. "," .. (IsValid(wep) and wep:GetClass() or "") .. "\n")
		--buylogger.File:Flush()
	end
end

function buylogger.LogDeath(ply, atk, wep, newmoney, delta)
	if buylogger.Active then
		if ply == atk then atk = nil end
		buylogger.File:Write("death," .. ply:Nick() .. "," .. (IsValid(atk) and atk:IsPlayer() and atk:Nick() or "") .. "," .. newmoney .. "," .. delta .. "," .. (IsValid(wep) and wep:GetClass() or "") .. "\n")
		--buylogger.File:Flush()
	end
end

function buylogger.LogBuy(ply, class, buytype, newmoney, delta)
	if buylogger.Active then
		buylogger.File:Write("buy-" .. buytype .. "," .. ply:Nick() .. "," .. class .. "," .. newmoney .. "," .. delta .. "\n")
		if buytype != "ammo" then
			buylogger.File:Flush()
		end
	end
end

function buylogger.LogBailout(ply, newmoney, delta)
	if buylogger.Active then
		buylogger.File:Write("bailout," .. ply:Nick() .. ",," .. newmoney .. "," .. delta .. "\n")
		--buylogger.File:Flush()
	end
end

function buylogger.LogReset(resettype, newmoney)
	if buylogger.Active then
		buylogger.File:Write("reset-" .. resettype .. ",,," .. newmoney .. "\n")
		--buylogger.File:Flush()
	end
end

function buylogger.LogJoin(ply)
	if buylogger.Active then
		buylogger.File:Write(os.date("%H:%M:%S %d.%m.%Y", os.time()) .. " --" .. ply:Nick() .. " JOINED--\n")
	end
end

function buylogger.LogLeave(ply)
	if buylogger.Active then
		buylogger.File:Write(os.date("%H:%M:%S %d.%m.%Y", os.time()) .. " --" .. ply:Nick() .. " LEFT--\n")
	end
end