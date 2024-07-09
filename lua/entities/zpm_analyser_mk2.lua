
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "ZPM Analyser MK II"
ENT.Author = "Madman07, Rafael De Jongh"
ENT.Contact = ""
ENT.Purpose = ""
ENT.Instructions = "May include Carter's toaster."
ENT.Category = "Stargate Carter Addon Pack"
if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
ENT.Category = SGLanguage.GetMessage("entity_main_cat");
end
list.Set("CAP.Entity", ENT.PrintName, ENT)


if SERVER then
	AddCSLuaFile()

	ENT.Sounds = {
        Place = Sound("tech/comstone_placestone.wav"),
        Transfer = Sound("tech/comstone_transferminds.wav")
    }

	function ENT:Initialize()
		self.Entity:SetModel("models/soren/zpm_analyzer/zpm_analyzer_mk2.mdl");
		self.Entity:PhysicsInit(SOLID_VPHYSICS)
		self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
		self.Entity:SetSolid(SOLID_VPHYSICS)
		self.Entity:SetUseType(SIMPLE_USE)
		self.Sound = CreateSound(self,Sound("weapons/atlantis_scanner.wav"));
		local phys = self.Entity:GetPhysicsObject();
		if(phys:IsValid())then
			phys:EnableMotion(false);
			phys:SetMass(2000);
		end
		self.Active = false
		self.CanEject = true
		self.InContact = false
		self.Percentcomp = 0
		self.Time = 0
		self.Complete = 0

		self.ZPM = {
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

        self.Position = {
            R = 0,
            F = 0.8
        }
	end


	function ENT:SpawnFunction(p,t)
		if (not t.Hit) then return end
		local ang = p:GetAimVector():Angle(); ang.p = 0; ang.r = 0; ang.y = (ang.y+90) % 360;
		local pos = t.HitPos+Vector(0,0,0);
		local e = ents.Create("zpm_analyser_mk2");
		e:SetPos(pos);
		e:SetAngles(ang);
		e:DrawShadow(true);
		e:SetVar("Owner",p)
		e:Spawn();
		e:Activate();
		e.Owner = p;
		return e;
	end

	function ENT:Use()
		if (self.Active) then
			self.Entity:SetNWBool("Active", false)
			self.Sound:Stop();
			self.Active = false
		else
            self.Entity:SetNWBool("Active", true)
            self.Sound:PlayEx(0.5,70);
            self.Active = true
            self.Entity:SetNWInt("Result",0)
		end
	end


	function ENT:Touch(ent)
        local pos = self.Entity:GetPos()
        local ang = self.Entity:GetAngles()

        if (self.CanEject == true and ent.IsZPM and ent ~= self.ZPM.Ent) then
            if (not self.ZPM.IsValid and self.ZPM.Eject == 0) then
                self.ZPM.Ent = ent
                self.ZPM.Dist = 1
                self.ZPM.Dir = 1
                self.ZPM.Type = "ZPH"
                self.ZPM.IsValid = true
                ent:SetUseType(SIMPLE_USE)

                ent.Use = function()
                    local constr = constraint.FindConstraint(self, "Weld")

                    if (constr and IsValid(constr.Entity[1].Entity)) then
                        constr.Entity[1].Entity:UseZPM()
                    end
                end

                constraint.RemoveAll(ent)
                ent:SetPos(pos + self.Entity:GetRight() * (self.Position.R) + self.Entity:GetUp() * (10) + self.Entity:GetForward() * (self.Position.F))
                ent:SetAngles(ang)
                constraint.Weld(self.Entity, ent, 0, 0, 0, true)
            end
        end
    end

	function ENT:ZPMsMovement()
        local pos = self.Entity:GetPos()
        local ang = self.Entity:GetAngles()
        local spd = 0.015

        if (self.ZPM.IsValid and self.ZPM.Dist ~= self.ZPM.Dir) then
            if (self.ZPM.Dist < 0) then
                self.ZPM.Dist = 0
            elseif (self.ZPM.Dist > 1) then
                self.ZPM.Dist = 1
            end

            if (self.ZPM.Dir < self.ZPM.Dist) then
                self.ZPM.Dist = self.ZPM.Dist - spd

                if (self.ZPM.SoundIn == 1) then
                    self.Entity:EmitSound(self.Sounds.SlideIn, 60, 100)
                    self.ZPM.SoundIn = 2
                end

                if (self.ZPM.SoundOut == 2) then
                    self.ZPM.SoundOut = 0
                end
            elseif (self.ZPM.Dir > self.ZPM.Dist) then

                self.ZPM.Dist = self.ZPM.Dist + spd

                if (self.ZPM.SoundOut == 1) then
                    self.Entity:EmitSound(self.Sounds.SlideOut, 60, 100)
                    self.ZPM.SoundOut = 2
                end

                if (self.ZPM.SoundIn == 2) then
                    self.ZPM.SoundIn = 0
                end
            end

            constraint.RemoveAll(self.ZPM.Ent)
            self.ZPM.Ent:SetAngles(self.Entity:GetAngles())
            self.ZPM.Ent:SetPos(pos + self.Entity:GetRight() * (self.Position.R) + self.Entity:GetUp() * (10 * self.ZPM.Dist) + self.Entity:GetForward() * (self.Position.F))
            constraint.Weld(self.Entity, self.ZPM.Ent, 0, 0, math.floor(self.ZPM.Dist) * 5000, true)
        end
    end

	function ENT:Think()
		if self.Active then
			if CurTime() > self.Time then
				self.Percentcomp = math.Clamp(self.Percentcomp + math.floor(math.Rand(0.5, 5)) , 0, 100) 
				self.Time = CurTime() + 0.2
                self.Entity:SetNWInt("zpm_analyzer_percent",self.Percentcomp)
			end

			self.Entity:SetNWInt("Percentage", self.Percentcomp)
			if self.Percentcomp == 100 then
				self.Active = false
				self.InContact = false
				self.Entity:SetNWBool("Active", false)
				self.Sound:Stop();
				if (self.ZPM.IsTampered) then
					self.Entity:SetNWInt("Result",1)
					self:EmitSound("sg/scanner/deactivate2.wav")
				else
					self.Entity:SetNWInt("Result",2)
					self:EmitSound("sg/scanner/deactivate2.wav")
				end

			end
		end
		self:ZPMsMovement()
	end

	function ENT:EjectZPM()
        if (self.ZPM.Ent and IsValid(self.ZPM.Ent)) then
            self.ZPM.Ent.Use = function() end
            local phys = self.ZPM.Ent:GetPhysicsObject()

            if (phys:IsValid()) then
                constraint.RemoveAll(self.ZPM.Ent)
            end

            local mul = 3.2
            self.CanEject = false

            timer.Simple(1, function()
                if (IsValid(self.Entity)) then
                    self.CanEject = true
                end
            end)

            local pos = self.Entity:GetPos()
            self.ZPM.Ent:SetPos(pos + self.Entity:GetRight() * (self.Position.R * mul) + self.Entity:GetUp() * (29.1 + 12) + self.Entity:GetForward() * (self.Position.F * mul))
        end

        self.ZPM.Ent = nil
        self.ZPM.IsValid = false
        self.ZPM.On = false
    end

	function ENT:OnRemove()
        if (self.ZPM.IsValid) then
            self:EjectZPM()
        end
    end
end


if CLIENT then

	ENT.Device_hud = surface.GetTextureID("VGUI/resources_hud/tier_1")
	function ENT:Draw()
        local percentComplete = 0
        if (IsValid(self.Entity)) then
            percentComplete = self.Entity:GetNWInt("zpm_analyzer_percent",0)
        end
        self.Entity:DrawModel()
        hook.Remove("HUDPaint", tostring(self.Entity) .. "zpm_a")
        if (LocalPlayer():GetEyeTrace().Entity == self.Entity and EyePos():Distance(self.Entity:GetPos()) < 1024) then
            hook.Add("HUDPaint", tostring(self.Entity) .. "zpm_a", function()
                
                
                -- Set the position and size of the graph
                local graphX, graphY = 100, 100
                local graphWidth, graphHeight = 500, 300
                local totalPoints = 200  -- Total number of points to draw

                -- Calculate the number of points to draw based on percentComplete
                local numPoints = math.floor(totalPoints * (percentComplete / 100))

                -- Draw the background of the graph
                surface.SetDrawColor(50, 50, 50, 200)  -- Dark grey background with some transparency
                surface.DrawRect(graphX, graphY, graphWidth, graphHeight)

                -- Draw the axes
                surface.SetDrawColor(255, 255, 255, 255)  -- White color for axes
                -- X-axis
                surface.DrawLine(graphX, graphY + graphHeight / 2, graphX + graphWidth, graphY + graphHeight / 2)
                -- Y-axis
                surface.DrawLine(graphX + graphWidth / 2, graphY, graphX + graphWidth / 2, graphY + graphHeight)

                -- Plot the points for the sine function
                for i = 0, numPoints do
                    local x = i / totalPoints * graphWidth
                    local y = math.sin(i / totalPoints * math.pi * 2) * (graphHeight / 2)  -- Sine function
                    local pointX = graphX + x
                    local pointY = graphY + (graphHeight / 2) - y

                    if percentComplete == 100 then
                        -- Draw the point
                        if (i < 80 and i > 60) or (i > 110 and i < 120) then
                            surface.SetDrawColor(255, 0, 0)  -- Green color for points
                        else
                            surface.SetDrawColor(0, 255, 0, 255)  -- Green color for points
                        end
                    else
                        surface.SetDrawColor(0, 255, 0, 255)  -- Green color for points
                    end
                    surface.DrawRect(pointX - 2, pointY - 2, 4, 4)  -- Draw a small square for each point
                end
            end)
        end

        local Online = self:GetNWBool("Active")
        --self:DrawModel()

        if (Online) then
            self:DynLight(true)
        elseif ((not (Online))) then
            self:DynLight(false)
        end
    end


    function ENT:DynLight()
        local percentComplete = 0
        if (IsValid(self.Entity)) then
            percentComplete = self.Entity:GetNWInt("zpm_analyzer_percent",0)
        end
        local pos = self:GetPos() + self:GetUp() * 15 + self:GetUp() * (math.sin(CurTime()*2)*5)
        local pos2 = self:GetPos() + self:GetUp() * (percentComplete/5)
        local Online = self:GetNWBool("Active",false)


        if (IsValid(self)) then
            if (Online) then
                local dynlight = DynamicLight(self:EntIndex() + 4096)
                dynlight.Pos = pos2
                dynlight.Brightness = 15
                dynlight.Size = 14
                dynlight.Decay = 1024
                dynlight.R = 25
                dynlight.G = 255
                dynlight.B = 255
                dynlight.DieTime = CurTime() + 1
            end
        end
    end



    function ENT:OnRemove()
        hook.Remove("HUDPaint", tostring(self.Entity) .. "zpm_a")
    end


end