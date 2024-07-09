--[[
  Puddle Jumper V4 for GarrysMod 10
	Copyright (C) 2009-2012 RononDex,aVoN

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]
--
--################# HEADER #################
if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("ship")) then return end
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
include("server/sv_toggles.lua")
include("server/sv_drones.lua")
include("server/sv_spawn.lua")
include("server/sv_control.lua")
include("server/sv_physics.lua")
include("server/sv_damage.lua")
local COCKPIT_POS = Vector(19.5255, 3.0715, -50.6359) -- Center of Cockpit
ENT.CDSIgnore = true -- CDS Immunity

-- GCombat invulnarability!
function ENT:gcbt_breakactions()
end

ENT.hasdamagecase = true -- GCombat invulnarability!

ENT.Sounds = {
    Cloak = Sound("jumper/puddlejumpercloak2.wav"),
    Uncloak = Sound("jumper/JumperUnCloak.mp3"),
    Startup = Sound("jumper/puddlestartup2.wav"),
    EnginePodOpen = Sound("jumper/Drivepods1.mp3"),
    EnginePodClose = Sound("jumper/Drivepods2.mp3"),
    Explosion = Sound("jumper/JumperExplosion.mp3"),
    Door = Sound("jumper/jumperreardoor.wav"),
    Shutdown = Sound("jumper/jumperpowerdown.wav"),
    Drone = Sound("weapons/drone_shot.mp3"),
    BulkDoor = Sound("jumper/jumpcentdoor.wav")
}

ENT.Gibs = {
    Gib1 = "models/Iziraider/jumper/gibs/backdoor.mdl",
    Gib2 = "models/Iziraider/jumper/gibs/front.mdl",
    Gib3 = "models/Iziraider/jumper/gibs/internal.mdl",
    Gib4 = "models/Iziraider/jumper/gibs/wepleft.mdl",
    Gib5 = "models/Iziraider/jumper/gibs/wepright.mdl",
    Gib6 = "models/Iziraider/jumper/gibs/wingleft.mdl",
    Gib7 = "models/Iziraider/jumper/gibs/wingright.mdl"
}

--############### Makes it spawn
function ENT:SpawnFunction(pl, tr)
    if (not tr.HitWorld) then return end
    local PropLimit = GetConVar("CAP_ships_max"):GetInt()

    if (pl:GetCount("CAP_ships") + 1 > PropLimit) then
        pl:SendLua("GAMEMODE:AddNotify(Ships limit reached!, NOTIFY_ERROR, 5); surface.PlaySound( \"buttons/button2.wav\" )")

        return
    end

    local e = ents.Create("puddle_jumper")
    e:SetPos(tr.HitPos + Vector(0, 0, 60))
    e:SetAngles(Angle(0, pl:GetAimVector():Angle().Yaw, 0))
    e:Spawn()
    e:Activate()
    e:SetVar("Owner", pl)
    -- Spawn the doors
    e:SpawnBackDoor(nil, pl)
    e:SpawnBulkHeadDoor(nil, pl)
    e:SpawnToggleButton(pl)
    e:SpawnShieldGen(pl)
    --e:SpawnOpenedDoor();
    e.Owner = pl
    pl:AddCount("CAP_ships", e)
    pl:Give("weapon_jumper_remote")

    return e
end

function ENT:HangarSpawn(pl)
    self:SetVar("Owner", pl)
    -- Spawn the doors
    self:SpawnBackDoor(nil, pl)
    self:SpawnBulkHeadDoor(nil, pl)
    self:SpawnToggleButton(pl)
    self:SpawnShieldGen(pl)
    --e:SpawnOpenedDoor();
end

