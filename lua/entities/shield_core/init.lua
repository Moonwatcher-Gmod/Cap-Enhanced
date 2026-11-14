--[[
	Shield Core
	Copyright (C) 2011 Madman07
]]--

if (StarGate==nil or StarGate.CheckModule==nil or not StarGate.CheckModule("devices")) then return end
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Sounds={
	Engage=Sound("shields/shield_engage.mp3"),
	Disengage=Sound("shields/shield_disengage.mp3"),
	Fail={Sound("buttons/button19.wav"),Sound("buttons/combine_button2.wav")},
	Open=Sound("shields/shield_core.wav"),
};

-----------------------------------INIT----------------------------------

function ENT:Initialize()

	self.Entity:SetModel("models/Madman07/destiny_emmiter/destiny_emmiter.mdl");

	self.Entity:SetName("Shield Core");
	self.Entity:PhysicsInit(SOLID_VPHYSICS);
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS);
	self.Entity:SetSolid(SOLID_VPHYSICS);
	self.Entity:SetUseType(SIMPLE_USE);

	self.Immunity = false;
	self.Strength = 0;
	self.Mod = "models/Madman07/shields/sphere.mdl";
	self.Anim = false;
	self.ThinkTime = CurTime()+0.5;
	self.MenuData = "0 0 0 0 5 0 0 0 0 0";
	self.RisingEdge = false; -- Rise/lower (with the glowing edge) even without "Always show Bubble"
	self.AllowedPlayers = {}; -- Wire "Allowed Players"
	self.Frequency = 0; -- Shield identifiers on this frequency let their contraption through (0 = off)
	self.FireFrequency = 0; -- Weapons tuned to this frequency hit much softer (0 = off)
	self.AntiNoclip = false;
	self.Containment = false;

	self.Entity:SetNWBool("Kill", false);
	self.Entity:SetNWVector("Size", Vector(100,100,100));
	self.Entity:SetNWAngle("Ang", Angle(0,0,0));
	self.Entity:SetNWVector("Pos", Vector(0,0,0));
	self.Entity:SetNWVector("Col", Vector(170,189,255));
	self.Entity:SetNWString("Mod", self.Mod);
	self.Entity:SetNWString("MenuData", self.MenuData);

	self.StrengthMultiplier = {1,1,1}; -- The first argument is the strength multiplier, the second is the regeneration multiplier. The third value is the "raw" value n, set by SetMultiplier(n) This will get set by the TOOL
	self.Strength = 100; -- Start with 100% Strength by default
	self.EngageEnergy = StarGate.CFG:Get("shield","engage_energy",500); -- This energy will be needed to engage the shield. You will get it back, when the shield collapses
	self.ConsumeMultiplier = StarGate.CFG:Get("shield","consume_multiplier",1)*100; -- As higher this is, as more energy it will take when enabled
	-- For the energy estimate in the menu (ENT:EstimateEnergy in shared.lua)
	self.Entity:SetNWFloat("EnergyConsumeMul", self.ConsumeMultiplier);
	self.Entity:SetNWFloat("EnergyEngage", self.EngageEnergy);
	self.RestoreMultiplier = StarGate.CFG:Get("shield","restore_multiplier",1); -- How fast can it restore it's health?
	self.StrengthConfigMultiplier = StarGate.CFG:Get("shield","strength_multiplier",1); -- Doing this value higher will make the shiels stronger (look at the config)

	self.RestoreThresold = StarGate.CFG:Get("shield","restore_thresold",15); -- Which powerlevel has the shield to reach again until it works again?
	self:AddResource("energy",1);
	self:CreateWireInputs("Activate","Size [VECTOR]","Immunity","Containment","Allowed Players [ARRAY]","Frequency","Fire Frequency");
	self:CreateWireOutputs("Active","Strength","Energy Use","Covered %","Resizing","Size [VECTOR]","Contained","Hit","Hit Position [VECTOR]","Hit Strength");
	-- Limits for resizing (the menu sliders and the Wire "Size" input)
	self.MinSize = StarGate.CFG:Get("shield_core","min_size",100);
	self.MaxSize = StarGate.CFG:Get("shield_core","max_size",4096);
	self.WireResizeDelay = StarGate.CFG:Get("shield_core","wire_resize_delay",2);
	self.Entity:SetNWFloat("MinSize", self.MinSize);
	self.Entity:SetNWFloat("MaxSize", self.MaxSize);
	self:SetWire("Strength",self.Strength);

	self.Pressed = false;

	self:SetNWBool("HUD_Enable", 0);
	self:SetNWInt("HUD_Percent", self.Strength);

	self.RegTime = 0;
	self.Depleted = false;

	self.PlyOldEyeAngle = Angle(0,0,0);

	-- The menu commands below used to accept anyone: any player could resize, move or reconfigure
	-- (e.g. enable Immunity on) someone else's shield core from the console. Only the owner, who is
	-- the only one allowed to open the menu (ENT:TrueUse), may use them now.
	local core = self;
	local function MayConfigure(ply)
		return IsValid(ply) and ply == core.Owner and ply == core.Player;
	end

	concommand.Add("SC_Apply"..self:EntIndex(),function(ply,cmd,args)
		if not MayConfigure(ply) then return end
		self:ApplyMenu(args);
	end);

	concommand.Add("SC_Close"..self:EntIndex(),function(ply,cmd,args)
		if not MayConfigure(ply) then return end
		self:CloseMenu();
		self:RestoreMenuSnapshot(); -- Undo the preview changes

		if (not self.Anim and not (IsValid(self.Shield) and self.Shield.Enabled)) then
			self.Busy = false;
			local seq = self:LookupSequence("Close");
			self:ResetSequence(seq);
			self.Anim = true;
			if timer.Exists("Anim"..self:EntIndex()) then timer.Destroy("Anim"..self:EntIndex()); end
			timer.Create( "Anim"..self:EntIndex(), 10, 0, function()
				self.Anim = false;
				self.Entity:SetModel("models/Madman07/destiny_emmiter/destiny_emmiter.mdl");
			end);
		end
    end);

	concommand.Add("SC_Size"..self:EntIndex(),function(ply,cmd,args)
		if not MayConfigure(ply) then return end
		self.Entity:SetNWVector("Size", Vector(tonumber(args[1]),tonumber(args[2]),tonumber(args[3])));
		self.SSize = Vector(tonumber(args[1]),tonumber(args[2]),tonumber(args[3]));
    end);

	concommand.Add("SC_Angle"..self:EntIndex(),function(ply,cmd,args)
		if not MayConfigure(ply) then return end
		self.Entity:SetNWAngle("Ang", Angle(tonumber(args[1]),tonumber(args[2]),tonumber(args[3])));
		self.Ang = Angle(tonumber(args[1]),tonumber(args[2]),tonumber(args[3]));
    end);

	concommand.Add("SC_Pos"..self:EntIndex(),function(ply,cmd,args)
		if not MayConfigure(ply) then return end
		self.Entity:SetNWVector("Pos", Vector(tonumber(args[1]),tonumber(args[2]),tonumber(args[3])));
		self.Pos = Vector(tonumber(args[1]),tonumber(args[2]),tonumber(args[3]))
    end);

	concommand.Add("SC_Visual_Model"..self:EntIndex(),function(ply,cmd,args)
		if not MayConfigure(ply) then return end
		if (args[1] == "1") then 	 self.Mod = "models/Madman07/shields/sphere.mdl";
		elseif (args[1] == "2") then self.Mod = "models/Madman07/shields/box.mdl";
		elseif (args[1] == "3") then self.Mod = "models/Madman07/shields/atlantis.mdl"; end
		self.Entity:SetNWString("Mod", self.Mod);
    end);

	concommand.Add("SC_Visual_Col"..self:EntIndex(),function(ply,cmd,args)
		if not MayConfigure(ply) then return end
		self.Col = Vector(tonumber(args[1]),tonumber(args[2]),tonumber(args[3]));
		self.Entity:SetNWVector("Col", self.Col);
    end);
	
	self:SpawnButton()

