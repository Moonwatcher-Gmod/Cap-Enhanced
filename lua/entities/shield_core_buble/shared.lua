if (StarGate!=nil and StarGate.LifeSupportAndWire!=nil) then StarGate.LifeSupportAndWire(ENT); end
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Shield Core Buble"
ENT.WireDebugName = "Shield Core Buble"
ENT.Author = "Madman07"
ENT.Instructions= ""
ENT.Contact = "madman097@gmail.com"
ENT.Category = "Stargate Carter Addon Pack"

ENT.Spawnable		= false
ENT.AdminSpawnable	= false

ENT.RenderGroup = RENDERGROUP_BOTH
ENT.AutomaticFrameAdvance = true

function ENT:GetTraceSize()
	return self.Entity:GetNWVector("TraceSize",Vector(1,1,1));
end

-- Rising/lowering with "Always show Bubble": the switch on/off effect (shield_core_flash_atl) fills the
-- shield from the bottom up (and empties it from the top down) over 5 seconds. These make the shield only
-- block where it is drawn, the same way on server (pushing, tracelines) and clients (beam effects).
ENT.CoverTime = 5

-- World height range of the shape, measured like the effect does it (it ignores the shield's rotation)
function ENT:GetCoverRange()
	local scale = self:GetNWVector("PhysicScale", Vector(1,1,1))
	local z = self:GetPos().z
	if (self:GetNWInt("PhysicModel",1) == 3) then return z, z + 208*scale.z end -- The Atlantis dome sits on its base
	return z - 200*scale.z, z + 200*scale.z
end

-- World height the shield covers right now. nil = all of it
function ENT:GetCoverLevel()
	if (not self:GetNWBool("AlwaysShow",false)) then return nil end
	local on, off = self:GetNWFloat("EnabledTime",0), self:GetNWFloat("DisabledTime",0)
	local bottom, top = self:GetCoverRange()
	if (off > on) then -- Lowering, from the top down
		return Lerp(math.Clamp((CurTime() - off)/self.CoverTime, 0, 1), top, bottom)
	end
	local f = (CurTime() - on)/self.CoverTime
	if (f >= 1) then return nil end
	return Lerp(math.max(f, 0), bottom, top) -- Rising, from the bottom up
end

function ENT:IsCoveredAt(pos)
	local level = self:GetCoverLevel()
	return level == nil or pos.z <= level
end

-- Switched on, or still lowering after being switched off
function ENT:IsShieldUp()
	if (self:GetNWBool("Enabled",false)) then return true end
	return self:GetNWBool("AlwaysShow",false) and CurTime() < self:GetNWFloat("DisabledTime",0) + self.CoverTime
end

-- Radius of the visible shape in each direction (the meshes are 200 units at scale 1, the Atlantis dome
-- 279 wide and 208 high on its base). Unlike the trace size (TraceSize), which is ~28% bigger.
function ENT:GetShapeRadii()
	local scale = self:GetNWVector("PhysicScale", Vector(1,1,1))
	local base = (self:GetNWInt("PhysicModel",1) == 3) and Vector(279,279,208) or Vector(200,200,200)
	return Vector(base.x*scale.x, base.y*scale.y, base.z*scale.z)
end

-- Is a world position inside the visible shape? (margin grows the shape by that many units)
function ENT:ContainsPoint(pos, margin)
	margin = margin or 0
	local r = self:GetShapeRadii() + Vector(margin, margin, margin)
	local lp = self:WorldToLocal(pos)
	local shape = self:GetNWInt("PhysicModel",1)
	if (shape == 2) then
		return math.abs(lp.x) < r.x and math.abs(lp.y) < r.y and math.abs(lp.z) < r.z
	end
	if (shape == 3 and lp.z < -margin) then return false end -- Below the dome's base
	return (lp.x/r.x)^2 + (lp.y/r.y)^2 + (lp.z/r.z)^2 < 1
end

-- Containment field: keeps things in instead of out (shield core menu)
function ENT:IsContainment()
	return self:GetNWBool("Containment",false)
end
