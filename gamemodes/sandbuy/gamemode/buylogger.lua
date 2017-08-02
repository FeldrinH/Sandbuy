buylogger = buylogger or {Active=false}

function buylogger.Init()
	if !file.Exists("buylog.txt", "DATA") then
		file.Write("buylog.txt", "action,player,target,newmoney\n")
	end
	
	buylogger.File = file.Open("buylog.txt", "a", "DATA")
	buylogger.File:Write("--SERVER STARTED--\n")
	buylogger.Active = true
end

function buylogger.Close()
	if buylogger.Active then
		buylogger.Active = false
		buylogger.File:Close()
	end
end

function buylogger.LogKill(ply, victim, newmoney)
	if buylogger.Active then
		buylogger.File:Write("kill," .. ply:Nick() .. "," .. victim:Nick() .. "," .. newmoney .. "\n")
		--buylogger.File:Flush()
	end
end

function buylogger.LogDeath(ply, newmoney)
	if buylogger.Active then
		buylogger.File:Write("death," .. ply:Nick() .. ",," .. newmoney .. "\n")
		--buylogger.File:Flush()
	end
end

function buylogger.LogBuy(ply, class, buytype, newmoney)
	if buylogger.Active then
		buylogger.File:Write("buy-" .. buytype .. "," .. ply:Nick() .. "," .. class .. "," .. newmoney .. "\n")
		buylogger.File:Flush()
	end
end

function buylogger.LogBailout(ply, newmoney)
	if buylogger.Active then
		buylogger.File:Write("bailout," .. ply:Nick() .. ",," .. newmoney .. "\n")
		--buylogger.File:Flush()
	end
end