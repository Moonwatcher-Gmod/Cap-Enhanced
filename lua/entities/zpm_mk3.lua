--[[
	ZPM MK III for GarrysMod 10
	Copyright (C) 2010 Llapp
]]
if (StarGate ~= nil and StarGate.LifeSupportAndWire ~= nil) then
    StarGate.LifeSupportAndWire(ENT)
end

ENT.Type = "anim"
ENT.Base = "base_anim" --gmodentity
ENT.PrintName = "Zero Point Module"
ENT.Author = "Llapp, Rafael De Jongh, Progsys"
ENT.WireDebugName = "ZPM MK III"
ENT.Category = "Stargate Carter Addon Pack"
ENT.Spawnable = false
ENT.IsZPM = true

if SERVER then
    if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("energy")) then return end
    AddCSLuaFile()

    function ENT:Initialize()
        self.Entity:SetModel("models/pg_props/pg_zpm/pg_zpm.mdl")
        self.Entity:PhysicsInit(SOLID_VPHYSICS)
        self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
        self.Entity:SetSolid(SOLID_VPHYSICS)
        local phys = self.Entity:GetPhysicsObject()

        if (phys:IsValid()) then
            phys:EnableMotion(false)
            phys:SetMass(10)
        end

        self:AddResource("energy", StarGate.CFG:Get("zpm_mk3", "energy_capacity", 1000000))
        self:SupplyResource("energy", StarGate.CFG:Get("zpm_mk3", "energy_capacity", 1000000))
        self.MaxEnergy = StarGate.CFG:Get("zpm_mk3", "capacity", 88000000)
        self.Energy = StarGate.CFG:Get("zpm_mk3", "capacity", 88000000)
        self:CreateWireOutputs("Active", "ZPM %", "ZPM Energy", "Internal Overload")
        self:Skin(2)
        self.IsTampered = false
        self.IsMk4 = false
        self:SetNWInt("zpmempty",0)
        self.empty = false
        self.Connected = false
        self.Flow = 0
        self.MaxEnergyFlow = 4000000000 -- MW
        self.isZPM = 1
        self:Spark();
        self.Deto = true;
        self.Nuke=true
        self.InitBomb=true;
        self.acolor = 255
        self.IsConnectedToHub = false
        self.InternalOverload = 0
        self.Cloaked = false
        self.Boom = false

        self.Entity:SetNWInt("zpmyellowlightalpha", 100)
    end

    function ENT:SpawnFunction(p, t)
        if (not t.Hit) then return end
        local e = ents.Create("zpm_mk3")
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
        self.Zpm = e
        return e
    end

    function ENT:Skin(a)
        if (a == 1) then
            self.Entity:SetSkin(1)
        elseif (a == 2) then
            self.Entity:SetSkin(2)
        elseif (a ==3) then
            self.Entity:SetSkin(2)
        end
    end

    function ENT:Think()

        if (self.IsCloaked) then
            self.Cloaked = true
            self.Entity:SetNWInt("zpmyellowlightalpha", 1)
            self:DrawShadow(false)
        else
            self.Cloaked = false
            self:DrawShadow(true)
            if (self.Connected) then
                self.Entity:SetNWInt("zpmyellowlightalpha", 100)
            end
        end


        if (self.empty or not self.HasResourceDistribution) then 

            self.acolor = math.Clamp( self.acolor +3, 30, 255)
            self.Entity:SetColor(Color(255,self.acolor,self.acolor,255))

            return end

        if (self.Entity:SetNetworkedEntity("ZPM", self.Zpm) == NULL) then
            self.Entity:SetNetworkedEntity("ZPM", self.Zpm)
        end

        local energy = self:GetResource("energy")

        if (self.Flow == 0) then
            --[[local entTable = RD.GetEntityTable(self);
		local netTable = RD.GetNetTable(entTable["network"]);
		local entities = netTable["entities"]; ]]
            local entities = StarGate.WireRD.GetEntListTable(self)
     
            if (entities ~= nil) then
                zpms = 0
                local zpmsarray = {}
                for k, v in pairs(entities) do
                    if IsValid(v) then
                        if (v.isZPM ~= NULL) then
                            zpms = zpms + 1
                            zpmsarray[zpms] = v
                        end
                    end
                end

                local nw_capacity = self:GetNetworkCapacity("energy")
                local rate = (nw_capacity - energy) / zpms

                for k, v in pairs(zpmsarray) do
                    v.Flow = rate
                end
            end
        end

        if (StarGate.CFG:Get("zpm_mk3", "explode", false)) then
            if (self.IsConnectedToHub == false) then
                if (self.Flow > 1578) then
                    self.InternalOverload = math.Clamp(self.InternalOverload + 2.5, 0, 120) 
                else
                    self.InternalOverload = math.Clamp(self.InternalOverload - 0.15, 0, 120) 
                end
            end

            if (self.IsConnectedToHub == true) then
                self.InternalOverload = math.Clamp(self.InternalOverload - 0.15, 0, 120) 
            end
            self.acolor = math.Clamp(255 - (2.55 * self.InternalOverload), 30, 255) 
            self.Entity:SetColor(Color(255,self.acolor,self.acolor,255))
            self:SetWire("Internal Overload",self.InternalOverload)

            if (self.InternalOverload > 100) then
                local fx = EffectData()
                fx:SetOrigin(self:GetPos())
                util.Effect("Explosion", fx)
                self.Entity:Remove()
            end
        else
            self.InternalOverload = math.Clamp(self.InternalOverload - 0.15, 0, 120) 
            self.Entity:SetColor(Color(255,255,255,255))
            self:SetWire("Internal Overload",0)
        end

        local active = 1

        if (StarGate.WireRD.Connected(self.Entity)) then
            if (not self.Connected) then
                self:Skin(1)
                self.Connected = true
            end
        else
            if (self.Connected) then
                self:Skin(2)
                self.Connected = false
            end
        end

        if (self.Energy > 0) then
            local my_capacity = self:GetUnitCapacity("energy")
            local nw_capacity = self:GetNetworkCapacity("energy")
            percent = (self.Energy / self.MaxEnergy) * 100

            if (self.IsTampered) then
                if self.Connected and self.Boom ==false then
                    self:EmitSound("ambient/energy/powerup2.wav", 100, 80)
                    self:EmitSound("ambient/energy/powerup2.wav", 100, 80)
                    timer.Create("TZPME"..self.Entity:EntIndex(), 3.0, 0, function() if IsValid(self.Entity) then self:ExplodeTimer() end end);

                    self.Boom = true
                end

                if self.Connected == false and self.Boom == true then
                    self:StopSound("ambient/energy/powerup2.wav")
                    self:EmitSound("ambient/energy/powerdown2.wav")
                    timer.Remove("TZPME"..self.Entity:EntIndex());
                    self.Boom = false
                end
            end
            if (energy < nw_capacity) then
                --local rate = (my_capacity+nw_capacity)/2;
                local rate = self.Flow
                rate = math.Clamp(rate, 0, self.Energy)
                rate = math.Clamp(rate, 0, nw_capacity - energy)
                self:SupplyResource("energy", rate)
                self.Energy = self.Energy - rate
                if (self.IsTampered) then
                    local ran = math.random(1,30);
                    if(ran == 1 and self.Connected)then
                        self:Sparks();
                    end
                    timer.Simple(0.1, function()
                        if(IsValid(self.Entity))then
                            self.SparkEnt:Fire("StopSpark", "", 0);
                        end
                    end);
                    if(self.Nuke and percent < 10)then
                        self:Nuker();
                        self.Nuke=false;
                    end
                end
            end
        else
            percent = 0
            self.Energy = 0
            active = 0
            self.empty = true
            self:SetNWInt("zpmempty",1)
            self:Skin(2)
            --if (self.HasRD) then StarGate.WireRD.OnRemove(self,true) end;
            self:AddResource("energy", 0)
            self.Connected = false
        end

        self.Flow = 0
        self:SetWire("Active", active)
        self:SetWire("ZPM Energy", math.floor(self.Energy))
        self:SetWire("ZPM %", percent)
        self:Output(percent, self.Energy)
        self.Entity:NextThink(CurTime() + 0.01)

        return true
    end

    function ENT:Output(perc, eng)
        local add = "Disconnected"

        if (self.Connected) then
            add = "Connected"
        end

        if (self.Energy <= 0) then
            add = "Depleted"
        end

        self.Entity:SetNWString("add", add)
        self.Entity:SetNWString("perc", perc)
        self.Entity:SetNWString("eng", math.floor(eng))
    end
