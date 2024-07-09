if (StarGate ~= nil and StarGate.LifeSupportAndWire ~= nil) then
    StarGate.LifeSupportAndWire(ENT)
end

ENT.Type = "anim"
ENT.Base = "base_anim" --gmodentity
ENT.PrintName = "Asgard ion generator"
ENT.Author = "Soren , god mode"
ENT.WireDebugName = "Asgard ion generator"

--ENT.Category = "Stargate Carter Addon Pack: MoonWatcher"
--list.Set("CAP.Entity", ENT.PrintName, ENT)
--ENT.Category = "MoonWatcher"

ENT.Untouchable = false
ENT.Spawnable = false
ENT.AdminSpawnable = false

if SERVER then
	if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("energy")) then return end
    AddCSLuaFile()

    function ENT:Initialize()
        if (not util.IsValidModel("models/lordtrilobite/starwars/props/bactatank.mdl")) then
            self.Entity:SetModel("models/MarkJaw/naquadah_generator.mdl")
        else
            self.Entity:SetModel("models/lordtrilobite/starwars/props/bactatank.mdl")
        end
        self.Entity:PhysicsInit(SOLID_VPHYSICS)
        self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
        self.Entity:SetSolid(SOLID_VPHYSICS)
        self.Entity:DrawShadow(true)
        self.Entity:SetSkin(2)
        self:AddResource("energy",10000)
        self:SetSkin(4)
        self.OnAllowed = true
        self.OffAllowed = false
        self.Active = false
        self.EntHealth = 100
        self.MaxHealth = self.EntHealth
        self.Online = false
        self.AC_on = false
        self.Effect_time = 0
        self.PowerLevel = 0
        self.Particle_Time = 0
        self.Debug = false
        --if (self.Debug) then
            self:CreateWireInputs("Activate", "Mute", "Disable Use", "Powerlevel")
            self:CreateWireOutputs("Health")
            self:SetWire("Health", self.EntHealth)
        --else
            --self:CreateWireInputs("Activate", "Mute", "Disable Use")           
        --end
  --       self.Glass = ents.Create("prop_physics")
  --       self.Glass:SetModel("models/lordtrilobite/starwars/props/bactatankb.mdl")
  -- 	   self.Glass:SetPos(self:GetPos() + Vector(0, 0, 0))
  --       self.Glass:SetMoveType(MOVETYPE_NONE)
  --       self.Glass.Untouchable = false
  --       self.Glass:SetSolid(SOLID_VPHYSICS)
  --       self.Glass:SetParent(self.Entity)
  --       self.Glass:SetColor( Color(80,255,255,4))
  --       self.Glass:SetRenderMode(RENDERMODE_GLOW)
    end


    function ENT:OnRemove()
        print("stopped")
        if (self.Active) then
            self.Active = false
            --self:EmitSound("ambient/energy/power_off1.wav",75,100,1)
            --self:StopSound("displacer_new/portals/loop.wav")

            self.AttachedEnt:SetParent(nil)
            self.AttachedEnt:Remove()
            self:SetNWBool("Online",self.Active);
        end
    end

    function ENT:SpawnFunction(pl, tr)
        if (not tr.HitWorld) then return end
        if (not util.IsValidModel("models/lordtrilobite/starwars/props/bactatank.mdl")) then
            pl:EmitSound( "buttons/button8.wav" )
            pl:SendLua( "GAMEMODE:AddNotify('Providing replacement model', NOTIFY_HINT, 9);" )
            pl:SendLua( "GAMEMODE:AddNotify('Have you subscribed to: (Star Wars - Misc Prop Pack) ?', NOTIFY_ERROR, 9);" )
            pl:SendLua( "GAMEMODE:AddNotify('Error: Client/server missing model: (bactatank.mdl)', NOTIFY_ERROR, 9);" )
        end
        local e = ents.Create("asgard_ion_generator")
        e:SetPos(tr.HitPos + Vector(0, 0, 0))
        e:SetUseType(SIMPLE_USE)
        e:Spawn()

        phys = e:GetPhysicsObject()

        if (phys:IsValid()) then
            phys:EnableMotion(true)
            phys:Wake()
            phys:SetMass(10)
        end

        return e
    end



   function ENT:Use(p)
        if (self:GetWire("Disable Use") > 0) then return end
        if (self.depleted) then return end

        if (not (self.Online)) then
            self.Online = true
        else
            self.Online = false
        end
    end

    function ENT:TriggerInput(k, v)
        if (self.depleted) then return end

        if (k == "Activate") then
            if ((v or 0) >= 1) then
                if (not (self.Online)) then
                    self.Online = true
                end
            end
        elseif (self.Debug) then
            if (k == "Powerlevel") then
                self.PowerLevel = v
            end
        end
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

    function ENT:AC_toggle()
        if (self.Online == true) then
            if (self.AC_on == false) then
                self.ACEnt = ents.Create("pfx8_04")
                     self.ACEnt:SetPos(self:GetPos() + self:GetUp()*570)
                     self.ACEnt:SetMoveType(MOVETYPE_NONE)
                     self.ACEnt:SetParent(self.Entity)
                     ParticleEffectAttach( "[8]core_1", 1, self.ACEnt, 1 )
                self.AC_on = true
            else
                self.ACEnt:SetParent(nil)
                self.ACEnt:Remove()
                self.AC_on = false
            end
        else
            if (self.AC_on == true) then
                self.ACEnt:SetParent(nil)
                self.ACEnt:Remove()
                self.AC_on = false
            end
        end
    end

    function ENT:Think()
        if (self.Debug) then
        self.Particle_Time = math.Clamp(0.4 - (0.006 * self.PowerLevel), 0.000002, 0.4)
        end

    	if (self:GetWire("Mute") > 0) then
    		self:StopSound("ambient/machines/thumper_startup1.wav")
	    	self:StopSound("displacer_new/portals/loop.wav")
    	end

	    if (self.Online == true ) then
	    	
	    	if (self.OnAllowed == true) then
	    		self.Active = true
	    		if (self:GetWire("Mute") == 0) then
	    			self:EmitSound("ambient/machines/thumper_startup1.wav",75,100,1)
	    			self:EmitSound("displacer_new/portals/loop.wav",75,100,1)
	    		end

	    		 self.AttachedEnt = ents.Create("pfx5_00_alt_s")
		         self.AttachedEnt:SetPos(self:GetPos() + self:GetUp()*70)
		         self.AttachedEnt:SetMoveType(MOVETYPE_NONE)
		         self.AttachedEnt:SetParent(self.Entity)
		         ParticleEffectAttach( "[5]black_hole_micro_b", 1, self.AttachedEnt, 1 )

	    		self.OnAllowed = false
	    		self.OffAllowed = true
	    		self:SetNWBool("Online",self.Active);
	    	end
	    else
	    	if (self.OffAllowed == true) then
	    		if (self:GetWire("Mute") == 0) then
	    			self:EmitSound("ambient/energy/power_off1.wav",75,100,1)
	    			self:StopSound("displacer_new/portals/loop.wav")
	    		end
	    		self.Active = false
	    		self.AttachedEnt:SetParent(nil)
				self.AttachedEnt:Remove()
	    		self.OnAllowed = true
	    		self.OffAllowed = false
	    		self:SetNWBool("Online",self.Active);
                
	    	end
	    end
        if (self.Debug) then
            if (CurTime() > self.Effect_time) then

                    self:AC_toggle()

                    self.Effect_time = CurTime() + self.Particle_Time
            end
        end
	    if (self.Active) then	    	
	    	if (self:GetResource("energy") < self:GetNetworkCapacity("energy")) then

                self:SupplyResource("energy", 5000 * 10)                   
            end
	    end
	end