end

function ENT:SpawnFunction( ply, tr )
	if (!tr.Hit) then return end

	local PropLimit = GetConVar("CAP_shieldcore_max"):GetInt()
	if(ply:GetCount("CAP_shieldcore")+1 > PropLimit) then
		ply:SendLua("GAMEMODE:AddNotify(SGLanguage.GetMessage(\"entity_limit_shield_core\"), NOTIFY_ERROR, 5); surface.PlaySound( \"buttons/button2.wav\" )");
		return
	end

	local ang = ply:GetAimVector():Angle(); ang.p = 0; ang.r = 0; ang.y = (ang.y+135) % 360;

	local ent = ents.Create("shield_core");
	ent:SetAngles(ang);
	ent:SetPos(tr.HitPos);
	ent:Spawn();
	ent:Activate();
	ent.Owner = ply;

	local phys = ent:GetPhysicsObject()
	if IsValid(phys) then phys:EnableMotion(false) end

	ply:AddCount("CAP_shieldcore", ent)
	return ent;
end

function ENT:SpawnButton()
	local button = ents.Create("shield_core_button");
	button:SetParent(self);
	--button:SetRenderMode(RENDERMODE_TRANSALPHA);
	button.Parent = self;
	button:SetPos(self:GetPos()-self:GetForward()*0.2+self:GetRight()*40+self:GetUp()*18)
	button:SetAngles(self:GetAngles()+Angle(0,0,0))
	--button:SetColor(Color(0,0,0,0))
	button:DrawShadow(false)
	button:Spawn();
	button:Activate();
	self.Button = button	
	if CPPI and IsValid(p) and button.CPPISetOwner then button:CPPISetOwner(p) end
