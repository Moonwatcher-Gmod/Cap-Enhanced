--[[
	Naquadah Generator for GarrysMod10, based on aVoN's ZPM
	Copyright (C) 2007 RononDex

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]
-- When you need to add LifeSupport and Wire capabilities, you NEED TO CALL this before anything else or it wont work!
if (StarGate ~= nil and StarGate.LifeSupportAndWire ~= nil) then
    StarGate.LifeSupportAndWire(ENT)
end

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Naquadah Generator"
ENT.Author = "RononDex"
ENT.Contact = ""
ENT.WireDebugName = "Naquadah Generator"
ENT.Spawnable = false
ENT.AdminSpawnable = false

if SERVER then
    --################# HEADER #################
    if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("energy")) then return end
    AddCSLuaFile()

    --################# SENT CODE ###############
    --################# Init
    function ENT:Initialize()
        self.Entity:SetModel("models/naquada-reactor.mdl")
        self.Entity:SetMaterial("materials/models/reactor-skin-off")
        self.Entity:PhysicsInit(SOLID_VPHYSICS)
        self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
        self.Entity:SetSolid(SOLID_VPHYSICS)
        self.MaxEnergy = StarGate.CFG:Get("naq_gen_mk1", "naquadah", 12000)
        self.Energy = StarGate.CFG:Get("naq_gen_mk1", "naquadah", 12000)
        self:AddResource("energy", StarGate.CFG:Get("naq_gen_mk1", "energy", 10000))
        self.Generate = StarGate.CFG:Get("naq_gen_mk1", "generate", 130)
        self.GenMulti = StarGate.CFG:Get("naq_gen_mk1", "multiplier", 20)
        self:CreateWireInputs("ON/OFF", "Disable Use")
        self:CreateWireOutputs("Active", "Naquadah", "Naquadah %", "Energy")
        self.EntHealth = 100
        self.MaxHealth = self.EntHealth
        self:SetWire("Health", self.EntHealth)
        self:Off()
        self.On = false
        local phys = self.Entity:GetPhysicsObject()

        if (phys:IsValid()) then
            phys:Wake()
            phys:SetMass(10)
        end

        self.Entity:SetUseType(SIMPLE_USE)
    end

    --############### Makes it spawn
    function ENT:SpawnFunction(pl, tr)
        if (not tr.HitWorld) then return end
        local e = ents.Create("naquadah_generator")
        e:SetPos(tr.HitPos + Vector(0, 0, 50))
        e:SetUseType(SIMPLE_USE)
        e:Spawn()

        return e
    end

    --################# Think
    function ENT:Think()
        if (self.depleted or not self.HasResourceDistribution) then return end

        --if not self.On then return end;
        if self.On then
            if (self.Energy > 0 and self:GetResource("energy") < self:GetNetworkCapacity("energy")) then
                local rnd = math.Round(self.Generate * math.Rand(0.95, 1.05)) -- just for better visual consume

                if (self:GetResource("energy") + rnd * self.GenMulti > self:GetNetworkCapacity("energy")) then
                    local en = self:GetNetworkCapacity("energy") - self:GetResource("energy")
                    self:SupplyResource("energy", en)
                    rnd = math.Round(en / self.GenMulti)
                else
                    self:SupplyResource("energy", rnd * self.GenMulti)
                end

                if (self.Energy - rnd < 0) then
                    self.Energy = 0
                else
                    self.Energy = self.Energy - rnd
                end
            end

            local Naquadah = self.Energy

            -- No Naquadah available anymore - We are dead!
            if (Naquadah <= 0) then
                self.Entity:SetMaterial("materials/models/reactor-skin-off")
                self.depleted = true
                self.enabled = false
                --self:SetOverlayText("Naquadah Generator\nDepleted"); -- Why not work anymore?!
                self:Off()
            end

            if (self.depleted) then
                --if (self.HasRD) then StarGate.WireRD.OnRemove(self,true) end;
                self:AddResource("energy", 0)
                self:SetWire("Active", -1)
                self:SetWire("Naquadah", 0)
                self:SetWire("Naquadah %", 0)
                self:SetWire("Energy", 0)
                self.Energy = 0
                self:Off()
            else
                local percent = (self.Energy / self.MaxEnergy) * 100
                self:SetWire("Naquadah", math.floor(Naquadah))
                self:SetWire("Naquadah %", percent)
                self:SetWire("Energy", self:GetResource("energy"))
            end
        elseif (not self.depleted) then
            self:SetWire("Energy", self:GetResource("energy"))
        end

        --local my_capacity = self:GetUnitCapacity("energy");
        --local nw_capacity = self:GetNetworkCapacity("energy");
        --if(my_capacity ~= nw_capacity)then
        if (StarGate.WireRD.Connected(self.Entity)) then
            self.Connected = true
        else
            self.Connected = false
        end

        self.Flow = 0
        percent = (self.Energy / self.MaxEnergy) * 100
        self:Output(percent, self.Energy)
        self.Entity:NextThink(CurTime() + 1)

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

        self:SetWire("Active", self.enabled)
        self.Entity:SetNWString("add", add)
        self.Entity:SetNWString("perc", perc)
        self.Entity:SetNWString("eng", math.floor(eng))
    end

    function ENT:Off()
        self.CloseAnim = self:LookupSequence("open") -- For some reason the anims are the wrong way round
        self.On = false
        self.enabled = false
        self:SetSequence(self.CloseAnim)
    end

    function ENT:SetOn()
        self.OpenSeq = self:LookupSequence("close")
        self.On = true
        self.enabled = true
        self:ResetSequence(self.OpenSeq)
    end

    function ENT:OnTakeDamage(dmg, attacker)
        self.EntHealth = self.EntHealth - dmg:GetDamage()
        self:SetWire("Health", self.EntHealth)

        if (self.EntHealth < 1) then
            self:Boom()
        end
    end

    function ENT:HealthRepair(health)
        self.EntHealth = health
        self:SetWire("Health", health)
    end

    function ENT:Boom()
        local fx = EffectData()
        fx:SetOrigin(self:GetPos())
        util.Effect("Explosion", fx)
        self:Remove()
        StarGate.WireRD.OnRemove(self)
    end

    function ENT:TriggerInput(k, v)
        if (self.depleted) then return end

        if (k == "ON/OFF") then
            if ((v or 0) >= 1) then
                if (self.enabled) then
                    self:Off()
                else
                    self:SetOn()
                end
            end
        end
    end

    function ENT:Use(p)
        if (self:GetWire("Disable Use") > 0) then return end
        if (self.depleted) then return end

        if (self.enabled) then
            self:Off()
        else
            self:SetOn()
        end
    end

    function ENT:PostEntityPaste(ply, Ent, CreatedEntities)
        if (StarGate.NotSpawnable("naq_gen_mks", ply, "tool")) then
            self.Entity:Remove()

            return
        end

        if (IsValid(ply)) then
            if (ply:GetCount("naq_gen_mks") + 1 > GetConVar("sbox_maxnaq_gen_mks"):GetInt()) then
                ply:SendLua("GAMEMODE:AddNotify(\"Naquadah generator limit reached!\", NOTIFY_ERROR, 5); surface.PlaySound( \"buttons/button2.wav\" )")
                self.Entity:Remove()

                return
            end

            ply:AddCount("naq_gen_mks", self.Entity)
        end

        StarGate.WireRD.PostEntityPaste(self, ply, Ent, CreatedEntities)
    end

    if (StarGate and StarGate.CAP_GmodDuplicator) then
        duplicator.RegisterEntityClass("naquadah_generator", StarGate.CAP_GmodDuplicator, "Data")
    end