--################# Over filled Init function @ RononDex
function ENT:Initialize(ply)
    --######### Jumper Vars
    self.Roll = 0
    self.Engine = true -- Is the engine not damaged?
    -- Add a race check here for the ATA gene.
    -- if e.pl is ancient then
    self.AllowActivation = true -- Can we get in?
    -- else
    -- 	self.AllowActivation = false;
    -- end
    self.CanDoCloak = true
    self.CanCloak = true
    self.Cloaked = false -- Even though bools are false by default, i need to set it here for the SWep
    self.CanOpenPods = true
    self.CanShoot = true
    self.CanWepPods = true
    self.CanShield = true
    self.CanHaveLS = true
    self.PWeapons = {}
    self.EntHealth = 500
    self.MaxHealth = self.EntHealth

    self.IsJumper = true
    self.Vehicle = "PuddleJumper"
    self.EHAngles = Angle(0, 0, 0)
    self.AutoAccel = 0
    self.Buttons = {}
    self.door = false
    self.BulkHead = false
    --############## Standard Crap
    self:SetModel("models/Iziraider/jumper/jumper.mdl") -- Hooray Izi's model
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:StartMotionController()
    self:SetUseType(SIMPLE_USE)
    self:SetRenderMode(RENDERMODE_TRANSALPHA)
    self:CreateWireInputs("Target [VECTOR]", "Cloak", "Shield", "Toggle Light", "AutoDestruct")
    self:CreateWireOutputs("Shield Strength", "Shield Enabled", "Health", "Driver [ENTITY]")
    self:SetWire("Health", self.EntHealth)
    self.Hover = true
    self:SpawnSeats()
    --############ Drone vars
    self.Target = Vector(0, 0, 0)
    self.DroneMaxSpeed = 6000
    self.TrackTime = 1000000
    self.Drones = {}
    self.DroneCount = 0
    self.MaxDrones = 6
    self.On = 1

    self.Accel = {
        FWD = 0,
        RIGHT = 0,
        UP = 0
    }

    if (self.HasRD) then
        if (self.CanHaveLS) then
            self.grav_plate = 1
        end
    end

    -- Cloak var
    self.ImmuneOwner = true -- We can see the jumper when cloaked, no one else can
    local phys = self:GetPhysicsObject()

    if (phys:IsValid()) then
        phys:Wake()
        phys:SetMass(100000)
    end
end

--######### @ RononDex
function ENT:OnRemove()
    if ((self.Inflight) and (IsValid(self.Pilot))) then
        if (not (self.Done)) then
            self:ExitJumper(self.Pilot)
        end
    end

    if (IsValid(self.Shields)) then
        self.Shields:Remove()
    end

    for _, v in pairs(self.Seats or {}) do
        if IsValid(v) then
            v:Remove()
        end
    end

    self:RemoveAll()
end

