if (StarGate ~= nil and StarGate.LifeSupportAndWire ~= nil) then
    StarGate.LifeSupportAndWire(ENT)
end
local shield_debounce = false
include("stargate/shared/mw_library.lua")

ENT.Base = "base_anim"
ENT.Type = "anim"
ENT.PrintName = "Control Chair"
ENT.Author = "RononDex, Markjaw, Soren"
ENT.Category = "Stargate Carter Addon Pack: Ships"
list.Set("CAP.Entity", ENT.PrintName, ENT)
ENT.AutomaticFrameAdvance = true

if CLIENT then
	if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
		ENT.Category = SGLanguage.GetMessage("entity_ships_cat");
		ENT.PrintName = SGLanguage.GetMessage("entity_control_chair");
	end


    ENT.Controlchair_bottomleft = surface.GetTextureID("VGUI/resources_hud/control_chair_bottomleft")
    ENT.Controlchair_bottomright = surface.GetTextureID("VGUI/resources_hud/control_chair_bottomright")
    
    ENT.ViewPos = Vector(0, 0, 100)
    ENT.ViewFace = ((Vector(0, 0, 100) + Vector(0, 0, 20)) - Vector(0, 0, 100)):Angle()
    ENT.PlayerMouse = false


    function ENT:Initialize()
        self.DAmt = 0
        self.Dist = -200
        self.UDist = 90
        self.NextUse = CurTime()
        --self:SetShouldDrawInViewMode(true)
    end

    function ENT:HandleMessageFromServer(originEntity, subject, ...)
        local data1 = select(1, ...)
        local data2 = select(2, ...)
        local data3 = select(3, ...)

        if subject == "controlchair_targetmenu_v2" then
            TargetControlMenu(originEntity, data1)
        elseif subject == "controlchair_interact" then
            ControlChair_Interact(originEntity, data1)
        elseif subject == "controlchair_click" then
            ControlChair_Click(originEntity)
        end
    end

    function ENT:OnRemove()
        hook.Remove("HUDPaint", tostring(self.Entity) .. "CChair")


    end

    function ENT:Draw()
        local p = LocalPlayer()
        local Controlling = p:GetNWBool("Control")
        local chair_initialized = p:GetNetworkedBool("chair_initialized")
        local sc_vehicle = p:GetNWEntity("ScriptedVehicle",nil)

        self:DrawModel()

        if (Controlling and IsValid(self.Entity) and (sc_vehicle==self.Entity)) then
            --self:DynLight(true)

            hook.Add("HUDPaint", tostring(self.Entity) .. "CChair", function()
            -------- Bottom Left--------------------------------------------------------------------------------
                local w = -930
                local h = -310

                surface.SetTexture(self.Controlchair_bottomleft)
                surface.SetDrawColor(Color(255, 255, 255, 255))
                surface.DrawTexturedRect(ScrW() / 2 - 42 + w, ScrH() / 2 - 50 - h, 360, 360)
                draw.DrawText("Ancient Control Chair", "HudHintTextLarge", ScrW() / 2 + 48 + w, ScrH() / 2 + 41 - h, color_white, 0)

                draw.DrawText("R: Engage rotation", "HudHintTextLarge", ScrW() / 2 - 5 + w, ScrH() / 2 + 70 - h, color_white, 0)
                
                if (self:GetNetworkedBool("Rotate",true) == true) then
                    draw.DrawText("Online", "HudHintTextLarge", ScrW() / 2 + 130 + w, ScrH() / 2 + 70 - h, Color(0, 255, 0, 255), 0)
                else
                    draw.DrawText("Offline", "HudHintTextLarge", ScrW() / 2 + 130 + w, ScrH() / 2 + 70 - h, Color(255, 0, 0, 255), 0)
                end

                draw.DrawText("D: Enable shield", "HudHintTextLarge", ScrW() / 2 - 5 + w, ScrH() / 2 + 90 - h, color_white, 0)

                if (self:GetNetworkedBool("Shield_online",false) == true) then
                    draw.DrawText("Online", "HudHintTextLarge", ScrW() / 2 + 130 + w, ScrH() / 2 + 90 - h, Color(0, 255, 0, 255), 0)
                else
                    draw.DrawText("Offline", "HudHintTextLarge", ScrW() / 2 + 130 + w, ScrH() / 2 + 90 - h, Color(255, 0, 0, 255), 0)
                end


                draw.DrawText("1: Target Menu", "HudHintTextLarge", ScrW() / 2 - 5 + w, ScrH() / 2 + 110 - h, color_white, 0)

                draw.DrawText("Left Mouse Button: Fire Drones", "HudHintTextLarge", ScrW() / 2 - 5 + w, ScrH() / 2 + 130 - h, color_white, 0)

                draw.DrawText("Space (hold): Stardrive", "HudHintTextLarge", ScrW() / 2 - 5 + w, ScrH() / 2 + 150 - h, color_white, 0)



            -------- Bottom Right--------------------------------------------------------------------------------
                w = 655
                h = -310
                surface.SetTexture(self.Controlchair_bottomright)
                surface.SetDrawColor(color_white)
                surface.DrawTexturedRect(ScrW() / 2 - 42 + w, ScrH() / 2 - 50 - h, 360, 360)
                -- Draw Power Header
                draw.DrawText("Power", "HudHintTextLarge", ScrW() / 2 + w, ScrH() / 2 + 41 - h, color_white, 0)

                -- Internal ZPM
                if self:GetNetworkedString("ZPM_Online", "Inactive") == "Active" then
                    draw.DrawText("Internal ZPM: ", "HudHintTextLarge", ScrW() / 2 + w, ScrH() / 2 + 61 - h, color_white, 0)
                    draw.DrawText("Online", "HudHintTextLarge", ScrW() / 2 + 100 + w, ScrH() / 2 + 61 - h, color_white, 0)

                    draw.DrawText("ZPM %: ", "HudHintTextLarge", ScrW() / 2 + w, ScrH() / 2 + 81 - h, color_white, 0)
                    draw.DrawText(math.Round(self:GetNetworkedInt("ZPM_Percentage", 0), 1) .. "%", "HudHintTextLarge", ScrW() / 2 + 60 + w, ScrH() / 2 + 81 - h, color_white, 0)
                else
                    draw.DrawText("Internal ZPM: ", "HudHintTextLarge", ScrW() / 2 + w, ScrH() / 2 + 61 - h, color_white, 0)
                    draw.DrawText("Offline", "HudHintTextLarge", ScrW() / 2 + 100 + w, ScrH() / 2 + 61 - h, color_white, 0)
                end
                if self:GetNetworkedInt("Internal_Source", 0) == 1 then
                    draw.DrawText("Energy Reserves: ", "HudHintTextLarge", ScrW() / 2 + w, ScrH() / 2 + 101 - h, color_white, 0)
                    draw.DrawText(math.Round(self:GetNetworkedInt("Internal_Percentage", 0), 1) .. "%", "HudHintTextLarge", ScrW() / 2 + 121 + w, ScrH() / 2 + 101 - h, color_white, 0)
                end

            end)
        elseif ((not (Controlling))) then
            hook.Remove("HUDPaint", tostring(self.Entity) .. "CChair")
            --self:DynLight(false)
        end

        if (chair_initialized and (sc_vehicle==self.Entity)) then
            self:DynLight(true)

        elseif (not (chair_initialized)) then
            self:DynLight(false)
        end
    end

    local function Data(um)
        local p = LocalPlayer()
        p.Controlling = um:ReadBool()
        p.Enabled = um:ReadBool()
        p.DroneCount = um:ReadShort()
        p.Chair = um:ReadEntity()
    end

    usermessage.Hook("ControlChair", Data)

     
	local chair_zoom = 0
	hook.Add("InputMouseApply", "Chair_Zoom", function(cmd, x, y, ang)
        local p = LocalPlayer()
        if (p.Controlling) then
	       chair_zoom = chair_zoom + cmd:GetMouseWheel() * -2
        end
	end)

    function ControlChair_Interact(senderEntity, isMouseActive)
    local localPlayer = LocalPlayer()
        if localPlayer.Controlling then
            localPlayer:SetNWBool("player_chair_mouse", isMouseActive)
        end
    end

    function ControlChair_Click(originEntity)
        local pilot = LocalPlayer()
        if (pilot.Controlling) then
            if (gui.MousePos()!=0) then
                t = util.TraceLine( util.GetPlayerTrace( pilot, gui.ScreenToVector(gui.MousePos()) ) )
                SendMessageToServer("nil",originEntity, "Chair_ClientClickToChair", t.Entity, t.HitPos)
            end
        end
    end

    function ControlCHCalcView(Player, Origin, Angles, FieldOfView)
        local view = {}
        local p = Player
        local self = p:GetNetworkedEntity("ScriptedVehicle", NULL)
        local chair = p:GetNWEntity("chair")
        if (not IsValid(chair) or self:GetClass() ~= "control_chair") then return end
        if IsValid(self) then
            if (not p:GetNWBool("player_chair_mouse",false)) then
                local pos = chair:GetPos() + Vector(0, 0, 100) - p:GetAimVector()*(math.Clamp(chair_zoom, 4, 400) *30)
                local face = ((chair:GetPos() + Vector(0, 0, 20)) - pos):Angle()

                self.ViewPos = pos
                self.ViewFace = face   
            end

            if (p:GetNWBool("player_chair_mouse",false)) then 
                p:SetNWVector("chairvec", self.ViewPos)
                p:SetNWVector("chairang", self.ViewFace)
            end

            view.origin = self.ViewPos
            view.angles = self.ViewFace
            view.fov = nil
            return view
        end
    end

    hook.Add("CalcView", "ControlCHCalcView", ControlCHCalcView)

    function ENT:DynLight()
        local p = LocalPlayer()
        local pos = self:GetPos() + self:GetUp() * 100
        local Chair_init = p:GetNWInt("chair_initialized")

        if (IsValid(self)) then
            if (Chair_init > 0) then
                if (StarGate.VisualsMisc("cl_chair_dynlights")) then
                    local dynlight = DynamicLight(self:EntIndex() + 4096)
                    dynlight.Pos = pos
                    if (Chair_init == 2) then
                        dynlight.Brightness = 10
                    else
                        dynlight.Brightness = 7
                    end
                    dynlight.Size = 184
                    dynlight.Decay = 1024
                    dynlight.R = 25
                    dynlight.G = 255
                    dynlight.B = 255
                    dynlight.DieTime = CurTime() + 2
                end
            end
        end
    end
