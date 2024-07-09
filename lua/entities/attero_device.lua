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
ENT.PrintName = "Attero Device"


ENT.Category = "Stargate Carter Addon Pack: Weapons"
if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
ENT.Category = SGLanguage.GetMessage("entity_weapon_cat");
end
list.Set("CAP.Entity", ENT.PrintName, ENT)


ENT.WireDebugName = "Attero Device"


if SERVER then
    --################# HEADER #################
    if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("energy")) then return end
    AddCSLuaFile()

    --################# SENT CODE ###############
    --################# Init
    function ENT:Initialize()

        self.Debug = false

        if (not util.IsValidModel("models/atero/atero.mdl")) then
            self.Entity:SetModel("models/MarkJaw/naquadah_generator.mdl")
        else
            self.Entity:SetModel("models/atero/atero.mdl")
        end
        self.Entity:PhysicsInit(SOLID_VPHYSICS)
        self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
        self.Entity:SetSolid(SOLID_VPHYSICS)
        if self.Debug then
            self:CreateWireInputs("Activate","Dest [VECTOR]","ATA Mode")
            self.Mobilegate = nil
            self.Mobilegate2 = nil
            self.EntitiesOnRoute = 0
        else
            self:CreateWireInputs("Activate","ATA Mode")
        end
        self:CreateWireOutputs("Active")
        self.EntHealth = 100
        self.MaxHealth = self.EntHealth
        self.On = false
        self.ZapTime = 0
        self.Gates = nil
        self.SearchTime = 0
        self.Target = nil
        self.DestinationVector = nil
        self.Outbound = true
        self.ReadyToOverload = true
        
        --self:IsBlocked(true)
        local phys = self.Entity:GetPhysicsObject()

        if (phys:IsValid()) then
            phys:Wake()
            phys:SetMass(8000)
        end

        self.Entity:SetUseType(SIMPLE_USE)

    end

    --############### Makes it spawn
    function ENT:SpawnFunction(pl, tr)
        local PropLimit = GetConVar("CAP_attero_device_max"):GetInt()

        if (not tr.Hit) then return end
        if (not util.IsValidModel("models/atero/atero.mdl")) then
            pl:EmitSound( "buttons/button8.wav" )
            pl:SendLua( "GAMEMODE:AddNotify('Providing replacement model', NOTIFY_HINT, 9);" )
            pl:SendLua( "GAMEMODE:AddNotify('Have you subscribed to: (usg_stargate_jaanus) ?', NOTIFY_ERROR, 9);" )
            pl:SendLua( "GAMEMODE:AddNotify('Error: Client/server missing model: (atero.mdl)', NOTIFY_ERROR, 9);" )
        end

        if (pl:GetCount("CAP_attero_device") + 1 > PropLimit) then
            pl:SendLua("GAMEMODE:AddNotify(\"Attero Device limit reached!\", NOTIFY_ERROR, 5); surface.PlaySound( \"buttons/button2.wav\" )")

            return
        end
        

        local e = ents.Create("attero_device")
        e:SetPos(tr.HitPos + Vector(0, 0, 60))
        e:SetUseType(SIMPLE_USE)
        e:Spawn()
        e:SetAngles(Angle(0, pl:GetAimVector():Angle().Yaw-90, 0))
        pl:AddCount("CAP_attero_device", e)

        return e
    end

    --################# Think
    function ENT:Think()
        if (self.On) then
                if (CurTime() > self.SearchTime )then
                    --local e = ents.FindInSphere(self:GetPos(), 40000)
                    for _, v in pairs(ents.FindByClass( "stargate_*" )) do
                            --print(tostring(v)..":"..v:GetClass()..":"..tostring(v.IsOpen))
                            if (v.IsOpen) then
                                if v:GetNWBool("MW_Overloading", false) == false then
                                    v:SetNWBool("MW_Overloading", true)
                                end
                                if (StarGate.IsStargateOutbound(v)) then
                                    StarGate.JamRemoteGate(v,true)
                                end
                                self:HeatGate(v)
                            end
                    end
                    self.SearchTime = CurTime() + 3
                end
                if (CurTime() > self.ZapTime )then
                    local startpos = self:GetPos() + Vector(0, 0, 30)
                    local endpos = self:GetPos()+ Vector(math.random(-75,75), math.random(-75,75), 80)
                    local SparkFX = EffectData()
                    local zapfx = EffectData()
                    zapfx:SetOrigin(startpos)
                    zapfx:SetStart(endpos)
                    util.Effect("icarus_zap", zapfx)
                    SparkFX:SetOrigin(startpos)
                    SparkFX:SetMagnitude(1)
                    SparkFX:SetScale(1)
                    SparkFX:SetRadius(100)
                    util.Effect("Sparks",SparkFX)
                    self.ZapTime = CurTime() + math.random(0,0.8)
                end
        end
        self.Entity:NextThink(CurTime() + 0.3)
        return true
    end

    function ENT:Output()

    end

    function ENT:SetOn()
        self.On = true
        self.ReadyToOverload = true
        self:SetNWBool("On",true)
        self:EmitSound("ambient/atmosphere/underground_hall_loop1.wav",70,60)
        self:EmitSound("janus/janus_wall_tone_1.wav",70,90)
        self:SetWire("Active", 1)
        for _, v in pairs(ents.FindByClass( "stargate_*" )) do
            if (v.IsOpen and (StarGate.IsStargateOutbound(v))) then 
                StarGate.JamRemoteGate(v)
            end
        end

        if(self.Debug) then
            ---Destination Gate---
            local Gate2Pos = nil

            if (self.DestinationVector == nil) then
                Gate2Pos = self.Entity:GetPos()+self.Entity:GetUp()*200 + self.Entity:GetRight()*-400
            else
                Gate2Pos = self.DestinationVector + Vector(0,0,50)
            end
            local Gate2Angle = self.Entity:GetAngles() + Angle(0, 90, 0)
            local mg2 = ents.Create("mobile_gate")
            mg2:SetPos(Gate2Pos)
            mg2:SetAngles(Gate2Angle)
            mg2:Activate()
            self.Mobilegate2 = mg2
            local e2 = ents.Create("event_horizon")
            e2:SetPos(Gate2Pos)
            e2:SetAngles(Gate2Angle)
            e2:SetParent(self.Mobilegate2);
            if(self.Sounds and self.Sounds.Open) then
                e.Sounds.Open = self.Sounds.Open;
            end
            e2:Spawn();
            e2:Activate();
            e2:SetParent(self.Mobilegate2)
            if(IsValid(self.EventHorizon2)) then self.EventHorizon2:Remove() end
            self.EventHorizon2 = e2;
            self.Target = self.EventHorizon2

            ---Origin Gate---

            local Gate1Pos = self.Entity:GetPos()+self.Entity:GetUp()*200
            local Gate1Angle = self.Entity:GetAngles() - Angle(0, 90, 0)
            local mg = ents.Create("mobile_gate")
            mg:SetPos(Gate1Pos)
            mg:SetAngles(Gate1Angle)
            mg:Activate()
            self.Mobilegate = mg
            local e = ents.Create("event_horizon");
            e:SetPos(Gate1Pos);
            e:SetAngles(Gate1Angle);
            e:SetParent(self.Mobilegate)
            if(self.Sounds and self.Sounds.Open) then
                e.Sounds.Open = self.Sounds.Open;
            end
            e:Spawn();
            e:Activate();
            e:SetTarget(self.Target)
            if(IsValid(self.EventHorizon)) then self.EventHorizon:Remove() end
            self.EventHorizon = e;
            self.EventHorizon.Target = self.EventHorizon2
            self.EventHorizon2.Target = self.EventHorizon
        end
    end

    function ENT:TriggerInput(k, v)
        if(k == "Activate") then
            if(v > 0) then
                if(self.On == true) then
                    return
                else
                    self:SetOn()
                end
            else
                if(self.On == true) then
                    self:Off()
                end
            end
        elseif(k == "Dest") then
            self.DestinationVector = v
        elseif(k == "ATA Mode") then
            if(v > 0) then
                self.ATAMode = true
            else
                self.ATAMode = false
            end
        end
    end

    function ENT:HealthRepair(health)
        self.EntHealth = health
    end

    function ENT:Off()
        self.On = false
        self:StopSound("ambient/atmosphere/underground_hall_loop1.wav")
        self:StopSound("apc_engine_start")
        self:EmitSound("janus/janus_wall_tone_1.wav",70,60)
        self:SetNWBool("On",false)
        self:SetWire("Active", 0)

        if(self.Debug) then
            self.EventHorizon:Shutdown(true)
            self.EventHorizon2:Shutdown(true)
        end
        for _, v in pairs(ents.FindByClass( "stargate_*" )) do
            if (v.IsOpen) then
                if v:GetNWBool("MW_Overloading",false) == true then
                    v:SetNWBool("MW_Overloading",false)
                    StarGate.UnJamGate(v)
                end
            end
        end
    end
    function ENT:HeatGate(gate)
        if (gate == nil) then
            return false
        elseif (gate:IsValid() == false) then
            return false
        elseif (gate.isOverloading == true) then
            return true
        end


        if (gate.excessPowerLimit == nil) then
            gate.excessPowerLimit = 580000
            end
            if (gate.excessPower == nil) then
            gate.excessPower = 0
            end

            gate.excessPower = gate.excessPower + 26000

            if (gate.excessPower and gate.excessPowerLimit and gate.excessPower >= gate.excessPowerLimit) then
                gate.isOverloading = true
                StarGate.DrawGateHeatEffects(gate)
                           
                    timer.Simple(5, function()
                        if IsValid(gate) then
                            StarGate.UnJamGate(gate)
                            StarGate.DestroyStargate(gate)
                        end
                    end)
            end
        return true
    end


    function ENT:OnTakeDamage(dmg, attacker)
        self.EntHealth = self.EntHealth - dmg:GetDamage()
        damage = dmg:GetDamage()

        if (self.EntHealth < 1) then
            self:Boom()
        end
        local startpos = self:GetPos() + Vector(0, 0, 30)
        local endpos = self:GetPos()+ Vector(math.random(-35,35), math.random(-35,35), 30)
        local SparkFX = EffectData()
        local zapfx = EffectData()
        
        zapfx:SetOrigin(startpos)
        zapfx:SetStart(endpos)
        util.Effect("icarus_zap", zapfx)

        SparkFX:SetOrigin(startpos)
        SparkFX:SetMagnitude(1)
        SparkFX:SetScale(1)
        SparkFX:SetRadius(100)
        util.Effect("Sparks",SparkFX)
        if self.Debug and self.On then
            if (damage<=5) then
                self.EventHorizon:Flicker(6)
                self.EventHorizon2:Flicker(6)
            elseif (damage>10 and damage<=20) then
                self.EventHorizon:Flicker(3)
                self.EventHorizon2:Flicker(3)
            elseif (damage>20) then
                self.EventHorizon:Flicker(5)
                self.EventHorizon2:Flicker(5)
            end
        end
    end

    function ENT:Boom()
        if(self.Debug) and (self.On) then
            self.EventHorizon:Shutdown(true)
            self.EventHorizon2:Shutdown(true)
        end
        self:StopSound("apc_engine_start")
        local fx = EffectData()
        fx:SetOrigin(self:GetPos())
        util.Effect("Explosion", fx)
        self:Remove()
        StarGate.WireRD.OnRemove(self)
    end

    function ENT:Use(p)
        if(self.ATAMode == true and p:GetNWInt("ATAGene",0) == 0) then return end

        if (self.On) then
            self:Off()
        else
            self:SetOn()
        end
    end

    function ENT:OnRemove()
        for _, v in pairs(ents.FindByClass( "stargate_*" )) do
            if (v.IsOpen) then
                if v:GetNWBool("MW_Overloading",false) == true then
                    v:SetNWBool("MW_Overloading",false)
                    StarGate.UnJamGate(v)
                end
            end
        end
        if(self.Debug) then
            self.EventHorizon:Shutdown(true)
            self.EventHorizon2:Shutdown(true)
        end
        self:StopSound("apc_engine_start")
    end

    function ENT:PostEntityPaste(ply, Ent, CreatedEntities)
        if (StarGate.NotSpawnable("naq_gen_mks", ply, "tool")) then
            self.Entity:Remove()

            return
        end

        StarGate.WireRD.PostEntityPaste(self, ply, Ent, CreatedEntities)

        if (IsValid(ply)) then
            local PropLimit = GetConVar("CAP_attero_device_max"):GetInt()

            if (ply:GetCount("CAP_attero_device") + 1 > PropLimit) then
                ply:SendLua("GAMEMODE:AddNotify(\"Attero Device limit reached!\", NOTIFY_ERROR, 5); surface.PlaySound( \"buttons/button2.wav\" )")
                self.Entity:Remove()

                return
            end
        end

        if (IsValid(ply)) then
            ply:AddCount("CAP_attero_device", self.Entity)
        end
    end

    if (StarGate and StarGate.CAP_GmodDuplicator) then
        duplicator.RegisterEntityClass("attero_device", StarGate.CAP_GmodDuplicator, "Data")
    end


    function ENT:IsBlocked(only_by_iris,no_open,only_block)
        return false
    end
end

if CLIENT then

    function ENT:Draw()
        local Online = self:GetNWBool("On")
        self:DrawModel()

        if (Online) then
            self:DynLight(true)
        elseif ((not (Online))) then
            self:DynLight(false)
        end
    end

    function ENT:DynLight()

        local pos = self:GetPos() + self:GetUp() * 80
        local Online = self:GetNWBool("On")

        if (IsValid(self)) then
            if (Online) then
                if (StarGate.VisualsMisc("cl_chair_dynlights")) then
                    local dynlight = DynamicLight(self:EntIndex() + 4096)
                    dynlight.Pos = pos
                    dynlight.Brightness = 8
                    dynlight.Size = 184
                    dynlight.Decay = 1024
                    dynlight.R = 25
                    dynlight.G = 255
                    dynlight.B = 255
                    dynlight.DieTime = CurTime() + 1
                end
            end
        end
    end

    function ENT:OnRemove()
        self.Entity:StopSound("ambient/atmosphere/underground_hall_loop1.wav")
    end

end
