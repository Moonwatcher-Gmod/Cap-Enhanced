if (StarGate ~= nil and StarGate.LifeSupportAndWire ~= nil) then
    StarGate.LifeSupportAndWire(ENT)
end

ENT.Type = "anim"
ENT.Base = "base_anim" --gmodentity
ENT.PrintName = "Small Powercell"
ENT.Author = "Soren MC, Spacebuild"
ENT.WireDebugName = "Powercell_small"

ENT.Category = "Stargate Carter Addon Pack: MoonWatcher"
list.Set("CAP.Entity", ENT.PrintName, ENT)
ENT.Category = "MoonWatcher"


ENT.Spawnable = false
ENT.AdminSpawnable = false
--list.Add("MW.Entity", ENT.PrintName)



if SERVER then
	if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("energy")) then return end
	AddCSLuaFile()

	function ENT:Initialize()
        if(!util.IsValidModel("models/props_phx/life_support/battery_small.mdl")) then 
            self.Entity.Owner:SendLua("GAMEMODE:AddNotify(\"Missing Powercell Model! You need to install Spacebuild!\", NOTIFY_ERROR, 8); surface.PlaySound( \"buttons/button2.wav\" )")
            self.Entity:Remove()
            return
        end

        self.Entity:SetModel("models/props_phx/life_support/battery_small.mdl")
        self.Entity:PhysicsInit(SOLID_VPHYSICS)
        self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
        self.Entity:SetSolid(SOLID_VPHYSICS)
        local phys = self.Entity:GetPhysicsObject()

        if (phys:IsValid()) then
            phys:EnableMotion(false)
            phys:SetMass(10)
        end

        self:AddResource("energy", StarGate.CFG:Get("powercell_small", "energy_capacity", 100000))
        self:SupplyResource("energy", StarGate.CFG:Get("powercell_small", "energy_capacity", 8800000))
        self.MaxEnergy = StarGate.CFG:Get("powercell_small", "capacity", 8800000)
        self.Energy = StarGate.CFG:Get("powercell_small", "capacity", 8800000)
        self.Status = false
        self:CreateWireOutputs("Active", "Powercell %", "Powercell Energy")
        self.Connected = false
        self.CurrentEnergy = 0
        self.LastEnergy = 0
        self.MaxOutput = 20000
    end

    function ENT:SpawnFunction(p, t)
        if (not t.Hit) then return end
        local e = ents.Create("powercell_small")
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
	    --if(self.depleted or not self.HasResourceDistribution) then self.Entity:NextThink(CurTime()+0.5); return true; end;
	    local energy = self:GetResource("energy")
        local nw_capacity = self:GetNetworkCapacity("energy")

        local rate = nw_capacity - energy

	    if (StarGate.WireRD.Connected(self)) then
	    	self.Status = true
	    end


	    local en = self:GetNetworkCapacity("energy") - self:GetResource("energy")

	    
	    self.Energy = math.Clamp(self.Energy - rate, 0, self.MaxEnergy) 
        if (self.Energy <= 0) then
        	self.Status = false
        	--self:SupplyResource("energy", 0)
        else
        	self:SupplyResource("energy", en)
        end

	    ----OUTPUT---------
	    percent = (self.Energy/self.MaxEnergy)*100
	    if (self.Status) then
	    	self.Entity:SetNWString("add", "ON")
		else
			self.Entity:SetNWString("add", "OFF")
	    end
	    self.Entity:SetNWString("energy%",percent)
	    self.Entity:SetNWString("energy",self.Energy)

        self.Entity:NextThink(CurTime() + 0.01)
	    return true
	end
end


if CLIENT then

	ENT.Zpm_hud = surface.GetTextureID("VGUI/resources_hud/tier_3_small")

    function ENT:Initialize()
        self.Entity:SetNWString("add", "OFF")
        self.Entity:SetNWString("energy%", 0)
        self.Entity:GetNWString("energy",0)
    end	


    function ENT:Think()
        self.Entity:NextThink(CurTime() + 0.001)

        return true
    end

function ENT:Draw()

        self.Entity:DrawModel()

        if (not StarGate.VisualsMisc("cl_draw_huds", true)) then
            hook.Remove("HUDPaint", tostring(self.Entity) .. "powercell_small")

            return
        end

        hook.Remove("HUDPaint", tostring(self.Entity) .. "powercell_small")

        if (LocalPlayer():GetEyeTrace().Entity == self.Entity and EyePos():Distance(self.Entity:GetPos()) < 1024) then
            hook.Add("HUDPaint", tostring(self.Entity) .. "powercell_small", function()
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
                    energyPercent = self.Entity:GetNWString("energy%",0)
                    energy = self.Entity:GetNWString("energy",0)
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
	    hook.Remove("HUDPaint", tostring(self.Entity) .. "powercell_small")
	end
end