end

if SERVER then
    if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("ship")) then return end
    AddCSLuaFile()

    util.AddNetworkString("controlchair_interact")
    util.AddNetworkString("controlchair_click")
    util.AddNetworkString("Chair_ClientClickToChair")

    util.PrecacheSound("thrusters/hover01.wav")
	util.PrecacheSound("ambient/explosions/exp2.wav")
	util.PrecacheSound("tech/hover01_end2.wav")

    ENT.Models = {
        Base = Model("models/soren/chair_zpm/chair_base_zpm.mdl"),
        Chair = Model("models/soren/drone_chair_v2/drone_chair_v2.mdl"),
        Base2 = Model("models/soren/soclseige_2/soclseige_2.mdl"),
        Base3 = Model("models/markjaw/drone_chair/chair_base_2.mdl")
    }

    ENT.Sounds = {
        Activate = Sound("tech/chair2.wav"),
        Activate2 = Sound("jumper/puddlestartup2.wav"),
        Activate3 = Sound("control_chair/chair_hologram.wav"),
        Deactivate = Sound("control_chair/chair_exit.wav"),
        Deactivate2 = Sound("tech/chair2_exit.wav")
    }

    function ENT:SpawnFunction(pl, tr)
        --if (not tr.HitWorld) then return end
        local e = ents.Create("control_chair")
        e:SetPos(tr.HitPos + Vector(0, 0, 10))
        local ang = pl:GetAimVector():Angle()
        ang.p = 0
        ang.r = 0
        ang.y = ang.y % 360
        e:SetAngles(ang)
        e:Spawn()
        e:Activate()

        e:AddChair(pl)
        e:AddZPMHub(pl)
        self.Owner = pl

        return e
    end

    function ENT:Initialize()
        self:SetModel(self.Models.Base)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        self.ActiveTime = 0
        --self:AddChair()
        self:CreateWireInputs("X", "Y", "Z", "Start X", "Start Y", "Start Z", "Entity [ENTITY]", "Vector [VECTOR]")
        self:CreateWireOutputs("X", "Y", "Z", "Vector [VECTOR]", "LitUp", "Active", "Secondary", "Stardrive Active")
        --############ Drone vars
        self.Target = Vector(0, 0, 0)
        self.DroneMaxSpeed = (8000)
        self.AllowAutoTrack = true
        self.AllowEyeTrack = false
        self.TrackTime = 1000000
        self.TargetClass = nil
        self.Drones = {}
        self.DroneCount = 0
        self.pilotPos = Vector(0,0,0)
        --########################
        self.PlayerTouching = nil
        self.RotateIsOn = true
        self.Debug = false
        self.EyeTrack = false
        self.Pressed = false
        self.Shield = nil
        self.AllowedPlayers = {};
        self.Strength = 100
        self.StrengthShield = 100
        self.ShieldColor = Vector(0, 255, 0)
        self.ShieldActive = false
        self.Ragdoll_Angle = 0
        self.Targets = {}
        self.Teststring = nil
        self.RotationSpeed = 0
        self.PilotViewing = false
        self.RequireATAGene = StarGate.CFG:Get("cap_enhanced_cfg","ATA_gene_active",false);
        self.LastCheckTime = 0
        --###### Energy Vars
        self:AddResource("energy", 1)

        if (self.HasRD) then
            self.ShouldConsume = true
        else
            self.ShouldConsume = false
        end

        self.CanActivate = true
        self.Antarticatype = false
        self.Atlantistype = false
        self.Socleseige_type = false

        if (self.Antarticatype) then
    		self:SetSkin(3)
        else
        	self:SetSkin(0)
        end

        self.NextUse = CurTime()
        self.FirePos = Vector(0, 0, 0)
        self.StartPos = self:GetPos() + self:GetForward() * -150
        self.LastSwitch = CurTime()
        local phys = self:GetPhysicsObject()

        if (phys:IsValid()) then
            phys:SetMass(20000)
            phys:Wake()
        end
    end

    function ENT:UpdateTarget(targetclass)
        self.TargetClass = targetclass
    end

    


    function ENT:Targetlist()
        if(IsValid(self.Targets)) then
    	    self.Target = self.Targets[1]:GetPos()
        end
    end


    function ENT:SwitchType()
    	if (self.Antarticatype) then
    		self:SetSkin(0)
    		self.Chair:SetSkin(0)

    		self.Antarticatype=false
    	else
    		self:SetSkin(3)
    		self.Chair:SetSkin(2)
    		self.Antarticatype=true
    	end
    end

    function ENT:AtlantisVersion()
    	if (self.Socleseige_type) then
            self:SetModel(self.Models.Base)
    		self:PhysicsInit(SOLID_VPHYSICS)
        	self:SetMoveType(MOVETYPE_VPHYSICS)
        	self:SetSolid(SOLID_VPHYSICS)
        	self:SetUseType(SIMPLE_USE)
    		local phys = self:GetPhysicsObject()
        	if (phys:IsValid()) then
            	phys:SetMass(20000)
            	phys:Wake()
        	end
    		self.Chair:SetParent(nil)
    		self.Chair:SetPos(self:GetPos() + self:GetUp() * 15)
    		self.Chair:SetAngles(self:GetAngles())
    		self.Chair:SetParent(self)
            self:AddZPMHub()
    		self.Socleseige_type=false    
    	elseif (self.Atlantistype) then
            if (IsValid(self.ZpmHub)) then self.ZpmHub:Remove() end
    		self:SetModel(self.Models.Base2)
    		self:PhysicsInit(SOLID_VPHYSICS)
        	self:SetMoveType(MOVETYPE_VPHYSICS)
        	self:SetSolid(SOLID_VPHYSICS)
        	self:SetUseType(SIMPLE_USE)
    		local phys = self:GetPhysicsObject()
        	if (phys:IsValid()) then
            	phys:SetMass(20000)
            	phys:Wake()
        	end
    		self.Chair:SetParent(nil)
    		self.Chair:SetPos(self:GetPos() + self:GetUp() * 9)
    		self.Chair:SetAngles(self:GetAngles())
    		self.Chair:SetParent(self)
            self.Atlantistype=false
    		self.Socleseige_type=true
        else
            if (IsValid(self.ZpmHub)) then self.ZpmHub:Remove() end
            self:SetModel(self.Models.Base3)
            self:PhysicsInit(SOLID_VPHYSICS)
            self:SetMoveType(MOVETYPE_VPHYSICS)
            self:SetSolid(SOLID_VPHYSICS)
            self:SetUseType(SIMPLE_USE)
            local phys = self:GetPhysicsObject()
            if (phys:IsValid()) then
                phys:SetMass(20000)
                phys:Wake()
            end
            self.Chair:SetParent(nil)
            self.Chair:SetPos(self:GetPos() + self:GetUp() * 15)
            self.Chair:SetAngles(self:GetAngles())
            self.Chair:SetParent(self)
            self.Atlantistype=true
    		
    	end
    end

    function ENT:Hit(strength, normal, pos)
    end


    function ENT:SearchForTargets(pos, targetlist)

    	local allTargets = ents.FindInSphere( self:GetPos(), 4000 )

    	for k,v in pairs(allTargets) do
    		
    		if (allTargets[k]:GetClass() == self.TargetClass) then
    			table.insert(targetlist,v)
    		end
    	end
    end

    function ENT:SpawnShield()
        if (shield_debounce) then return end
        shield_debounce = true
        local e = ents.Create("shield")
        e.Size = 200
        e.DrawBubble = true
        e:SetPos(self.Entity:GetPos())
        e:SetAngles(self.Entity:GetAngles())
        e:SetColor(Color(230, 230, 230, 255))
        e:SetParent(self.Entity)
        e:Spawn()
        e:SetNWBool("containment", false)
        e:DrawBubbleEffect()
        e:SetTrigger(true)
        self.Entity:EmitSound("shields/shield_engage.mp3", 90, math.random(90, 110))
        --this sound is part of a workshop addon so we should change it later
        self.ShieldActive = true

        if(e and e:IsValid() and not e.Disable) then -- When our new shield mentioned, that there is already a shield
			self.Shield = e;
			self:SetNoCollideWithAllowedPlayers();
		end
        shield_debounce = false
        return e
    end

    function ENT:SetNoCollideWithAllowedPlayers()
		if(self.AllowedPlayers ~= {}) then
			for _,ply in pairs(self.AllowedPlayers) do
				if IsValid(ply) and ply:IsPlayer() then
					if not self.Shield:IsContainment() then
						self.Shield.nocollide[ply] = true;
					else
						self.Shield.nocollide[ply] = false;
					end
				end
			end
		end
	end




    function ENT:HandleMessageFromClient(ply, originEntity, receiverEntityID, subject, ...)
        if not originEntity:GetClass() == self:GetClass() then print("error wrong sender") return end

        local data1 = select(1, ...)
        local data2 = select(2, ...)
        local data3 = select(3, ...)


        if subject == "ControlChair_Relay_from_client_target" then
            --print(data1)
            self:UpdateTarget(data1)
        elseif subject == "ToggleChairMode_Atlantis" then 

            local entity = data1
            if (util.IsValidModel("models/soclesiege.mdl")) then       
                ply:EmitSound( "buttons/button24.wav" )
                ply:SendLua( "GAMEMODE:AddNotify('Version Toggled', NOTIFY_GENERIC, 7);" )
                entity:AtlantisVersion()
            elseif (entity.Atlantistype) then
                ply:EmitSound( "buttons/button8.wav" )
                ply:SendLua( "GAMEMODE:AddNotify('Skipping chair version', NOTIFY_ERROR, 7);" )
                ply:SendLua( "GAMEMODE:AddNotify('Error: Client/server missing model: (soclesiege)', NOTIFY_ERROR, 7);" )
                entity:AtlantisVersion()
                entity:AtlantisVersion()
            else
                ply:EmitSound( "buttons/button24.wav" )
                ply:SendLua( "GAMEMODE:AddNotify('Version Toggled', NOTIFY_GENERIC, 7);" )
                entity:AtlantisVersion()
            end

        elseif subject == "ToggleChairMode" then 
                local entity = data1
                ply:EmitSound( "buttons/button24.wav" )
                ply:SendLua( "GAMEMODE:AddNotify('Type Toggled', NOTIFY_GENERIC, 7);" )
                entity:SwitchType()
        elseif subject == "Chair_ClientClickToChair" then
                self:ChairClickwire(data1,data2,ply)
        end


        -- if subject == "test2" then
        --     --print(originEntity)
        --     --print(receiverEntityID)
        --     if messageType == "string" then
        --         print("Received a string message:", data)
        --     elseif messageType == "int" then
        --         print("Received an integer message:", data)
        --     elseif messageType == "entity" then
        --         print("Received an entity message:", data)
        --     elseif messageType == "table" then
        --         print("Received a table message:", data)
        --     else
        --         print("Unhandled message type:", messageType)
        --     end
        -- else
        --     print("Unhandled subject:", subject)
        -- end

    end

    function ENT:RemoveShield()
        if (self.Shield:IsValid() and !shield_debounce) then
            shield_debounce = true
            self.Shield:DrawBubbleEffect(true)

            timer.Simple(1, function ()
                if (IsValid(self.Shield)) then
                    self.Shield.Strength = -1
                    self.Shield:Remove()
                    self.Shield = nil
                    self.ShieldActive = false
                    self:SetNetworkedBool("Shield_online",false)
                end
            end)
            self:EmitSound("shields/shield_disengage.mp3", 90, math.random(90, 110))
            shield_debounce = false

        end
    end

    function ENT:OnRemove()
        if (self.Pilot ~= nil) then
            self.Pilot:SetNWBool("Control",false)
            self.Pilot:SetNWBool("Controlling",false)
        end
        if (self.Controlling) then
            self:DeactivateChair(self.Pilot)
        end
        self:StopSound("tech/asgard_holo_loop.wav")
        if (self.Shield and self.Shield:IsValid()) then
            self.Shield:Remove()
        end
        if (IsValid(self.ZpmHub)) then
            self.ZpmHub:Remove()
        end
        self.Pilot = nil
        StarGate.WireRD.OnRemove(self)
        self:Remove()
        
    end

    function ENT:AddChair(p)
        local e = ents.Create("prop_physics")
        e:SetModel(self.Models.Chair)
        if (self:GetModel()=="models/soclesiege.mdl") then
        	e:SetPos(self:GetPos() + self:GetUp() * 9)
        else
        	e:SetPos(self:GetPos() + self:GetUp() * 15)
    	end
        e:SetAngles(self:GetAngles())
        e:Spawn()
        e:Activate()
        e:SetParent(self)

        if (self.Antarticatype) then
    		e:SetSkin(3)
    	else
        	e:SetSkin(0)
        end
        self.Chair = e
        self:SetNetworkedEntity("Chair", self.Chair)
        p:SetNWInt("chair_initialized", 0)

        if CPPI and IsValid(p) and e.CPPISetOwner then
            e:CPPISetOwner(p)
        end
    end

    function ENT:AddZPMHub(p)
        local e = ents.Create("chair_zpm_hub")
        e:SetModel("models/soren/zpm_slot/zpm_slot.mdl")
        e:SetPos(self:GetPos() + self:GetUp()*2 + self:GetRight()*-39.80 + self:GetForward()*-69.32)
        e:SetAngles(self:GetAngles())
        e:Spawn()
        e:Activate()
        e.Chair = self
        self.ZpmHub = e
        e:HubLink(self)
        if CPPI and IsValid(p) and e.CPPISetOwner then
            e:CPPISetOwner(p)
        end
        constraint.Weld(e,self.Entity,0,0,0,true);
    end

    function ENT:LowPriorityThink()
    	self.Strength = 100
    	if (self.Pressed == true) then
            timer.Simple(2, function()

                self.Pressed = false
            end)
        end
    end

    function ENT:Use(p)
        if (IsValid(self) and (not (self.Controlling))) then
            if (self.RequireATAGene) then
                if (p:GetNWInt('ATAGene', 0)==1) then
                    self:ActivateChair(p)
                end
            else
                self:ActivateChair(p)
            end
        end
    end

    function ENT:ActivateChair(p)
        if (self.ShouldConsume) then
            if (self:GetResource("energy")) > 500 then
                self.CanActivate = true
            else
                self.CanActivate = false
            end
        end

        if (self.CanActivate) then
            if (self.NextUse < CurTime()) then
                p:Spectate(OBS_MODE_CHASE)
                p:DrawWorldModel(false)
                p:DrawViewModel(false)
                --p:StripWeapons() --
            
                self.Pilot = p
                self:SpawnRagdoll()
                --p:SetScriptedVehicle(self)
                p:SetNetworkedEntity("ScriptedVehicle", self)
                p:SetViewEntity(self)
                p:SetEyeAngles(self.Chair:GetAngles())
                --p:SetNWBool("Control", true)
                p:SetNWEntity("chair", self.Chair)
                --self:EmitSound(self.Sounds.Activate,100,100)
                --self.Chair:SetSkin(1)
                self:ConsumeResource("energy", 500)
                self.Controlling = true
                
                
                self.ActiveTime = 0
                self.NextUse = CurTime() + 1
                self.Nextthink = true
            end
        end
    end

    function ENT:DeactivateChair(p)
        if (self.Pilot) then
            self.Pilot:SetNWBool("Control",false)

            if (self:GetResource("energy") < 500) then
                self.Pilot:SetNWInt("chair_initialized", 0)
            else
                self.Pilot:SetNWInt("chair_initialized", 1)
            end
        end

        self.Pilot:UnSpectate()
        self.Pilot:DrawWorldModel(true)
        self.Pilot:DrawViewModel(true)

        self.Pilot:SetNetworkedEntity("ScriptedVehicle", NULL)
        self.Pilot:SetViewEntity(NULL)
        if (p:Alive()) then
            self.Pilot:Spawn()
            self.Pilot:SetParent()
            self.Pilot:SetPos(self:GetPos() + self:GetRight() * 60 + self:GetUp() * 20)
        else
            self.Pilot:SetPos(self:GetPos() + self:GetRight() * 60 + self:GetUp() * 20)
        end

        if (IsValid(self.Chair)) then
            if (self.Antarticatype) then
    			self.Chair:SetSkin(2)
    		else
        		self.Chair:SetSkin(0)
        	end
        end

        self.PilotViewing = false
        self.Pilot:SetNWBool("Chair_viewing",false)
        SendMessageToClient(self.Pilot, self, "controlchair_interact",false)

        self.Pilot:SetParent()
        self.Pilot:SetNWEntity("chair", NULL)
        self:SupplyResource("energy", 500)
        self.Ragdoll:Remove()
        self.Controlling = false
        self.NextUse = CurTime() + 3
        self.Nextthink = false
        self.Enabled = false
        firstsound = false
    end
    function ENT:ChairClickwire(ChairclickT,clickposition,player)

        local inputs = WireLib.GetPorts(ChairclickT)
        local alt = player:KeyDown(IN_SPEED)

        local Controlchair = player:GetNWEntity("chair",NULL):GetParent()

        --Controlchair:RelayToHud(inputs,player)

        local playernumber = player:GetNWInt("ChairWireNumber",0)

        if ChairclickT:GetClass() == "cap_doors_frame" then
             for i=1,#inputs do
             end
            --print(self:GetPorts(ChairclickT))
            ChairclickT:TriggerInput(inputs[1][1],1)
        elseif (istable(inputs)) then
            
            --print(inputs[1][1].." :"..inputs[1][2])
            if (playernumber == 0) then

               --self.Entity:RelayToHud(inputs,player)

                --self.Entity:SetNWBool("DisplayHud",true)

                 for i=1,# inputs do
                  -- PrintTable(inputs[1][1])
                   --print(i..": "..inputs[i][1])
                   --print(i..": "..inputs[i][1].." - "..inputs[i][2])

                 end
            else
                if alt then ChairclickT:TriggerInput(inputs[playernumber][1],0) else ChairclickT:TriggerInput(inputs[playernumber][1],1) end
            end
        else
            Controlchair.Target = clickposition
        end
    end

    function ENT:RelayToHud(inputtable,ply)

        --SendMessageToClient(ply,self,"Chair_DisplayInputs",inputtable)
        
        -- net.start("Chair_DisplayInputs")
        --     net.WriteTable(inputtable)
        -- net.Send(ply)
    end

    hook.Add( "PlayerButtonDown", "ChairWirePlayerButtonDown", function( ply, button )
        
        if (ply:GetNWBool("Chair_viewing",true)) then
            
            if button == 2 then 
                ply:SetNWInt("ChairWireNumber",1)
            elseif button == 3 then 
                ply:SetNWInt("ChairWireNumber",2)
            elseif button == 4 then 
                ply:SetNWInt("ChairWireNumber",3)
            elseif button == 5 then 
                ply:SetNWInt("ChairWireNumber",4)
            elseif button == 6 then 
                ply:SetNWInt("ChairWireNumber",5)
            elseif button == 7 then 
                ply:SetNWInt("ChairWireNumber",6)
            elseif button == 8 then 
                ply:SetNWInt("ChairWireNumber",7)
            elseif button == 9 then 
                ply:SetNWInt("ChairWireNumber",8)
            elseif button == 10 then 
                ply:SetNWInt("ChairWireNumber",9)
            elseif button == 11 then 
                ply:SetNWInt("ChairWireNumber",10)
            end

            if CLIENT and not IsFirstTimePredicted() then
                return
            end
        else return end
    end)


    hook.Add( "PlayerButtonUp", "ChairWirePlayerButtonUp", function( ply, button )
        
        if (ply:GetNWBool("Chair_viewing",true)) then
            if button == 2 then 
                ply:SetNWInt("ChairWireNumber",0)
            elseif button == 3 then 
                ply:SetNWInt("ChairWireNumber",0)
            elseif button == 4 then 
                ply:SetNWInt("ChairWireNumber",0)
            elseif button == 5 then 
                ply:SetNWInt("ChairWireNumber",0)
            elseif button == 6 then 
                ply:SetNWInt("ChairWireNumber",0)
            elseif button == 7 then 
                ply:SetNWInt("ChairWireNumber",0)
            elseif button == 8 then 
                ply:SetNWInt("ChairWireNumber",0)
            elseif button == 9 then 
                ply:SetNWInt("ChairWireNumber",0)
            elseif button == 10 then 
                ply:SetNWInt("ChairWireNumber",0)
            elseif button == 11 then 
                ply:SetNWInt("ChairWireNumber",0)
            end

            if CLIENT and not IsFirstTimePredicted() then
                return
            end
        else return end
    end)




    function ENT:Think()
        local curTime = CurTime()
        if curTime >= self.LastCheckTime + 1 then
            -- Run the player detection code every 1 second
            local radius = 128
            local foundPlayer = false
            
            local entities = ents.FindInSphere(self:GetPos(), radius)
            
            for _, ent in ipairs(entities) do
                if IsValid(ent) and ent:IsPlayer() then
                    if self.RequireATAGene and ent:GetNWInt('ATAGene', 0) ~= 1 then
                        continue
                    end
                    
                    if self.ShouldConsume and self:GetResource("energy") < 200 then
                        continue
                    end
                    
                    self.PlayerTouching = ent
                    self:SetWire("LitUp", 1)
                    self.PlayerTouching:SetNWInt("chair_initialized", 1)
                    
                    if not self.firstsound then
                        self:EmitSound("chair_sound_v2", 100, 10, 1)
                        self:EmitSound(self.Sounds.Activate2, 120, 70)
                        self:EmitSound(self.Sounds.Activate2, 120, 70)
                        self.firstsound = true
                    end
    
                    if self.Antarticatype then
                        self:SetSkin(4)
                    else
                        self:SetSkin(1)
                    end
                    
                    self.ChairActive = true
                    self.Touching = true
                    foundPlayer = true
                    break
                end
            end
            if not foundPlayer then

                self.Touching = false
                --self.ChairActive = false
                --self:SetWire("LitUp", 0)
                self.firstsound = false
            end
            
            self.LastCheckTime = curTime
        end



        if (IsValid(self.Pilot)) then
            umsg.Start("ControlChair", self.Pilot)
            umsg.Bool(self.Controlling)
            umsg.Bool(self.Enabled)
            umsg.Short(self.DroneCount)
            umsg.Entity(self.Chair)
            umsg.End()
        end

        if (self.ShieldActive) then
            if not StarGate.LifeSupportAndWire == nil then
            	if (self:GetResource("energy") < 100) then
                    self:SetNetworkedBool("Shield_online",false)
            		self.Entity:RemoveShield()
            		self:StopSound("tech/asgard_holo_loop.wav")
            	end
            	self:ConsumeResource("energy", 3000)
            end
        end

        if (self.ChairActive == false) then
        	self:StopSound("tech/asgard_holo_loop.wav")
        end


        if (self.ChairActive) then
            if (self.ShouldConsume) then
                if (self:GetResource("energy") < 100) then
                    self:Anims("close")
                    if (self.Shield and self.Shield:IsValid()) then
                        self.Entity:RemoveShield()
                    end   
                    self.ActiveTime = 180
                    if (self.Controlling) then
                        self.Pilot:SetNetworkedBool("Control",false)
                    	self:EmitSound(self.Sounds.Deactivate2, 100, 120)
                    self:EmitSound(self.Sounds.Deactivate2, 100, 120)
                    	self.PlayerTouching:SetNWInt("chair_initialized", 0)
                        self:DeactivateChair(self.Pilot)
                        self:StopSound("tech/asgard_holo_loop.wav")
                        --self:StopSound("tech/asgard_holo_loop.wav")
                        self:EmitSound(self.Sounds.Deactivate, 100, 60)
                        self:EmitSound(self.Sounds.Deactivate, 100, 60)
                        self:EmitSound(self.Sounds.Deactivate, 100, 60)
                 		self:StopSound("thrusters/hover01.wav")
                    end

                    self:SetWire("Active", 0)
                    self:SetWire("Stardrive Active", 0)
                    self:SetWire("LitUp", 0)

                    if (self.Antarticatype) then
            		self:SetSkin(3)
            	else
                	self:SetSkin(0)
                end
                    return
                end

                self:ConsumeResource("energy", 300)
            end
        end

        if (self.Controlling) then
            if (self.Enabled) then
                self:SetWire("Active", 1)

                if (self.RotateIsOn) then
                    self.RotationSpeed = math.Clamp(self.RotationSpeed + 0.01, 0, 0.3)
                else
                    self.RotationSpeed = math.Clamp(self.RotationSpeed - 0.01, 0, 0.3)
            	end

                if (self.RotationSpeed >0) then
                local a = self.Chair:GetAngles()
                    a:RotateAroundAxis(self:GetUp(), self.RotationSpeed)
                    self.Chair:SetAngles(a)
                end

                self:ConsumeResource("energy", 200)

            end
        end

        if (self.Controlling and IsValid(self.Pilot)) then
            if (self.Pilot:KeyDown(IN_FORWARD)) then
                if (self.Enabled) then
                    
                    --self.RotateIsOn = false
                    self.RotationSpeed = 0
                	if (self.Antarticatype) then
    				self.Chair:SetSkin(2)
    				else
        			self.Chair:SetSkin(0)
        			end
                    self.Pilot:SetNWInt("chair_initialized", 1)
                    self.Pilot:SetNetworkedBool("Control",false)
                	self:EmitSound(self.Sounds.Deactivate2, 100, 120)
                    self:EmitSound(self.Sounds.Deactivate2, 100, 120)
                    --self:StopSound("tech/asgard_holo_loop.wav")
                    self:Anims("close")
                    self:SetWire("Active", 0)
                    self:SetWire("Stardrive Active", 0)
                end
            elseif (self.Pilot:KeyDown(IN_BACK)) then
                if (not (self.Enabled)) then
                    self.Pilot:SetNWInt("chair_initialized", 2)
                	if (self.Antarticatype) then
    				self.Chair:SetSkin(3)
    				else
        			self.Chair:SetSkin(1)
        			end
                    self.Pilot:SetNetworkedBool("Control",true)
                    self:EmitSound(self.Sounds.Activate, 100, 100)
                    self:EmitSound(self.Sounds.Activate, 100, 100)
                    
                    self:Anims("open")
                    self:ConsumeResource("energy", 6000)
                end
            elseif (self.Pilot:KeyPressed(IN_MOVERIGHT)) then
                if (self.Pressed == false) then
                    self.Pressed = true
                	if (not self.Shield and self.StrengthShield == 100) then
                        self.Shield = self.Entity:SpawnShield()
                        self:SetNetworkedBool("Shield_online",true)
                    elseif (self.Shield and self.Shield:IsValid()) then
                        self:SetNetworkedBool("Shield_online",false) 
                        self.Entity:RemoveShield() 
                    end
                    timer.Simple(1, function() self.Pressed = false end)
                end
            elseif (self.Pilot:KeyPressed(IN_RELOAD)) then
                 	if ( not self.RotateIsOn) then
                 		self.RotateIsOn = true
                        self:SetNetworkedBool("Rotate",true)
                 	else
                 		self.RotateIsOn = false
                        self:SetNetworkedBool("Rotate",false)
                 	end
            elseif (self.Pilot:KeyPressed(IN_JUMP)) then
            		self:EmitSound("thrusters/hover01.wav",100,80)
            		self:EmitSound("ambient/explosions/exp2.wav",100,80)
            elseif (self.Pilot:KeyDown(IN_JUMP)) then
            		self:ConsumeResource("energy", 5000)
                    self:SetWire("Stardrive Active", 1)
            elseif (self.Pilot:KeyReleased(IN_JUMP)) then
                    self:SetWire("Stardrive Active", 0)
            		self:EmitSound("tech/hover01_end2.wav",100,80)
                 	self:StopSound("thrusters/hover01.wav")
                 	self:StopSound("thrusters/hover01.wav")
                 	self:StopSound("thrusters/hover01.wav")
            end
        end

        hook.Add( "PlayerButtonDown", "ControlChair_TargetMenu", function( ply, button )
        	if (self.Controlling and IsValid(self.Pilot) and self.Pilot == ply) then
				if (button == 2 and self.Debug and not self.PilotViewing ) then
                    SendMessageToClient(self.Pilot, self, "controlchair_targetmenu_v2", self.Targets)
				end
			end
		end)

        hook.Add( "PlayerButtonDown", "ControlChair_interact_on", function( ply, button )
            if (self.Controlling and IsValid(self.Pilot) and self.Pilot == ply) then
                if (button == 13) then
                    ply:SetNWBool("Chair_viewing",true)
                    self.PilotViewing = true
                    SendMessageToClient(self.Pilot, self, "controlchair_interact",true)
                    -- net.Start("controlchair_interact")
                    -- net.WriteBool(true)
                    -- net.Send(ply)
                end
            end
        end)
        hook.Add( "PlayerButtonUp", "ControlChair_interact_off", function( ply, button )
            if (self.Controlling and IsValid(self.Pilot) and self.Pilot == ply) then
                if (button == 13) then
                    self.PilotViewing = false
                    ply:SetNWBool("Chair_viewing",false)
                    SendMessageToClient(self.Pilot, self, "controlchair_interact",false)
                    -- net.Start("controlchair_interact")
                    -- net.WriteBool(false)
                    -- net.Send(ply)
                end
            end
        end)

        -- Click functions wiremod


        -- hook.Add( "PlayerButtonDown", "Hook_ControlChair_wireclick", function( ply, button )
        --     if (self.Controlling and IsValid(self.Pilot) and self.Pilot == ply) then
        --         if (button == 1 ) then
        --             net.Start("controlchair_click")
        --                 net.WriteInt(1,32)
        --                 net.Send(self.Pilot)
        --         end
        --     end
        -- end)

        ----------------------
        if (self.Pilot and self.Pilot == nil) then
            if (self.Controlling) then
                self:Anims("close")
                if (self.Shield and self.Shield:IsValid()) then
                    self.Entity:RemoveShield()
                end            
                self:DeactivateChair(self.Pilot)
                self.Pilot:SetNWInt("chair_initialized", 0)
                if (self.Antarticatype) then
                    self:SetSkin(3)
                else
                    self:SetSkin(0)
                end
                self:SetWire("LitUp", 0)
                self:SetWire("Stardrive Active", 0)
                self:StopSound("tech/asgard_holo_loop.wav")
                self:EmitSound(self.Sounds.Deactivate, 100, 60)
                self:EmitSound(self.Sounds.Deactivate, 100, 60)
                self:EmitSound(self.Sounds.Deactivate, 100, 60)
                self:StopSound("thrusters/hover01.wav")
                self.Pilot = nil
            end
        end
        if (self.ShouldConsume) then
            if (self:GetResource("energy") < 500) then
                if (self.Controlling) then
                    self:Anims("close")
                    if (self.Shield and self.Shield:IsValid()) then
                        self.Entity:RemoveShield()
                    end            
                    self:DeactivateChair(self.Pilot)
                    self.Pilot:SetNWInt("chair_initialized", 0)
                    if (self.Antarticatype) then
            			self:SetSkin(3)
            		else
                		self:SetSkin(0)
                	end
                    self:SetWire("LitUp", 0)
                    self:SetWire("Stardrive Active", 0)
                    self:StopSound("tech/asgard_holo_loop.wav")
                    self:EmitSound(self.Sounds.Deactivate, 100, 60)
                    self:EmitSound(self.Sounds.Deactivate, 100, 60)
                    self:EmitSound(self.Sounds.Deactivate, 100, 60)
                 	self:StopSound("thrusters/hover01.wav")
                end
            end
        end

        if (self.ChairActive) then
            if (not (self.Controlling)) then
                self.ActiveTime = math.Approach(self.ActiveTime, 180, 10)

            end
        end

        if (self.Controlling) then
            self:ConsumeResource("energy", 200)

            if (self:GetSkin() < 1) then
                self:SetSkin(1)
            end
        end

        if (self.Controlling and IsValid(self.Pilot)) then
            if (self.Pilot:KeyDown(IN_USE)) then
                if (self.NextUse < CurTime()) then
                    if self.Enabled then
                        self:Anims("close")
                    end

                    --self:SetSkin(0)
                    --self:SetWire("LitUp",0)
                    self:SetWire("Active", 0)
                    self.Pilot:SetNetworkedBool("Control",false)
                    --self:StopSound("tech/asgard_holo_loop.wav")
                    self:EmitSound(self.Sounds.Deactivate, 100, 90)
                    self:EmitSound(self.Sounds.Deactivate, 100, 90)
                    self:EmitSound(self.Sounds.Deactivate, 100, 90)
                 	self:StopSound("thrusters/hover01.wav")

                    --self.ChairActive=false
                    if (self.Controlling) then
                        self:DeactivateChair(self.Pilot)
                    end
                end
            end
        end

        if (self.ActiveTime) >= 180 then
            if ((not (self.Touching)) and (not (self.Controlling))) then
            	self.PlayerTouching:SetNWInt("chair_initialized", 0)
            	if (self.Antarticatype) then
            		self:SetSkin(3)
            	else
                	self:SetSkin(0)
                end
                self:StopSound("tech/asgard_holo_loop.wav")
                self:EmitSound(self.Sounds.Deactivate, 100, 70)
                self:EmitSound(self.Sounds.Deactivate, 100, 70)
                self:EmitSound(self.Sounds.Deactivate, 100, 70)
                firstsound = false
                self:SetWire("LitUp", 0)
                self:SetWire("Stardrive Active", 0)
                self.ChairActive = false
                self.ActiveTime = 0
            end
        end

        if (IsValid(self.Pilot)) then
            if (self.Controlling) then
                if (IsValid(self.ZpmHub)) then
                    self:SetNetworkedString("ZPM_Online",self.ZpmHub.ZPM_Active)
                    self:SetNetworkedInt("ZPM_Percentage",self.ZpmHub.ZPM_Percentage)
                end
                if (self:GetResource("energy") >= 1) then
                    self:SetNetworkedInt("Internal_Source",self:GetResource("energy") > 0 and 1 or 0)
                    local max = self:GetUnitCapacity("energy")
                    local percent = math.Clamp(self:GetResource("energy") / max, 0, 1) * 100
                    self:SetNetworkedInt("Internal_Percentage",percent)
                end

                self:ConsumeResource("energy", 5 * self.DroneCount)
            	self.Track = true
                if (self.Pilot:KeyDown(IN_ATTACK)) then
                    if (not self.PilotViewing) then
                        self:FireDrones()
                    end

                end

                if (self.Pilot:KeyPressed(IN_ATTACK)) then
                    if (self.PilotViewing and self.Debug) then
                        SendMessageToClient(self.Pilot,self,"controlchair_click")
                        -- net.Start("controlchair_click")
                        -- net.Send(self.Pilot)
                    end
                end
                if (self.Pilot:KeyDown(IN_ATTACK2)) then
                    self:SetWire("Secondary", 1)
                    self:Targetlist()
                    --self.Track = true
                else
                    self:SetWire("Secondary", 0)
                    --self.Track = false
                end
            else
            	self.Track = false
            end
        end

        self.FirePos = Vector(self.StartPos.X, self.StartPos.Y, self.StartPos.Z)

        if (self.Nextthink) then
            self:NextThink(CurTime())

            return true
        end

        self:SetWire("X", self.Target.x)
        self:SetWire("Y", self.Target.y)
        self:SetWire("Z", self.Target.z)
        self:SetWire("Vector", self.Target)
    end

    --######### Fire aVoN's type of drones @RononDex
    function ENT:FireDrones()
        if (self.DroneCount < 16) then
                
            local vel = self:GetVelocity()
            --calculate the drone's position offset. Otherwise it might collide with the launcher
            local e = ents.Create("drone")
            e.Parent = self
            e:SetPos(self.FirePos)
            e:SetAngles(Angle(-90, 0, 0))
            e:SetOwner(self) -- Don't collide with this thing here please
            e.Owner = self.Owner
            e:Spawn()
            e:SetVelocity(vel)
            self.DroneCount = self.DroneCount + 1
            self.Drones[e] = true
            self.Drone = e
        end
    end

    --###### Dummy function for drones
    function ENT:ShowOutput()
    end

    --#########Add the wire inputs @ RononDex
    function ENT:TriggerInput(k, v)
        if (not self.EyeTrack and k == "X") then
            self.PositionSet = true
            self.Target.x = v
        elseif (not self.EyeTrack and k == "Y") then
            self.PositionSet = true
            self.Target.y = v
        elseif (not self.EyeTrack and k == "Z") then
            self.PositionSet = true
            self.Target.z = v
        end

        if (k == "Vector") then
            self.Target = v
        end

        if (k == "Start X") then
            self.StartPos.X = v
        elseif (k == "Start Y") then
            self.StartPos.Y = v
        elseif (k == "Start Z") then
            self.StartPos.Z = v
        end
    end

    function ENT:Anims(anim)
        if (IsValid(self) and IsValid(self.Chair)) then
            if self.Enabled and anim == "open" then return end

            if not self.Enabled and anim == "close" then return end

            if (anim == "close") then
                self:Lean(false)
                self.Enabled = false
            elseif (anim == "open") then
                self:Lean(true)
                self.Enabled = true
            end
            self.Anim = self.Chair:LookupSequence(anim)
            self.Chair:SetCycle(0) -- Start from the beginning of the animation
            self.Chair:ResetSequenceInfo()
            self.Chair:SetSequence(self.Anim)
            local animlen = 10
            -- Set up a timer to advance frames
            timer.Create("AnimationTimer", 0.01, math.ceil(animlen / 000.1), function()
                if IsValid(self) and IsValid(self.Chair) then
                    self.Chair:SetCycle(self.Chair:GetCycle() + 000.1 / animlen)
                else
                    timer.Remove("AnimationTimer")
                end
            end)
            
            
        end
    end



    function ENT:Lean(active)
        local pelvis = "ValveBiped.Bip01_Pelvis"
        local L_thigh = "ValveBiped.Bip01_L_Thigh"
        local R_thigh = "ValveBiped.Bip01_R_Thigh"
        local L_calf = "ValveBiped.Bip01_L_Calf"
        local R_calf = "ValveBiped.Bip01_R_Calf"

        local L_upperarm = "ValveBiped.Bip01_L_UpperArm"
        local R_upperarm = "ValveBiped.Bip01_R_UpperArm"
        local L_forarm = "ValveBiped.Bip01_L_Forearm"
        local R_forarm = "ValveBiped.Bip01_R_Forearm"


        if (active) then
            
            local bonetomove = self.Ragdoll:LookupBone(pelvis)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, 0, -30))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(L_thigh)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -60, 0))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(R_thigh)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -60, 0))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(L_calf)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, 50, 0))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(R_calf)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, 50, 0))  -- Tilt the pelvis backward
            end
            
            local bonetomove = self.Ragdoll:LookupBone(L_upperarm)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -15, 0))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(R_upperarm)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -15, 0))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(L_forarm)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -75, 0))  -- Tilt the pelvis backward
                self.Ragdoll:ManipulateBonePosition(bonetomove, Vector(8,8 , 0),true)
            end

            local bonetomove = self.Ragdoll:LookupBone(R_forarm)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -75, 0))  -- Tilt the pelvis backward
                self.Ragdoll:ManipulateBonePosition(bonetomove, Vector(8,8 , 0),true)
            end

        else

            local bonetomove = self.Ragdoll:LookupBone(pelvis)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, 0,0 ))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(L_thigh)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -90, 0))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(R_thigh)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -90, 0))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(L_calf)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, 90, 0))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(R_calf)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, 90, 0))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(L_upperarm)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -35, 0))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(R_upperarm)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -35, 0))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(L_forarm)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -55, 0))  -- Tilt the pelvis backward
                self.Ragdoll:ManipulateBonePosition(bonetomove, Vector(4,4 , 0),true)
            end

            local bonetomove = self.Ragdoll:LookupBone(R_forarm)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -55, 0))  -- Tilt the pelvis backward
                self.Ragdoll:ManipulateBonePosition(bonetomove, Vector(4,4 , 0),true)
            end

        end
    end


