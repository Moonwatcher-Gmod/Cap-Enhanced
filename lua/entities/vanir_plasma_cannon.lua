--[[
	Ori Beam Cannon
	Copyright (C) 2010 Madman07
]]
--
if (StarGate ~= nil and StarGate.LifeSupportAndWire ~= nil) then
    StarGate.LifeSupportAndWire(ENT)
end

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Vanir Plasma Cannon"
ENT.Author = "Madman07, Rafael De Jongh, PyroSpirit"
ENT.Instructions = ""
ENT.Contact = "madman097@gmail.com"
ENT.Category = "Stargate Carter Addon Pack: Weapons"
if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
ENT.Category = SGLanguage.GetMessage("entity_weapon_cat");
end
list.Set("CAP.Entity", ENT.PrintName, ENT)

if SERVER then
    if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("entweapon")) then return end
    AddCSLuaFile()

    ENT.Sounds = {
        Shoot = Sound("glider/hatak_blast.wav")
    }

    ENT.CDSIgnore = true -- CDS Immunity

    -- GCombat invulnarability!
    function ENT:gcbt_breakactions()
    end

    ENT.hasdamagecase = true

    -----------------------------------INIT----------------------------------
    function ENT:Initialize()
        self:SetModel("models/Madman07/ori_main/ori_main.mdl")
        self:SetName("Vanir Plasma Cannon")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)

        if (WireAddon) then
            self.Inputs = WireLib.CreateInputs(self, {"Fire [NORMAL]", "Active [NORMAL]", "Vector [VECTOR]", "Entity [ENTITY]","Salvo [NORMAL]"})

            self.Outputs = WireLib.CreateOutputs(self, {"Charged % [NORMAL]"})
        end

        self.WireShoot = nil
        self.WireEnt = nil
        self.WireVec = nil
        self.WireActive = nil
        self.WireSalvo = nil

        self.APC = nil
        self.APCply = nil
        self.Target = Vector(0, 0, 0)
        self.Power = 0
        local ChargingTime = 1
        self.ChargingTime = math.random(ChargingTime - 1, ChargingTime + 1)
        self:AddResource("energy", 2000)
        self.energy_drain = 10000
    end

    -----------------------------------SPAWN----------------------------------
    function ENT:SpawnFunction(ply, tr)
        if (not tr.Hit) then return end
        local PropLimit = GetConVar("CAP_vanir_cannon_max"):GetInt()

        if (ply:GetCount("CAP_vanir_cannon") + 1 > PropLimit) then
            ply:SendLua("GAMEMODE:AddNotify(\"Vanir Plasma Cannon limit reached!\", NOTIFY_ERROR, 5); surface.PlaySound( \"buttons/button2.wav\" )")

            return
        end

        ent = ents.Create("vanir_plasma_cannon")
        ent:SetPos(tr.HitPos)
        ent:Spawn()
        ent:Activate()
        local phys = ent:GetPhysicsObject()

        if IsValid(phys) then
            phys:EnableMotion(false)
        end

        ply:AddCount("CAP_vanir_cannon", ent)

        return ent
    end

    -----------------------------------DIFFERENT CRAP----------------------------------
    function ENT:TriggerInput(variable, value)
        if (variable == "Vector") then
            self.WireVec = value
        elseif (variable == "Entity") then
            self.WireEnt = value
        elseif (variable == "Fire") then
            self.WireShoot = value
        elseif (variable == "Active") then
            self.WireActive = value
        elseif (variable == "Salvo") then
        	self.WireSalvo = value
        end
    end

    function ENT:StartTouch(ent)
        if IsValid(ent) and ent:IsVehicle() then
            if (self.APC ~= ent) then
                local ed = EffectData()
                ed:SetEntity(ent)
                util.Effect("old_propspawn", ed, true, true)
            end

            self.APC = ent
        end
    end

    -----------------------------------THINK----------------------------------
    function ENT:Think(ply)

    	if (self.WireSalvo == 1) then
        	self.Power = math.Clamp(self.Power + 285 / self.ChargingTime, 0, 100)
    	else
    		self.Power = math.Clamp(self.Power + 8 / self.ChargingTime, 0, 100)
    	end
    	Wire_TriggerOutput(self, "Charged %", self.Power)
        if (self.Power < 100) then
            self:ConsumeResource("energy", 2000)
        end


        if IsValid(self.APC) then
            self.APCply = self.APC:GetPassenger(0)

            if IsValid(self.APCply) then
                self.APCply:CrosshairEnable()
                self.Target = self.APCply:GetEyeTrace().HitPos

                if (self.APCply:KeyDown(IN_ATTACK) and (self.Power == 100)) then
                    self:Shoot()
                end
            end
        elseif (self.WireActive == 1) then
            if ((self.WireShoot == 1) and (self.Power > 10)) then
                self:Shoot()
            end

            if IsValid(self.WireEnt) then
                self.Target = self.WireEnt:LocalToWorld(self.WireEnt:OBBCenter())
            elseif (self.WireVec) then
                self.Target = self.WireVec
            end
        end
    end

    function ENT:Shoot()
        local energy = self:GetResource("energy")

        if (energy > self.energy_drain or not self.HasRD) then
            local FiringPos = self:GetPos() + self:GetUp() * 30
            local ShootDir = (self.Target - FiringPos):GetNormal()

            local trace = util.TraceLine({
                start = FiringPos,
                endpos = self.Target,
                ignoreworld = true
            })

            if (IsValid(trace.Entity) and trace.Entity == self) then return end
            self:ConsumeResource("energy", self.energy_drain)
            self:EmitSound(self.Sounds.Shoot, 100, math.random(88, 102))
            self.Power = self.Power-10
            local e = ents.Create("vanir_pulse")

            e:PrepareBullet(ShootDir, 80, 4000, 5)
            e:SetPos(FiringPos)
            e:SetOwner(self)
            e.Owner = self
            e:Spawn()
            e:Activate()
            e:SetColor(Color(255, 179, 0, 255))
            --e:SetColor(Color(119, 176, math.random(175, 255), 255))
            --self:EmitSound(self.Sounds.Shoot, 100, math.random(95, 105))
            util.ScreenShake(FiringPos, 2, 2.5, 1, 700)
        end
    end

    function ENT:PreEntityCopy()
        local dupeInfo = {}

        if IsValid(self) then
            dupeInfo.EntityID = self:EntIndex()
        end

        if IsValid(self.APC) then
            dupeInfo.APCID = self.APC
        end

        --[[
	if WireAddon then
		dupeInfo.WireData = WireLib.BuildDupeInfo( self.Entity )
	end      ]]
        duplicator.StoreEntityModifier(self, "OriShipDupeInfo", dupeInfo)
        StarGate.WireRD.PreEntityCopy(self)
    end

    duplicator.RegisterEntityModifier("OriShipDupeInfo", function() end)

    function ENT:PostEntityPaste(ply, Ent, CreatedEntities)
        if (StarGate.NotSpawnable(Ent:GetClass(), ply)) then
            self:Remove()

            return
        end

        if (IsValid(ply)) then
            local PropLimit = GetConVar("CAP_vanir_cannon_max"):GetInt()

            if (ply:GetCount("CAP_vanir_cannon") + 1 > PropLimit) then
                ply:SendLua("GAMEMODE:AddNotify(\"Vanir Plasma Cannon limit reached!\", NOTIFY_ERROR, 5); surface.PlaySound( \"buttons/button2.wav\" )")
                self:Remove()

                return
            end
        end

        local dupeInfo = Ent.EntityMods.OriShipDupeInfo

        if dupeInfo.EntityID then
            self = CreatedEntities[dupeInfo.EntityID]
        end

        if dupeInfo.APCID then
            self.APC = dupeInfo.APCID
        end

        --[[
	if(Ent.EntityMods and Ent.EntityMods.AsgardDupeInfo.WireData) then
		WireLib.ApplyDupeInfo( ply, Ent, Ent.EntityMods.AsgardDupeInfo.WireData, function(id) return CreatedEntities[id] end)
	end         ]]
        if (IsValid(ply)) then
            ply:AddCount("CAP_vanir_cannon", self)
        end

        StarGate.WireRD.PostEntityPaste(self, ply, Ent, CreatedEntities)
    end

    if (StarGate and StarGate.CAP_GmodDuplicator) then
        duplicator.RegisterEntityClass("vanir_plasma_cannon", StarGate.CAP_GmodDuplicator, "Data")
    end
end
