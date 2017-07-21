local blocked_ammo = {[10]=true, [30]=true, [32]=true, [33]=true, [35]=true, [37]=true}

hook.Remove("PlayerSpawnSENT", "BlockNuclearSEnts")
hook.Remove("PlayerGiveSWEP", "BlockNukeSWep")
hook.Remove("PlayerSpawnSWEP", "BlockNukeSpawn")

--hook.Remove("PlayerSwitchWeapon", "AutoGiveAmmo")
hook.Add("PlayerSwitchWeapon", "AutoGiveAmmo", function(ply, oldWpn, newWpn)
	local primary_ammo = newWpn:GetPrimaryAmmoType()
	if !blocked_ammo[primary_ammo] then
		print("Score1", primary_ammo)
		ply:SetAmmo( 9999, primary_ammo )
	end
	
	local secondary_ammo = newWpn:GetSecondaryAmmoType()
	if !blocked_ammo[secondary_ammo] then
		print("Score2", secondary_ammo)
		ply:SetAmmo( 9999, secondary_ammo )
	end
end)