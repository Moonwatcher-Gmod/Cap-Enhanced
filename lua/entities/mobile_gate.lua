if (StarGate ~= nil and StarGate.LifeSupportAndWire ~= nil) then
    StarGate.LifeSupportAndWire(ENT)
end

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Mobile Gate"

ENT.EventHorizonData = {
    OpeningDelay = 0.8,
    OpenTime = 2.2,
    NNFix = 0,
    Model = "models/sgorlin/stargate_horizon_orlin.mdl",
    Kawoosh = "orlin",
}

ENT.UnstableSound = Sound("stargate/orlin/gateflicker.wav");

if SERVER then
    AddCSLuaFile()
    function ENT:Initialize()
        self.EntitiesOnRoute = 0
        
        local phys = self.Entity:GetPhysicsObject()

        if (phys:IsValid()) then
            phys:Wake()
            phys:SetMass(5000)
        end

        self.Entity:SetUseType(SIMPLE_USE)
        self:SetDialMode(false,true,true)
    end


    function ENT:IsBlocked(only_by_iris,no_open,only_block)


        return false
    end


    function ENT:DeactivateStargate()




    end



end