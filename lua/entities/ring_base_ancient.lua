ENT.Type = "anim"
ENT.Base = "ring_base"
ENT.PrintName = "Rings (Ancient)"
ENT.Author = "Catdaemon, Madman07, Rafael De Jongh"
ENT.Instructions = "Place where desired, USE to set its address."
ENT.Category = "Stargate Carter Addon Pack: Gates and Rings"
if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
ENT.Category = SGLanguage.GetMessage("stargate_category");
end
list.Set("CAP.Entity", ENT.PrintName, ENT)
ENT.IsRings = true
ENT.AutomaticFrameAdvance = true

if SERVER then
    if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("extra")) then return end
    AddCSLuaFile()
    ENT.RingModel = "models/Madman07/ancient_rings/ring.mdl"
    ENT.BaseModel = "models/Madman07/ancient_rings/cover.mdl"
    ENT.OriFix = 0

    function ENT:SpawnFunction(p, tr)
        if (not tr.Hit) then return end
        local e = ents.Create("ring_base_ancient")
        e:SetModel(e.BaseModel)
        e:SetPos(tr.HitPos)
        e:Spawn()
        e:Activate()
        local ang = p:GetAimVector():Angle()
        ang.p = 0
        ang.r = 0
        ang.y = (ang.y + 180) % 360
        e:SetAngles(ang)
        local phys = e:GetPhysicsObject()

        if IsValid(phys) then
            phys:EnableMotion(false)
        end

        e:CartersRampsRing(tr)

        return e
    end

    if (StarGate and StarGate.CAP_GmodDuplicator) then
        duplicator.RegisterEntityClass("ring_base_ancient", StarGate.CAP_GmodDuplicator, "Data")
    end
end

