ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Base = "base_anim"
ENT.Type = "anim"

ENT.PrintName = "Shield Core Button"
ENT.Author = "Gmod4phun"
ENT.Category = "Stargate Carter Addon Pack"

if SERVER then

if (StarGate==nil or StarGate.CheckModule==nil or not StarGate.CheckModule("ship")) then return end
AddCSLuaFile()

ENT.CAP_NotSave = true;

function ENT:Initialize()

	self:SetModel("models/Mechanics/gears/gear12x6_small.mdl")
	self:SetModelScale(0.8)
	self:SetMaterial("Boba_Fett/textures/catwalk_metal")
	self:SetSolid(SOLID_VPHYSICS)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self.NextUse = CurTime();
	self:SetUseType(SIMPLE_USE)

end

function ENT:Use(activator,caller,useType,value)
	if self.NextUse < CurTime() then
		if IsValid(self.Parent) then
			self.Parent:TrueUse(activator)
		end
		self.NextUse = CurTime() + 1;
	end
end

end

if CLIENT then
	function ENT:Draw(flags)
		if(GetConVar("r_rootlod"):GetString() == "2") then -- is 2 when 'low' model detail
			self:DrawModel(flags)
		end
	end
end