end

function ENT:OnRemove()
	StarGate.WireRD.OnRemove(self);
	if IsValid(self.Shield) then self.Shield:Remove() end
	if timer.Exists("Anim"..self:EntIndex()) then timer.Destroy("Anim"..self:EntIndex()); end
	if IsValid(self.Entity) then self.Entity:Remove(); end
	if IsValid(self.Camera) then self.Camera:Remove(); end
	if IsValid(self.Player) then self.Player:SetViewEntity(self.Player); end
end

function ENT:TrueUse(ply)
	if(not self.Busy and ply == self.Owner and not self.Pressed)then
		-- The shield stays up while you edit it; OK compares with how it is now (see ENT:ApplyMenu)
		self:TakeMenuSnapshot();

		if (not IsValid(self.Camera)) then
			self.Camera = ents.Create("prop_physics");
		end
		self.Camera:SetModel("models/sandeno/naquadah_bottle.mdl");
		self.Camera:SetColor(Color(0,0,0,0));
		self.Camera:SetRenderMode(RENDERMODE_TRANSALPHA);
		local pos = self:LocalToWorld(Vector(750,750,500));
		self.Camera:SetPos(pos);
		local ang = (self:GetPos()-pos):Angle();
		self.Camera:SetAngles(ang);
		self.Camera:Spawn();
		self.Camera:Activate();
		if CPPI and IsValid(self.Owner) and self.Camera.CPPISetOwner then self.Camera:CPPISetOwner(self.Owner) end

		local phys = self.Camera:GetPhysicsObject()
		if IsValid(phys) then phys:EnableMotion(false) end
		constraint.Weld(self.Entity,self.Camera,0,0,0,true)

		self.PlyOldEyeAngle = ply:EyeAngles();
		ply:SetViewEntity(self.Camera);
		--ply:SnapEyeAngles(Angle(0,180,0));

		self.Entity:SetNWBool("Kill", false);

		umsg.Start("ShieldCorePanel",ply)
	    umsg.Entity(self.Entity);
	    umsg.End()
		self.Player = ply;
		ply.ShieldCore = self;

		local fx = EffectData();
		fx:SetEntity(self.Entity);
		fx:SetOrigin(self.Entity:GetPos()); -- Effects only reach players near their origin (was 0,0,0)
		util.Effect("shield_core_preview",fx,true,true);

		//self.Entity:SetNWVector("Col", Vector(170,189,255)); // shield dont want to accept colors after menu creation, lets fix it here
	end
end

--################# Menu: editing the shield while it stays up

-- How the shield is before editing (the preview commands below change these while the menu is open)
function ENT:TakeMenuSnapshot()
	self.MenuSnapshot = {
		Size = self.Entity:GetNWVector("Size", Vector(100,100,100)),
		Ang = self.Entity:GetNWAngle("Ang", Angle(0,0,0)),
		Pos = self.Entity:GetNWVector("Pos", Vector(0,0,0)),
		Col = self.Entity:GetNWVector("Col", Vector(170,189,255)),
		Mod = self.Mod,
		MenuData = self.MenuData,
	};
end

function ENT:RestoreMenuSnapshot()
	local snap = self.MenuSnapshot;
	if (not snap) then return end
	self.SSize, self.Ang, self.Pos, self.Col, self.Mod = snap.Size, snap.Ang, snap.Pos, snap.Col, snap.Mod;
	self.Entity:SetNWVector("Size", snap.Size);
	self.Entity:SetNWAngle("Ang", snap.Ang);
	self.Entity:SetNWVector("Pos", snap.Pos);
	self.Entity:SetNWVector("Col", snap.Col);
	self.Entity:SetNWString("Mod", snap.Mod);
	self.MenuSnapshot = nil;
end

function ENT:CloseMenu()
	if IsValid(self.Player) then self.Player:SetViewEntity(self.Player) end
	self.Busy = false;
	self.Entity:SetNWBool("Kill", true); -- Ends the preview effect
	if IsValid(self.Camera) then self.Camera:Remove() end
end

