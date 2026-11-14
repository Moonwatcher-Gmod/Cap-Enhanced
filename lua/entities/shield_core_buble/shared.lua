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

-- Does this shield rise and lower? With "Always show Bubble", or the "Rising edge" option without it.
function ENT:Rises()
	return self:GetNWBool("AlwaysShow",false) or self:GetNWBool("RisingEdge",false)
end

-- World height the shield covers right now. nil = all of it
function ENT:GetCoverLevel()
	if (not self:Rises()) then return nil end
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
	return self:Rises() and CurTime() < self:GetNWFloat("DisabledTime",0) + self.CoverTime
end

-- Radius of the visible shape in each direction (the meshes are 200 units at scale 1, the Atlantis dome
-- 279 wide and 208 high on its base). This is the one size used everywhere: blocking, tracelines, effects.
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

-- Where does the segment start->endpos first cross the shield's surface? Entering when it starts outside,
-- leaving when it starts inside. Returns the hit position, the surface normal facing the ray, and the
-- fraction of the segment, or nil. Exact maths on the visible shape (ellipsoid, box, or the Atlantis
-- dome: the upper half of an ellipsoid on a flat base).
function ENT:TraceIntersect(start, endpos)
	local r = self:GetShapeRadii()
	local shape = self:GetNWInt("PhysicModel",1)
	local a = self:WorldToLocal(start)
	local d = self:WorldToLocal(endpos) - a
	local tin, tout = -math.huge, math.huge
	local nin, nout -- Local normals at the entry and exit points (nil = work it out from the point)

	-- Narrow [tin, tout] down to the part of the line inside the slab low <= a[i] + d[i]*t <= high
	local function slab(i, low, high, axis_normal)
		local ai, di = a[i], d[i]
		if (di == 0) then return ai >= low and ai <= high end
		local t1, t2 = (low - ai)/di, (high - ai)/di
		local n1, n2 = -axis_normal, axis_normal
		if (t1 > t2) then t1, t2, n1, n2 = t2, t1, n2, n1 end
		if (t1 > tin) then tin, nin = t1, n1 end
		if (t2 < tout) then tout, nout = t2, n2 end
		return tin <= tout
	end

	if (shape == 2) then -- Box
		if (not slab(1, -r.x, r.x, Vector(1,0,0))) then return end
		if (not slab(2, -r.y, r.y, Vector(0,1,0))) then return end
		if (not slab(3, -r.z, r.z, Vector(0,0,1))) then return end
	else -- Ellipsoid: scale to a unit sphere and solve |A + D*t| = 1
		local A = Vector(a.x/r.x, a.y/r.y, a.z/r.z)
		local D = Vector(d.x/r.x, d.y/r.y, d.z/r.z)
		local qa, qb, qc = D:Dot(D), 2*A:Dot(D), A:Dot(A) - 1
		if (qa == 0) then return end
		local disc = qb*qb - 4*qa*qc
		if (disc < 0) then return end
		disc = math.sqrt(disc)
		tin, tout = (-qb - disc)/(2*qa), (-qb + disc)/(2*qa)
		if (shape == 3 and not slab(3, 0, math.huge, Vector(0,0,1))) then return end -- Dome: only above its base
	end

	local inside = self:ContainsPoint(start)
	local t = inside and tout or tin
	if (t < 0 or t > 1) then return end
	local p = a + d*t
	local n = inside and nout or nin
	if (not n) then -- On the curved surface
		n = Vector(p.x/(r.x*r.x), p.y/(r.y*r.y), p.z/(r.z*r.z))
		n:Normalize()
	end
	if (inside) then n = -1*n end -- Face the ray: from inside it hits the inner side of the surface
	return self:LocalToWorld(p), self:LocalToWorld(n) - self:GetPos(), t
end
