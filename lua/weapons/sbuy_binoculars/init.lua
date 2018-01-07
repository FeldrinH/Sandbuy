AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
resource.AddFile("materials/VGUI/entities/laserPointer.vmt")
resource.AddFile("materials/VGUI/entities/laserPointer.vtf")
include('shared.lua')

local zoommultipliers = { 4, 8, 16, 32 }
local zoomsteps = {}
for k,v in pairs(zoommultipliers) do
	zoomsteps[k] = 75 / v
end

function SWEP:Initialize()
	self:SetWeaponHoldType( self.HoldType )
	
	self.ZoomLevel = 1
	self.Weapon:SetNWInt("ZoomMult", zoommultipliers[1])
end

function SWEP:Deploy()
	self.Pointing = false
	self.Weapon:SetNWBool("Active", false)
	
	return true
end

function SWEP:Holster( wep )
	self.Pointing = false
	self.Weapon:SetNWBool("Active", false)
		
	return true
end

function SWEP:PrimaryAttack()
	self.Pointing = !self.Pointing
	self.Weapon:SetNWBool("Active", self.Pointing)
	if(self.Pointing)then
		self.Owner:EmitSound( "binoculars/binoculars_zoomout.wav" )
	else		
		self.Owner:EmitSound( "binoculars/binoculars_zoomin.wav" )
		self.Weapon:SetNextPrimaryFire(CurTime() + 0.1)
	end
end

function SWEP:SecondaryAttack()
	if self.Pointing then
		self.ZoomLevel = (self.ZoomLevel) % 4 + 1
		self.Weapon:SetNWInt("ZoomMult", zoommultipliers[self.ZoomLevel])
		self.Weapon:SetNextSecondaryFire(CurTime() + 0.1)
		
		--print(self.ZoomLevel, zoommultipliers[self.ZoomLevel])
	end
	
	return false
end

function SWEP:Think()
	if( self.Pointing )then
		self.Owner:DrawViewModel(false)
		self.Owner:SetFOV( zoomsteps[self.ZoomLevel], 0 )
	else
		self.Owner:DrawViewModel(true)
		self.Owner:SetFOV( 0, 0 )	
	end
	
	-- print(self.Zoom)
end
