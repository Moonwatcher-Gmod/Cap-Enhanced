ENT.Type = "anim"
ENT.Base = "stargate_base"
ENT.PrintName = "Stargate (Virgo)"
ENT.Author = "aVoN, Madman07, Llapp, Rafael De Jongh, AlexALX"
ENT.Category = "Stargate Carter Addon Pack: Gates and Rings"

list.Set("CAP.Entity", ENT.PrintName, ENT);
ENT.WireDebugName = "Stargate Virgo"

ENT.IsNewSlowDial = true; // this gate use new slow dial (with chevron lock on symbol)

ENT.EventHorizonData = {
	OpeningDelay = 1.5,
	OpenTime = 2.2,
	NNFix = 1,
	Type = "sg1"
}

StarGate.RegisterEventHorizon("Virgo",{
	ID=9,
	Name="Infinity V2",
	Material="sgu/effect_02.vmt",
	UnstableMaterial="sgu/effect_shock.vmt",
	LightColor={
		r = Vector(200,230),
		g = Vector(60,80),
		b = Vector(150,230),
		sync = true, -- sync random (for white), will be used only first value from this table (r)
	},
	Color=Color(255,255,255),
})	

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