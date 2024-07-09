if (StarGate ~= nil and StarGate.LifeSupportAndWire ~= nil) then
    StarGate.LifeSupportAndWire(ENT)
end

ENT.Type = "anim"
ENT.Base = "base_anim" --gmodentity
ENT.PrintName = "Resource consumer"
ENT.Author = "Soren"
ENT.WireDebugName = "Resource consumer"
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
        self:AddResource("energy",0)
        self:CreateWireInputs("Consume", "Amount")
        self:CreateWireOutputs("Efficiency")
        self.Energy = 0
        self.EnergyCap= 10000
        self.Switch= true
        self.Node=nil
        self.Efficiency = 0
        self.Buffer = 0
    end

    function ENT:SpawnFunction(p, t)
        if (not t.Hit) then return end
        local e = ents.Create("mw_resource_consumer")
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
        
            local energy_gained =self:ConsumeResource("energy",math.Clamp(10000*(self.Efficiency/100),500,10000))
            self.Buffer = math.Clamp(self.Buffer + energy_gained, 0, 100000)
            self.Efficiency = (self.Buffer/100000)*100

        if(self:GetWire("Consume") >0) then
            self.Buffer = math.Clamp(self.Buffer - 2000*(self.Efficiency/100), 0, 100000)
        end

        self:SetWire("Efficiency", self.Efficiency)

        if (self:GetWire("Consume") >0) then
            self.Entity:SetNWString("add", "ON")
        else
            self.Entity:SetNWString("add", "OFF")
        end

        self.Entity:SetNWString("Buffer",self.Buffer)
        self.Entity:SetNWString("Efficiency",self.Efficiency)

        self.Entity:NextThink(CurTime() + 0.3)

        return true
    end
end


if CLIENT then

    ENT.Zpm_hud = surface.GetTextureID("VGUI/resources_hud/tier_3_small")

    function ENT:Initialize()
        self.Entity:SetNWString("add", "OFF")
        self.Entity:GetNWString("Efficiency",0)
        self.Entity:SetNWString("Buffer", 0)
        
    end 


    function ENT:Think()
        self.Entity:NextThink(CurTime() + 0.001)

        return true
    end

function ENT:Draw()

        self.Entity:DrawModel()

        if (not StarGate.VisualsMisc("cl_draw_huds", true)) then
            hook.Remove("HUDPaint", tostring(self.Entity) .. "mw_resource_consumer")

            return
        end

        hook.Remove("HUDPaint", tostring(self.Entity) .. "mw_resource_consumer")

        if (LocalPlayer():GetEyeTrace().Entity == self.Entity and EyePos():Distance(self.Entity:GetPos()) < 1024) then
            hook.Add("HUDPaint", tostring(self.Entity) .. "mw_resource_consumer", function()
                local w = 0
                local h = 260
                surface.SetTexture(self.Zpm_hud)
                surface.SetDrawColor(Color(255, 255, 255, 255))
                surface.DrawTexturedRect(ScrW() / 2 + 6 + w, ScrH() / 2 - 50 - h, 180, 360)
                surface.SetFont("center2")
                surface.SetFont("header")
                draw.DrawText("Powercell", "header", ScrW() / 2 + 58 + w, ScrH() / 2 + 41 - h, Color(255, 255, 255, 255), 0)

                if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then
                    draw.DrawText("Energy", "center2", ScrW() / 2 + 40 + w, ScrH() / 2 + 65 - h, Color(209, 238, 238, 255), 0)         
                end

                if (IsValid(self.Entity)) then
                    add = self.Entity:GetNWString("add","OFF")
                    energyPercent = self.Entity:GetNWString("Efficiency",0)
                    energy = self.Entity:GetNWString("Buffer",0)
                end
                local color = Color(255, 255, 255, 255)
                surface.SetFont("center")
                if (add == "ON") then
                    color = Color(0, 255, 0, 255)
                else
                    color = Color(255, 0, 0, 255)
                end

                if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then
                    draw.SimpleText(add, "center", ScrW() / 2 + 135 + w, ScrH() / 2 + 40 - h, color, 0)
                end

                draw.SimpleText(tostring(math.Round(energyPercent,2)).."%", "center", ScrW() / 2 + 85 + w, ScrH() / 2 + 67 - h, Color(255, 255, 255, 255), 0)
                draw.SimpleText(tostring(energy), "center", ScrW() / 2 + 40 + w, ScrH() / 2 + 85 - h, Color(255, 255, 255, 255), 0)
            end)
        end
    end
    function ENT:OnRemove()
        hook.Remove("HUDPaint", tostring(self.Entity) .. "mw_resource_consumer")
    end
end