-- (Re)creates the shield bubble with the current settings. It starts switched off.
function ENT:BuildShield()
	if IsValid(self.Shield) then self.Shield:Remove() end

	local a = ents.Create("shield_core_buble");
	a:SetModel("models/hunter/blocks/cube025x025x025.mdl");
	a:SetPos(self:LocalToWorld(self.Pos));
	a:SetAngles(self:GetAngles()+self.Ang);
	a.Parent = self;
	if CPPI and IsValid(self.Owner) and a.CPPISetOwner then a:CPPISetOwner(self.Owner) end
	a:SetNWVector("Col",self.Entity:GetNWVector("Col",Vector(100,100,100)));

	a:Spawn();
	a:Activate();

	a:SetCollisionScale(self.Mod, self.SSize/512);
	-- Parented, so the shield follows the generator every frame. It used to be welded, but its physics
	-- object is frozen, so the weld couldn't carry it and Think snapped it into place every 0.5s.
	a:SetParent(self.Entity);
	self.Shield = a;
end

local function Changed(a, b) -- Menu sliders aren't always exact whole numbers
	if (isvector(a) or isangle(a)) then
		return math.abs(a[1]-b[1]) + math.abs(a[2]-b[2]) + math.abs(a[3]-b[3]) > 0.5
	end
	return math.abs((tonumber(a) or 0) - (tonumber(b) or 0)) > 0.001
end

-- OK in the menu. args: strength, immunity, always show, atlantis, key, anti noclip, containment, frequency,
-- fire frequency, rising edge
--  * Size: the shield stays up and smoothly resizes
--  * Immunity, Containment, frequencies, the key: applied straight away
--  * Anything else (shape, angle, position, colour, strength, always show, atlantis, anti noclip, rising edge):
--    the shield is rebuilt with the new settings, which switches it off
function ENT:ApplyMenu(args)
	self:CloseMenu();
	local snap = self.MenuSnapshot or {Size = self.SSize, Ang = self.Ang, Pos = self.Pos, Col = self.Col, Mod = self.Mod, MenuData = self.MenuData};
	self.MenuSnapshot = nil;
	self.SSize = self.SSize or self.Entity:GetNWVector("Size", Vector(100,100,100));
	self.Ang = self.Ang or self.Entity:GetNWAngle("Ang", Angle(0,0,0));
	self.Pos = self.Pos or self.Entity:GetNWVector("Pos", Vector(0,0,0));
	self.Col = self.Col or self.Entity:GetNWVector("Col", Vector(170,189,255));
	-- Menu sizes are limited like the Wire input
	self.SSize = Vector(math.Clamp(self.SSize.x, self.MinSize, self.MaxSize), math.Clamp(self.SSize.y, self.MinSize, self.MaxSize), math.Clamp(self.SSize.z, self.MinSize, self.MaxSize));
	self.Entity:SetNWVector("Size", self.SSize);
	for i = 1, 10 do args[i] = args[i] or "0" end
	local old = string.Explode(" ", snap.MenuData or "0 0 0 0 5 0 0 0 0 0");

	local rebuild = not IsValid(self.Shield) or self.Mod ~= snap.Mod
		or Changed(self.Ang, snap.Ang) or Changed(self.Pos, snap.Pos) or Changed(self.Col, snap.Col)
		or Changed(args[1], old[1]) or Changed(args[3], old[3]) or Changed(args[4], old[4]) or Changed(args[6], old[6]) or Changed(args[10], old[10]);

	self:SetMultiplier(tonumber(args[1]));
	self.Immunity = util.tobool(tonumber(args[2]));
	self.Draw = util.tobool(tonumber(args[3]));
	self.Atlantis = util.tobool(tonumber(args[4])) and self.HasResourceDistribution; -- this is working only with power attached, so it need RS
	self.AntiNoclip = util.tobool(tonumber(args[6])); -- Kick noclipping players out of noclip when they hit the shield
	self.Containment = util.tobool(tonumber(args[7])); -- Keep things in instead of out
	self.Frequency = math.Clamp(math.floor(tonumber(args[8]) or 0), 0, 1500);
	self.FireFrequency = math.Clamp(math.floor(tonumber(args[9]) or 0), 0, 1500);
	args[8], args[9] = tostring(self.Frequency), tostring(self.FireFrequency);
	self.RisingEdge = util.tobool(tonumber(args[10]));

	if (Changed(args[5], old[5]) or not self.NumpadSet) then
		numpad.OnDown(self.Owner, tonumber(args[5]), "Toggle_Shield_Core", self.Entity);
		self.NumpadSet = true;
	end

	self.MenuData = table.concat(args, " ", 1, 10);
	self.Entity:SetNWString("MenuData", self.MenuData);

	if (rebuild) then
		if (IsValid(self.Shield) and self.Shield.Enabled) then
			self.Pressed = false; -- Status() ignores calls for 7s after the last toggle
			self:Status(false);
		end
		self:BuildShield();
	else
		if (Changed(self.SSize, snap.Size)) then
			self.Shield:ResizeTo(self.SSize/512);
		end
		if (self.Shield.Enabled) then
			self.Shield:SetContainment(self.Containment);
		end
	end

	// for tracelines
	self.Shield:SetNWBool("Immunity",self.Immunity);
	self.Shield:SetNWEntity("Own",self.Owner);
	self:UpdateTrusted();
