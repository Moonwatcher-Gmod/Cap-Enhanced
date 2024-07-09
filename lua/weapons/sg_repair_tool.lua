local SWEP = {Primary = {}, Secondary = {}}

if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("weapon")) then return end

if (SGLanguage != nil and SGLanguage.GetMessage != nil) then
	--SWEP.PrintName = SGLanguage.GetMessage("weapon_misc_repair_tool"); --there is no language for this yet
	SWEP.PrintName = "Repair Tool"
	SWEP.Category = SGLanguage.GetMessage("weapon_misc_cat");
	SWEP.ClassName = "sg_repair_tool"
end

list.Set("CAP.Weapon", SWEP.PrintName or "", SWEP)

SWEP.Author 		= "Nova Astral"
SWEP.Purpose		= "Repair Ships, DHD's and Stargates"
SWEP.Instructions	= "Left Click to repair"

SWEP.DrawCrosshair	= true
SWEP.SlotPos = 1
SWEP.Slot = 2
SWEP.Spawnable = false
SWEP.Weight = 1
SWEP.HoldType = "pistol"
SWEP.Primary.Ammo = "none" --This stops it from giving pistol ammo when you get the tool
SWEP.Secondary.Ammo = "none"
SWEP.Primary.Delay = 1-- Repair Delay
SWEP.Primary.Automatic = true
SWEP.ViewModelFOV = 70
SWEP.ViewModel = "models/weapons/c_toolgun.mdl"
SWEP.WorldModel = "models/weapons/w_toolgun.mdl"
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = true
SWEP.UseHands = true


--function SWEP:DrawWorldModel() end
--function SWEP:DrawWorldModelTranslucent() end
function SWEP:CanPrimaryAttack() return false end
function SWEP:CanSecondaryAttack() return false end
function SWEP:Holster() return true end
function SWEP:ShouldDropOnDie() return false end

function SWEP:Initialize()
	self:SetNWInt("health",0)
	self:SetNWInt("maxhealth",0)
	self:SetNWString("screencol","200 100 100 255")
	self.Weldsound = self.Weldsound or CreateSound(self, "ambient/energy/electric_loop.wav")
	self.NextTrace = 0
	self.Trace = nil

	self:DrawShadow(false)
end



if SERVER then
	AddCSLuaFile()
	function SWEP:Think()
		if CurTime() > self.NextTrace then
			self.Trace = self.Owner:GetEyeTrace()
			self.NextTrace = CurTime() + 0.1

			if(IsValid(self.Trace.Entity) and self.Trace.Entity.EntHealth and self.Trace.Entity.MaxHealth) then
				local trclass = self.Trace.Entity:GetClass()
			end
		end

		if(self.Owner:GetShootPos():Distance(self.Trace.HitPos) < 300) then
				if(IsValid(self.Trace.Entity) and self.Trace.Entity.EntHealth and self.Trace.Entity.MaxHealth) then
					local curhp = math.Round(self.Trace.Entity.EntHealth)
					local maxhp = math.Round(self.Trace.Entity.MaxHealth)

					self:SetNWInt("health",curhp)
					self:SetNWInt("maxhealth",maxhp)
					self:SetNWString("screencol","100 200 100 255")
					self:SetNWString("repairname",self.Trace.Entity:GetNWString("WireName", self.Trace.Entity.PrintName) or trclass)

					if(self.Owner:KeyPressed(1)) and curhp < maxhp then
						self.Weldsound:PlayEx(1, 100)
					end

					if(self.Owner:KeyReleased(1)) then
						self.Weldsound:Stop()
					end

					if curhp == maxhp then
						self.Weldsound:Stop()
					end
				else
					self:SetNWInt("health",0)
					self:SetNWInt("maxhealth",0)
					self:SetNWString("screencol","200 100 100 255")
					self:SetNWString("repairname","Repair")
				end

				if (self.Owner:KeyDown(1)) then
					local CurHP = self:GetNWInt("health")
					local MaxHP = self:GetNWInt("maxhealth")
					local HPInc = math.Clamp(CurHP + 1,0,MaxHP)

					if(self.Trace.Entity:IsValid()) then
						local trclass = self.Trace.Entity:GetClass()

						if(CurHP >= MaxHP) then
							local fullpitch = math.random(100,125)
						else
							local effectData = EffectData()
							effectData:SetOrigin(self.Trace.HitPos)
							effectData:SetNormal(self.Trace.HitNormal)
							util.Effect("stunstickimpact", effectData, true, true)
							self.Trace.Entity:HealthRepair(HPInc)
						end

						if(string.sub(self.Trace.Entity:GetClass(),1,4) == "dhd_") then
							if CurHP >= MaxHP and self.Trace.Entity.Destroyed then
								self.Trace.Entity.Destroyed = false
								self.Trace.Entity:SetNetworkedBool("Destroyed",false)
								self.Trace.Entity:Spawn()
							end
						end
					end
				end

		else
			self:SetNWInt("health",0)
			self:SetNWInt("maxhealth",0)
			self:SetNWString("screencol","200 100 100 255")
			self:SetNWString("repairname","Repair")
		end
	end
end

if CLIENT then
	local matScreen = Material("models/weapons/v_toolgun/screen")

    -- GetRenderTarget returns the texture if it exists, or creates it if it doesn't
    local rtTexture = GetRenderTarget("GModToolgunScreen",256,256)

    surface.CreateFont("SGRepairToolDesc",{
        font = "Helvetica",
        size = 30,
        weight = 900
    })
    surface.CreateFont("SGRepairToolHealth",{
        font = "Helvetica",
        size = 100,
        weight = 900
    })
	surface.CreateFont("SGRepairToolMaxHealth",{
        font = "Helvetica",
        size = 50,
        weight = 900
    })

    function SWEP:RenderScreen()
        local TEX_SIZE = 256

        -- Set the material of the screen to our render target
        matScreen:SetTexture("$basetexture",rtTexture)

        local oldRT = render.GetRenderTarget()

        -- Set up our view for drawing to the texture
        render.SetViewPort(0,0,ScrW(),ScrH())
		render.PushRenderTarget(rtTexture)

        cam.Start2D()
            local RepairHealth = self:GetNWInt("health")
			local RepairMaxHealth = self:GetNWInt("maxhealth")
			local RepairEntName = self:GetNWString("repairname")
			local BGColor = self:GetNWString("screencol")

            surface.SetDrawColor(string.ToColor(BGColor):Unpack())
            surface.DrawRect(0,0,TEX_SIZE,TEX_SIZE)

            self:drawShadowedText(RepairEntName, TEX_SIZE / 2, 32, "SGRepairToolDesc")
            self:drawShadowedText(RepairHealth, TEX_SIZE / 2, TEX_SIZE / 2, "SGRepairToolHealth")
			self:drawShadowedText(RepairMaxHealth, TEX_SIZE / 2, TEX_SIZE / 1.2, "SGRepairToolMaxHealth")
        cam.End2D()

        render.SetRenderTarget(oldRT)
        render.SetViewPort(0,0,ScrW(),ScrH())
		render.PopRenderTarget()
	end

    function SWEP:drawShadowedText(text, x, y, font)
        draw.SimpleText( text, font, x + 3, y + 3, Color(0, 0, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText( text, font, x , y , Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

function SWEP:OnDrop()
    if SERVER then
		self:Remove() -- This deletes the SWEP entity if you drop it so there isn't just a invisible repair tool somewhere
	end
end

timer.Simple(0.1, function() weapons.Register(SWEP,"sg_repair_tool", true) end) --Putting this in a timer stops bugs from happening if the weapon is given while the game is paused