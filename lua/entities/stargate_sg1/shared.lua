ENT.Type = "anim"
ENT.Base = "stargate_base"
ENT.PrintName = "Stargate (SG1)"
ENT.Author = "aVoN, Madman07, Llapp, Rafael De Jongh, AlexALX"
ENT.Category = "Stargate Carter Addon Pack: Gates and Rings"

ENT.WireDebugName = "Stargate SG1"
list.Set("CAP.Entity", ENT.PrintName, ENT);

ENT.IsNewSlowDial = true; // this gate use new slow dial (with chevron lock on symbol)

ENT.EventHorizonData = {
	OpeningDelay = 1.5,
	OpenTime = 2.2,
	NNFix = 1,
}

-- StarGate.RegisterEventHorizon("sghd_2",{
-- 	ID=14,
-- 	Name="SG-HD",
-- 	Material="event_horizon_sg/effect_01.vmt",
-- 	UnstableMaterial="event_horizon_sg/effect_shock_hd.vmt",
-- 	LightColor={
-- 		r = Vector(20,40),
-- 		g = Vector(60,80),
-- 		b = Vector(150,230),
-- 		sync = false, -- sync random (for white), will be used only first value from this table (r)
-- 	},
-- 	Color=Color(255,255,255),
-- })

ENT.DialSlowDelay = 2.0

ENT.StargateRingRotate = true
ENT.StargateHasSGCType = true
ENT.StargateTwoPoO = true
ENT.StargateHas9ChevSpecial = true

function ENT:GetRingAng()
	if not IsValid(self.EntRing) then self.EntRing=self:GetNWEntity("EntRing") if not IsValid(self.EntRing) then return end end   -- Use this trick beacause NWVars hooks not works yet...
	local angle = tonumber(math.NormalizeAngle(self.EntRing:GetLocalAngles().r));
	return (angle<0) and angle+360 or angle
end