end

-- Energy factor for the shield's current size and shape
function ENT:UpdateSizeCost()
	if (IsValid(self.Shield) and self.Shield.ShapeScale) then
		self.ConsumeAmmount = self:GetSizeCostFactor(self.Shield.ShapeScale*512, self.Shield.ShShap or 1);
	end
end

function ENT:EmmiterAnimation(open)
	self.Anim = true;
	self:SetNWBool("ShouldClip", true);
	if timer.Exists("Anim"..self:EntIndex()) then timer.Destroy("Anim"..self:EntIndex()); end
	if open then
		self.Entity:SetModel("models/Madman07/destiny_emmiter/destiny_emmiter_anim.mdl");
		local seq = self:LookupSequence("Open");
		self:ResetSequence(seq);
		timer.Create( "Anim"..self:EntIndex(), 7, 1, function()
			self.Anim = false;
			self:SetNWBool("ShouldClip", false);
		end);
	else
		local seq = self:LookupSequence("Close");
		self:ResetSequence(seq);
		timer.Create( "Anim"..self:EntIndex(), 7, 1, function()
			self.Anim = false;
			self:SetNWBool("ShouldClip", false);
			self.Entity:SetModel("models/Madman07/destiny_emmiter/destiny_emmiter.mdl");
		end);
	end
	timer.Create( "Sound"..self:EntIndex(), 0.4, 1, function() if (IsValid(self)) then self:EmitSound(self.Sounds.Open,100,100); end end);
end

function ENT:Status(status,nosound)
	if not IsValid(self.Shield) then return end

	if not self.Pressed then
		self.Pressed = true;
		timer.Create( "Press", 7, 0, function() self.Pressed = false end);

		if (self.Depleted and status) then
			self:EmmiterAnimation(false); -- Close emmiter - shield inactive
			self.Depleted = nil;
			self.Shield.Depleted = nil;
			return
		end
		if (status and not self.Shield.Enabled) then
			-- Bigger shields cost much more, to run and to switch on (see ENT:GetSizeCostFactor in shared.lua).
			-- This used the size multiplier as a radius in units, so it always came out as 1.
			self:UpdateSizeCost();
			self.ExtraConsume = math.exp(math.Clamp(self.StrengthMultiplier[3]*1.3,0.2,600));
			local engage = self.EngageEnergy*self.ConsumeAmmount;
			local energy = self:GetResource("energy",engage);
			if((not self.Depleted or (self.Strength >= self.RestoreThresold)) and self.Strength > 0 and energy >= engage) then
				-- Taking the enagage energy, you will get back later (when turning off the shield)
				self:ConsumeResource("energy",engage);
				self.EngagedEnergy = engage; -- Given back exactly, even if it was resized meanwhile
				--Enable shield
				self.Shield:Status(true);
				if(not nosound) then
					self:EmitSound(self.Sounds.Engage,90,math.random(90,110));
				end
				self:EmmiterAnimation(true); -- Open emmiter - shield active
				self:SetWire("Active",1);
				self:SetSkin(1);
				return
			end
		elseif(not status and self.Shield.Enabled) then
			-- Give back the energy, we took when it was enagaged
			self:SupplyResource("energy",self.EngagedEnergy or self.EngageEnergy);
			self.EngagedEnergy = nil;
			-- Disable Shield
			self.Shield:Status(false);
			if(not nosound and not self.Depleted) then
				self:EmitSound(self.Sounds.Disengage,90,math.random(90,110));
			end
			self:SetSkin(0);
			self:EmmiterAnimation(false); -- Close emmiter - shield inactive
			self:SetWire("Active",0);
			return
		end

		-- Fail animation
		self:EmitSound(self.Sounds.Fail[1],90,math.random(90,110));
		self:EmitSound(self.Sounds.Fail[2],90,math.random(90,110));
	end
end