end

if CLIENT then

    function ENT:OnRemove()
        self:StopSound("displacer_new/portals/loop.wav")
    end

	function ENT:Draw() self:DrawModel() end

	function ENT:Think()
		local On = self:GetNWBool("Online");
		if(On) then
			--self:Light();
		end
	end

	function ENT:Light()

		local r = 60
		local g = 100
		local b = 255
		local pos = self:GetPos()+self:GetUp()*70;
		local Brightness = 2
		local size = 600

		local dynlight = DynamicLight(self:EntIndex());
		dynlight.Pos = pos;
		dynlight.Brightness = Brightness;
		dynlight.Size = size;
		dynlight.Decay = size*5;
		dynlight.r = r;
		dynlight.g = g;
		dynlight.b = b;
		dynlight.DieTime = CurTime()+0.1;
	end
end

if CLIENT then
    --ENT.Zpm_hud = surface.GetTextureID("VGUI/resources_hud/ion_gen");
    hud = surface.GetTextureID("VGUI/resources_hud/tier_6")

    function ENT:Initialize()
        self.Entity:SetNWBool("Online",false)
    end

    function ENT:OnRemove()
        self:StopSound("displacer_new/portals/loop.wav")
    end

	function ENT:Draw()
		local status = "Offline"
	    self.Entity:DrawModel()
	    hook.Remove("HUDPaint", tostring(self.Entity) .. "hud")
	    if (not StarGate.VisualsMisc("cl_draw_huds", true)) then return end

	    if (LocalPlayer():GetEyeTrace().Entity == self.Entity and EyePos():Distance(self.Entity:GetPos()) < 1024) then
	        hook.Add("HUDPaint", tostring(self.Entity) .. "hud", function()
            local w = 0
            local h = 260
            surface.SetTexture(hud)
            surface.SetDrawColor(Color(255, 255, 255, 255))
            surface.DrawTexturedRect(ScrW() / 2 + 6 + w, ScrH() / 2 - 50 - h, 180, 360)
            surface.SetFont("center2")
            surface.SetFont("header")
            draw.DrawText("Status:", "center2", ScrW() / 2 + 48 + w, ScrH() / 2 +95 - h, Color(209,238,238,255),0);

            if (IsValid(self.Entity)) then
                Online = self.Entity:GetNWBool("Online")
                if (Online) then
                	status = "Online"
                else
                	status = "Offline"
                end
            end
            draw.SimpleText(status, "center", ScrW() / 2 + 90 + w, ScrH() / 2 + 96 - h, color, 0)
            draw.SimpleText("Asgard Ion Generator", "center", ScrW() / 2 + 48 + w, ScrH() / 2 + 65 - h, Color(255, 255, 255, 255), 0)
	    end)        
	end
end
end


function ENT:OnRemove()
    hook.Remove("HUDPaint", tostring(self.Entity) .. "hud")
    self:EmitSound("ambient/energy/power_off1.wav",75,100,1)
    self:StopSound("displacer_new/portals/loop.wav")
end