end

function ENT:ExplodeTimer()
    if not IsValid(self.Entity) then return end
    if (self.Connected) then
        self:Nuker();
        self.Nuke=false;
    end
end

function ENT:Spark()
    local spawnflags = 512;
    local maxdelay = math.Round(math.Clamp(60, .12, 120));
    local magnitude = math.Round(math.Clamp(0.38, .5, 15));
    local traillength = math.Round(math.Clamp(0.45, .12, 15));
    if(math.Round(math.Clamp(1, 0, 1)) == 1)then
        spawnflags = spawnflags + 128;
    end
    if(math.Round(math.Clamp(1, 0, 1)) == 0)then
        spawnflags = spawnflags + 256;
    end
    local e = ents.Create("env_spark");
    e:SetPos(self.Entity:GetPos());
    e:SetAngles(self.Entity:GetAngles());
    e:SetKeyValue("MaxDelay", tostring(maxdelay));
    e:SetKeyValue("Magnitude", tostring(magnitude));
    e:SetKeyValue("TrailLength", tostring(traillength));
    e:SetKeyValue("spawnflags", tostring(spawnflags));
    e:Spawn();
    e:Activate();
    self.SparkEnt = e;
    return e;
end

function ENT:Sparks()
    local pos = Vector(3.7, 0, 45);
    local rand = math.random(1,7);
    local rang = math.random(0,360);
    local vec1 = math.random(-3,3);
    local vec2 = math.random(-3,3);
    local vec3 = math.random(-3,3);
    self.SparkEnt:SetPos(self.Entity:LocalToWorld(Vector(vec1,vec2,vec3)));
    self.SparkEnt:SetAngles(self.Entity:GetAngles()+Angle(rang,rang,0));
    self.SparkEnt:Fire("SparkOnce", "", 0);
    self.SparkEnt:Fire("StartSpark", "", 0);