end

if CLIENT then
    ENT.Zpm_hud = surface.GetTextureID("VGUI/resources_hud/mk1")

    function ENT:Initialize()
        self.Entity:SetNWString("add", "Disconnected")
        self.Entity:SetNWString("perc", 0)
        self.Entity:SetNWString("eng", 0)
    end

    function ENT:Draw()
        self.Entity:DrawModel()
        hook.Remove("HUDPaint", tostring(self.Entity) .. "MK1")
        if (not StarGate.VisualsMisc("cl_draw_huds", true)) then return end

        if (LocalPlayer():GetEyeTrace().Entity == self.Entity and EyePos():Distance(self.Entity:GetPos()) < 1024) then
            hook.Add("HUDPaint", tostring(self.Entity) .. "MK1", function()
                local w = 0
                local h = 260
                surface.SetTexture(self.Zpm_hud)
                surface.SetDrawColor(Color(255, 255, 255, 255))
                surface.DrawTexturedRect(ScrW() / 2 + 6 + w, ScrH() / 2 - 50 - h, 180, 360)
                surface.SetFont("center2")
                surface.SetFont("header")
                draw.DrawText("NGEN MK1", "header", ScrW() / 2 + 54 + w, ScrH() / 2 + 41 - h, Color(0, 255, 255, 255), 0)
                draw.DrawText("Status", "center2", ScrW() / 2 + 40 + w, ScrH() / 2 + 65 - h, Color(209, 238, 238, 255), 0)
                draw.DrawText("Naquadah", "center2", ScrW() / 2 + 40 + w, ScrH() / 2 + 115 - h, Color(209, 238, 238, 255), 0)
                draw.DrawText("Capacity", "center2", ScrW() / 2 + 40 + w, ScrH() / 2 + 165 - h, Color(209, 238, 238, 255), 0)

                if (IsValid(self.Entity)) then
                    add = self.Entity:GetNetworkedString("add")
                    perc = self.Entity:GetNWString("perc")
                    eng = self.Entity:GetNWString("eng")
                else
                    add = ""
                    perc = 0
                    eng = ""
                end

                surface.SetFont("center")
                local color = Color(0, 255, 0, 255)

                if (add == "Disconnected" or add == "Depleted") then
                    color = Color(255, 0, 0, 255)
                end

                if (tonumber(perc) > 0) then
                    perc = string.format("%4.2f", perc)
                end

                draw.SimpleText(add, "center", ScrW() / 2 + 40 + w, ScrH() / 2 + 85 - h, color, 0)
                draw.SimpleText(tostring(eng), "center", ScrW() / 2 + 40 + w, ScrH() / 2 + 135 - h, Color(255, 255, 255, 255), 0)
                draw.SimpleText(tostring(perc) .. "%", "center", ScrW() / 2 + 40 + w, ScrH() / 2 + 185 - h, Color(255, 255, 255, 255), 0)
            end)
        end
    end

    function ENT:OnRemove()
        hook.Remove("HUDPaint", tostring(self.Entity) .. "MK1")
    end
end