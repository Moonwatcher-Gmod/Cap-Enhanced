--[[
	ZPM Hub for GarrysMod10
	Copyright (C) 2010  Llapp, cooldudetb
]]
if (StarGate ~= nil and StarGate.LifeSupportAndWire ~= nil) then
    StarGate.LifeSupportAndWire(ENT)
end

ENT.Type = "anim"
ENT.Base = "base_anim" --gmodentity
ENT.PrintName = "ZPM Hub Mk2"
ENT.Author = "Llapp, cooldudetb, Rafael De Jongh"
ENT.Category = "Stargate Carter Addon Pack"
ENT.WireDebugName = "ZPM Hub Mk2"
ENT.Spawnable = false
ENT.AdminSpawnable = false

if (Environments) then
    ENT.IsNode = false
else
    ENT.IsNode = true
end

ENT.ZPMHub = true

if SERVER then
    if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("energy")) then return end
    AddCSLuaFile()

    ENT.Sounds = {
        PowerUp = Sound("zpmhub/zpm_power_up.wav"),
        PowerDown = Sound("zpmhub/zpm_power_down.wav"),
        SlideIn = Sound("zpmhub/zpm_hub_slide_in.wav"),
        SlideOut = Sound("zpmhub/zpm_hub_slide_out.wav"),
        Idle = Sound("zpmhub/zpm_hub_idle.wav")
    }

    function ENT:Initialize()
        self.Entity:SetModel("models/pg_props/pg_zpm/pg_zpm_hub.mdl")
        self.Entity:PhysicsInit(SOLID_VPHYSICS)
        self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
        self.Entity:SetSolid(SOLID_VPHYSICS)
        self.Entity:SetUseType(SIMPLE_USE)
        local phys = self.Entity:GetPhysicsObject()

        if (phys:IsValid()) then
            phys:EnableMotion(false)
            phys:SetMass(1000)
        end

        self:CreateWireInputs("Deactivate ZPM 1", "Deactivate ZPM 2", "Deactivate ZPM 3", "Eject ZPM 1", "Eject ZPM 2", "Eject ZPM 3", "Unhide ZPM Text", "Disable Use", "Disable Sound", "Disable Failsafe")
        self:CreateWireOutputs("Active", "ZPM Hub %", "ZPM Hub Energy", "ZPM 1 %", "ZPM 2 %", "ZPM 3 %", "Flowrate", "Current Overload", "Max transfer rate")
        self.CanEject = true
        self.C = true
        self.HaveRD3 = false
        self.delay = 1.5
        self.lastOccurance = -self.delay
        self.lastUseTime = CurTime()
        self.Last_energy = 0
        self.Current_energy = 0
        self.rateOfChange = 0
        self.Overload = 0
        self.Selfdestruct = false
        self.MaxTransferRate = 150000
        self.CurrentOverload = 1
        self.OverloadFactor = 4
        self.ZapTime = 0
        self.SoundPitch = 35
        self.Overload_disabled = false
        self.CheckOverloadConfig = 0
        self.IsOverloadOn = true
        self.Failsafe = true
        self:SetNWBool("HubAdvButtons", StarGate.CFG:Get("cap_enhanced_cfg", "hub_advbuttons", false))
        self.ZPM1_Current_energy = 0
        self.ZPM2_Current_energy = 0
        self.ZPM3_Current_energy = 0
        self.ComboBuf =  {}
        self.ComboLast =  0
        
        self.ZPM1_lastenergy = 0
        self.ZPM2_lastenergy = 0
        self.ZPM3_lastenergy = 0

        self.ZPM_energyDiff = 0

        if (CAF and CAF.GetAddon("Resource Distribution")) then
            self.HaveRD3 = true
        end

        -- Make us a node!
        if self.HaveRD3 then
            self.netid = CAF.GetAddon("Resource Distribution").CreateNetwork(self)
            self:SetNWInt("netid", self.netid)
            self.range = 2048
            self:SetNWInt("range", self.range)
            self.RDEnt = CAF.GetAddon("Resource Distribution")
        elseif (RES_DISTRIB == 2) then
            self:AddResource("energy", 1)
        end

        self.ZPMs = {
            {
                On = false,
                Ent = nil,
                IsValid = false,
                Dir = 1,
                Dist = 1,
                Eject = 0,
                Type = "ZPH",
                SoundIn = 0,
                SoundOut = 0
            },
            {
                On = false,
                Ent = nil,
                IsValid = false,
                Dir = 1,
                Dist = 1,
                Eject = 0,
                Type = "ZPH",
                SoundIn = 0,
                SoundOut = 0
            },
            {
                On = false,
                Ent = nil,
                IsValid = false,
                Dir = 1,
                Dist = 1,
                Eject = 0,
                Type = "ZPH",
                SoundIn = 0,
                SoundOut = 0
            }
        }

        local mul = 0.93

        self.Positions = {
            {
                R = 0,
                F = -13 * mul
            },
            {
                R = -11.2 * mul,
                F = 6.5 * mul
            },
            {
                R = 11.2 * mul,
                F = 6.5 * mul
            }
        }

        self.Active = false
        self.IdleSound = self.IdleSound or CreateSound(self.Entity, self.Sounds.Idle)
        self.IdleS = false
        self:Skins()
        self.ZPMMaxEnergy = StarGate.CFG:Get("zpm_mk3", "capacity", 88000000)
    end

    function ENT:SpawnFunction(p, t)
        if (not t.Hit) then return end
        local ang = p:GetAimVector():Angle()
        ang.p = 0
        ang.r = 0
        ang.y = (ang.y + 90) % 360
        local pos = t.HitPos + Vector(0, 0, -10)
        local e = ents.Create("zpmhub")
        e:SetPos(pos)
        e:SetAngles(ang)
        e:DrawShadow(true)
        e:SetVar("Owner", p)
        e:Spawn()
        e:Activate()

        return e
    end

    function ENT:OnTakeDamage()
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
    end





    function ENT:UseZPM(num)
        if (self.ZPMs[num].Dist == 1) then
            self.ZPMs[num].Eject = self.ZPMs[num].Eject + 1

            timer.Simple(0.1, function()
                if (IsValid(self.Entity) and self.ZPMs[num].Eject >= 1) then
                    self.ZPMs[num].Eject = self.ZPMs[num].Eject - 1
                end
            end)
        else
            self.ZPMs[num].Dir = 1
        end
    end

    function ENT:Touch(ent)
        local pos = self.Entity:GetPos()
        local ang = self.Entity:GetAngles()

        if (self.CanEject == true and ent.IsZPM and self.ZPMs and ent ~= self.ZPMs[1].Ent and ent ~= self.ZPMs[2].Ent and ent ~= self.ZPMs[3].Ent) then          
            for i, v in ipairs(self.ZPMs) do
                if (not v.IsValid and v.Eject == 0) then
                    v.Ent = ent
                    v.Dist = 1
                    v.Dir = 1
                    v.Type = "ZPH"
                    v.IsValid = true
                    ent:SetUseType(SIMPLE_USE)


                    if (ent.IsMk4 == true) then
                		if (ent.Energy == 0) then
                			ent:SetSkin(4)
                		else           
                    		ent:SetSkin(5)
                    		ent:EmitSound(self.Sounds.PowerUp, 90, 100)
                    	end
                    elseif(ent:GetClass()=="tampered_zpm") then
                        if (ent.Energy == 0) then
                            ent:SetSkin(2)
                        else           
                            ent:SetSkin(3)
                            ent:EmitSound(self.Sounds.PowerUp, 90, 100)
                        end
                    else
                    	if (ent.Energy == 0) then
                    		ent:SetSkin(2)
                    	else                  	
                    		ent:SetSkin(1)
                    		ent:EmitSound(self.Sounds.PowerUp, 90, 100)
                    	end
                	end
                    	
                    ent.Use = function()
                        local constr = constraint.FindConstraint(self, "Weld")
                        if(constr.Entity[1].Entity:GetWire("Disable Use") > 0) then return end

                        if (ent.IsMk4 == true) then
	                		if (ent.Energy == 0) then
	                			ent:SetSkin(4)
	                		else           
	                    		ent:SetSkin(4)
	                    		ent:EmitSound(self.Sounds.PowerDown, 90, 100)
	                    	end
                    	else
	                    	if (ent.Energy == 0) then
	                    		ent:SetSkin(2)
	                    	else                 	
	                    		ent:SetSkin(2)
	                    		ent:EmitSound(self.Sounds.PowerDown, 90, 100)
	                    	end
                		end

                        if (constr and IsValid(constr.Entity[1].Entity) and constr.Entity[1].Entity.UseZPM) then
                            constr.Entity[1].Entity:UseZPM(i)
                        end
                    end

                    constraint.RemoveAll(ent)
                    ent:SetPos(pos + self.Entity:GetRight() * (self.Positions[i].R) + self.Entity:GetUp() * (41 + 10) + self.Entity:GetForward() * (self.Positions[i].F) )
                    ent:SetAngles(ang)
                    constraint.Weld(self.Entity, ent, 0, 0, 0, true)
                    break
                end
            end
        end
    end

    function ENT:TriggerInput(variable, value)
        for i = 1, 3 do
            if (variable == "Deactivate ZPM " .. i) then
                self.ZPMs[i].Dir = value
            elseif (variable == "Eject ZPM " .. i) then
                self.ZPMs[i].Eject = value
            end
        end

        if (variable == "Unhide ZPM Text" and value >= 1) then
            self.Entity:SetNWBool("DrawText", true)
        elseif (variable == "Disable Failsafe") and not self.Selfdestruct then
            if value >= 1 then self.Failsafe = false else self.Failsafe = true end
        elseif (variable == "Unhide ZPM Text" and value <= 0) then
            self.Entity:SetNWBool("DrawText", false)
        elseif (variable == "Disable Sound") then
            if (value > 0) then
                self.IdleSound:Stop()
            else
                if (self.Active) then
                    self.IdleSound:ChangePitch(45, 0)
                    self.IdleSound:SetSoundLevel(80)
                    self.IdleSound:PlayEx(1, self.SoundPitch)
                end
            end
        end
    end

    function ENT:Skins()
        if (self.Active) then
            self.Entity:SetSkin(2)
            if (self.C == true) then
                self.Entity:EmitSound(self.Sounds.PowerUp, 90, 100)
                self.C = false
            end
        else
            self.Entity:SetSkin(1)
            self.C = true
        end
    end


    function ENT:DisableOverload()
        if (self.Overload_disabled == false) then
            self.Overload_disabled = true
            
            timer.Simple( 2.3, function()
                self.Overload_disabled = false
            end )
        end
    end

    function ENT:Think()
        --player.GetAll()[1]:ChatPrint(tostring(self.Overload_disabled))
        if (self._NextCfgSync or 0) < CurTime() then
            self._NextCfgSync = CurTime() + 10
            self:SetNWBool("HubAdvButtons", StarGate.CFG:Get("cap_enhanced_cfg", "hub_advbuttons", false))
        end
        if self.HaveRD3 then
            local nettable = CAF.GetAddon("Resource Distribution").GetNetTable(self.netid)

            if table.Count(nettable) > 0 then
                local entities = nettable.entities

                if table.Count(entities) > 0 then
                    for k, ent in pairs(entities) do
                        if ent and IsValid(ent) then
                            local pos = ent:GetPos()

                            if pos:Distance(self:GetPos()) > self.range then
                                self:HubUnlink(ent)
                                self:EmitSound("physics/metal/metal_computer_impact_bullet" .. math.random(1, 3) .. ".wav", 500)
                                ent:EmitSound("physics/metal/metal_computer_impact_bullet" .. math.random(1, 3) .. ".wav", 500)
                            end
                        end
                    end
                end

                local cons = nettable.cons

                if table.Count(cons) > 0 then
                    for k, v in pairs(cons) do
                        local tab = CAF.GetAddon("Resource Distribution").GetNetTable(v)

                        if tab and table.Count(tab) > 0 then
                            local ent = tab.nodeent

                            if ent and IsValid(ent) then
                                local pos = ent:GetPos()
                                local range = pos:Distance(self:GetPos())

                                if range > self.range and range > ent.range then
                                    CAF.GetAddon("Resource Distribution").UnlinkNodes(self.netid, ent.netid)
                                    self:EmitSound("physics/metal/metal_computer_impact_bullet" .. math.random(1, 3) .. ".wav", 500)
                                    ent:EmitSound("physics/metal/metal_computer_impact_bullet" .. math.random(1, 3) .. ".wav", 500)
                                end
                            end
                        end
                    end
                end
            end
        end

        local zpm = {
            {
                En = 0,
                Per = 0,
                Max = 0,
                On = false
            },
            {
                En = 0,
                Per = 0,
                Max = 0,
                On = false
            },
            {
                En = 0,
                Per = 0,
                Max = 0,
                On = false
            }
        }

        self.Active = false
        local ZPH = 0
        local percent = 0

        for i, v in ipairs(self.ZPMs) do
            v.IsValid = (v.Ent and v.Ent:IsValid())

            if (v.IsValid) then
                v.On = ((v.Ent.Connected and not v.Ent.Empty) or v.Ent.enabled == true)

                if v.On then
                    if (v.Type == "ZPH") then
                        zpm[i].En = v.Ent.Energy
                        zpm[i].Max = v.Ent.MaxEnergy
                    else
                        zpm[i].En = v.Ent:GetResource(v.Type)
                        zpm[i].Max = v.Ent.MaxEnergy
                    end

                    zpm[i].Per = (zpm[i].En / zpm[i].Max) * 100

                    if (zpm[i].Per <= 0) then
                        zpm[i].Per = 0
                    end

                    ZPH = ZPH + zpm[i].En
                    percent = percent + zpm[i].Max
                else
                    percent = percent + self.ZPMMaxEnergy
                end

                zpm[i].On = (not util.tobool(v.Dist)) and (v.Ent.Connected or v.Ent.empty)
                local constr = constraint.FindConstraint(v.Ent, "Weld")

                if (v.Dist == 1 and (v.Eject == 1 or not constr or constr.Entity[1].Entity ~= self.Entity)) then
                

                	if (v.Ent.IsMk4 == true) then
                		if (v.Ent.Energy == 0) then
                			v.Ent:SetSkin(4)
                		else           
                    		v.Ent:SetSkin(4)
                    		v.Ent:EmitSound(self.Sounds.PowerDown, 90, 100)
                    	end
                	elseif(v.Ent:GetClass()=="tampered_zpm") then
                        if (v.Ent.Energy == 0) then
                            v.Ent:SetSkin(2)
                        else           
                            v.Ent:SetSkin(2)
                            v.Ent:EmitSound(self.Sounds.PowerDown, 90, 100)
                        end
                    else
                    	if (v.Ent.Energy == 0) then
                    		v.Ent:SetSkin(2)
                    	else                 	
                    		v.Ent:SetSkin(2)
                    		v.Ent:EmitSound(self.Sounds.PowerDown, 90, 100)
                    	end
            		end
                    self:EjectZPM(i)

                elseif (v.Dist == 0 and v.On) then
                    self.Active = true
                end
            else
                percent = percent + self.ZPMMaxEnergy
            end
        end

        self:ZPMsMovement()
        self:SoundIdle(self.Active)
        self:Skins()
        self:SoundSetup()
        self:SetWire("Active", self.Active)

        if percent > 0 then
            percent = (ZPH / percent) * 100
        else
            percent = 0
        end

        if (self:GetWire("Disable Sound", 0) < 1) then
            if (self.IdleS) then
                self.IdleSound:ChangePitch(self.SoundPitch, 0)
                self.IdleSound:SetSoundLevel(80)
                self.IdleSound:PlayEx(1, self.SoundPitch)
            else
                self.IdleSound:Stop()
            end
        end

        for i = 1, 3 do
            if self.ZPMs[i] and IsValid(self.ZPMs[i].Ent) and self.ZPMs[i].Dist == 0 then
                self:SetWire("ZPM " .. i .. " %", zpm[i].On and zpm[i].Per or -1)
            else
                self:SetWire("ZPM " .. i .. " %", -1)
            end
        end

        timer.Simple(0.1, function()
            if (IsValid(self.Entity)) then
                self.Entity:SetNWInt("Percents", percent)
            end
        end)

        if (self.Overload > 20) then
            
        end

        if (self.Overload >50) then

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


		    	--self.ZapTime = CurTime() + 0.1
		    	util.Effect("Sparks",SparkFX)
		    	self.ZapTime = CurTime() + math.random(0,0.1)
        	end
        		
        	--print (self.ZapTime - CurTime())
        end
        self.SoundPitch = 35 + (self.Overload*0.6)

        if (self.Overload > 99) then

            local bomb = ents.Create("gate_nuke")

            if (bomb ~= nil and bomb:IsValid()) then
                bomb:Setup(self.Entity:GetPos(), 30)
                bomb:SetVar("owner", self.Owner)
                bomb:Spawn()
                bomb:Activate()
            end

            for i, v in ipairs(self.ZPMs) do
                if (IsValid(v.Ent)) then
                    v.Ent:Remove()
                end

            end


            self.Entity:Remove()
        end

        self:Output(percent, ZPH, zpm[1].Per, zpm[2].Per, zpm[3].Per)
         -- Very important to prevent instant explosion


        if (CurTime() > self.CheckOverloadConfig) then
                self.IsOverloadOn = StarGate.CFG:Get("cap_enhanced_cfg", "allow_overload", false)
                self.CheckOverloadConfig = CurTime() + 10
        end



        local timeElapsed = CurTime() - self.lastOccurance

        if timeElapsed >= self.delay then
            self.ZPM1_Current_energy = zpm[1].On and zpm[1].En or self.ZPM1_Current_energy
            self.ZPM2_Current_energy = zpm[2].On and zpm[2].En or self.ZPM2_Current_energy
            self.ZPM3_Current_energy = zpm[3].On and zpm[3].En or self.ZPM3_Current_energy

            self.ZPM_energyDiff = (self.ZPM1_lastenergy - self.ZPM1_Current_energy) +
                                  (self.ZPM2_lastenergy - self.ZPM2_Current_energy) +
                                  (self.ZPM3_lastenergy - self.ZPM3_Current_energy)
            self.lastOccurance = CurTime()
            self.rateOfChange = math.Clamp(math.floor(self.ZPM_energyDiff), 0, 4984310)
        end

        self.ZPM1_lastenergy = self.ZPM1_Current_energy
        self.ZPM2_lastenergy = self.ZPM2_Current_energy
        self.ZPM3_lastenergy = self.ZPM3_Current_energy



        ----------------Failsafe and overload------------------- Current overload thredshold is 14 MW

        if (self.IsOverloadOn) then
            if (self.Active) then
                
                self.CurrentOverload = (math.abs(self.rateOfChange) - self.MaxTransferRate)/100000

                if (self.Selfdestruct) then
                    self.Overload = math.Clamp( self.Overload + 0.085,0,100)
                end
                
                self.Overload =  math.Clamp( self.Overload +  ((self.CurrentOverload * self.OverloadFactor)/100),0,100 )

                    if (self.Overload > 20 and self.Failsafe and not self.Selfdestruct) then
                        timer.Simple(1, function()
                            if (IsValid(self.Entity) and self.ZPMs) then
                                for i = 1, 3 do
                                    self.ZPMs[i].Dir = 1
                                end
                            end
                        end)
                    end
            else
                self.Overload = math.Clamp(self.Overload - 0.05, 0, 100)
            end
        else
            if (self.Overload > 0) and not self.Selfdestruct then
                self.Overload = math.Clamp(self.Overload - 0.05, 0, 100)
            end
        end
        ---------------------------------------------

        self:SetWire("Current Overload", self.Overload)
        self:SetWire("Active", self.Active)
        self:SetWire("ZPM Hub Energy", math.floor(ZPH))
        self:SetWire("ZPM Hub %", percent)
        
        self:SetWire("Flowrate", self.rateOfChange)
        self.Entity:NextThink(CurTime() + 0.01)
  
        return true
    end

    function ENT:Output(perc, eng, zpm1, zpm2, zpm3)
        -- local timeElapsed = CurTime() - self.lastOccurance

        -- if (timeElapsed < self.delay) then
        -- else
        --     self.Current_energy = eng
        --     self.lastOccurance = CurTime()
        --     self.rateOfChange = math.floor((self.Last_energy - self.Current_energy) / 10)
        -- end

        -- self.Last_energy = self.Current_energy
        local add = "Inactive"

        if (self.Active) then
            add = "Active"
        end

        self.Entity:SetNWString("add", add)
        self.Entity:SetNWString("perc", perc)
        --self.Entity:SetNWString("eng",math.floor(eng));
        self.Entity:SetNWString("flow", (self.rateOfChange))
        self.Entity:SetNWString("overload", math.floor(self.Overload))

        local zpmm = {zpm1, zpm2, zpm3}

        for i = 1, 3 do
            self.Entity:SetNWString("zpm" .. i, math.floor(zpmm[i]))
        end
    end

    function ENT:ZPMsMovement()
        local pos = self.Entity:GetPos()
        local ang = self.Entity:GetAngles()
        local spd = 0.015

        for i, v in ipairs(self.ZPMs) do
            if (v.IsValid and v.Dist ~= v.Dir) then
                if (v.Dist < 0) then
                    v.Dist = 0
                elseif (v.Dist > 1) then
                    v.Dist = 1
                end

                if (v.Dir < v.Dist) then
                    v.Dist = v.Dist - spd

                    v.Ent.IsConnectedToHub = true

                    if (v.SoundIn == 1) then
                        --self:DisableOverload()
                        self.Entity:EmitSound(self.Sounds.SlideIn, 50, 82)
                        v.SoundIn = 2
                    end

                    if (v.SoundOut == 2) then
                        v.SoundOut = 0
                    end
                elseif (v.Dir > v.Dist) then

                    v.Ent.IsConnectedToHub = false

                	if (v.Ent.IsMk4 == true) then
                		if (v.Ent.Energy == 0) then
                			v.Ent:SetSkin(4)
                		else           
                    		v.Ent:SetSkin(5)
                    	end
                    elseif(v.Ent:GetClass()=="tampered_zpm") then
                        if (v.Energy == 0) then
                            v.Ent:SetSkin(2)
                        else           
                            v.Ent:SetSkin(3)
                        end
                    else
                    	if (v.Ent.Energy == 0) then
                    		v.Ent:SetSkin(0)
                    	else                  	
                    		v.Ent:SetSkin(1)
                    	end
                	end

                    v.Dist = v.Dist + spd

                    if (v.SoundOut == 1) then
                        --self:DisableOverload()
                        self.Entity:EmitSound(self.Sounds.SlideOut, 50, 82)
                        v.SoundOut = 2
                    end

                    if (v.SoundIn == 2) then
                        v.SoundIn = 0
                    end
                end
                constraint.RemoveAll(v.Ent)
                v.Ent:SetAngles(self.Entity:GetAngles())
                v.Ent:SetPos(pos + self.Entity:GetRight() * (self.Positions[i].R) + self.Entity:GetUp() * (41 + 11.4 * v.Dist) + self.Entity:GetForward() * (self.Positions[i].F) - Vector(0, 0, 1.6))
                constraint.Weld(self.Entity, v.Ent, 0, 0, math.floor(v.Dist) * 5000, true)

                if (v.Dir == 0 and v.Dist == 0) then
                    self:HubLink(v.Ent)
                elseif (v.Dir == 1) then
                    self:HubUnlink(v.Ent)
                    if (i == 1) then
                        self.ZPM1_Current_energy = 0
                        self.ZPM1_lastenergy = 0
                    elseif (i == 2) then
                        self.ZPM2_Current_energy = 0
                        self.ZPM2_lastenergy = 0
                    elseif (i == 3) then
                        self.ZPM3_Current_energy = 0
                        self.ZPM3_lastenergy = 0
                    end
                end
            end
        end
    end

    function ENT:SoundSetup()
        for i, v in ipairs(self.ZPMs) do
            if (v.Dir == 0) then
                if (v.SoundIn == 0) then
                    v.SoundIn = 1
                end
            elseif (v.Dir == 1) then
                if (v.SoundOut == 0) then
                    v.SoundOut = 1
                end
            end
        end
    end

    function ENT:SoundIdle(idle)
        if (idle) then
            self.IdleS = true
        else
            self.IdleS = false
        end
    end

    function ENT:HubLink(ent)
        if self.HaveRD3 then
            CAF.GetAddon("Resource Distribution").Link(ent, self.netid)
        elseif Environments then
            ent:Link(self.node)

            if (self.node) then
                self.node:Link(ent)
            end
        elseif (RES_DISTRIB == 2) then
            Dev_Link(ent, self, nil, nil, nil, nil, nil)
        end
    end

    function ENT:HubUnlink(ent)
        if self.HaveRD3 and CAF then
            CAF.GetAddon("Resource Distribution").Unlink(ent)
        elseif Environments then
            ent:Unlink()
        elseif (RES_DISTRIB == 2 and Dev_Unlink_All) then
            Dev_Unlink_All(ent)
        end
    end


    function MWButtonCheck (pos,targetpos,margin)
        if math.abs(pos.x - targetpos.x) <= margin
        and math.abs(pos.y - targetpos.y) <= margin
        and math.abs(pos.z - targetpos.z) <= margin then
        return true else return false end
    end

    function rotateVector(vec, center, angle)
        local cosA = math.cos(angle)
        local sinA = math.sin(angle)

        local xTranslated = vec.x - center.x
        local yTranslated = vec.y - center.y

        local xRotated = xTranslated * cosA - yTranslated * sinA
        local yRotated = xTranslated * sinA + yTranslated * cosA

        return Vector(xRotated + center.x, yRotated + center.y, vec.z)
    end

    local function RotateAroundZ(p, center, deg)
        local a  = math.rad(deg)
        local ca = math.cos(a)
        local sa = math.sin(a)

        local x = p.x - center.x
        local y = p.y - center.y

        return Vector(
            x * ca - y * sa + center.x,
            x * sa + y * ca + center.y,
            p.z
        )
    end

    -- Derive the ring center from the known 3-way "AllToggle" points
    local RING_CENTER_XY = (Vector(-7.057692,  18.680084, 0)
                        + Vector(-13.034216, -15.619967, 0)
                        + Vector(19.961227,  -3.455073, 0)) / 3

    local function AnySideHit(relativePos, basePos, margin)
        if not basePos or not basePos.x then return false end
        margin = margin or 0.5

        local center = Vector(RING_CENTER_XY.x, RING_CENTER_XY.y, basePos.z)
        for _, deg in ipairs({0, 120, 240}) do
            local p = RotateAroundZ(basePos, center, deg)
            if MWButtonCheck(relativePos, p, margin) then
                return true
            end
        end
        return false
    end

    function ENT:Use(activator)
        if (self:GetWire("Disable Use") > 0) then return end

        if StarGate.CFG:Get("cap_enhanced_cfg", "hub_advbuttons", false) == false then 
            self:EmitSound("button/ancient_button1.wav",90,math.Rand(90,110))
                local val = false
                for i = 1, 3 do
                    if (self.ZPMs and (self.ZPMs[i].IsValid and self.ZPMs[i].Dist == 1)) then
                        val = true
                        break
                    end
                end

                if (val) then
                    timer.Simple(1, function()
                        if (IsValid(self.Entity) and self.ZPMs) then
                            for i = 1, 3 do
                                self.ZPMs[i].Dir = 0                                       
                            end
                        end
                    end)
                else
                    timer.Simple(1, function()
                        if (IsValid(self.Entity) and self.ZPMs) then
                            for i = 1, 3 do     
                                self.ZPMs[i].Dir = 1
                            end
                        end
                    end)
                end
            return
        end

        if activator:IsPlayer() then
            local aimPos = activator:GetEyeTrace().HitPos
            local relativePos = self.Entity:WorldToLocal(aimPos)

            local BTN = {
                AllToggle = { pos = Vector(-7.057692, 18.680084, 44.346169), margin = 0.5 },
                ZPM1      = { pos = Vector(-9.146106, 17.862841, 44.346172), margin = 0.5 },
                ZPM2      = { pos = Vector(-10.982636, 16.641993, 44.346161), margin = 0.5 },
                ZPM3      = { pos = Vector(-12.613367, 15.498039, 44.346161), margin = 0.5 },

                FailSafe  = { pos = Vector(-14.92, 18.65, 44.35),            margin = 0.5 },
            }
            local comboBtns = {
                [1] = Vector(-7.27,  22.77, 44.35),
                [2] = Vector(-9.49,  21.32, 44.35),
                [3] = Vector(-11.34, 20.29, 44.35),
            }
            local comboMargin = 0.5
            self.ComboBuf = self.ComboBuf or {}
            self.ComboLast = self.ComboLast or 0

            local COMBO_TIMEOUT = 12.0
            if (CurTime() - self.ComboLast) > COMBO_TIMEOUT then
                self.ComboBuf = {}
            end

            local pressedCombo = nil
            for idx = 1, 3 do
                if AnySideHit(relativePos, comboBtns[idx], comboMargin) then
                    pressedCombo = idx
                    break
                end
            end

            if pressedCombo then
                self.ComboLast = CurTime()
                table.insert(self.ComboBuf, pressedCombo)

                local count = #self.ComboBuf

                if count == 3 then
                    self:EmitSound("button/ancient_button1.wav", 90, math.Rand(110,130))

                    local a, b, c = self.ComboBuf[1], self.ComboBuf[2], self.ComboBuf[3]
                    self.ComboBuf = {}

                    if a == 1 and b == 3 and c == 2 then
                        self.Selfdestruct = not self.Selfdestruct
                    end
                else
                    self:EmitSound("button/ancient_button1.wav", 90, math.Rand(90,110))
                end

                return
            end

            if AnySideHit(relativePos, BTN.AllToggle.pos, BTN.AllToggle.margin) then
                if (self.Selfdestruct) then self:EmitSound("door/atlantis_door_fail.wav",60) return end
                self:EmitSound("button/ancient_button1.wav",90,math.Rand(90,110))
                local val = false
                for i = 1, 3 do
                    if (self.ZPMs and (self.ZPMs[i].IsValid and self.ZPMs[i].Dist == 1)) then
                        val = true
                        break
                    end
                end

                if (val) then
                    timer.Simple(1, function()
                        if (IsValid(self.Entity) and self.ZPMs) then
                            for i = 1, 3 do
                                self.ZPMs[i].Dir = 0                                       
                            end
                        end
                    end)
                else
                    timer.Simple(1, function()
                        if (IsValid(self.Entity) and self.ZPMs) then
                            for i = 1, 3 do     
                                self.ZPMs[i].Dir = 1
                            end
                        end
                    end)
                end

            end
            if AnySideHit(relativePos, BTN.ZPM2.pos, BTN.ZPM2.margin) then
                if (self.Selfdestruct) then self:EmitSound("door/atlantis_door_fail.wav",60) return end
                self:EmitSound("button/ancient_button1.wav",90,math.Rand(90,110))
                local val = false
                if ((self.ZPMs[2].IsValid and self.ZPMs[2].Dist == 1)) then val = true end
                if (val) then
                    timer.Simple(1, function()
                        if (IsValid(self.Entity) and self.ZPMs) then self.ZPMs[2].Dir = 0 end
                    end)
                else
                    timer.Simple(1, function()
                        if (IsValid(self.Entity) and self.ZPMs) then self.ZPMs[2].Dir = 1 end
                    end)
                end
            end
            
            if AnySideHit(relativePos, BTN.ZPM3.pos, BTN.ZPM3.margin) then

                if (self.Selfdestruct) then self:EmitSound("door/atlantis_door_fail.wav",60) return end
                self:EmitSound("button/ancient_button1.wav",90,math.Rand(90,110))
                local val = false
                if ((self.ZPMs[3].IsValid and self.ZPMs[3].Dist == 1)) then val = true end
                if (val) then
                    timer.Simple(1, function()
                        if (IsValid(self.Entity) and self.ZPMs) then self.ZPMs[3].Dir = 0 end
                    end)
                else
                    timer.Simple(1, function()
                        if (IsValid(self.Entity) and self.ZPMs) then self.ZPMs[3].Dir = 1 end
                    end)
                end
            end
            if AnySideHit(relativePos, BTN.ZPM1.pos, BTN.ZPM1.margin) then
                if (self.Selfdestruct) then self:EmitSound("door/atlantis_door_fail.wav",60) return end
                self:EmitSound("button/ancient_button1.wav",90,math.Rand(90,110))
                local val = false
                if ((self.ZPMs[1].IsValid and self.ZPMs[1].Dist == 1)) then val = true end
                if (val) then
                    timer.Simple(1, function()
                        if (IsValid(self.Entity) and self.ZPMs) then self.ZPMs[1].Dir = 0 end
                    end)
                else
                    timer.Simple(1, function()
                        if (IsValid(self.Entity) and self.ZPMs) then self.ZPMs[1].Dir = 1 end
                    end)
                end
            end
            if AnySideHit(relativePos, BTN.FailSafe.pos, BTN.FailSafe.margin) then
                if (self.Selfdestruct) then self:EmitSound("door/atlantis_door_fail.wav",60) return end
                self:EmitSound("button/ancient_button1.wav",90,math.Rand(90,110))
                if (self.Failsafe) then 
                    self.Failsafe = false 
                else 
                    self.Failsafe = true 
                end
            end
        end
    end

    function ENT:SetCustomNodeName(name)
    end

    function ENT:EjectZPM(num)
        if (self.ZPMs[num].Ent) then
            self.ZPMs[num].Ent.Use = function() end
            self:HubUnlink(self.ZPMs[num].Ent)
            local phys = self.ZPMs[num].Ent:GetPhysicsObject()

            if (phys:IsValid()) then
                constraint.RemoveAll(self.ZPMs[num].Ent)
            end

            local mul = 3.2
            self.CanEject = false

            timer.Simple(1, function()
                if (IsValid(self.Entity)) then
                    self.CanEject = true
                end
            end)

            local pos = self.Entity:GetPos()
            self.ZPMs[num].Ent:SetPos(pos + self.Entity:GetRight() * (self.Positions[num].R * mul) + self.Entity:GetUp() * (41 + 12) + self.Entity:GetForward() * (self.Positions[num].F * mul))
        end

        self.ZPMs[num].Ent = nil
        self.ZPMs[num].IsValid = false
        self.ZPMs[num].On = false
    end

    function ENT:Repair()
    end

    function ENT:SetRange(range)
    end

    function ENT:OnRemove()
        StarGate.WireRD.OnRemove(self)

        for i, v in ipairs(self.ZPMs) do
            if (v.IsValid) then
                self:EjectZPM(i)
            end
        end

        self.IdleSound:Stop()
    end

    function ENT:PreEntityCopy()
        local dupeInfo = {}
        dupeInfo.ZPMs = self.ZPMs
        dupeInfo.ZPMid = {}

        for i, v in ipairs(self.ZPMs) do
            if (IsValid(v.Ent)) then
                dupeInfo.ZPMid[i] = v.Ent:EntIndex()
            else
                dupeInfo.ZPMid[i] = -1
            end
        end

        duplicator.StoreEntityModifier(self, "ZPMs", dupeInfo)
        StarGate.WireRD.PreEntityCopy(self)
    end

    function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
        self.ZPMs = Ent.EntityMods.ZPMs.ZPMs

        for i, v in ipairs(Ent.EntityMods.ZPMs.ZPMid) do
            if (v ~= -1) then
                if (self.ZPMs[i]) then
                    self.ZPMs[i].Ent = CreatedEntities[v]
                    self.ZPMs[i].Ent:SetUseType(SIMPLE_USE)

                    self.ZPMs[i].Ent.Use = function()
                        local constr = constraint.FindConstraint(self, "Weld")

                        if (IsValid(constr.Entity[1].Entity)) then
                            constr.Entity[1].Entity:UseZPM(i)
                        end
                    end
                end
            end
        end

        StarGate.WireRD.PostEntityPaste(self, Player, Ent, CreatedEntities)
    end

    if (Environments) then
        ENT.Link = function(self, ent, delay)
            if self.node and IsValid(self.node) then
                self:Unlink()

                for i, v in ipairs(self.ZPMs) do
                    if (IsValid(v.Ent) and v.Dist == 0 and v.Ent.node and IsValid(v.Ent.node)) then
                        v.Ent:Unlink()
                    end
                end
            end

            if ent and ent:IsValid() then
                for i, v in ipairs(self.ZPMs) do
                    if (IsValid(v.Ent) and v.Dist == 0) then
                        v.Ent:Link(ent)
                        ent:Link(v.Ent)
                    end
                end

                self.node = ent

                if delay then
                    timer.Simple(0.1, function()
                        umsg.Start("Env_SetNodeOnEnt")
                        umsg.Short(self:EntIndex())
                        umsg.Short(ent:EntIndex())
                        umsg.End()
                    end)
                else
                    umsg.Start("Env_SetNodeOnEnt")
                    umsg.Short(self:EntIndex())
                    umsg.Short(ent:EntIndex())
                    umsg.End()
                end
                --self:SetNWEntity("node", ent)
            end
        end

        ENT.Unlink = function(self)
            if self.node then
                for i, v in ipairs(self.ZPMs) do
                    if (IsValid(v.Ent) and v.Dist == 0 and v.Ent.node and IsValid(v.Ent.node)) then
                        v.Ent:Unlink()
                    end
                end

                self.node:Unlink(self)
                self.node = nil
                umsg.Start("Env_SetNodeOnEnt")
                umsg.Short(self:EntIndex())
                umsg.Short(0)
                umsg.End()
            end
        end
    end