end

function ENT:Detonate()
    local bomb = ents.Create("gate_nuke")
    if(bomb ~= nil and bomb:IsValid()) then
        bomb:Setup(self.Entity:GetPos(), 200)
        bomb:SetVar("owner",self.Owner)
        bomb:Spawn()
        bomb:Activate()
    end
    self.Entity:Remove()
end

function ENT:NukeInit()
    local effect = EffectData()
    effect:SetOrigin(self.Entity:GetPos())
    effect:SetMagnitude(5)
    util.Effect("Tampered_Zpm_Nuke", effect)
end

function ENT:Nuker()
    if(not self.Nuke)then return end;
    if(IsValid(self.Entity))then
        self:NukeInit();
    end
    timer.Simple(1.5,function()
        if(IsValid(self.Entity))then
            self:NukeInit();
        end
    end);
    timer.Simple(4,function()
        if(IsValid(self.Entity))then
            self:Detonate();
        end
    end);
end

if CLIENT then
    if (StarGate == nil or StarGate.MaterialFromVMT == nil) then return end

    local font = {
        font = "Arial",
        size = 16,
        weight = 500,
        antialias = true,
        additive = false
    }

    surface.CreateFont("center2", font)

    local font = {
        font = "Arial",
        size = 12,
        weight = 500,
        antialias = true,
        additive = false
    }

    surface.CreateFont("header", font)

    local font = {
        font = "Arial",
        size = 15,
        weight = 500,
        antialias = true,
        additive = true
    }

    surface.CreateFont("center", font)
    ENT.ZpmSprite = StarGate.MaterialFromVMT("ZpmSprite", [["Sprite"
	{
		"$spriteorientation" "vp_parallel"
		"$spriteorigin" "[ 0.50 0.50 ]"
		"$basetexture" "sprites/glow04"
		"$spriterendermode" 5
	}]])

    ENT.SpritePositions = {Vector(0, 0, 5), Vector(0, 0, 3), Vector(0, 0, 0), Vector(0, 0, -3), Vector(0, 0, -5)}

    ENT.Zpm_hud = surface.GetTextureID("VGUI/resources_hud/zpm")

    function ENT:Initialize()
        self.Entity:SetNWString("add", "Disconnected")
        self.Entity:SetNWString("perc", 0)
        self.Entity:SetNWString("eng", 0)
    end

    function ENT:Draw()
        self.Entity:DrawModel()
        hook.Remove("HUDPaint", tostring(self.Entity) .. "ZMK")
        if (not StarGate.VisualsMisc("cl_draw_huds", true)) then return end

        if (LocalPlayer():GetEyeTrace().Entity == self.Entity and not self.Cloaked and EyePos():Distance(self.Entity:GetPos()) < 1024) then
            hook.Add("HUDPaint", tostring(self.Entity) .. "ZMK", function()
                local w = 0
                local h = 260
                surface.SetTexture(self.Zpm_hud)
                surface.SetDrawColor(Color(255, 255, 255, 255))
                surface.DrawTexturedRect(ScrW() / 2 + 6 + w, ScrH() / 2 - 50 - h, 180, 360)
                surface.SetFont("center2")
                surface.SetFont("header")
                draw.DrawText("ZPM MK 3", "header", ScrW() / 2 + 58 + w, ScrH() / 2 + 41 - h, Color(0, 255, 255, 255), 0)
                draw.DrawText("Status", "center2", ScrW() / 2 + 40 + w, ScrH() / 2 + 65 - h, Color(209, 238, 238, 255), 0)
                draw.DrawText("Energy", "center2", ScrW() / 2 + 40 + w, ScrH() / 2 + 115 - h, Color(209, 238, 238, 255), 0)
                draw.DrawText("Capacity", "center2", ScrW() / 2 + 40 + w, ScrH() / 2 + 165 - h, Color(209, 238, 238, 255), 0)

                if (IsValid(self.Entity)) then
                    add = self.Entity:GetNetworkedString("add")
                    perc = self.Entity:GetNWString("perc")
                    eng = self.Entity:GetNWString("eng")
                end

                surface.SetFont("center")
                local color = Color(0, 255, 0, 255)

                if (add == "Disconnected" or add == "Depleted") then
                    color = Color(255, 0, 0, 255)
                end

                if (tonumber(perc) > 0) then
                    perc = string.format("%f", perc)
                end

                draw.SimpleText(add, "center", ScrW() / 2 + 40 + w, ScrH() / 2 + 85 - h, color, 0)
                draw.SimpleText(tostring(eng), "center", ScrW() / 2 + 40 + w, ScrH() / 2 + 135 - h, Color(255, 255, 255, 255), 0)
                draw.SimpleText(tostring(perc) .. "%", "center", ScrW() / 2 + 40 + w, ScrH() / 2 + 185 - h, Color(255, 255, 255, 255), 0)
            end)
        end
        
        render.SetMaterial(self.ZpmSprite)
        local alpha = self.Entity:GetNWInt("zpmyellowlightalpha")

        if(self.Entity:GetNWInt("ZPMScannedTainted") == 1) then
            zpmcol = Color(50,50,255,255)
            lightadd = 10
        else
            zpmcol = Color(255, 165, 0, alpha)
            lightadd = 25
        end

        if(self:GetNWInt("zpmempty") == 0) then
            for i = 1, 5 do
                local size = 9

                if (i == 3) then
                    size = 8
                elseif (i == 4) then
                    size = 7
                elseif (i == 5) then
                    size = 6
                end

                render.DrawSprite(self.Entity:LocalToWorld(self.SpritePositions[i]), size, size, zpmcol)
            end

            local dlight = DynamicLight(self:EntIndex())
            if(dlight) then
                dlight.Pos = self:GetPos()
                dlight.Decay = 100
                dlight.Brightness = 1
                dlight.Size = self.Entity:GetNWString("perc") + lightadd
                dlight.DieTime = CurTime() + 1
                dlight.r = zpmcol.r
                dlight.g = zpmcol.g
                dlight.b = zpmcol.b
            end
        end
    end

    function ENT:OnRemove()
        hook.Remove("HUDPaint", tostring(self.Entity) .. "ZMK")
    end
end