function ENT:Think(ply)

	if (self.ThinkTime < CurTime() and IsValid(self.Shield)) then

		if (self.Shield:GetParent() ~= self.Entity) then -- Parented shields follow by themselves
			self.Shield:SetPos(self:LocalToWorld(self.Pos));
			self.Shield:SetAngles(self:GetAngles()+self.Ang);
		end

		self.ThinkTime = CurTime()+0.5
		self:WireThink();
		local enabled = self.Shield.Enabled;
		if self.Atlantis then	-- infinite strength if we have power
			self:ShowOutput(enabled, true);
			local energy = self:GetResource("energy");
			if(energy <= 1000) then -- minimal energy for making it work
				self:Status(false);
				return
			end
		else
			if (CurTime() > self.RegTime) then self:Regenerate(enabled); end
			self:ShowOutput(enabled);
			if (self.Strength < 1 and not self.Depleted) then
				self.Depleted = true;
				self.Shield.Depleted = true;
				self.Shield:SetNWBool("depleted",true);
				self.Shield:Status(false);
				self:SetWire("Active",0);
			end
			if(self.Depleted) then
				-- Reenable shielt - It was depleted before (But alter the Thresold, so people wont have it up so fast again or need to wait ages)
				if(self.Strength >= math.Clamp(self.RestoreThresold/self.StrengthMultiplier[2],3,40)) then
					self.Depleted = nil;
					self.Shield.Depleted = nil;
					self:EmitSound(self.Sounds.Engage,90,math.random(90,110));

					--Engage Shield!
					self.Shield:Status(true);
					self.Shield:SetNWBool("depleted",false); -- For the traceline class - Clientside
					self:SetWire("Active",1);
				end
			elseif(enabled and self.HasResourceDistribution and self.ConsumeMultiplier ~= 0) then
				-- Consume energy
				local energy = self:GetResource("energy");

				-- Make the shield consume more power depending on it's strength and size (follows a resize)
				self:UpdateSizeCost();
				local take_energy = (self.ConsumeAmmount or 1)*(self.ExtraConsume or 1)*self.ConsumeMultiplier
				self:ConsumeResource("energy",math.Clamp(take_energy,1,energy));
				if(energy <= take_energy) then -- no energy - shut down it
					self:Status(false);
					return
				end
			end

		end
	end

	if self.Anim then
		self:NextThink(CurTime());
		return true
	else
		self:NextThink(CurTime()+0.5);
		return true
	end
end

function ENT:ShowOutput(enabled, atl)
	local add = 0;
	if(enabled) then
		add = 1;
	end
	if(self.Depleted) then
		add = 2;
	end
	self:SetNWInt("HUD_Enable", add);
	if atl then
		self:SetNWInt("HUD_Percent", 100);
		self:SetWire("Strength",100);
	else
		self:SetNWInt("HUD_Percent", self.Strength);
		self:SetWire("Strength",math.floor(self.Strength));
	end
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
function ENT:Hit(strength,normal,pos,fireFrequency)
	-- Weapons on the shield's fire frequency hit much softer (like the regular shield)
	if (fireFrequency and (self.FireFrequency or 0) ~= 0 and math.abs(self.FireFrequency - fireFrequency) < 50) then
		strength = (strength or 0)/5;
	end
	self:SetWire("Hit", 1);
	self:SetWire("Hit Position", pos or self.Entity:GetPos());
	self:SetWire("Hit Strength", math.Round(strength or 0, 2));
	self.HitPulse = true;

	-- Calculate strenght-taking multiplier: Are we a shield, which is not moving? If so, we are many times stronger than a shield of a ship which is moving.
	local divisor = 1;
	if(self.Entity:GetVelocity():Length() < 5) then
		divisor = StarGate.CFG:Get("shield","stationary_shield_multiplier",10);
	end

	-- Take strength if not atlantis, otherwise take energy
	if self.Atlantis then
		-- Consume energy
		local energy = self:GetResource("energy");

		-- Make the shield consume more power depending on hit strength
		local take_energy = math.Clamp(200*math.Clamp(strength,1,40)/(self.StrengthMultiplier[1]*self.StrengthConfigMultiplier*divisor),1,10000)*StarGate.CFG:Get("shield_core","atlantis_hit",50);
		self:ConsumeResource("energy",math.Clamp(take_energy,1,energy));
	else
		self.Strength = math.Clamp(self.Strength-2*math.Clamp(strength,1,20)/(self.StrengthMultiplier[1]*self.StrengthConfigMultiplier*divisor),0,100);
	end

	self.RegTime = CurTime()+2.5;

	if(StarGate.CFG:Get("shield","apply_force",false)) then
		-- Make us bounce around
		local phys = self:GetPhysicsObject();
		phys:ApplyForceOffset(-1*normal*strength*100*phys:GetMass()/self.StrengthMultiplier[1],pos);
	end
end