end

if CLIENT then
    if (StarGate == nil or StarGate.MaterialFromVMT == nil) then return end


    local function MWButtonCheck(pos, targetpos, margin)
        return math.abs(pos.x - targetpos.x) <= margin
        and math.abs(pos.y - targetpos.y) <= margin
        and math.abs(pos.z - targetpos.z) <= margin
    end


    local function RotateAroundZ(p, center, deg)
        local a  = math.rad(deg)
        local ca = math.cos(a)
        local sa = math.sin(a)

        local x = p.x - center.x
        local y = p.y - center.y

        return Vector(
            x * ca - y * sa + center.x,
            x * sa + y * ca + center.y,
            p.z
        )
    end

    local RING_CENTER_XY = (Vector(-7.057692,  18.680084, 0)
                      + Vector(-13.034216, -15.619967, 0)
                      + Vector(19.961227,  -3.455073, 0)) / 3



    local function AnySideHit(relativePos, basePos, margin)
        if not basePos then return false end
        margin = margin or 0.5

        local center = Vector(RING_CENTER_XY.x, RING_CENTER_XY.y, basePos.z)
        for _, deg in ipairs({0, 120, 240}) do
            local p = RotateAroundZ(basePos, center, deg)
            if MWButtonCheck(relativePos, p, margin) then
                return true
            end
        end
        return false
    end




    local function GetHubHoverText(ent, hitWorldPos)
        if not IsValid(ent) then return nil end
        local relativePos = ent:WorldToLocal(hitWorldPos)


        local BTN = {
            AllToggle = { pos = Vector(-7.057692, 18.680084, 44.346169), margin = 0.5, text = "Toggle ALL ZPMs" },
            ZPM1      = { pos = Vector(-9.146106, 17.862841, 44.346172), margin = 0.5, text = "Toggle ZPM 1" },
            ZPM2      = { pos = Vector(-10.982636, 16.641993, 44.346161), margin = 0.5, text = "Toggle ZPM 2" },
            ZPM3      = { pos = Vector(-12.613367, 15.498039, 44.346161), margin = 0.5, text = "Toggle ZPM 3" },
            FailSafe  = { pos = Vector(-14.92, 18.65, 44.35),            margin = 0.5, text = "Toggle Failsafe" },
        }

        -- local comboBtns = {
        --     [1] = { pos = Vector(-7.27,  22.77, 44.35), margin = 0.5, text = "Combo Key 1" },
        --     [2] = { pos = Vector(-9.49,  21.32, 44.35), margin = 0.5, text = "Combo Key 2" },
        --     [3] = { pos = Vector(-11.34, 20.29, 44.35), margin = 0.5, text = "Combo Key 3" },
        -- }
        -- for i = 1, 3 do
        --     if AnySideHit(relativePos, comboBtns[i].pos, comboBtns[i].margin) then
        --         return comboBtns[i].text
        --     end
        -- end

        for _, b in pairs(BTN) do
            if AnySideHit(relativePos, b.pos, b.margin) then
                return b.text
            end
        end

        return nil
    end

    local function DrawCrosshairTooltip(text)
        if not text or text == "" then return end

        surface.SetFont("Trebuchet18")
        local tw, th = surface.GetTextSize(text)

        local x = ScrW() * 0.5
        local y = ScrH() * 0.5 + 28

        local pad = 6
        surface.SetDrawColor(0, 0, 0, 180)
        surface.DrawRect(x - tw * 0.5 - pad, y - pad, tw + pad * 2, th + pad * 2)

        draw.SimpleText(text, "Trebuchet18", x, y, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end


    ENT.ZpmSprite = StarGate.MaterialFromVMT("ZpmSprite", [["Sprite"
	{
		"$spriteorientation" "vp_parallel"
		"$spriteorigin" "[ 0.50 0.50 ]"
		"$basetexture" "sprites/glow04"
		"$spriterendermode" 5
	}]])

    ENT.SpritePositions = {Vector(0, 0, 5), Vector(0, 0, 3), Vector(0, 0, 0), Vector(0, 0, -3), Vector(0, 0, -5)}

    ENT.Zpm_hud = surface.GetTextureID("VGUI/resources_hud/sga_hub")

    function ENT:Initialize()
        self.DAmt = 0
        self.Entity:SetNWString("add", "Inactive")
        self.Entity:SetNWString("perc", 0)
        self.Entity:SetNWString("eng", 0)
        self.Entity:SetNWString("flow", 0)
        self.Entity:SetNWString("overload", 0)
        self.Entity:SetNWString("zpm1", 0)
        self.Entity:SetNWString("zpm2", 0)
        self.Entity:SetNWString("zpm3", 0)
        local mul = 0.93

        self.Positions = {
            {
                R = 0,
                F = -13 * mul
            },
            {
                R = -11.2 * mul,
                F = 6.5 * mul
            },
            {
                R = 11.2 * mul,
                F = 6.5 * mul
            }
        }
    end

    function ENT:Think()
        self.Entity:NextThink(CurTime() + 0.001)

        return true
    end

    local font = {
        font = "Arial",
        size = 14,
        weight = 500,
        antialias = true,
        additive = false
    }

    surface.CreateFont("zpmheader", font)

    function ENT:Draw()
        if (self.Entity:GetNetworkedBool("DrawText")) then
            self.DAmt = math.Clamp(self.DAmt + 0.1, 0, 1)
        else
            self.DAmt = math.Clamp(self.DAmt - 0.05, 0, 1)
        end

        self.Entity:DrawModel()

        if (not StarGate.VisualsMisc("cl_draw_huds", true)) then
            hook.Remove("HUDPaint", tostring(self.Entity) .. "SGAH")

            return
        end

        local ang = EyeAngles()
        ang.y = ang.y
        ang:RotateAroundAxis(ang:Right(), 90)
        ang:RotateAroundAxis(ang:Up(), -90)
        local pos = self.Entity:GetPos() + self.Entity:GetRight() * (self.Positions[1].R) + self.Entity:GetUp() * (62) + self.Entity:GetForward() * (self.Positions[1].F)
        local str = "ZPM 1"
        surface.SetFont("SandboxLabel")
        local w, h = surface.GetTextSize(str)
        cam.Start3D2D(pos, ang, 0.02)
        surface.SetDrawColor(0, 0, 0, 0)
        surface.DrawRect(0 - w / 1, 0, w, h)
        draw.DrawText(str, "SandboxLabel", 0, 0, Color(255, 255, 255, 255 * self.DAmt), TEXT_ALIGN_CENTER)
        cam.End3D2D()
        local pos = self.Entity:GetPos() + self.Entity:GetRight() * (self.Positions[2].R) + self.Entity:GetUp() * (62) + self.Entity:GetForward() * (self.Positions[2].F)
        local str = "ZPM 2"
        surface.SetFont("SandboxLabel")
        local w, h = surface.GetTextSize(str)
        cam.Start3D2D(pos, ang, 0.02)
        surface.SetDrawColor(0, 0, 0, 0)
        surface.DrawRect(0 - w / 1, 0, w, h)
        draw.DrawText(str, "SandboxLabel", 0, 0, Color(255, 255, 255, 255 * self.DAmt), TEXT_ALIGN_CENTER)
        cam.End3D2D()
        local pos = self.Entity:GetPos() + self.Entity:GetRight() * (self.Positions[3].R) + self.Entity:GetUp() * (62) + self.Entity:GetForward() * (self.Positions[3].F)
        local str = "ZPM 3"
        surface.SetFont("SandboxLabel")
        local w, h = surface.GetTextSize(str)
        cam.Start3D2D(pos, ang, 0.02)
        surface.SetDrawColor(0, 0, 0, 0)
        surface.DrawRect(0 - w / 1, 0, w, h)
        draw.DrawText(str, "SandboxLabel", 0, 0, Color(255, 255, 255, 255 * self.DAmt), TEXT_ALIGN_CENTER)
        cam.End3D2D()
        hook.Remove("HUDPaint", tostring(self.Entity) .. "SGAH")

        if (LocalPlayer():GetEyeTrace().Entity == self.Entity and EyePos():Distance(self.Entity:GetPos()) < 1024) then
            hook.Add("HUDPaint", tostring(self.Entity) .. "SGAH", function()
                local w = 0
                local h = 260
                surface.SetTexture(self.Zpm_hud)
                surface.SetDrawColor(Color(255, 255, 255, 255))
                surface.DrawTexturedRect(ScrW() / 2 - 42 + w, ScrH() / 2 - 50 - h, 360, 360)
                surface.SetFont("center2")
                surface.SetFont("header")
                surface.SetFont("zpmheader")
                surface.SetFont("center")
                draw.DrawText("SGA HUB", "header", ScrW() / 2 + 58 + w, ScrH() / 2 + 41 - h, Color(0, 255, 255, 255), 0)
                draw.DrawText("Status", "center2", ScrW() / 2 + 40 + w, ScrH() / 2 + 65 - h, Color(209, 238, 238, 255), 0)
                draw.DrawText("Flowrate", "center2", ScrW() / 2 + 40 + w, ScrH() / 2 + 105 - h, Color(209, 238, 238, 255), 0)
                draw.DrawText("Overload", "center2", ScrW() / 2 + 40 + w, ScrH() / 2 + 145 - h, Color(209, 238, 238, 255), 0)
                draw.DrawText("Capacity", "center2", ScrW() / 2 + 40 + w, ScrH() / 2 + 185 - h, Color(209, 238, 238, 255), 0)
                draw.DrawText("Capacities", "zpmheader", ScrW() / 2 + 180 + w, ScrH() / 2 + 45 - h, Color(209, 238, 238, 255), 0)
                draw.DrawText("ZPM 1", "center", ScrW() / 2 + 180 + w, ScrH() / 2 + 65 - h, Color(209, 238, 238, 255), 0)
                draw.DrawText("ZPM 2", "center", ScrW() / 2 + 180 + w, ScrH() / 2 + 115 - h, Color(209, 238, 238, 255), 0)
                draw.DrawText("ZPM 3", "center", ScrW() / 2 + 180 + w, ScrH() / 2 + 165 - h, Color(209, 238, 238, 255), 0)

                if (IsValid(self.Entity)) then
                    add = self.Entity:GetNWString("add")
                    perc = self.Entity:GetNWString("perc")
                    eng = self.Entity:GetNWString("eng")
                    flow = self.Entity:GetNWString("flow")
                    zpm1 = self.Entity:GetNWString("zpm1")
                    zpm2 = self.Entity:GetNWString("zpm2")
                    zpm3 = self.Entity:GetNWString("zpm3")
                    overload = self.Entity:GetNWString("overload")
                end

                -- Button tooltip
                local tr = LocalPlayer():GetEyeTrace()
                if tr and tr.Entity == self.Entity then
                    local tip = GetHubHoverText(self.Entity, tr.HitPos)
                    DrawCrosshairTooltip(tip)
                end


                local realpower = "nil"
                if (flow >=1000000000) then
                    realpower = tostring((string.format("%G",flow/1000000000)).." GW")
                elseif(flow >=1000000) then
                    realpower = tostring((string.format("%G",flow/1000000)).." MW")
                elseif (flow >=1000) then
                    realpower = tostring((string.format("%G",flow/1000)).." kW")
                else
                    realpower = tostring((string.format("%G",flow)).." W")
                end
                
                surface.SetFont("center")
                local color = Color(0, 255, 0, 255)

                if (add == "Inactive") then
                    color = Color(255, 0, 0, 255)
                end

                if (tonumber(perc) > 0) then
                    perc = string.format("%f", perc)
                end

                if (tonumber(zpm1) > 0 and zpm1 ~= nil) then
                    zpm1 = string.format("%G", zpm1)
                end

                if (tonumber(zpm2) > 0 and zpm2 ~= nil) then
                    zpm2 = string.format("%G", zpm2)
                end

                if (tonumber(zpm3) > 0 and zpm3 ~= nil) then
                    zpm3 = string.format("%G", zpm3)
                end

                draw.SimpleText(add, "center", ScrW() / 2 + 40 + w, ScrH() / 2 + 85 - h, color, 0)
                draw.SimpleText(tostring(realpower), "center", ScrW() / 2 + 40 + w, ScrH() / 2 + 120 - h, Color(255, 255, 255, 255), 0)
                draw.SimpleText(tostring(overload) .. "%", "center", ScrW() / 2 + 40 + w, ScrH() / 2 + 160 - h, Color(255, 255, 255, 255), 0)
                draw.SimpleText(tostring(perc) .. "%", "center", ScrW() / 2 + 40 + w, ScrH() / 2 + 200 - h, Color(255, 255, 255, 255), 0)
                draw.SimpleText(tostring(zpm1) .. "%", "center", ScrW() / 2 + 180 + w, ScrH() / 2 + 85 - h, Color(255, 255, 255, 255), 0)
                draw.SimpleText(tostring(zpm2) .. "%", "center", ScrW() / 2 + 180 + w, ScrH() / 2 + 135 - h, Color(255, 255, 255, 255), 0)
                draw.SimpleText(tostring(zpm3) .. "%", "center", ScrW() / 2 + 180 + w, ScrH() / 2 + 185 - h, Color(255, 255, 255, 255), 0)
            end)
        end

        render.SetMaterial(self.ZpmSprite)
        local alpha1 = self.Entity:GetNWInt("zpm1yellowlightalpha")
        local col1 = Color(255, 165, 0, alpha1)
        if (self.Entity:GetNetworkedEntity("ZPMA") == NULL) then return end

        for i = 1, 5 do
            render.DrawSprite(self.Entity:GetNetworkedEntity("ZPMA"):LocalToWorld(self.SpritePositions[i]), 10, 10, col1)
        end

        local alpha = self.Entity:GetNWInt("zpm2yellowlightalpha")
        local col = Color(255, 165, 0, alpha)
        if (self.Entity:GetNetworkedEntity("ZPMB") == NULL) then return end

        for i = 1, 5 do
            render.DrawSprite(self.Entity:GetNetworkedEntity("ZPMB"):LocalToWorld(self.SpritePositions[i]), 10, 10, col)
        end

        local alpha = self.Entity:GetNWInt("zpm3yellowlightalpha")
        local col = Color(255, 165, 0, alpha)
        if (self.Entity:GetNetworkedEntity("ZPMC") == NULL) then return end

        for i = 1, 5 do
            render.DrawSprite(self.Entity:GetNetworkedEntity("ZPMC"):LocalToWorld(self.SpritePositions[i]), 10, 10, col)
        end
    end


    function ENT:OnRemove()
        hook.Remove("HUDPaint", tostring(self.Entity) .. "SGAH")
    end
end


