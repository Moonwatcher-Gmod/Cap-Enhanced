--[[
	Kino Ball
	Copyright (C) 2010 Madman07
]]
--

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Kino"
ENT.WireDebugName = "Kino"
ENT.Author = "Madman07, Rafael De Jongh"
ENT.Instructions = ""
ENT.Contact = "madman097@gmail.com"
ENT.Category = "Stargate Carter Addon Pack"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.AutomaticFrameAdvance = true

if (StarGate ~= nil and StarGate.LifeSupportAndWire ~= nil) then
    StarGate.LifeSupportAndWire(ENT)
end

function ENT:SetOn(_in_)
    self:SetNWBool("Enabled", _in_)
end

function ENT:GetOn()
    return self:GetNetworkedVar("Enabled", true)
end

if SERVER then
    if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("extra")) then return end
    AddCSLuaFile()

    ENT.Sounds = {
        TurnOn = Sound("kino/kino_turn_on.wav"),
        Zoom = Sound("kino/kinozoom.wav")
    }

    -----------------------------------INIT----------------------------------
    function ENT:Initialize()
        self.Entity:SetName("Kino")
        self.Entity:PhysicsInit(SOLID_VPHYSICS)
        self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
        self.Entity:SetSolid(SOLID_VPHYSICS)
        util.PrecacheModel("models/Boba_Fett/kino/kino.mdl")
        self.Entity:SetModel("models/Boba_Fett/kino/kino.mdl")
        self.Phys = self.Entity:GetPhysicsObject()

        if IsValid(self.Phys) then
            self.Phys:EnableGravity(false)
            self.Phys:Wake()
        end

        self.Entity:SetGravity(0)

        construct.SetPhysProp(nil, self, 0, nil, {
            GravityToggle = false
        })

        self.Entity:StartMotionController()
        self.Entity:SetNetworkedEntity("KinoEnt", self.Entity)
        self.LastYaw = self.Entity:GetAngles().Yaw
        self.AccSwep = self.AccSwep or Vector(0, 0, 0)
        self.Acc = self.Acc or Vector(0, 0, 0)
        self.AnglesSwep = self.AnglesSwep or Angle(0, 0, 0)
        self.Vel = self.Vel or Vector(0, 0, 0)
        self.KillKino = false
        self.CurTel = 0
        self.EntHealth = 10
        self.MaxHealth = self.EntHealth
        self.RemoveEnt = false
        self.Traveled = false
        self.CanZoom = true
        self.IsControlled = false
        self.FOV = 0
        self:CreateWireOutputs("Gravity", "Habitat", "Atmosphere", "Temperature", "O2 Percent", "CO2 Percent", "N2 Percent", "H2 Percent", "Water Level")

        self.environment = {
            gravity = 1,
            habitat = 1,
            atmosphere = 1,
            temperature = 288,
            o2 = 20.94,
            co2 = 0.04,
            n2 = 78.08,
            h2 = 0,
            water = 0
        }

        if (CAF and CAF.GetAddon and CAF.GetAddon("Spacebuild") and table.Count(CAF.GetAddon("Spacebuild"):GetEnvironments()) ~= 0) then
            self.CAF = true
        end

        timer.Create("KinoWire_" .. self:EntIndex(), 0.25, 0, function()
            if IsValid(self) then
                if (not self.damaged) then
                    if (self.CAF) then
                        local Env = CAF.GetAddon("Spacebuild").FindEnvironmentOnPos(self:GetPos())

                        if (Env.sbenvironment) then
                            self.environment.gravity = Env.sbenvironment.gravity or 0
                            self.environment.temperature = Env.sbenvironment.temperature2 or 0
                            self.environment.atmosphere = Env.sbenvironment.atmosphere or 0
                            self.environment.o2 = Env.sbenvironment.air.o2per or 0
                            self.environment.co2 = Env.sbenvironment.air.co2per or 0
                            self.environment.h2 = Env.sbenvironment.air.hper or 0
                            self.environment.n2 = Env.sbenvironment.air.nper or 0
                            self.environment.habitat = Env.sbenvironment.habitat or 0
                        else
                            self.environment.gravity = Env:GetGravity() or 0
                            self.environment.temperature = Env:GetTemperature() or 0
                            self.environment.atmosphere = Env:GetAtmosphere() or 0
                            self.environment.o2 = Env:GetO2Percentage() or 0
                            self.environment.co2 = Env:GetCO2Percentage() or 0
                            self.environment.h2 = Env:GetHPercentage() or 0
                            self.environment.n2 = Env:GetNPercentage() or 0
                            self.environment.habitat = Env.habitat or 0
                        end
                    else
                        local grav = self:GetPhysicsObject():IsGravityEnabled()

                        if (grav) then
                            local sv_grav = physenv.GetGravity().z
                            self.environment.gravity = math.Round(sv_grav * (-1) / 600, 3)
                        else
                            self.environment.gravity = 0
                        end
                    end

                    self.environment.water = self:WaterLevel()
                end

                self:SetWire("Gravity", self.environment.gravity)
                self:SetWire("Habitat", self.environment.habitat)
                self:SetWire("Atmosphere", self.environment.atmosphere)
                self:SetWire("Temperature", self.environment.temperature)
                self:SetWire("O2 Percent", self.environment.o2)
                self:SetWire("CO2 Percent", self.environment.co2)
                self:SetWire("N2 Percent", self.environment.n2)
                self:SetWire("H2 Percent", self.environment.h2)
                self:SetWire("Water Level", self.environment.water)
            end
        end)
    end

    -----------------------------------SPAWN----------------------------------
    function ENT:SpawnFunction(ply, tr)
        if (not tr.Hit) then return end
        local ent = ents.Create("kino_ball")
        ent:SetPos(tr.HitPos)
        ent:Spawn()
        ent:Activate()

        return ent
    end

    function ENT:UpdateTransmitState()
        return TRANSMIT_ALWAYS
    end

    -----------------------------------TELEPORT----------------------------------
    function ENT.FixAngles(self, pos, ang, vel, old_pos, old_ang, old_vel, ang_delta)
        local newphys = self.Entity:GetPhysicsObject()
        local kinoang = ang
        kinoang.p = kinoang.p + ang_delta.p
        kinoang.y = kinoang.y + ang_delta.y + 180
        kinoang.r = kinoang.r + ang_delta.r

        if self.IsControlled then
            self.Owner:SetEyeAngles(kinoang)
        end

        self.LastYaw = kinoang.Yaw
        self.AnglesSwep = kinoang
        self.Vel = vel / 10
        self.Acc = vel / 10
        self.AccSwep = vel / 40
        self.Vel = LerpVector(FrameTime() * 10, self.Vel + vel / 10, Vector(0, 0, 0))
        newphys:SetVelocity(self.Acc * 10 + self.Vel)
    end

    StarGate.Teleport:Add("kino_ball", ENT.FixAngles)

    -----------------------------------REMOVE AND DAMAGE----------------------------------
    function ENT:OnRemove()
        local ent = self.Entity

        if (ent and ent:IsValid()) then
            for i = 0, 4 do
                local effectdata = EffectData()
                effectdata:SetEntity(ent)
                util.Effect("entity_remove", effectdata)
            end

            ent:Remove()
            self.PhysicsUpdate = function() end
        end
        timer.Remove("KinoWire_" .. self:EntIndex())
    end

    function ENT:OnTakeDamage(dmg)
        self.EntHealth = self.EntHealth - dmg:GetDamage()

        if (self.EntHealth <= 1) then
            self.Entity:PrepareRemove()
        end
    end

    function ENT:HealthRepair(health)
        self.EntHealth = health
        self:SetWire("Health", health)
    end
    
    function ENT:PrepareRemove()
        local ent = self.Entity

        if (ent and ent:IsValid() and self.KillKino == false) then
            self.KillKino = true
            local phys = ent:GetPhysicsObject()
            phys:EnableGravity(true)
            phys:EnableDrag(true)
            constraint.RemoveAll(self)
            phys:EnableMotion(true)

            timer.Simple(2, function()
                self.RemoveEnt = true
            end)
        end
    end

    -----------------------------------CONTROLL----------------------------------
    function ENT:MoveKino(dir)
        local ply = self.Owner
        if (not IsValid(ply)) then return end

        if not dir then
            self.AnglesSwep = ply:EyeAngles()
        end

        local pos = Vector(0, 0, 0)

        if (ply:KeyDown(IN_FORWARD)) then
            if (ply:KeyDown(IN_SPEED)) then
                pos = pos + self.Entity:GetForward() * 5
            else
                pos = pos + self.Entity:GetForward() * 1.5
            end
        elseif (ply:KeyDown(IN_BACK)) then
            pos = pos - self.Entity:GetForward()
        end

        if (ply:KeyDown(IN_MOVERIGHT)) then
            pos = pos + self.Entity:GetRight()
        elseif (ply:KeyDown(IN_MOVELEFT)) then
            pos = pos - self.Entity:GetRight()
        end

        if (ply:KeyDown(IN_JUMP)) then
            pos = pos + self.Entity:GetUp()
        elseif (ply:KeyDown(IN_DUCK)) then
            pos = pos - self.Entity:GetUp()
        end

        if dir then
            pos = dir
        end

        self.AccSwep = pos * 1.5
    end

    function ENT:Keys(ply)
        local ply = self.Owner

        if (ply:KeyPressed(IN_RELOAD) and self.CanZoom == true) then
            self.CanZoom = false

            timer.Simple(1, function()
                self.CanZoom = true
            end)

            self.Entity:EmitSound(self.Sounds.Zoom, 150)
            local fov = ply:GetFOV()

            if (fov > 74 and fov < 91) then
                self.FOV = self.Owner:GetFOV()
                ply:SetFOV(30, 0.3)
            else
                ply:SetFOV(self.FOV, 0.5)
            end
        end
    end

    function ENT:SwitchedKino(ply)
        self:EmitSound(self.Sounds.TurnOn, 150)
        local ang = self.Entity:GetAngles()
        ply:SetEyeAngles(ang)
        self.AnglesSwep = ang
        self.LastYaw = ang.Yaw
        self.Entity:SetAngles(ang)
    end

    function ENT:ExitKino(ply)
        if (IsValid(ply)) then
            if (ply:Alive()) then
                ply:SetMoveType(MOVETYPE_WALK)
                ply:SetObserverMode(OBS_MODE_NONE)
                ply:Spawn()
                ply:SetFOV(ply.CAP_KINO_FOV or 0, 0.3)
                ply:SetPos(ply.CAP_KINO_StartPos or ply:GetPos() + Vector(0, 0, 5)) -- whoa it repaired everythin
            end

            ply:SetViewEntity(ply)
            ply:SetNWBool("KActive", false)
            ply:SetNWEntity("Kino", NULL)
        end

        self:MoveKino(Vector(0, 0, 0))
        self.IsControlled = false
        self.Remote = nil
        self.Player = nil
    end

    -- second fix if player dead when kino and swep removed
    hook.Add("PlayerDeath", "CAP.Kino.DeathFix", function(ply)
        if (IsValid(ply)) then
            ply:SetViewEntity(ply)
            ply:SetNWBool("KActive", false)
            ply:SetNWEntity("Kino", NULL)
        end
    end)

    -----------------------------------THINK----------------------------------
    function ENT:Think()
        if ((not IsValid(self.Remote) or not IsValid(self.Remote.Owner)) and IsValid(self.Player) or not IsValid(self.Player) or not self.Player:Alive()) then
            self:ExitKino(self.Player)
        end

        if (self.IsControlled == false) then
            self.AccSwep = Vector(0, 0, 0)
        end

        if (self.RemoveEnt == true) then
            self.Entity:OnRemove()
        end

        if IsValid(self.Phys) then
            if not self.KillKino then
                self.Phys:EnableGravity(false)
            end
        end
    end

    -----------------------------------PHYS----------------------------------
    function ENT:PhysicsUpdate(phys, deltatime)
        if not self.KillKino and FrameTime() > 0 then
            local newphys = self.Entity:GetPhysicsObject()
            self.Vel = LerpVector(FrameTime() * 10, self.Vel + self.Entity:GetVelocity() / 10, Vector(0, 0, 0))
            self.Acc = LerpVector(FrameTime(), self.Acc, self.AccSwep * 4)
            newphys:SetVelocity(self.Acc * 10 + self.Vel)
            local AerodynamicRoll = self.Entity:GetAngles().Yaw - self.LastYaw
            local roll = math.Clamp(-8 * AerodynamicRoll, -40, 40)
            self.LastYaw = self.Entity:GetAngles().Yaw
            local ang = self.Entity:GetAngles()
            local p = math.AngleDifference(self.AnglesSwep.Pitch, ang.Pitch)
            local y = math.AngleDifference(self.AnglesSwep.Yaw, ang.Yaw)
            local r = math.AngleDifference(roll, ang.Roll)
            newphys:AddAngleVelocity(-1 * newphys:GetAngleVelocity())
            newphys:AddAngleVelocity(Vector(r, p, y))
        end
    end

    function ENT:PostEntityPaste(ply, Ent, CreatedEntities)
        if (StarGate.NotSpawnable(Ent:GetClass(), ply)) then
            self.Entity:Remove()

            return
        end

        if (IsValid(ply)) then
            local PropLimit = StarGate.CFG:Get("kino_dispenser", "max_kino", 4)

            if (ply:GetCount("CAP_kino") + 1 > PropLimit) then
                ply:SendLua("GAMEMODE:AddNotify(\"Kino limit reached!\", NOTIFY_ERROR, 5); surface.PlaySound( \"buttons/button2.wav\" )")
                self.Entity:Remove()

                return
            end
        end

        if (IsValid(ply)) then
            self.Owner = ply
            ply:AddCount("CAP_kino", self.Entity)
        end
    end

    if (StarGate and StarGate.CAP_GmodDuplicator) then
        duplicator.RegisterEntityClass("kino_ball", StarGate.CAP_GmodDuplicator, "Data")
    end
end

if CLIENT then
    ENT.RenderGroup = RENDERGROUP_BOTH

    ENT.Sounds = {
        Fly = Sound("kino/kino_fly.wav")
    }

    function ENT:Initialize()
        self.FlySound = self.FlySound or CreateSound(self.Entity, self.Sounds.Fly)
        self.FlySoundOn = false
        self:StartClientsideSound()
    end

    function ENT:OnRemove()
        self.FlySound:Stop()
    end

    function ENT:StartClientsideSound()
        self.FlySound:SetSoundLevel(80)
        self.FlySound:PlayEx(1, 80)
        self.FlySoundOn = true
    end

    function ENT:Think()
        local velo = self.Entity:GetVelocity() * 10
        local pitch = -1 * self.Entity:GetVelocity():Length()
        local doppler = 0
        local dir = (LocalPlayer():GetPos() - self.Entity:GetPos())
        doppler = velo:Dot(dir) / (150 * dir:Length())

        if (self.FlySoundOn) then
            self.FlySound:ChangePitch(math.Clamp(60 + pitch / 25, 75, 100), 0.1) -- + doppler,0);
        end
    end
end