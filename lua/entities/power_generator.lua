if (StarGate ~= nil and StarGate.LifeSupportAndWire ~= nil) then
    StarGate.LifeSupportAndWire(ENT)
end

ENT.Type = "anim"
ENT.Base = "base_anim" --gmodentity
ENT.PrintName = "Power Generator"
ENT.Author = "Soren"
ENT.WireDebugName = "Power Generator"
ENT.Category = "Moonwatcher:Machines"
ENT.Spawnable = false
ENT.AdminSpawnable = false


if SERVER then
    if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("energy")) then return end
    AddCSLuaFile()

	function ENT:Initialize()

		self.Entity:SetModel("models/naquada-reactor.mdl")
        self.Entity:SetMaterial("materials/models/reactor-skin-off")
		self.Entity:SetName("power_generator")
		self.Entity:PhysicsInit(SOLID_VPHYSICS)
		self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
		self.Entity:SetSolid(SOLID_VPHYSICS)

		self.InternalPower = 0
		self.MaxTransfer = 100000
		self.GenTime = 0
        self.Active = false



		local phys = self.Entity:GetPhysicsObject()
        if (phys:IsValid()) then
            phys:Wake()
            phys:SetMass(10)
        end
        self.Entity:SetUseType(SIMPLE_USE)
        
	end

    function ENT:Use()
        if (not (self.Active)) then
            self.Active = true
        else
            self.Active = false
        end
    end

	function ENT:RequestPower (entity, power_requested)

		if (power_requested <= self.InternalPower) then
            if (power_requested > self.MaxTransfer) then
                self.InternalPower = self.InternalPower - self.MaxTransfer
                return self.MaxTransfer
            else
			     self.InternalPower = self.InternalPower - power_requested
			     return power_requested
            end
		else
            local power = self.InternalPower
            self.InternalPower = math.Clamp(self.InternalPower - power_requested, 0, 999999999) 
			return power
		end
	end

	function ENT:Think()

        if (self.Active) then
    		if (CurTime() > self.GenTime )then

    			self.InternalPower = self.InternalPower + 10


    			self.Entity:SetNWString("energy",self.InternalPower)
    			self.GenTime = CurTime() + 1
    		end
        end

        self.Entity:SetNWBool("add",self.Active)
	end
end


if CLIENT then

	ENT.Zpm_hud = surface.GetTextureID("VGUI/resources_hud/tier_7")

    function ENT:Initialize()
        self.Entity:SetNWBool("add", false)
        self.Entity:GetNWString("energy",0)
    end	


    function ENT:Think()
        self.Entity:NextThink(CurTime() + 1)

        return true
    end

function ENT:Draw()

        self.Entity:DrawModel()

        if (not StarGate.VisualsMisc("cl_draw_huds", true)) then
            hook.Remove("HUDPaint", tostring(self.Entity) .. "power_generator")

            return
        end

        hook.Remove("HUDPaint", tostring(self.Entity) .. "power_generator")

        if (LocalPlayer():GetEyeTrace().Entity == self.Entity and EyePos():Distance(self.Entity:GetPos()) < 1024) then
            hook.Add("HUDPaint", tostring(self.Entity) .. "power_generator", function()
                local w = 0
                local h = 260
                surface.SetTexture(self.Zpm_hud)
                surface.SetDrawColor(Color(255, 255, 255, 255))
                surface.DrawTexturedRect(ScrW() / 2 + 6 + w, ScrH() / 2 - 50 - h, 180, 360)
                surface.SetFont("center2")
                surface.SetFont("header")
                draw.DrawText("Power Gen", "header", ScrW() / 2 + 62 + w, ScrH() / 2 + 41 - h, Color(255, 255, 255, 255), 0)

                if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then
                    draw.DrawText("Energy", "center2", ScrW() / 2 + 45 + w, ScrH() / 2 + 65 - h, Color(209, 238, 238, 255), 0)         
                end

                if (IsValid(self.Entity)) then
                	add = self.Entity:GetNWBool("add",false)
                    energyPercent = 0
                    energy = self.Entity:GetNWString("energy",0)
                end
                local color = Color(255, 255, 255, 255)
                surface.SetFont("center")
                if (add == true) then
                 	color = Color(0, 255, 0, 255)
            	else
            		color = Color(255, 0, 0, 255)
            	end

                if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then
                    draw.SimpleText(add, "center", ScrW() / 2 + 135 + w, ScrH() / 2 + 40 - h, color, 0)
                end

                --draw.SimpleText(tostring(math.Round(energyPercent,2)).."%", "center", ScrW() / 2 + 85 + w, ScrH() / 2 + 67 - h, Color(255, 255, 255, 255), 0)
                draw.SimpleText(tostring(energy), "center", ScrW() / 2 + 90 + w, ScrH() / 2 + 67 - h, Color(255, 255, 255, 255), 0)
            end)
        end
    end
	function ENT:OnRemove()
	    hook.Remove("HUDPaint", tostring(self.Entity) .. "power_generator")
	end
end