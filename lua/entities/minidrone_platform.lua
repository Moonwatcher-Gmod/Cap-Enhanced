--[[
	Minidrone Platform
	Copyright (C) 2010 Madman07
]]
--
if (StarGate ~= nil and StarGate.LifeSupportAndWire ~= nil) then
    StarGate.LifeSupportAndWire(ENT)
end

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Minidrone Platform"
ENT.Author = "aVoN, RononDex, Madman07, Rafael De Jongh"
ENT.Category = "Stargate Carter Addon Pack: Weapons"
if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
ENT.Category = SGLanguage.GetMessage("entity_weapon_cat");
end
ENT.WireDebugName = "Minidrone Platform"
list.Set("CAP.Entity", ENT.PrintName, ENT)

if SERVER then
    if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("entweapon")) then return end
    AddCSLuaFile()

    ENT.Sounds = {
        Enable = Sound("weapons/minidrone_turnon.wav")
    }

    -----------------------------------INIT----------------------------------
    function ENT:Initialize()
        self.Entity:SetName("Minidrone Platform")
        self.Entity:SetModel("models/Madman07/minidrone_platform/platform.mdl")
        self.Entity:PhysicsInit(SOLID_VPHYSICS)
        self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
        self.Entity:SetSolid(SOLID_VPHYSICS)
        self.Entity:SetUseType(SIMPLE_USE)
        self.LastFire = CurTime()
        self.Target = Vector(0, 0, 0)
        self.SoundPlayed = false
        self.Wiremode = false
        self.Wire_Fire = false
        if(self.HasWire) then
            self:CreateWireInputs("Activate","Fire","Target [VECTOR]")
            self:CreateWireOutputs("Active","Drones In the Air")
        end
    end

    -----------------------------------SPAWN----------------------------------
    function ENT:SpawnFunction(ply, tr)
        if (not tr.Hit) then return end
        local PropLimit = GetConVar("CAP_minidrone_max"):GetInt()

        if (ply:GetCount("CAP_minidrone") + 1 > PropLimit) then
            ply:SendLua("GAMEMODE:AddNotify(\"Minidrone Platform limit reached!\", NOTIFY_ERROR, 5); surface.PlaySound( \"buttons/button2.wav\" )")

            return
        end

        local ang = ply:GetAimVector():Angle()
        ang.p = 0
        ang.r = 0
        ang.y = (ang.y + 180) % 360
        local ent = ents.Create("minidrone_platform")
        ent:SetAngles(ang)
        ent:SetPos(tr.HitPos)
        ent:Spawn()
        ent:Activate()
        ent.Owner = ply
        local phys = ent:GetPhysicsObject()

        if IsValid(phys) then
            phys:EnableMotion(false)
        end

        ply:AddCount("CAO_minidrone", ent)

        return ent
    end

    --------------------------------Wire inputs-----------------------------
    function ENT:TriggerInput(k,v)
        if (k=="Activate") then
            if v>=1 then
                self.Wiremode = true
            else
                self.Wiremode = false
                self.Wire_Fire = false
            end
        elseif (k=="Fire") then
            if v>=1 then
                if (self.Wiremode) then self.Wire_Fire = true end
            else
                self.Wire_Fire = false
            end
        elseif (k=="Target") then
                self.Target = v
        end
        --print(self.Wiremode)
    end
    -----------------------------------USE----------------------------------
    function ENT:Use(ply)
        if (not self.Wiremode) then
            if (self.Owner == ply) then
                ply.MiniDronePlatform = self
                ply:SetNetworkedEntity("DronePlatform", self)
                ply:Give("minidrone_key")
                ply:SelectWeapon("minidrone_key")
            end
        end
    end

    function ENT:Think(ply)
        local pos = self:GetPos()
        local shouldlight = false


        if (self.Wiremode) then
            if (self.Wire_Fire) then
                self:FireDrones()
            end

            shouldlight = true
        else
            for _, v in pairs(player.GetAll()) do
                if (v.CanMinidroneControll and v.MiniDronePlatform == self) then
                    if ((pos - v:GetPos()):Length() < 500) then
                        shouldlight = true
                    end
                end
            end
        end

        if shouldlight then
            if not self.SoundPlayed then
                self.SoundPlayed = true
                self.Entity:EmitSound(self.Sounds.Enable, 100, math.random(98, 102))
            end

            self:SetSkin(1)
        else
            self.SoundPlayed = false
            self:SetSkin(0)
        end
    end

    -----------------------------------OTHER CRAP----------------------------------


    function ENT:FireDrones(ply)
        local aimvector = Vector(0, 0, 1)
        local multiply = 10
        local data = self:GetAttachment(self:LookupAttachment("Fire"))
        if (not (data and data.Pos)) then return end
        local e = ents.Create("mini_drone")
        e:SetPos(data.Pos)
        e:SetAngles(Angle(-90, 0, 0))
        if (not self.Wiremode) then
            e.Ply = ply
        end
        if (self.Wiremode) then
            e.Wiremode = true
            e.Wiremode_target = self.Target
        end
        e:Spawn()
        e:SetVelocity(aimvector * 800 + VectorRand() * multiply) -- Velocity and "randomness"
        e:SetOwner(self)
        --self:EmitSound(self.Sounds.Shot[math.random(1,#self.Sounds.Shot)],90,math.random(97,103));
    end

    function ENT:PreEntityCopy()
        local dupeInfo = {}
        if self.HaveCore then return end -- dupe it by clicking on apple core u dumb

        if IsValid(self.Entity) then
            dupeInfo.EntID = self.Entity:EntIndex()
        end

        duplicator.StoreEntityModifier(self, "MiniDroneDupeInfo", dupeInfo)
    end

    duplicator.RegisterEntityModifier("MiniDroneDupeInfo", function() end)

    function ENT:PostEntityPaste(ply, Ent, CreatedEntities)
        if (StarGate.NotSpawnable(Ent:GetClass(), ply)) then
            self.Entity:Remove()

            return
        end

        local dupeInfo = Ent.EntityMods.MiniDroneDupeInfo

        if (IsValid(ply)) then
            local PropLimit = GetConVar("CAP_minidrone_max"):GetInt()

            if (ply:GetCount("CAP_minidrone") + 1 > PropLimit) then
                ply:SendLua("GAMEMODE:AddNotify(\"Minidrone Platform limit reached!\", NOTIFY_ERROR, 5); surface.PlaySound( \"buttons/button2.wav\" )")
                self.Entity:Remove()

                return false
            end
        end

        if dupeInfo.EntID then
            self.Entity = CreatedEntities[dupeInfo.EntID]
        end

        if (IsValid(ply)) then
            self.Owner = ply
            ply:AddCount("CAP_minidrone", self.Entity)
        end
    end

    if (StarGate and StarGate.CAP_GmodDuplicator) then
        duplicator.RegisterEntityClass("minidrone_platform", StarGate.CAP_GmodDuplicator, "Data")
    end
end