--######### Do a lot of stuff@ RononDex
function ENT:Think()
    --######### This stops the bug, of your health going below 0 and not blowing up
    if ((self.EntHealth) <= 1) then
        self:DoKill()
    end

    if (not self.Inflight) then
        for k, v in pairs(ents.GetAll()) do
            if (v:IsPlayer()) then
                if (self.Cloaked) then
                    if (self:InJumper(v)) then
                        v:SetNoTarget(true)
                    else
                        v:SetNoTarget(false)
                    end
                else
                    v:SetNoTarget(false)
                end
            end
        end
    end

    --####### This sends necessary information to the client
    if (IsValid(self.Pilot)) then
        umsg.Start("jumperData", self.Pilot)
        umsg.Entity(self)
        umsg.Short(self.DroneCount)
        umsg.Bool(self.epodo)
        umsg.Bool(self.CantCloak)
        umsg.Bool(self.Cloaked)
        umsg.Bool(self.CanShield)
        umsg.Bool(self.CanShoot)
        umsg.Short(self.EntHealth)
        umsg.Bool(self.Engine)
        umsg.Bool(self.Inflight)
        umsg.End()
    end

    if (self.Cloaked) then
        umsg.Start("JumperCloakData", self.Owner)
        umsg.Entity(self)
        umsg.Bool(self.CloakPods)
        umsg.Bool(self.door)
        umsg.Bool(self.BulkHead)
        umsg.Bool(self.WepPods)
        umsg.Bool(self.AnimCloaked)
        umsg.End()
    end

    --####### Keep giving us air, coolant etc.
    if (self.HasRD) then
        if (self.CanHaveLS) then
            self:LSSupport()
        end
    end

    --######### Apply water pressure damage
    if (self:WaterLevel() >= 1) then
        self:GetPhysicsObject():SetMass(100) --Sink slowly

        if (self.Shields) then
            if (not (self.Shields:Enabled())) then
                self.WaterDamage = true

                if (not (self.RunningAnimation)) then
                    self:TakeDamage(1)
                else
                    self:TakeDamage(0.1)
                end

                timer.Simple(0.5, function()
                    self.WaterDamage = false
                end)
            else
                self.Shields.Shield:DrawBubbleEffect(_, true)
                self.Shields.Strength = (self.Shields.Strength) - 5
            end
        end
    end

    --######## This fixes a bug since the first Jumper V2.5 i made, when people couldn't hover
    if (not (self.Hover)) then
        if (self.Inflight) then
            self.Hover = true
        end
    end

    if (IsValid(self.FrontPassenger)) then
        if (self.FrontPassenger:KeyDown(IN_RELOAD)) then
            self:OpenDHD(self.FrontPassenger)
        end
    end

    --########## Mostly key presses
    if (IsValid(self.Pilot) and self.Inflight) then
        self.Pilot:SetPos(self:GetPos())
        self.Pilot:SetColor(Color(255, 255, 255, 0))

        if (self.Exited and self.Autopilot) then
            self:AutoPilot(false)
        end

        if (not (self.DronePropsMade)) then
            if (self.WepPods) then
                if (self.FinalDrone) then
                    if (self.DroneCount == 0) then
                        self.FinalDrone = false

                        for i = 1, 6 do
                            self.DronePropFired[i] = false
                        end

                        self:RemoveDrones() -- Make sure that there are no old models

                        if (not self.Cloaked) then
                            self:SpawnDroneProps()
                        end
                    end
                end
            elseif (not self.WepPods and self.DroneCount == 0) then
                for i = 1, 6 do
                    if (self.DronePropFired[i]) then
                        self.DronePropFired[i] = false
                    end
                end
            end
        end

        -- TRACK!!!!!!
        if (self.Pilot:KeyDown(self.Vehicle, "TRACK")) then
            self.Track = true
        else
            self.Track = false
        end

        if (self.Pilot:KeyDown(self.Vehicle, "AUTOPILOT")) then
            if (self.NextUse.Autopilot < CurTime()) then
                if (not self.Autopilot) then
                    self:AutoPilot(true)
                else
                    self:AutoPilot(false)
                end

                self.NextUse.Autopilot = CurTime() + 1
            end
        end

        if (self.Pilot:KeyDown(self.Vehicle, "LIGHT")) then
            self:ToggleLight()
        end

        if (self.Pilot:KeyDown(self.Vehicle, "DHD")) then
            self:OpenDHD(self.Pilot) -- Open DHD for pilot
        end

        if (not self.Autopilot) then
            if (self.Pilot:KeyDown(self.Vehicle, "FIRE")) then
                if (not self.Cloaked) then
                    self:FireDrone()
                else
                    self:ToggleCloak()
                end
            end

            if (self.epodo) then
                if (self.CanWepPods) then
                    if (self.Pilot:KeyDown(self.Vehicle, "WEPPODS")) then
                        self:RemoveDrones()
                        self:ToggleWeaponPods()
                    end
                end
            end

            if (IsValid(self)) then
                if (self.Pilot:KeyDown(self.Vehicle, "BOOM")) then
                    self:DoKill()
                end
            end

            if (IsValid(self.Pilot)) then
                if (self.Pilot:KeyDown(self.Vehicle, "SPD")) then
                    self:TogglePods()
                end

                if (self.Pilot:KeyDown(self.Vehicle, "CLOAK")) then
                    self:ToggleCloak()
                end

                if (self.Pilot:KeyDown(self.Vehicle, "SHIELD")) then
                    self:ToggleShield()
                end

                if (self.Pilot:KeyDown(self.Vehicle, "HOVER")) then
                    if (self.NextUse.Hover < CurTime()) then
                        if (not self.HoverAlways) then
                            self.HoverAlways = true
                            self.Pilot:PrintMessage(HUD_PRINTTALK, "Engine Standby: ON")
                        else
                            self.HoverAlways = false
                            self.Pilot:PrintMessage(HUD_PRINTTALK, "Engine Standby: OFF")
                        end

                        self.NextUse.Hover = CurTime() + 1
                    end
                end

                if (not (self.epodo)) then
                    if (self.Pilot:KeyDown(self.Vehicle, "DOOR")) then
                        self:ToggleDoor()
                    end
                end

                if (self.AllowActivation) then
                    if (self.Pilot:KeyDown(self.Vehicle, "EXIT")) then
                        self:ExitJumper()
                    end
                end
            end
        end
    end

    if (IsValid(self.Shields)) then
        if (self.Shields.Depleted) then
            self:SetWire("Shield Enabled", -1)
            self:SetWire("Shield Strength", self.Shields.Strength)
        else
            self:SetWire("Shield Enabled", self.Shields:Enabled())
            self:SetWire("Shield Strength", self.Shields.Strength)
        end
    else
        self:SetWire("Shield Enabled", 0)
        self:SetWire("Shield Strength", 0)
    end

    if (self.Inflight or self.NextUse.Door > CurTime() or self.NextUse.BulkHead > CurTime()) then
        self:NextThink(CurTime())

        return true
    end
