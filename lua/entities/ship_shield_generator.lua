/*
	Stargate Shield for GarrysMod10
	Copyright (C) 2007  aVoN

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
*/

if (StarGate!=nil and StarGate.LifeSupportAndWire!=nil) then StarGate.LifeSupportAndWire(ENT); end -- When you need to add LifeSupport and Wire capabilities, you NEED TO CALL this before anything else or it wont work!
ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Ship Shield Generator"
ENT.Author = "aVoN, Madman07"
ENT.WireDebugName = "Ship Shield Generator"

ENT.Spawnable = false
ENT.AdminSpawnable = false

if SERVER then

--################# HEADER #################
if (StarGate==nil or StarGate.CheckModule==nil or not StarGate.CheckModule("ship")) then return end
AddCSLuaFile();

ENT.CAP_NotSave = true;

ENT.Sounds={
	Engage=Sound("shields/shield_engage.mp3"),
	Disengage=Sound("shields/shield_disengage.mp3"),
	Fail={Sound("buttons/button19.wav"),Sound("buttons/combine_button2.wav")},
};

--################# SENT CODE ###############
-- function ENT:SpawnFunction(pl, tr)
	-- if (!tr.HitWorld) then return end
	-- local e = ents.Create("ship_shield_generator")
		-- e:SetPos(tr.HitPos)
	-- e:Spawn()

	-- e:Activate()
	-- e.Owner = pl
	-- return e
-- end

--################# Init @aVoN
function ENT:Initialize()
	self.Entity:PhysicsInit(SOLID_VPHYSICS);
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS);
	self.Entity:SetSolid(SOLID_NONE);
	self.Entity:SetRenderMode(RENDERMODE_NONE)
	self.Entity:SetModel("models/micropro/shield_gen.mdl");
	self.StrengthMultiplier = {2,2,2}; -- The first argument is the strength multiplier, the second is the regeneration multiplier. The third value is the "raw" value n, set by SetMultiplier(n) This will get set by the TOOL
	self.Strength = 100; -- Start with 100% Strength by default
	self.RestoreMultiplier = StarGate.CFG:Get("shield","restore_multiplier",1); -- How fast can it restore it's health?
	self.StrengthConfigMultiplier = StarGate.CFG:Get("shield","strength_multiplier",1); -- Doing this value higher will make the shiels stronger (look at the config)
	self.MaxSize = StarGate.CFG:Get("shield","max_size",1024)
	self.Size = 512;
	self.RestoreThresold = StarGate.CFG:Get("shield","restore_thresold",15); -- Which powerlevel has the shield to reach again until it works again?
	--self:AddResource("energy",1);
	self:CreateWireInputs("Activate");
	self:CreateWireOutputs("Active","Strength");
	self:SetWire("Strength",self.Strength);
	self.Entity:SetUseType(SIMPLE_USE);
	self.Phys = self.Entity:GetPhysicsObject();
	if(self.Phys:IsValid()) then
		self.Phys:Wake();
		self.Phys:SetMass(10);
	end
	self.DrawBubble = true;
	self.Owner = self.Entity:GetParent()
end

--################# Prevent PVS bug/drop of all networkes vars (Let's hope, it works) @aVoN
function ENT:UpdateTransmitState() return TRANSMIT_ALWAYS end;

--################# Sets some NW Floats for the shield color @aVoN
function ENT:SetShieldColor(r,g,b)
	self.ShieldColor = Vector(r or 1,g or 1,b or 1);
	self:SetNWVector("shield_color",self.ShieldColor);
end

--################# Avoids crashing a server with to huge size @aVoN
function ENT:SetSize(size)
	self.Size = math.Clamp(size,1,self.MaxSize);
end

--################# Is the shield enabled? @aVoN
function ENT:Enabled()
	return (self.Shield and self.Shield:IsValid());
end

--################# Activates or deactivates the shield @aVoN
function ENT:Status(b,nosound)
	if (not StarGate.CFG:Get("cap_misc","ship_shield",true)) then return end // disable shield if convar != 1
	if(b) then
		if(not self:Enabled() and not self.CantBeEnabled) then
			/*local energy = self:GetResource("energy",self.EngageEnergy);
			self.ConsumeAmmount = math.ceil(((self.Size)^2*math.pi*4)/200000); -- Instead of doing this calculation very second, do it here
			self.ExtraConsume = math.exp(math.Clamp(self.StrengthMultiplier[3]*1.3,0.2,600));  */
			if((not self.Depleted or (self.Strength >= self.RestoreThresold)) and self.Strength > 0) then
				-- Taking the enagage energy, you will get back later (when turning off the shield)
				local e = ents.Create("ship_shield");
				--e.Size = self.Size;
				e:SetPos(self.Entity:GetPos());
				e:SetAngles(self.Entity:GetAngles());
				e:SetParent(self.Entity);
				e:Spawn();
				e:SetNWVector("shield_color",self.ShieldColor); -- Necessary for the effects!
				e:SetNWBool("containment",self.Containment); -- For the clientside traceline class
				if(e and e:IsValid() and not e.Disable) then -- When our new shield mentioned, that there is already a shield
					self.Shield = e;
					if(not nosound) then
						self:EmitSound(self.Sounds.Engage,90,math.random(90,110));
					end
					return;
				end
			end
		end
	else
		if(self:Enabled()) then
			-- Give back the energy, we took when it was enagaged
			self.Shield:Remove();
			self.Shield = nil;
			if(not nosound and not self.Depleted) then
				self:EmitSound(self.Sounds.Disengage,90,math.random(90,110));
			end
		end
		return;
	end
	-- Fail animation
	self:EmitSound(self.Sounds.Fail[1],90,math.random(90,110));
	self:EmitSound(self.Sounds.Fail[2],90,math.random(90,110));