--####### Spawn the ragdoll @RononDex
function ENT:SpawnRagdoll()

	if(IsValid(self)) then
		if(IsValid(self.Pilot)) then

        local offset = Vector(7.5, 0, -15)
        local chairAngles = self.Chair:GetAngles()
        
        -- Convert angles to radians
        local radPitch = math.rad(chairAngles.p)
        local radYaw = math.rad(chairAngles.y)
        local radRoll = math.rad(chairAngles.r)

        -- Calculate rotated offset
        local rotatedOffset = Vector(
            offset.x * math.cos(radYaw) - offset.y * math.sin(radYaw),
            offset.x * math.sin(radYaw) + offset.y * math.cos(radYaw),
            offset.z
        )

			local e = ents.Create("prop_dynamic")
			e:SetModel(self.Pilot:GetModel())
			e:SetPos(self.Chair:GetPos() + rotatedOffset)
			e:SetAngles(self.Chair:GetAngles()+Angle(0,180,0))

			e:Spawn()
			e:Activate()
			e:SetParent(self.Chair)
            --e:SetCollisionGroup(COLLISION_GROUP_NONE)

			--constraint.Weld(e,self.Chair,0,0,0,true)
			self.Ragdoll=e
			--self:RagdollPose()
            
            local L_thigh = "ValveBiped.Bip01_L_Thigh"
            local R_thigh = "ValveBiped.Bip01_R_Thigh"
            local L_calf = "ValveBiped.Bip01_L_Calf"
            local R_calf = "ValveBiped.Bip01_R_Calf"
            local L_upperarm = "ValveBiped.Bip01_L_UpperArm"
            local R_upperarm = "ValveBiped.Bip01_R_UpperArm"
            local L_forarm = "ValveBiped.Bip01_L_Forearm"
            local R_forarm = "ValveBiped.Bip01_R_Forearm"
            
            local bonetomove = self.Ragdoll:LookupBone(L_thigh)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -90, 0))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(R_thigh)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -90, 0))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(L_calf)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, 90, 0))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(R_calf)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, 90, 0))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(L_upperarm)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -35, 0))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(R_upperarm)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -35, 0))  -- Tilt the pelvis backward
            end

            local bonetomove = self.Ragdoll:LookupBone(L_forarm)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -55, 0))  -- Tilt the pelvis backward
                self.Ragdoll:ManipulateBonePosition(bonetomove, Vector(4,4 , 0),true)
            end

            local bonetomove = self.Ragdoll:LookupBone(R_forarm)
            if bonetomove then
                self.Ragdoll:ManipulateBoneAngles(bonetomove, Angle(0, -55, 0))  -- Tilt the pelvis backward
                self.Ragdoll:ManipulateBonePosition(bonetomove, Vector(4,4 , 0),true)
            end

		end
	end