--################# Reset it's strength @aVoN
function ENT:Regenerate(enabled)
	if(self.Strength < 100) then
		local multiplier = 1;
		-- Disabled shields can regenrate 2 times faster!
		if(not (enabled or self.Depleted)) then
			multiplier = multiplier*2.5;
		end
		-- Consume energy when restoring the strength
		if(StarGate.HasResourceDistribution) then
			local energy = self:GetResource("energy");
			local speed = math.Clamp(energy/5000,1,4); -- Can make up to 4 times faster to regenerate with enough power connected (ZPMs, resource Caches etc)
			multiplier = math.floor(multiplier*speed);
			local take_energy = multiplier*20
			if(take_energy > energy) then return end;
			self:ConsumeResource("energy",take_energy);
		else
			-- For those without lifesupport: Make the shield regenerate a bit faster (Due to request)
			multiplier = multiplier*2;
		end
		multiplier = multiplier*(self.RestoreMultiplier/self.StrengthMultiplier[2]); -- Multiplier from the config and with the StrengthMultiplier
		self.Strength = math.Clamp(self.Strength+multiplier,0,100);
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
	elseif(k=="Size") then
		-- Applied in Think, at most once every wire_resize_delay seconds, always as the smooth resize
		if (isvector(v) and not v:IsZero()) then
			self.WireSizeTarget = Vector(math.Clamp(v.x, self.MinSize, self.MaxSize), math.Clamp(v.y, self.MinSize, self.MaxSize), math.Clamp(v.z, self.MinSize, self.MaxSize));
		end
	elseif(k=="Immunity" or k=="Containment") then
		self:SetMenuOption(k == "Immunity" and 2 or 7, (v or 0) >= 1);
	elseif(k=="Frequency" or k=="Fire Frequency") then
		self:SetMenuOption(k == "Frequency" and 8 or 9, math.Clamp(math.floor(tonumber(v) or 0), 0, 1500));
	elseif(k=="Allowed Players") then
		self.AllowedPlayers = {};
		for _,ply in pairs(istable(v) and v or {}) do
			if (IsValid(ply) and ply:IsPlayer()) then table.insert(self.AllowedPlayers, ply) end
		end
		self:UpdateTrusted();
	end
end

-- Tell clients who may shoot through (for beam/bullet effects): Allowed Players, and with Immunity the owner
-- and his prop protection friends. See ENT:IsTrusted on the shield.
function ENT:UpdateTrusted()
	if (not IsValid(self.Shield)) then return end
	local ids = {};
	for _,ply in pairs(player.GetAll()) do
		if (self.Shield:IsTrusted(ply)) then table.insert(ids, ply:EntIndex()) end
	end
	local text = " " .. table.concat(ids, " ") .. " ";
	if (self.Shield:GetNWString("TrustedIDs", "") ~= text) then self.Shield:SetNWString("TrustedIDs", text) end
end

-- Immunity (2), Containment (7), Frequency (8) and Fire Frequency (9) can change live, from the menu or
-- Wire. Keeps the menu's data in sync.
function ENT:SetMenuOption(index, value)
	local data = string.Explode(" ", self.MenuData or "0 0 0 0 5 0 0 0 0 0");
	for i = 1, 10 do data[i] = data[i] or "0" end
	data[index] = (value == true and "1") or (value == false and "0") or tostring(value);
	self.MenuData = table.concat(data, " ", 1, 10);
	self.Entity:SetNWString("MenuData", self.MenuData);
	if (index == 2) then self.Immunity = value
	elseif (index == 7) then self.Containment = value
	elseif (index == 8) then self.Frequency = value
	elseif (index == 9) then self.FireFrequency = value end
	self:UpdateTrusted();
	if (IsValid(self.Shield)) then
		self.Shield:SetNWBool("Immunity", self.Immunity);
		if (self.Shield.Enabled) then self.Shield:SetContainment(self.Containment) end
	end
end

