
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "ZPM Analyser"
ENT.Author = "Madman07, Rafael De Jongh"
ENT.Contact = ""
ENT.Purpose = ""
ENT.Instructions = "Only for Ancients."
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
		self.Entity:SetModel("models/madman07/com_device/device.mdl");
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
		self.InContact = false
		self.Percentcomp = 0
		self.Time = 0
		self.Complete = 0
		self.ZPM = nil
	end

	function ENT:SpawnFunction(p,t)
		if (not t.Hit) then return end

		local ang = p:GetAimVector():Angle(); ang.p = 0; ang.r = 0; ang.y = (ang.y+90) % 360;
		local pos = t.HitPos+Vector(0,0,0);
		local e = ents.Create("zpm_analyser");
		e:SetPos(pos);
		e:SetAngles(ang);
		e:DrawShadow(true);
		e:SetVar("Owner",p)
		e:Spawn();
		e:Activate();
		e.Owner = p;
		return e;
	end

	function ENT:Use(ply)
		if (self.Active) then
			self.Entity:SetNWBool("Active", false)
			self.Sound:Stop();
			self.Active = false
		else
			if self.InContact then
				self.Entity:SetNWBool("Active", true)
				self.Sound:PlayEx(0.5,70);
				self.Active = true
				self.Entity:SetNWInt("Result",0)
			end
		end
	end

	function ENT:StartTouch(ent)
		if (ent:GetClass() == "zpm_mk3") then
			self:EmitSound(self.Sounds.Place, 100, math.random(98, 102))
			self.InContact = true
			self.ZPM = ent
			self.Entity:SetNWInt("Percentage", self.Percentcomp)
		end
	end

	function ENT:EndTouch(ent)
		if (ent:GetClass() == "zpm_mk3") then
			self.Entity:SetNWBool("Active", false)
			self.InContact = false
			self.Sound:Stop();
			self.Active = false
			self.Percentcomp = 0
			self.ZPM = nil
			self.Entity:SetNWInt("Percentage", self.Percentcomp)
		end
	end

	function ENT:Think()
		if self.Active then
			if CurTime() > self.Time then
				self.Percentcomp = math.Clamp(self.Percentcomp + math.floor(math.Rand(1, 10)) , 0, 100) 
				self.Time = CurTime() + 1
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
	end
end


if CLIENT then

	ENT.Device_hud = surface.GetTextureID("VGUI/resources_hud/tier_2")
	function ENT:Draw()
        self.Entity:DrawModel()
        hook.Remove("HUDPaint", tostring(self.Entity) .. "zpm_a")

        if (LocalPlayer():GetEyeTrace().Entity == self.Entity and EyePos():Distance(self.Entity:GetPos()) < 1024) then
            hook.Add("HUDPaint", tostring(self.Entity) .. "zpm_a", function()
            	local w = 0
	            local h = 260
                surface.SetTexture(self.Device_hud)
                surface.SetDrawColor(Color(255, 255, 255, 155))
                surface.DrawTexturedRect(ScrW() / 2 + 6 + w, ScrH() / 2 - 50 - h, 200, 360)
                local chann = 1

                if IsValid(self.Entity) then
                    chann = self.Entity:GetNetworkedInt("Chann", 1)
                end

                local act = false
                local percent = 0
                local result = 0

                if IsValid(self.Entity) then
                    act = self.Entity:GetNWBool("Active", false)
                    percent = self.Entity:GetNWInt("Percentage",0)
                    result = self.Entity:GetNWInt("Result",0)
                end
                draw.DrawText("Analyser", "HudHintTextLarge", ScrW() / 2 + 55, ScrH() / 2 -223, Color(0, 255, 255, 255), 0)
                
                if (act) then
                	draw.DrawText("Active", "HudHintTextLarge", ScrW() / 2 + 35, ScrH() / 2 - 200, Color(0, 238, 38, 255), 0)
            	else
            		draw.DrawText("Offline", "HudHintTextLarge", ScrW() / 2 + 35, ScrH() / 2 - 200, Color(255, 38, 38, 255), 0)
            	end
                
                draw.DrawText(percent.." %", "HudHintTextLarge", ScrW() / 2 + 35, ScrH() / 2 - 175, Color(209, 238, 238, 255), 0)

                draw.DrawText("Result:", "HudHintTextLarge", ScrW() / 2 + 35, ScrH() / 2 - 150, Color(209, 238, 238, 255), 0)

                if (result==1) then
                	draw.DrawText("Variance detected!", "HudHintTextLarge", ScrW() / 2 + 35, ScrH() / 2 - 130, Color(255, 38, 38, 255), 0)
                elseif (result==2) then
                	draw.DrawText("Stable", "HudHintTextLarge", ScrW() / 2 + 35, ScrH() / 2 - 130, Color(38, 255, 38, 255), 0)
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

        local pos = self:GetPos() + self:GetUp() * 15 + self:GetUp() * (math.sin(CurTime()*2)*5)
        local pos2 = self:GetPos() + self:GetUp() * 2
        local Online = self:GetNWBool("Active",false)


        if (IsValid(self)) then
            if (Online) then
                local dynlight = DynamicLight(self:EntIndex() + 4096)
                dynlight.Pos = pos
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