end

--############## This is what puts the ragdoll into the right pose @RononDex
    function ENT:RagdollPose()


    	-- for i = 0, self.Ragdoll:GetPhysicsObjectCount() - 1 do
    	-- 	local phys = self.Ragdoll:GetPhysicsObjectNum( i )
    	-- 	phys:EnableCollisions(false)
    	-- end

    	local chest = self.Ragdoll:GetPhysicsObjectNum(1)
    	--chest:EnableMotion(false)
    	chest:SetPos(self.Chair:GetPos()+self.Chair:GetUp()*290)


    	chest:SetAngles(self:GetAngles()+Angle(0,-45,0))
    	chest:SetAngles(self.Chair:GetAngles())

    	local pelvis = self.Ragdoll:GetPhysicsObjectNum(0)
    	--pelvis:EnableMotion(false)
    	pelvis:SetPos(self.Chair:GetPos())

    	local lthigh = self.Ragdoll:GetPhysicsObjectNum(11)
    	--lthigh:EnableMotion(false)
    	lthigh:SetPos(self.Chair:GetPos()+self:GetRight()*-10+self:GetUp()*25)

    	local lfoot = self.Ragdoll:GetPhysicsObjectNum(13)
    	--lfoot:EnableMotion(false)
    	--lfoot:SetPos(self.Chair:GetPos()+self.Chair:GetForward()*25+self.Chair:GetRight()*-10)

    	local rfoot = self.Ragdoll:GetPhysicsObjectNum(14)
    	--rfoot:EnableMotion(false)
    	--rfoot:SetPos(self.Chair:GetPos()+self.Chair:GetForward()*25+self.Chair:GetRight()*10)
    end

    function ENT:LookupBones()
        local bones = self.Ragdoll:LookupBone("ValveBiped.Bip01_L_Foot")
    end

    
    function ENT:PostEntityPaste(ply, Ent, CreatedEntities)
        if (StarGate.NotSpawnable(Ent:GetClass(), ply)) then
            self.Entity:Remove()

            return
        end

        self:AddChair(ply)
        self:AddZPMHub()
        StarGate.WireRD.PostEntityPaste(self, ply, Ent, CreatedEntities)
    end

    if (StarGate and StarGate.CAP_GmodDuplicator) then
        duplicator.RegisterEntityClass("control_chair", StarGate.CAP_GmodDuplicator, "Data")
    end