-- Wire size requests and the Wire outputs (called every 0.5s)
function ENT:WireThink()
	local shield = self.Shield;
	if (self.WireSizeTarget and CurTime() >= (self.NextWireResize or 0) and not self.MenuSnapshot and IsValid(shield)) then
		local target = self.WireSizeTarget;
		self.WireSizeTarget = nil;
		local current = self.SSize or self.Entity:GetNWVector("Size", Vector(100,100,100));
		if (target:Distance(current) > 1) then
			self.SSize = target;
			self.Entity:SetNWVector("Size", target);
			shield:ResizeTo(target/512);
			self.NextWireResize = CurTime() + self.WireResizeDelay;
		end
	end

	self:UpdateTrusted(); -- Prop protection friends can change any time

	local up = IsValid(shield) and shield.Enabled;
	local energy_use = 0;
	if (up and self.HasResourceDistribution and not self.Atlantis) then
		energy_use = (self.ConsumeAmmount or 1)*(self.ExtraConsume or 1)*self.ConsumeMultiplier*2; -- Charged every 0.5s
	end
	self:SetWire("Energy Use", math.Round(energy_use));
	self:SetWire("Size", self.SSize or self.Entity:GetNWVector("Size", Vector(100,100,100)));

	local covered = 0;
	local contained = 0;
	if (IsValid(shield) and shield.IsShieldUp and shield:IsShieldUp()) then
		local level = shield:GetCoverLevel();
		if (level) then
			local bottom, top = shield:GetCoverRange();
			covered = math.Clamp((level - bottom)/math.max(top - bottom, 1), 0, 1)*100;
		else
			covered = 100;
		end
		if (shield:IsContainment()) then
			for e,_ in pairs(shield.Contained or {}) do
				if (IsValid(e)) then contained = contained + 1 end
			end
		end
	end
	self:SetWire("Covered %", math.floor(covered));
	self:SetWire("Contained", contained);
	self:SetWire("Resizing", (IsValid(shield) and shield.ResizeEnd) and 1 or 0);

	if (self.HitPulse) then -- "Hit" is 1 for one update after a hit
		self.HitPulse = false;
	else
		self:SetWire("Hit", 0);
	end
end

numpad.Register("Toggle_Shield_Core",
	function(p,e)
		if not IsValid(e) then return end;
		if not IsValid(e.Shield) then return end;
		if(e.Shield.Enabled) then
			e:Status(false);
		else
			e:Status(true);
		end
	end
);


function ENT:PreEntityCopy()
	local dupeInfo = {}
	if IsValid(self.Entity) then
		dupeInfo.EntID = self.Entity:EntIndex()
	end
	/*
	if WireAddon then
		dupeInfo.WireData = WireLib.BuildDupeInfo( self.Entity )
	end*/

	dupeInfo.SSize = self.SSize;
	dupeInfo.Ang = self.Ang;
	dupeInfo.Pos = self.Pos;
	dupeInfo.Col = self.Col;
	dupeInfo.Mod = self.Mod;
	dupeInfo.MenuData = self.MenuData;

	duplicator.StoreEntityModifier(self, "SCDupeInfo", dupeInfo)
	StarGate.WireRD.PreEntityCopy(self)
end
duplicator.RegisterEntityModifier( "SCDupeInfo" , function() end)

function ENT:PostEntityPaste(ply, Ent, CreatedEntities)
	if (StarGate.NotSpawnable(Ent:GetClass(),ply)) then self.Entity:Remove(); return end
	if (IsValid(ply)) then
		local PropLimit = GetConVar("CAP_shieldcore_max"):GetInt();
		if(ply:GetCount("CAP_shieldcore")+1 > PropLimit) then
			ply:SendLua("GAMEMODE:AddNotify(SGLanguage.GetMessage(\"entity_limit_shield_core\"), NOTIFY_ERROR, 5); surface.PlaySound( \"buttons/button2.wav\" )");
			self.Entity:Remove();
			return
		end
	end

	local dupeInfo = Ent.EntityMods.SCDupeInfo

	if dupeInfo.EntID then
		self.Entity = CreatedEntities[ dupeInfo.EntID ]
	end
    /*
	if(Ent.EntityMods and Ent.EntityMods.SCDupeInfo.WireData) then
		WireLib.ApplyDupeInfo( ply, Ent, Ent.EntityMods.SCDupeInfo.WireData, function(id) return CreatedEntities[id] end)
	end  */

	self.Entity:SetNWVector("Size", dupeInfo.SSize);
	self.Entity:SetNWAngle("Ang", dupeInfo.Ang);
	self.Entity:SetNWVector("Pos", dupeInfo.Pos);
	self.Entity:SetNWVector("Col", dupeInfo.Col);
	self.Entity:SetNWString("Mod", dupeInfo.Mod);
	self.Entity:SetNWString("MenuData", dupeInfo.MenuData);

	self.SSize = dupeInfo.SSize;
	self.Ang = dupeInfo.Ang;
	self.Pos = dupeInfo.Pos;
	self.Col = dupeInfo.Col;
	self.Mod = dupeInfo.Mod;
	self.MenuData = dupeInfo.MenuData;

	if (IsValid(ply)) then
		self.Owner = ply;
		ply:AddCount("CAP_shieldcore", self.Entity)
	end
	StarGate.WireRD.PostEntityPaste(self,ply,Ent,CreatedEntities)

end

if (StarGate and StarGate.CAP_GmodDuplicator) then
	duplicator.RegisterEntityClass( "shield_core", StarGate.CAP_GmodDuplicator, "Data" )
end