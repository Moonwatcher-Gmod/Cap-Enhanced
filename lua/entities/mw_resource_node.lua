if (StarGate ~= nil and StarGate.LifeSupportAndWire ~= nil) then
    StarGate.LifeSupportAndWire(ENT)
end

ENT.Type = "anim"
ENT.Base = "base_anim" --gmodentity
ENT.PrintName = "MoonWatcher: Resource node"
ENT.Author = "Soren"
ENT.WireDebugName = "Resource node"
ENT.Category = "Moonwatcher: Storage"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.IsZPM = true
list.Add("MW.Entity", ENT.PrintName)

if SERVER then
    if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("energy")) then return end
    AddCSLuaFile()

    function ENT:Initialize()
        self.Entity:SetModel("models/micropro/shield_gen.mdl")
        self.Entity:PhysicsInit(SOLID_VPHYSICS)
        self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
        self.Entity:SetSolid(SOLID_VPHYSICS)
        local phys = self.Entity:GetPhysicsObject()

        if (phys:IsValid()) then
            phys:EnableMotion(false)
            phys:SetMass(1000)
        end
        self:CreateWireOutputs("Active", "Energy")
        self.Energy = 8000
        self.EnergyCap= 10000
    end

    function ENT:SpawnFunction(p, t)
        if (not t.Hit) then return end
        local e = ents.Create("mw_resource_node")
        e:SetPos(t.HitPos + Vector(0, 0, 0))
        e:DrawShadow(true)
        e:SetVar("Owner", p)
        e:Spawn()
        e:Activate()
        local ang = p:GetAimVector():Angle()
        ang.p = 0
        ang.r = 0
        ang.y = (ang.y + 180) % 360
        e:SetAngles(ang)

        return e
    end


    function ENT:Think()

        
        self:SetWire("Energy", self.Energy)
        self.Entity:NextThink(CurTime() + 0.2)
    end


    function ENT:RequestEnergy(ent,amount)
        if(not IsValid(ent)) then end
        if(self.Energy - amount >0) then
            self.Energy = self.Energy - amount
            return amount
        else
            return 0
        end
    end
end