end


properties.Add( "Stargate.Controlchair.DoAntartica",
{
	MenuLabel	=	"Toggle Type",
	Order		=	-100,
	MenuIcon	=	"icon16/plugin_go.png",

	Filter		=	function( self, ent, ply )
						if ( !IsValid( ent ) || !IsValid( ply )) then return false end
						if (not ent:GetClass()=="control_chair") then return false end
						
						if (ent:GetClass()=="control_chair") then
						return true
					end

					end,

	Action		=	function( self, ent )
                        SendMessageToServer(self,ent,"ToggleChairMode",ent)				
						self:MsgEnd()
					end,

	Receive		=	function( self, length, player )

						--player:ChatPrint("Chair type toggled")
						--player:EmitSound( "buttons/button15.wav" )
					end

});

properties.Add( "Stargate.Controlchair.DoAtlantis",
{
	MenuLabel	=	"Toggle Version",
	Order		=	-100,
	MenuIcon	=	"icon16/plugin_go.png",

	Filter		=	function( self, ent, ply )
						if ( !IsValid( ent ) || !IsValid( ply )) then return false end
						if (not ent:GetClass()=="control_chair") then return false end
						
						if (ent:GetClass()=="control_chair") then
						return true
					end

					end,

	Action		=	function( self, ent )
                        SendMessageToServer(self,ent,"ToggleChairMode_Atlantis",ent)
						
                        -- net.Start("ToggleChairMode_Atlantis")
						-- net.WriteEntity(ent)
						-- net.SendToServer()
							
						self:MsgEnd()
					end,

	Receive		=	function( self, length, player )

						--player:ChatPrint("Chair type toggled")
						--player:EmitSound( "buttons/button15.wav" )
					end

});