end

--################# Think @aVoN
function ENT:Think()
	local enabled = self:Enabled();
	self:Regenerate(enabled);
	if(self.Depleted) then
		-- Reenable shielt - It was depleted before (But alter the Thresold, so people wont have it up so fast again or need to wait ages)
		if(self.Strength >= math.Clamp(self.RestoreThresold/self.StrengthMultiplier[2],3,40)) then
			self.Depleted = nil;
			if(enabled) then
				self:EmitSound(self.Sounds.Engage,90,math.random(90,110));
				-- Add new entities to the shield, which "entered the shield" while it was offline!
				--for _,v in pairs(ents.FindInSphere(self.Shield:GetPos(),self.Shield.Size)) do
				--	self.Shield.NoCollide[v] = true;
				--end
				self.Shield:DrawBubbleEffect(); -- Draw shield effect when shield reengaged
				self.Shield:SetTrigger(true);
				self.Shield:SetNWBool("depleted",false); -- For the traceline class - Clientside
				self.Shield:AddAthmosphere();
				self.Shield:SetNotSolid(false);
			end
		end
	end

	self.Entity:NextThink(CurTime()+0.5);
	return true;
end

--################# Set's the strengthg multiplier which is necessary for the shields regeneration time and strength @aVoN
function ENT:SetMultiplier(n)
	local n = math.Clamp(n or 0,-5,5); -- Backwarts compatibility and idiot-proof
	if(n > 0) then
		n = 1 + n;
		self.StrengthMultiplier[1] = n
		self.StrengthMultiplier[2] = n^1.5
	else
		n = 1/(1 - n);
		self.StrengthMultiplier[1] = n^1.5;
		self.StrengthMultiplier[2] = n;
	end
	self.Strength = math.Clamp((self.StrengthMultiplier[3]/n)*self.Strength,0,100); -- This avoids cheating
	self.StrengthMultiplier[3] = n;
end

--################# Shield got hit - Take strength @aVoN
function ENT:Hit(strength,normal,pos)
	-- Calculate strenght-taking multiplier: Are we a shield, which is not moving? If so, we are many times stronger than a shield of a ship which is moving.
	local divisor = 1;
	if(self.Entity:GetVelocity():Length() < 5) then
		divisor = StarGate.CFG:Get("shield","stationary_shield_multiplier",10);
	end
	-- Take strength
	self.Strength = math.Clamp(self.Strength-2*math.Clamp(strength,1,20)/(self.StrengthMultiplier[1]*self.StrengthConfigMultiplier*divisor),0,100);
	if(StarGate.CFG:Get("shield","apply_force",false)) then
		-- Make us bounce around
		--self.Phys:ApplyForceOffset(-1*normal*strength*100*self.Phys:GetMass()/self.StrengthMultiplier[1],pos);
	end
end

--################# Reset it's strength @aVoN
function ENT:Regenerate(enabled)
	if(type(self.Strength) ~= "number") then self.Strength = 0 end; -- Somewhere the duplicator is setting self.Strength to a fucking bool. I dont know why. But it came with my new "save strength in adv dupe" system
	if(self.Strength < 100) then
		local multiplier = 1;
		-- Disabled shields can regenrate 2 times faster!
		if(not (enabled or self.Depleted)) then
			multiplier = multiplier*2.5;
		end
		multiplier = multiplier*2;
		multiplier = multiplier*(self.RestoreMultiplier/self.StrengthMultiplier[2]); -- Multiplier from the config and with the StrengthMultiplier
		self.Strength = math.Clamp(self.Strength+multiplier,0,100);
		self:SetWire("Strength",math.floor(self.Strength));
	end
end

--################# Wire input @aVoN
function ENT:TriggerInput(k,v)
	if(k=="Activate") then
		if((v or 0) >= 1) then
			self:Status(true);
		else
			self:Status(false);
		end
	end
end

--#################  Claok @aVoN
function ENT:Use(p)
	if(self:Enabled()) then
		self:Status(false);
	else
		self:Status(true);
	end
end

end

if CLIENT then

ENT.RenderGroup = RENDERGROUP_OPAQUE; -- This FUCKING THING avoids the clipping bug I have had for ages since stargate BETA 1.0. DAMN!

end