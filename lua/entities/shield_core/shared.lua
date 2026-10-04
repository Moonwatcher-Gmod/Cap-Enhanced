if (StarGate!=nil and StarGate.LifeSupportAndWire!=nil) then StarGate.LifeSupportAndWire(ENT); end
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Shield Core"
ENT.WireDebugName = "Shield Core"
ENT.Author = "Madman07, Rafael De Jongh"
ENT.Instructions= ""
ENT.Contact = "madman097@gmail.com"
ENT.Category = "Stargate Carter Addon Pack"

list.Set("CAP.Entity", ENT.PrintName, ENT);

ENT.RenderGroup = RENDERGROUP_BOTH
ENT.AutomaticFrameAdvance = true

--################# Energy cost. Shared, so the menu can show what the server will charge.
-- A shield with an equivalent radius of EnergyReferenceRadius (a sphere of menu size ~1024) costs the base
-- amount. Cost grows with the radius to the power 2.5: twice as big costs ~5.7x, the biggest ~32x (box ~72x).
ENT.EnergyReferenceRadius = 400
ENT.EnergySizeExponent = 2.5

local SHAPE_BASE = {Vector(200,200,200), Vector(200,200,200), Vector(279,279,208)} -- Sphere, box, Atlantis dome at size 512

-- size: menu size (Vector, 100-4096), shape: 1 sphere, 2 box, 3 Atlantis
function ENT:GetSizeCostFactor(size, shape)
	local base = SHAPE_BASE[shape] or SHAPE_BASE[1]
	local a, b, c = base.x*size.x/512, base.y*size.y/512, base.z*size.z/512
	local area
	if (shape == 2) then
		area = 8*(a*b + b*c + a*c)
	else
		local p = 1.6075 -- Knud Thomsen's approximation of an ellipsoid's surface area
		area = 4*math.pi*(((a*b)^p + (a*c)^p + (b*c)^p)/3)^(1/p)
		if (shape == 3) then area = area/2 + math.pi*a*b end -- Dome: half the ellipsoid plus its base
	end
	local radius = math.sqrt(area/(4*math.pi))
	return math.max((radius/self.EnergyReferenceRadius)^self.EnergySizeExponent, 0.05)
end

-- Strength setting (-5..5) to the energy multiplier (same as ENT:SetMultiplier and ENT:Status)
function ENT:GetStrengthCostFactor(power)
	local n = math.Clamp(power or 0, -5, 5)
	if (n > 0) then n = 1 + n else n = 1/(1 - n) end
	return math.exp(math.Clamp(n*1.3, 0.2, 600))
end

-- Energy per second while up, and the energy to switch it on (given back when switched off)
function ENT:EstimateEnergy(size, shape, power)
	local size_factor = self:GetSizeCostFactor(size, shape)
	local per_second = size_factor*self:GetStrengthCostFactor(power)*self:GetNWFloat("EnergyConsumeMul", 100)*2 -- Charged every 0.5s
	return per_second, size_factor*self:GetNWFloat("EnergyEngage", 500)
end

local SHAPE_MODELS = {["models/Madman07/shields/sphere.mdl"] = 1, ["models/Madman07/shields/box.mdl"] = 2, ["models/Madman07/shields/atlantis.mdl"] = 3}
function ENT:ShapeFromModel(model)
	return SHAPE_MODELS[model] or 1
end
