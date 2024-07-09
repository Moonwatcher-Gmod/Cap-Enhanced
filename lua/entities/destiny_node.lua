AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_anim" --gmodentity
ENT.PrintName = "Destiny Resource Node"
ENT.Author = "Llapp, cooldudetb, Rafael De Jongh"
ENT.Category = "Stargate Carter Addon Pack"

if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
ENT.Category = SGLanguage.GetMessage("entity_main_cat");
end


ENT.WireDebugName = "Destiny Node"
list.Set("CAP.Entity", ENT.PrintName, ENT)
ENT.Spawnable = false
ENT.AdminSpawnable = false

if (Environments) then
    ENT.IsNode = false
else
    ENT.IsNode = true
end

if SERVER then
    function ENT:Initialize()
        self.Entity:SetModel("models/circuitdest.mdl")
        self.Entity:PhysicsInit(SOLID_VPHYSICS)
        self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
        self.Entity:SetSolid(SOLID_VPHYSICS)
        self.Entity:SetUseType(SIMPLE_USE)
        local phys = self.Entity:GetPhysicsObject()

        if (phys:IsValid()) then
            phys:EnableMotion(false)
            phys:SetMass(1000)
        end

        self.HaveRD3 = false

        if (CAF and CAF.GetAddon("Resource Distribution")) then
            self.HaveRD3 = true
        end

        -- Make us a node!
        if self.HaveRD3 then
            self.netid = CAF.GetAddon("Resource Distribution").CreateNetwork(self)
            self:SetNWInt("netid", self.netid)
            self.range = 4096
            self:SetNWInt("range", self.range)
            self.RDEnt = CAF.GetAddon("Resource Distribution")
        elseif (RES_DISTRIB == 2) then
            self:AddResource("energy", 1)
        end
    end
end

function ENT:SpawnFunction(ply, trace)
    if (IsValid(p)) then
        local PropLimit = GetConVar("CAP_destiny_node_max"):GetInt()

        if (ply:GetCount("CAP_destiny_node") + 1 > PropLimit) then
            ply:SendLua("GAMEMODE:AddNotify(\"Destiny Resource Node limit reached!\"), NOTIFY_ERROR, 5); surface.PlaySound( \"buttons/button2.wav\" )")

            return
        end
    end

    local angle = ply:GetAimVector():Angle()
    angle.y = (angle.y + 380) % 360
    angle.p = 0
    angle.r = 0
    local ent = ents.Create("destiny_node")
    ent:SetAngles(angle)
    ent:SetPos(trace.HitPos + Vector(0, 0, 55))
    ent:SetVar("Owner", ply)
    ent:Spawn()
    ent:Activate()
    ent.Owner = ply
    local phys = ent:GetPhysicsObject()

    if (IsValid(phys)) then
        phys:EnableMotion(true)
    end

    if (IsValid(ply)) then
        ply:AddCount("CAP_destiny_node", ent)
    end

    return ent
end

if (StarGate and StarGate.CAP_GmodDuplicator) then
    duplicator.RegisterEntityClass("destiny_node", StarGate.CAP_GmodDuplicator, "Data")
end

function ENT:PostEntityPaste(player, Ent, CreatedEntities)
    if (StarGate.NotSpawnable(Ent:GetClass(), ply)) then
        self.Entity:Remove()

        return
    end

    local PropLimit = GetConVar("CAP_destiny_node_max"):GetInt()

    if (IsValid(player) and player:IsPlayer() and player:GetCount("CAP_destiny_node") + 1 > PropLimit) then
        player:SendLua("GAMEMODE:AddNotify(\"Destiny Resource Node limit reached!\"), NOTIFY_ERROR, 5); surface.PlaySound( \"buttons/button2.wav\" )")
        self.Entity:Remove()

        return
    end

    if (IsValid(player)) then
        player:AddCount("CAP_destiny_node", self.Entity)
        self.Owner = player
    end

    StarGate.WireRD.PostEntityPaste(self, player, Ent, CreatedEntities)
end