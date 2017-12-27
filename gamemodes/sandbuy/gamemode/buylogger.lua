buylogger = buylogger or {Active=false}

function buylogger.Init(isfreebuy)
	if buylogger.Active then return end

	if !file.Exists("buylog.txt", "DATA") then
		file.Write("buylog.txt", "action,player,target,newmoney,killweapon\n")
	end
	
	buylogger.File = file.Open("buylog.txt", "a", "DATA")
	if isfreebuy then
		buylogger.File:Write(os.date("%H:%M:%S %d.%m.%Y", os.time()) .. " --FREEBUY DISABLED--\n")
	else
		buylogger.File:Write(os.date("%H:%M:%S %d.%m.%Y", os.time()) .. " " .. game.GetMap() .. " --LOGGING STARTED--\n")
	end
	buylogger.Active = true
end

function buylogger.Close(isfreebuy)
	if !buylogger.Active then return end
	
	buylogger.Active = false
	if isfreebuy then
		buylogger.File:Write(os.date("%H:%M:%S %d.%m.%Y", os.time()) .. " --FREEBUY ENABLED--\n")
	else
		buylogger.File:Write(os.date("%H:%M:%S %d.%m.%Y", os.time()) .. " --LOGGING ENDED--\n")
	end
	buylogger.File:Close()
end

function buylogger.LogKill(ply, victim, wepname, newmoney, delta)
	if buylogger.Active then
		buylogger.File:Write("kill," .. ply:Nick() .. "," .. (victim:IsPlayer() and victim:Nick() or victim:GetClass()).. "," .. newmoney .. "," .. delta .. "," .. wepname .. "\n")
		--buylogger.File:Flush()
	end
end

function buylogger.LogDeath(ply, atk, wepname, newmoney, delta)
	if buylogger.Active then
		--if ply == atk then atk = nil end
		buylogger.File:Write("death," .. ply:Nick() .. "," .. (IsValid(atk) and atk:IsPlayer() and atk:Nick() or "") .. "," .. newmoney .. "," .. delta .. "," .. wepname .. "\n")
		--buylogger.File:Flush()
	end
end

function buylogger.LogDestroy(ply, veh, newmoney, delta)
	if buylogger.Active then
		buylogger.File:Write("destroy," .. ply:Nick() .. "," .. veh:GetClass() .. "," .. newmoney .. "," .. delta .. "\n")
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