--[[
	SG Turret Base Part
	Copyright (C) 2011 Madman07
]]--

if (StarGate!=nil and StarGate.LifeSupportAndWire!=nil) then StarGate.LifeSupportAndWire(ENT); end

	
PrecacheParticleSystem("env_fire_large_smoke")


ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Stargate Turret Part"
ENT.Author = "Madman07"
ENT.Instructions= ""
ENT.Contact = "madman097@gmail.com"
ENT.Category = "Stargate Carter Addon Pack: Weapons"

ENT.Spawnable		= false
ENT.AdminSpawnable	= false
ENT.AutomaticFrameAdvance = true

if SERVER then

if (StarGate==nil or StarGate.CheckModule==nil or not StarGate.CheckModule("entweapon")) then return end
AddCSLuaFile()

function ENT:Initialize()
	self.Entity:PhysicsInit(SOLID_VPHYSICS);
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS);
	self.Entity:SetSolid(SOLID_VPHYSICS);

	if (WireAddon) then
		--self.Inputs = WireLib.CreateInputs( self.Entity, {"Fire [NORMAL]", "Active [NORMAL]", "Vector [VECTOR]", "Entity [ENTITY]"});
	end

	local phys = self.Entity:GetPhysicsObject();
	if IsValid(phys) then
		phys:Wake();
		phys:EnableGravity(false);
		construct.SetPhysProp( nil, self.Entity, 0, nil, {GravityToggle = false});
	end

	self.Anim = false;
end

function ENT:TriggerInput(variable, value)
	if IsValid(self.Parent) then
		if (variable == "Vector") then self.Parent.WireVec = value;
		elseif (variable == "Entity") then self.Parent.WireEnt = value;
		elseif (variable == "Fire") then self.Parent.WireShoot = value;
		elseif (variable == "Active") then self.Parent.WireActive = value;

    	end
	end
end

function ENT:Think(ply)
	if self.Anim then
		self:NextThink(CurTime());
		return true
	end
end

function ENT:OnTakeDamage(DamageInfo)
	if (self.Parent.Destroyed == true) then return end
	self.Parent.EntHealth = math.Clamp(self.Parent.EntHealth - DamageInfo:GetDamage(), 0, self.Parent.MaxHealth)
	if (self.Parent.EntHealth < 1) then
		self.Parent.Destroyed = true
		self.Parent.WireActive = false
		local fx = EffectData()
        fx:SetOrigin(self:GetPos())
        util.Effect("Explosion", fx)
        self:SetNWBool("Turret_destroyed", true)
		--self.firesd = CreateSound(self, "ambient/fire/fire_small_loop1.wav")
		--self.firesd:SetSoundLevel(60)
		--self.firesd:PlayEx(1,100)
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


    --self.ZapTime = CurTime() + 0.1
    util.Effect("Sparks",SparkFX)
    end


function ENT:StartTouch( ent )
	if IsValid(self.Parent) then self.Parent:StartTouch(ent); end
end

function ENT:OnRemove()
	if timer.Exists(self.Entity:EntIndex().."Anim") then timer.Destroy(self.Entity:EntIndex().."Anim") end
end

function ENT:DoAnim(time, name)
	self.Anim = true;
	timer.Create(self.Entity:EntIndex().."Anim", time, 1, function()
		self.Anim = false;
	end);

	local seq = self.Entity:LookupSequence(name);
	self.Entity:ResetSequence(seq);
end

if (StarGate and StarGate.CAP_GmodDuplicator) then
	duplicator.RegisterEntityClass( "sg_turret_part", StarGate.CAP_GmodDuplicator, "Data" )
end

end

if CLIENT then
ENT.CAP_NextActivationCheckT = 0
ENT.DoneFireParticles = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:Think()
	if CurTime() > self.CAP_NextActivationCheckT then
		if self:GetNWBool("Turret_destroyed") == true then
			if self.DoneFireParticles == false then
					self.DoneFireParticles = true
				ParticleEffectAttach("env_fire_large_smoke",PATTACH_ABSORIGIN_FOLLOW,self,0)
				ParticleEffectAttach("env_embers_large",PATTACH_ABSORIGIN_FOLLOW,self,0)
			end
		else
			self:StopParticles()
			self.DoneFireParticles = false
		end
		self.CAP_NextActivationCheckT = CurTime() + 0.1
	end
end

end
