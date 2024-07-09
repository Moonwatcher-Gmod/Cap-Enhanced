--[[
	ZPM MK IV for GarrysMod 10
	Copyright (C) 2010 Llapp
]]
if (StarGate ~= nil and StarGate.LifeSupportAndWire ~= nil) then
    StarGate.LifeSupportAndWire(ENT)
end

ENT.Type = "anim"
ENT.Base = "base_anim" --gmodentity
ENT.PrintName = "Zero Point Module MK4"
ENT.Author = "Llapp, Rafael De Jongh, Progsys"
ENT.WireDebugName = "ZPM MK IV"
ENT.Category = "Stargate Carter Addon Pack"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.IsZPM = true
list.Add("MW.Entity", ENT.PrintName)

if SERVER then
    if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("energy")) then return end
    AddCSLuaFile()

    function ENT:Initialize()
        self.Entity:SetModel("models/pg_props/pg_zpm/pg_zpm4.mdl")
        self.Entity:PhysicsInit(SOLID_VPHYSICS)
        self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
        self.Entity:SetSolid(SOLID_VPHYSICS)
        local phys = self.Entity:GetPhysicsObject()

        if (phys:IsValid()) then
            phys:EnableMotion(false)
            phys:SetMass(10)
        end

        self:AddResource("energy", StarGate.CFG:Get("zpm_mk4", "energy_capacity", 1800000))
        self:SupplyResource("energy", StarGate.CFG:Get("zpm_mk4", "energy_capacity", 88000000))
        self.MaxEnergy = StarGate.CFG:Get("zpm_mk4", "capacity", 98000000)
        self.Energy = StarGate.CFG:Get("zpm_mk4", "capacity", 98000000)
        self:CreateWireOutputs("Active", "ZPM %", "ZPM Energy")
        self:Skin(2)
        self.IsMk4 = true
        self.empty = false
        self.Connected = false
        self.Flow = 0
        self.isZPM = 1
        self.acolor = 255
        self.IsConnectedToHub = false
        self.InternalOverload = 0
        self.Cloaked = false
    end

    function ENT:SpawnFunction(p, t)
        if (not t.Hit) then return end
        local e = ents.Create("zpm_mk4")
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
            self.Entity:SetSkin(5)
            self.Entity:SetNWInt("zpmbluelightalpha", 255)
        elseif (a == 2) then
            self.Entity:SetSkin(4)
            self.Entity:SetNWInt("zpmbluelightalpha", 1)
        end
    end

    function ENT:Think()

        if (self.IsCloaked) then
            self.Cloaked = true
            self.Entity:SetNWInt("zpmbluelightalpha", 1)
            self:DrawShadow(false)
        else
            self.Cloaked = false
            self:DrawShadow(true)
            if (self.Connected) then
                self.Entity:SetNWInt("zpmbluelightalpha", 155)
            end
        end



        
        if (self.empty or not self.HasResourceDistribution) then

            self.acolor = math.Clamp( self.acolor +3, 30, 255)
            self.Entity:SetColor(Color(255,self.acolor,self.acolor,255))
            return 
        end

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
------------------------Internal Overload------------------------------------------------
        if (StarGate.CFG:Get("zpm_mk4", "explode", false)) then
            if (self.IsConnectedToHub == false) then
                if (self.Flow > 2578) then
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

        
        

        
------------------------------------------------------------------------------------------
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

            if (energy < nw_capacity) then
                --local rate = (my_capacity+nw_capacity)/2;
                local rate = self.Flow
                rate = math.Clamp(rate, 0, self.Energy)
                rate = math.Clamp(rate, 0, nw_capacity - energy)
                self:SupplyResource("energy", rate)
                self.Energy = self.Energy - rate
            end
        else
            percent = 0
            self.Energy = 0
            active = 0
            self.empty = true
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

    ENT.Zpm_hud = surface.GetTextureID("VGUI/resources_hud/zpm4")

    function ENT:Initialize()
        self.Entity:SetNWString("add", "Disconnected")
        self.Entity:SetNWString("perc", 0)
        self.Entity:SetNWString("eng", 0)
    end

    function ENT:Draw()
        self.Entity:DrawModel()
        hook.Remove("HUDPaint", tostring(self.Entity) .. "ZMK4")
        if (not StarGate.VisualsMisc("cl_draw_huds", true)) then return end

        if (LocalPlayer():GetEyeTrace().Entity == self.Entity and not self.Cloaked and EyePos():Distance(self.Entity:GetPos()) < 1024) then
            hook.Add("HUDPaint", tostring(self.Entity) .. "ZMK4", function()
                local w = 0
                local h = 260
                surface.SetTexture(self.Zpm_hud)
                surface.SetDrawColor(Color(255, 255, 255, 255))
                surface.DrawTexturedRect(ScrW() / 2 + 6 + w, ScrH() / 2 - 50 - h, 180, 360)
                surface.SetFont("center2")
                surface.SetFont("header")
                draw.DrawText("ZPM MK 4", "header", ScrW() / 2 + 58 + w, ScrH() / 2 + 41 - h, Color(0, 255, 255, 255), 0)
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
        local alpha = self.Entity:GetNWInt("zpmbluelightalpha")
        local col = Color(0, 102, 255, alpha)

        for i = 1, 5 do
            local size = 9

            if (i == 3) then
                size = 8
            elseif (i == 4) then
                size = 7
            elseif (i == 5) then
                size = 6
            end

            render.DrawSprite(self.Entity:LocalToWorld(self.SpritePositions[i]), size, size, col)
        end
    end

    function ENT:OnRemove()
        hook.Remove("HUDPaint", tostring(self.Entity) .. "ZMK4")
    end
end