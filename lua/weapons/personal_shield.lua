if (StarGate==nil or StarGate.CheckModule==nil or not StarGate.CheckModule("weapon")) then return end
if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
SWEP.PrintName = SGLanguage.GetMessage("weapon_misc_shield");
SWEP.Category = SGLanguage.GetMessage("weapon_misc_cat");
end
SWEP.Author = "DrFattyJr"
SWEP.Purpose = "Shield yourself"
SWEP.Instructions = "Press primary attack to shield yourself and secondary to unshield!"
SWEP.Base = "weapon_base"
SWEP.Slot = 3
SWEP.SlotPos = 5
SWEP.DrawAmmo	= false
SWEP.DrawCrosshair = true
SWEP.ViewModel = "models/weapons/c_arms_animations.mdl"
SWEP.WorldModel = "models/roltzy/w_sodan.mdl"
SWEP.AnimPrefix = "melee"
SWEP.HoldType = "normal"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo	= "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

list.Set("CAP.Weapon", SWEP.PrintName or "", SWEP);

function SWEP:Initialize()
	self.Weapon:SetWeaponHoldType(self.HoldType)
end

if CLIENT then
	-- Inventory Icon
	if(file.Exists("materials/VGUI/weapons/personal_shield.vmt","GAME")) then
		SWEP.WepSelectIcon = surface.GetTextureID("VGUI/weapons/personal_shield");
	end

	local function PersonalShieldDrawHUD()
		local ply = LocalPlayer()
		if not( ply:IsValid() and ply:GetNetworkedBool("Has.A.pShield", false)) then return end

		local strength = math.Clamp(ply:GetNWFloat("pShieldStrength", 12), 12, 100)
		local a = 150

		if strength < 20 then
			a = 112.5+math.sin(CurTime()*6)*112.5
		end

		draw.RoundedBox(8, ScrW()/8, ScrH()/2-160,20,160, Color(255,0,0,a))
		draw.RoundedBox(8, ScrW()/8, ScrH()/2-1.6*strength,20,1.6*strength, Color(255,255,255,a*1.7))
	end

	hook.Add("HUDPaint", "PersonalShieldDrawHUD", PersonalShieldDrawHUD)
end

if SERVER then

if (StarGate==nil or StarGate.CheckModule==nil or not StarGate.CheckModule("weapon")) then return end
AddCSLuaFile()

local Sounds = {
	Engage=Sound("shields/personal_activate.wav"),
	Disengage=Sound("shields/personal_deactivate.wav"),
	Hit=Sound("shields/personal_impact.wav")
}

function SWEP:Initialize()
	self:SetWeaponHoldType(self.HoldType)
	--self.Owner:SetNWFloat("pShieldStrength", 0)
end

local function EngageEffect(ply)
	ply:EmitSound(Sounds.Engage,90,math.random(97,103))

	local fx = EffectData()
	fx:SetEntity(ply)
	fx:SetScale(1)
	util.Effect("pShield", fx, true, true)
end

local function DisengageEffect(ply)
	ply:EmitSound(Sounds.Disengage,90,math.random(97,103))
	local fx = EffectData()
	fx:SetEntity(ply)
	fx:SetScale(0)
	util.Effect("pShield", fx, true, true)
end

local function HitEffect(pos, ply)
	sound.Play(Sounds.Hit,pos,math.random(70,100),math.random(90,110))

	if CurTime()-(ply._DidLastEffect or 0) > 0.5 then
		ply._DidLastEffect = CurTime()
		local fx = EffectData()
		fx:SetEntity(ply)
		fx:SetOrigin(pos)
		util.Effect("pShield_Hit", fx, true, true)
	end
end

function SWEP:PrimaryAttack()
	if(not self.Owner.pShielded) then
		self.Owner.pShielded = true
		EngageEffect(self.Owner)
		self.Weapon:SetNextSecondaryFire(CurTime()+0.8)
	end
	return true
end

function SWEP:SecondaryAttack()
	if(self.Owner.pShielded) then
		self.Owner.pShielded = false
		DisengageEffect(self.Owner)
		self.Weapon:SetNextPrimaryFire(CurTime()+0.8)
	end
	return true
end

hook.Add("EntityTakeDamage", "Staraget.PersonalShield.StopDamage",
	function(ent, dmginfo)
		if ent and ent:IsValid() and ent:IsPlayer() and ent.pShielded and ent:HasWeapon("personal_shield") then
			local infl = dmginfo:GetInflictor()
    		local att = dmginfo:GetAttacker()
    		local amount    = dmginfo:GetDamage()
			local strength = ent:GetNetworkedFloat("pShieldStrength", 0)
			if  strength > 0 then
				local dmg = dmginfo:GetDamage()
				strength = strength - dmg/10

				if strength > 0 then
					dmginfo:SetDamage(0)
				else
					dmginfo:SetDamage(strength)
				end

				HitEffect(dmginfo:GetDamagePosition(), ent)

				strength = math.Clamp(strength, 0, 100)

				if strength == 0 then
					ent.pShielded = false
					DisengageEffect(ent)
				end

				ent:SetNWFloat("pShieldStrength", strength)
			end
		end
	end
)

timer.Create("StarGate.PersonalShield.Think",0.1,0,
	function()
		for _,v in pairs(player.GetAll()) do
			local valid = v:IsValid()
			local hw = v:HasWeapon("personal_shield")
			local nhw = v:GetNWBool("Has.A.pShield", false)

			if valid then
				if hw then
					if not nhw then
						v:SetNWBool("Has.A.pShield", true)
					end

					local strength = v:GetNWFloat("pShieldStrength", 0)

					if v.pShielded then
						if strength < 100 then
							strength = math.Clamp(strength-0.2, 0, 100)
						end

						if strength == 0 then
							v.pShielded = false
							DisengageEffect(v)
						end
					else
						if strength < 100 then
							strength = math.Clamp(strength+0.5, 0, 100)
						end
					end

					v:SetNWFloat("pShieldStrength", strength)
				elseif nhw then
					v:SetNWFloat("PShieldStrength", 0)
					v:SetNWBool("Has.A.pShield", false)
				end
			end
		end
	end
)

local function ConCommandShieldEngage(ply)
	local weapon = ply:GetWeapon("personal_shield")
	if weapon then weapon:PrimaryAttack() end
end

local function ConCommandShieldDisengage(ply)
	local weapon = ply:GetWeapon("personal_shield")
	if weapon then weapon:SecondaryAttack() end
end

concommand.Add("pShield_Engage", ConCommandShieldEngage)
concommand.Add("pShield_Disengage", ConCommandShieldDisengage)

end