end

--######### What happens when you press E?@ RononDex
function ENT:Use(ply)
    local pos = self:WorldToLocal(ply:GetPos()) - COCKPIT_POS

    if ((pos.x > -20 and pos.x < 100) and (pos.y > -90 and pos.y < 90) and (pos.z > -2 and pos.z < 80)) then
        if (not (self.Inflight)) then
            if (ply:KeyDown(self.Vehicle, "CLOAK") and IsValid(self.FrontSeat)) then
                ply:EnterVehicle(self.FrontSeat)
            else
                self:EnterJumper(ply)
            end
        end
    end
end

--####### Dummy function for drones @RononDex
function ENT:ShowOutput()
end

--######### @ aVoN
function ENT:OpenDHD(p)
    if (not IsValid(p)) then return end
    local e = self:FindGate(5000)
    if (not IsValid(e)) then return end
    if (hook.Call("StarGate.Player.CanDialGate", GAMEMODE, p, e) == false) then return end
    net.Start("StarGate.VGUI.Menu")
    net.WriteEntity(e)
    net.WriteInt(1, 8)
    net.Send(p)
end

--######### @ aVoN
function ENT:FindGate(dist)
    local gate
    local pos = self:GetPos()

    for _, v in pairs(ents.FindByClass("stargate_*")) do
        if (not v.IsStargate or v.IsSupergate) then continue end
        local sg_dist = (pos - v:GetPos()):Length()

        if (dist >= sg_dist) then
            dist = sg_dist
            gate = v
        end
    end

    return gate
end

function ENT:Enabled()
    return (self.Cloak and self.Cloak:IsValid())
end

--############## Add wire inputs
--######### @ RononDex
function ENT:TriggerInput(k, v)
    if (not self.EyeTrack and k == "Target") then
        self.PositionSet = true
        self.Target = v
    end

    if (k == "Cloak") then
        if ((v or 0) >= 1) then
            self:ToggleCloak()
        end
    end

    if (k == "Toggle Light") then
        if ((v or 0) >= 1) then
            self:ToggleLight()
        end
    end

    if (k == "AutoDestruct") then
        if ((v or 0) >= 1) then
            self:DoKill()
        end
    end

    if (k == "Shield") then
        if ((v or 0) >= 1) then
            self:ToggleShield()
        end
    end
end

--####### Give us air @RononDex
function ENT:LSSupport()
    local ent_pos = self:GetPos()

    if (IsValid(self)) then
        -- Find all players
        for _, p in pairs(player.GetAll()) do
            local pos = (p:GetPos() - ent_pos):Length() -- Where they are in relation to the jumper

            -- If they're close enough
            if (pos < 400 and p.suit) then
                if (not (StarGate.RDThree())) then
                    -- They get air
                    if (p.suit.air < 100) then
                        p.suit.air = 100
                    end

                    -- and energy
                    if (p.suit.energy < 100) then
                        p.suit.energy = 100
                    end

                    -- and coolant
                    if (p.suit.coolant < 100) then
                        p.suit.coolant = 100
                    end
                else
                    -- We need double the amount of LS3(No idea why)
                    -- They get air
                    if (p.suit.air < 200) then
                        p.suit.air = 200
                    end

                    -- and energy
                    if (p.suit.energy < 200) then
                        p.suit.energy = 200
                    end

                    -- and coolant
                    if (p.suit.coolant < 200) then
                        p.suit.coolant = 200
                    end
                end
            end
        end
    end
end

