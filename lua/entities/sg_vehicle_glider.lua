--[[
	DeathGlider for GarrysMod 10
	Copyright (C) 2009 RononDex

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
--
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Type = "vehicle"
ENT.Base = "sg_vehicle_base"
ENT.Author = "RononDex, Iziraider, Rafael De Jongh"
ENT.PrintName = "Death Glider"
ENT.Category = "Ships"
if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
ENT.Category = SGLanguage.GetMessage("entity_ships_cat");
end
list.Set("CAP.Entity", ENT.PrintName, ENT)

if SERVER then
    --########Header########--
    if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("ship")) then return end
    AddCSLuaFile()
    ENT.Model = Model("models/Iziraider/Deathglider/deathglider.mdl")

    ENT.Sounds = {
        Staff = Sound("pulse_weapon/staff_weapon.mp3")
    }

    --######## Pretty useless unless we can spawn it @RononDex
    function ENT:SpawnFunction(ply, tr)
        if (!tr.Hit) then return end
        local PropLimit = GetConVar("CAP_ships_max"):GetInt()
        local ang = ply:GetAimVector():Angle(); ang.p = 0; ang.r = 0; ang.y = (ang.y) % 360;
        if (ply:GetCount("CAP_ships") + 1 > PropLimit) then
            ply:SendLua("GAMEMODE:AddNotify(Ships limit reached!, NOTIFY_ERROR, 5); surface.PlaySound( \"buttons/button2.wav\" )")

            return
        end

        local e = ents.Create("sg_vehicle_glider")
        e:SetAngles(ang);
        e:SetPos(tr.HitPos + Vector(0, 0, 10))
        e:Spawn()
        e:Activate()
        ply:AddCount("CAP_ships", e)

        return e
    end

    --######## What happens when it first spawns(Set Model, Physics etc.) @RononDex
    function ENT:Initialize()
        self:SetModel(self.Model)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        self:StartMotionController()
        self.Vehicle = "DeathGlider"
        --self.BaseClass.Initialize(self,self.Vehicle,self.FlightVars,self.FlightPhys,self.Accel)
        self.EntHealth = 300
        self.MaxHealth = self.EntHealth
        self.BlastMaxVel = 10000000
        self.Blasts = {}
        self.BlastCount = 0
        self.MaxBlasts = (4)
        self.BlastsFired = 0
        self.Delay = 10
        --######### Flight Vars
        self.Accel = {}
        self.Accel.FWD = 0
        self.Accel.RIGHT = 0
        self.Accel.UP = 0
        self.ForwardSpeed = 2000
        self.BackwardSpeed = 0
        self.UpSpeed = 0
        self.MaxSpeed = 2750
        self.RightSpeed = 0
        self.Accel.SpeedForward = 20
        self.Accel.SpeedRight = 0
        self.Accel.SpeedUp = 0
        self.RollSpeed = 5
        self.num = 0
        self.num2 = 0
        self.num3 = 0
        self.Roll = 0
        self.Hover = false
        self.GoesRight = false
        self.GoesUp = false
        self.CanRoll = true
        self:CreateWireOutputs("Health")
        self:SetWire("Health", self.EntHealth)
        local phys = self:GetPhysicsObject()

        if (phys:IsValid()) then
            phys:Wake()
            phys:SetMass(10000)
        end
    end

    --########## Gliders aren't invincible are they? @RononDex
    function ENT:OnTakeDamage(dmg)
        self.EntHealth = self.EntHealth - dmg:GetDamage()
        self:SetWire("Health", self.EntHealth)

        if (self.EntHealth - dmg:GetDamage() <= 0) then
            self:Bang() -- Go boom
        end
    end

    function ENT:HealthRepair(health)
        self.EntHealth = health
        self:SetWire("Health", health)
    end

    function ENT:OnRemove()
        self.BaseClass.OnRemove(self)
    end

    function ENT:Think()
        self.BaseClass.Think(self)

        if (self.StartDelay) then
            self.Delay = math.Approach(self.Delay, 10, 3)
        end

        if (self.Delay >= 10) then
            self.StartDelay = false
        end

        if (IsValid(self.Pilot)) then
            if ((self.Pilot:KeyDown(self.Vehicle, "FIRE"))) then
                if (self.Delay >= 10) then
                    self:FireBlast(self:GetRight() * -130)
                    self:FireBlast(self:GetRight() * 130)
                    self.Delay = 0
                end

                self.StartDelay = true
            end
        end
    end

    function ENT:Exit(kill)
        self.BaseClass.Exit(self, kill)
        self.ExitPos = self:GetPos() + Vector(0, 0, 100)
    end

    function ENT:FireBlast(diff)
        local e = ents.Create("energy_pulse")

        e:PrepareBullet(self:GetForward(), 10, 16000, 6, {self.Entity})

        e:SetPos(self:GetPos() + diff + self:GetUp()*100)
        e:SetOwner(self)
        e.Owner = self
        e:Spawn()
        e:Activate()
        self:EmitSound(self.Sounds.Staff, 90, math.random(90, 110))
    end

    function ENT:ShowOutput()
    end

    if (StarGate and StarGate.CAP_GmodDuplicator) then
        duplicator.RegisterEntityClass("sg_vehicle_glider", StarGate.CAP_GmodDuplicator, "Data")
    end
end

if CLIENT then
    ENT.Sounds = {
        Engine = Sound("glider/deathglideridleoutside.wav")
    }

    if (StarGate == nil or StarGate.KeyBoard == nil or StarGate.KeyBoard.New == nil) then return end
    --########## Keybinder stuff
    local KBD = StarGate.KeyBoard:New("DeathGlider")
    --Navigation
    KBD:SetDefaultKey("FWD", StarGate.KeyBoard.BINDS["+forward"] or "W") -- Forward
    KBD:SetDefaultKey("SPD", StarGate.KeyBoard.BINDS["+speed"] or "SHIFT")
    --Roll
    KBD:SetDefaultKey("RL", "MWHEELDOWN") -- Roll left
    KBD:SetDefaultKey("RR", "MWHEELUP") -- Roll right
    KBD:SetDefaultKey("RROLL", "MOUSE3") -- Reset Roll
    --Attack
    KBD:SetDefaultKey("FIRE", StarGate.KeyBoard.BINDS["+attack"] or "MOUSE1") -- Fire blasts
    --Special Actions
    KBD:SetDefaultKey("RROLL", "MOUSE3") -- Reset roll
    KBD:SetDefaultKey("BOOM", "BACKSPACE")
    --View
    KBD:SetDefaultKey("Z+", "UPARROW")
    KBD:SetDefaultKey("Z-", "DOWNARROW")
    KBD:SetDefaultKey("A+", "LEFTARROW")
    KBD:SetDefaultKey("A-", "RIGHTARROW")
    KBD:SetDefaultKey("VIEW", "1")
    KBD:SetDefaultKey("EXIT", StarGate.KeyBoard.BINDS["+use"] or "E")

    function ENT:Initialize()
        self.Dist = -850
        self.UDist = 250
        self.FirstPerson = false
        self.lastswitch = CurTime()
        self.on1 = 0
        self.KBD = self.KBD or KBD:CreateInstance(self)
        self.BaseClass.Initialize(self)
        self.Vehicle = "DeathGlider"
    end

    --######## Mainly Keyboard stuff @RononDex
    function ENT:Think()
        self.BaseClass.Think(self)
        local p = LocalPlayer()
        local vehicle = p:GetNetworkedEntity("ScriptedVehicle", NULL)

        if ((vehicle) and ((vehicle) == self) and (vehicle:IsValid())) then
            self.KBD:SetActive(true)
            self:StartClientsideSound("Normal")
        else
            self.KBD:SetActive(false)
            self:StopClientsideSound("Normal")
        end

        if ((vehicle) and ((vehicle) == self) and (vehicle:IsValid())) then
            if (p:KeyDown(self.Vehicle, "Z+")) then
                self.Dist = self.Dist - 5
            elseif (p:KeyDown(self.Vehicle, "Z-")) then
                self.Dist = self.Dist + 5
            end

            if (p:KeyDown(self.Vehicle, "A+")) then
                self.UDist = self.UDist + 5
            elseif (p:KeyDown(self.Vehicle, "A-")) then
                self.UDist = self.UDist - 5
            end
        end
    end
    local HUD = surface.GetTextureID("VGUI/hud/hatak_hud/main_hud_v2")

    -- local function Glider_Hud()
    --     local p = LocalPlayer()
    --     local glider = p:GetNWEntity("DeathGlider")
    --     local self = p:GetNetworkedEntity("ScriptedVehicle", NULL)
    --     --print(p:GetNetworkedEntity("ScriptedVehicle", NULL))
    --     if (not IsValid(p:GetNetworkedEntity("ScriptedVehicle", NULL))) then return end
    --     --local health = math.Round(((self:GetNWInt("health")) / 5))
    --     --if (self.HideHUD) then return end

    --     --if (IsValid(glider)) then
    --         --if (glider == self) then
    --             surface.SetTexture(HUD)   
    --         --end
    --     --end
        
    -- end
    --hook.Add("HUDPaint", "Glider_HUD", Glider_Hud)
end