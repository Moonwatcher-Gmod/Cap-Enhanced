ENT.Type = "anim"
ENT.Base = "base_anim" --gmodentity
ENT.PrintName = "Ore deposit: Naquadah"
ENT.Author = "Soren"
ENT.Untouchable = true
ENT.Spawnable = false
ENT.AdminSpawnable = false

ENT.Category = "Stargate Carter Addon Pack: MoonWatcher"
--list.Set("CAP.Entity", ENT.PrintName, ENT)
ENT.Category = "MoonWatcher"

if SERVER then
    AddCSLuaFile()

    function ENT:Initialize()
        self.Entity:SetModel("models/metal/largeoredeposit.mdl")
        self.Entity:PhysicsInit(SOLID_VPHYSICS)
        self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
        self.Entity:SetSolid(SOLID_VPHYSICS)
        self.Entity:DrawShadow(false)
        self.Entity:SetSkin(2)
        self.type = 1
        local phys = self.Entity:GetPhysicsObject()

        if (phys:IsValid()) then
            phys:EnableMotion(false)
            phys:SetMass(10)
        end
    end

    function ENT:SpawnFunction(pl, tr)
        if (not tr.HitWorld) then return end
        local e = ents.Create("oredeposit_naq")
        e:SetPos(tr.HitPos + Vector(0, 0, -10))
        e:SetUseType(SIMPLE_USE)
        e:Spawn()

        return e
    end
end

if CLIENT then
    --ENT.Zpm_hud = surface.GetTextureID("VGUI/resources_hud/ion_gen");
    ore_hud = surface.GetTextureID("VGUI/resources_hud/ui_small")
end

--self:UpdateUI(self.Entity.GetNetworkedInt("tier"))
function ENT:Draw()
    self.Entity:DrawModel()
    hook.Remove("HUDPaint", tostring(self.Entity) .. "ore")
    if (not StarGate.VisualsMisc("cl_draw_huds", true)) then return end

    if (LocalPlayer():GetEyeTrace().Entity == self.Entity and EyePos():Distance(self.Entity:GetPos()) < 1024) then
        hook.Add("HUDPaint", tostring(self.Entity) .. "ore", function()
            local w = 0
            local h = 260
            surface.SetTexture(ore_hud)
            surface.SetDrawColor(Color(255, 255, 255, 255))
            surface.DrawTexturedRect(ScrW() / 2 + 6 + w, ScrH() / 2 - 50 - h, 180, 360)
            surface.SetFont("center2")
            surface.SetFont("header")
            --draw.DrawText("Promethium", "header", ScrW() / 2 + 54 + w, ScrH() / 2 +41 - h, Color(255,255,255,255), 0)
            draw.DrawText("Ore:", "center2", ScrW() / 2 + 40 + w, ScrH() / 2 + 65 - h, Color(209, 238, 238, 255), 0)
            --draw.DrawText("Status", "center2", ScrW() / 2 + 40 + w, ScrH() / 2 +115 - h, Color(209,238,238,255),0);
            --draw.DrawText("Capacity", "center2", ScrW() / 2 + 40 + w, ScrH() / 2 +165 - h, Color(209,238,238,255),0);
            surface.SetFont("center")
            -- local color = Color(255,255,255,255);
            -- if(add == "Offline" or add == "Depleted")then
            --     color = Color(255,255,255,255);
            -- end
            --draw.SimpleText(add, "HudHintTextLarge", ScrW() / 2 + 54 + w, ScrH() / 2 +35 - h, color,0);
            draw.SimpleText("Naquadah", "center", ScrW() / 2 + 70 + w, ScrH() / 2 + 65 - h, Color(255, 255, 255, 255), 0)
            draw.SimpleText("Nq", "DermaLarge", ScrW() / 2 + 40 + w, ScrH() / 2 + 85 - h, Color(255, 128, 0, 255), 0)
        end)
        --draw.SimpleText(tostring(perc).."%", "center", ScrW() / 2 + 40 + w, ScrH() / 2 +185 - h, Color(255,255,255,255),0)
    end
end

function ENT:OnRemove()
    hook.Remove("HUDPaint", tostring(self.Entity) .. "ore")
end