--####### Avoids the annoying bug that i've had since the start. When a player suicides the jumper now blows up @RononDex
hook.Add("PlayerDeath", "JumperPlayerDeath", function(p)
    local Jumper = p:GetNetworkedEntity("jumper")

    if (IsValid(Jumper) and Jumper.Inflight) then
        if (Jumper.Pilot == p) then
            Jumper:ExitJumper()

            if (not (Jumper.Done)) then
                Jumper:DoKill()
            end
        end
    end
end)

hook.Add("PlayerSilentDeath", "JumperPlayerDeath", function(p)
    local Jumper = p:GetNetworkedEntity("jumper")

    if (IsValid(Jumper) and Jumper.Inflight) then
        if (Jumper.Pilot == p) then
            Jumper:ExitJumper()

            if (not (Jumper.Done)) then
                Jumper:DoKill()
            end
        end
    end
end)

hook.Add("PlayerLeaveVehicle", "PuddleJumperSeatExit", function(p, v)
    if (IsValid(p) and IsValid(v)) then
        if (v.IsJumperSeat) then
            local Jumper = v.Jumper
            v:SetThirdPersonMode(false)
            p:SetNWBool("JumperPassenger", false)
            p:SetNetworkedEntity("JumperSeat", NULL)
            p:SetPos(Jumper:GetPos() + Jumper:GetUp() * -30 + Jumper:GetForward() * -100)

            if (v.FrontSeat) then
                v:GetParent().FrontPassenger = NULL
            end
        end
    end
end)

hook.Add("PlayerEnteredVehicle", "PuddleJumperSeatEnter", function(p, v)
    if (IsValid(v)) then
        if (IsValid(p)) then
            if (v.IsJumperSeat) then
                p:SetNetworkedEntity("JumperSeat", v)
                p:SetNetworkedEntity("JumperPassenger", v:GetParent())
                p:SetNWBool("JumperPassenger", true)

                if (v.FrontSeat) then
                    v:GetParent().FrontPassenger = p
                end
            end
        end
    end
end)

function ENT:PreEntityCopy()
    local dupeInfo = {}

    if (IsValid(self.Door)) then
        dupeInfo.Door = self.Door:EntIndex()
    end

    if (IsValid(self.BulkDoor)) then
        dupeInfo.BulkDoor = self.BulkDoor:EntIndex()
    end

    if (IsValid(self.OpenedDoor)) then
        dupeInfo.OpenerDoor = self.OpenedDoor:EntIndex()
    end

    duplicator.StoreEntityModifier(self, "JumperDupeInfo", dupeInfo)
    StarGate.WireRD.PreEntityCopy(self)
end

function ENT:PostEntityPaste(ply, Ent, CreatedEntities)
    local dupeInfo = Ent.EntityMods.JumperDupeInfo

    if (dupeInfo.Door) then
        self:SpawnBackDoor(CreatedEntities[dupeInfo.Door])
    end

    if (dupeInfo.BulkDoor) then
        self:SpawnBulkHeadDoor(CreatedEntities[dupeInfo.BulkDoor])
    end

    if (dupeInfo.OpenerDoor and IsValid(CreatedEntities[dupeInfo.OpenerDoor])) then
        -- fix
        timer.Simple(0.1, function()
            if IsValid(CreatedEntities[dupeInfo.OpenerDoor]) then
                CreatedEntities[dupeInfo.OpenerDoor]:Remove()
            end
        end)
    end

    self:SpawnToggleButton(ply)
    self:SpawnShieldGen(ply)

    if (StarGate.NotSpawnable(Ent:GetClass(), ply)) then
        self.Entity:Remove()

        return
    end

    if (IsValid(ply)) then
        local PropLimit = GetConVar("CAP_ships_max"):GetInt()

        if (ply:GetCount("CAP_ships") + 1 > PropLimit) then
            ply:SendLua("GAMEMODE:AddNotify(Ships limit reached!, NOTIFY_ERROR, 5); surface.PlaySound( \"buttons/button2.wav\" )")
            self.Entity:Remove()

            return
        end

        ply:AddCount("CAP_ships", Ent)
    end

    self.Owner = ply
    self:SetVar("Owner", ply)
    StarGate.WireRD.PostEntityPaste(self, ply, Ent, CreatedEntities)
end

if (StarGate and StarGate.CAP_GmodDuplicator) then
    duplicator.RegisterEntityClass("puddle_jumper", StarGate.CAP_GmodDuplicator, "Data")
end