if CLIENT then


    surface.CreateFont("Font", {
    font = "Arial",
    extended = true,
    size = 20
    })

    function TargetControlMenu(ent, targets)
        local faded_blue = Color(0, 100, 180, 200)
        local Frame = vgui.Create("DFrame")
        Frame:SetPos(50, 50)
        Frame:SetSize(500, 750)
        Frame:SetTitle("ControlChair: Targetmenu")
        Frame:SetVisible(true)
        Frame:SetDraggable(true)
        Frame:ShowCloseButton(true)
        Frame:MakePopup()

        local sheet = vgui.Create("DPropertySheet", Frame)
        sheet:Dock(FILL)

        local panel1 = vgui.Create("DPanel", sheet)
        panel1.Paint = function(self, w, h) draw.RoundedBox(4, 0, 0, w, h, faded_blue) end
        sheet:AddSheet("Target System", panel1, "icon16/asterisk_orange.png")

        local NameEntry = vgui.Create("DTextEntry", panel1)
        NameEntry:SetPos(25, 50)
        NameEntry:SetSize(85, 35)
        NameEntry:SetText("Target class")
        NameEntry.OnEnter = function(self)
            SendToChair(self:GetValue(), ent)
        end

        local panel2 = vgui.Create("DPanel", sheet)
        panel2.Paint = function(self, w, h) draw.RoundedBox(4, 0, 0, w, h, faded_blue) end
        sheet:AddSheet("Wiring", panel2, "icon16/bullet_wrench.png")

        local SheetItemTwo = vgui.Create("DCheckBoxLabel", panel2)
        SheetItemTwo:SetText("Toggle wire?")
        SheetItemTwo:SetConVar("CChair_togglewire")
        SheetItemTwo:SetValue(0)
        SheetItemTwo:SizeToContents()
    end



	function SendToChair (value, entity)

        SendMessageToServer(self, entity, "ControlChair_Relay_from_client_target",value )


		-- net.Start("ControlChair_Relay_from_client_target")
        -- net.WriteEntity(entity)
		-- net.WriteString(value)
		-- net.SendToServer()
	end
end


