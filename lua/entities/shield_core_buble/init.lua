--[[
	Shield Core Buble
	Copyright (C) 2011 Madman07
]]--

if (StarGate==nil or StarGate.CheckModule==nil or not StarGate.CheckModule("devices")) then return end
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.CAP_NotSave = true;
ENT.NoDissolve = true;
ENT.DoNotDuplicate = true 

AddCSLuaFile("modules/bullets.lua");
AddCSLuaFile("modules/sphere.lua");
AddCSLuaFile("modules/box.lua");
AddCSLuaFile("modules/atlantis.lua");
include("modules/bullets.lua");
include("modules/sphere.lua")
include("modules/box.lua")
include("modules/atlantis.lua")

StarGate.Trace:Add("shield_core_buble",
	function(e,values,trace,in_box)
		if(not e.Depleted and e.Enabled) then
			local own = e;
			if (type(values[3]) == "table") then
				own = StarGate.GetMultipleOwner(values[3][1]);
				if (IsValid(values[3][1])) then
					values[3][1]:SetNWEntity("SC_Owner", own); // for clientside prediction
				end
			else
				own = StarGate.GetMultipleOwner(values[3]);
				if (IsValid(values[3])) then
					values[3]:SetNWEntity("SC_Owner", own);
				end
			end
			if not IsValid(own) then return true end

			if (e.nocollide[own] or (e.Parent.Immunity and e.Parent.Owner == own)) then
				return false
			else
				return true
			end
		else
			return false
		end
	end
);

-- Shape ids (also sent to clients as "PhysicModel")
local SHAPE_SPHERE, SHAPE_BOX, SHAPE_ATLANTIS = 1, 2, 3
-- Radius of the shield meshes at scale 1. The Atlantis dome is 279 wide, 208 high and sits on its base (z >= 0).
-- (self.Size, used for tracelines, is 256 per unit and so ~28% bigger than what you actually see)
local SHAPE_RADII = {
	[SHAPE_SPHERE] = Vector(200,200,200),
	[SHAPE_BOX] = Vector(200,200,200),
	[SHAPE_ATLANTIS] = Vector(279,279,208),
}
local MAX_MARGIN = 64 -- Things are pushed back when their centre is this close to the shield (half their size, at most this)

local function WeakTable() return setmetatable({}, {__mode = "k"}) end

-----------------------------------INIT----------------------------------

function ENT:Initialize()
	self.Entity:PhysicsInit(SOLID_VPHYSICS);
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS);
	self.Entity:SetSolid(SOLID_VPHYSICS);
	self.Entity:SetColor(Color(0,0,0,0));
	self.Entity:SetRenderMode(RENDERMODE_TRANSALPHA);

	self.Enabled = false;
	self.nocollide = {}; -- [entity] = true: allowed to pass (inside when the shield came up)
	self.nocollideID = {};
	self.Passed = WeakTable(); -- Entities we have already seen inside
	self.NextHit = WeakTable(); -- Per entity cooldown for hit effects and energy drain
	self.Depleted = false;

	self.Radius = 0.01;
	self.Size = Vector(1,1,1);
	self.RayModel = {};

	self.IsShieldCore = true;
end

-----------------------------------COLLISION SCALE----------------------------------

function ENT:SetCollisionScale(model, size)
	local vect, vec;
	local convex = {}
	local ShieldModel;
	local mod = 1;

	if (model == "models/Madman07/shields/sphere.mdl") then ShieldModel = SphereModel;
	elseif (model == "models/Madman07/shields/box.mdl") then ShieldModel = BoxModel;  mod = 2;
	elseif (model == "models/Madman07/shields/atlantis.mdl") then ShieldModel = AtlantisModel;  mod = 3; end

	for _, vertex in pairs(ShieldModel) do
		vec = Vector(vertex.x*size.x,vertex.y*size.y,vertex.z*size.z); -- hm, somewhy it should be y,x,z not x,y,z @ now fixed?
		vect = Vertex(vec, 1, 1, Vector( 0, 0, 1 ) )
		table.insert(convex, vect);
		table.insert(self.RayModel, vec);
	end

	if (#convex == 0) then return end //safefail

	if (size.x > size.y) then
		if (size.x > size.z) then self.Radius = size.x
		else self.Radius = size.z end
	else
		if (size.y > size.z) then self.Radius = size.y
		else self.Radius = size.z end
	end
	self.Size = size*256;
	local radii = SHAPE_RADII[mod];
	self.ShapeRadii = Vector(radii.x*size.x, radii.y*size.y, radii.z*size.z);

	-- The mesh is only used for tracelines (RayModel) now. Things are stopped by ENT:Think, the same way
	-- the regular shield does it, so the shield itself doesn't physically collide with anything.
	self.Entity:PhysicsFromMesh(convex)
	local phys = self.Entity:GetPhysicsObject();
	phys:EnableCollisions(false)
	phys:EnableMotion(false)
	self:SetCollisionBounds(-1*self.Radius*Vector(1,1,1)*256,self.Radius*Vector(1,1,1)*256)

	self:SetNWBool("DoPhysicClientside", true);
	self:SetNWInt("PhysicModel", mod);
	self:SetNWVector("PhysicScale", size);

	self:SetNWInt("SGESize",self.Radius);

	self:SetNWVector("TraceSize",self.Size);

	self:SetNotSolid(true);
	self.ShShap = mod;
end

function ENT:GetTraceSize()
	return self.Size;
end

-----------------------------------SHAPE----------------------------------

-- How far inside the shield shape a local position is (< 1 = inside) and the outward normal there (local).
-- margin grows the shape, so big things are pushed back before their centre reaches the shield.
function ENT:ShapeDepth(lp, margin)
	margin = margin or 0;
	local r = self.ShapeRadii + Vector(margin,margin,margin);
	if (self.ShShap == SHAPE_BOX) then
		local ax, ay, az = math.abs(lp.x)/r.x, math.abs(lp.y)/r.y, math.abs(lp.z)/r.z;
		local depth = math.max(ax, ay, az);
		if (depth == ax) then return depth, Vector(lp.x >= 0 and 1 or -1, 0, 0) end
		if (depth == ay) then return depth, Vector(0, lp.y >= 0 and 1 or -1, 0) end
		return depth, Vector(0, 0, lp.z >= 0 and 1 or -1);
	end
	if (self.ShShap == SHAPE_ATLANTIS and lp.z < -margin) then
		return math.huge, Vector(0,0,-1); -- Below the dome's base
	end
	local depth = Vector(lp.x/r.x, lp.y/r.y, lp.z/r.z):Length();
	local normal = Vector(lp.x/(r.x*r.x), lp.y/(r.y*r.y), lp.z/(r.z*r.z));
	if (normal:LengthSqr() == 0) then normal = Vector(0,0,1) end
	normal:Normalize();
	return depth, normal;
end

function ENT:IsEntityInShield()
	self.nocollide = {};
	self.nocollideID = {};
	if (not self.ShapeRadii) then return end
	local reach = math.max(self.ShapeRadii.x, self.ShapeRadii.y, self.ShapeRadii.z);
	for _,v in pairs(ents.FindInSphere(self.Entity:GetPos(), reach)) do
		if (v ~= self.Entity and self:ShapeDepth(self:WorldToLocal(v:LocalToWorld(v:OBBCenter()))) < 1) then
			self.nocollide[v] = true;
			table.insert(self.nocollideID, v:EntIndex()); //tracelines
		end
	end
end

-----------------------------------STATUS----------------------------------

function ENT:Status(status)
	self.Enabled = status;
	self.Passed = WeakTable();
	if status then
		self.Depleted = false;
		self:SetNWBool("depleted", false); -- Was never reset after a depletion, so clients kept ignoring the shield
		self:DrawBubbleEffect(Vector(1,1,1), Vector(1,1,1), 1, false, false);
		self:SetNotSolid(true);
		self:SetNWBool("Enabled",true); // tracelines
		self:IsEntityInShield();
		self:SetNWString("NoCollideID", string.Implode(" ", self.nocollideID)); // tracelines

		-- "Always show Bubble": drawn by the client (cl_init.lua) once the switch-on effect is done
		if (IsValid(self.Parent)) then
			self:SetNWBool("AlwaysShow", self.Parent.Draw == true);
			self:SetNWString("BubbleModel", self.Parent.Mod or "");
			self:SetNWVector("BubbleScale", (self.Parent:GetNWVector("Size", Vector(100,100,100)) - Vector(10,10,10))/512);
			self:SetNWFloat("EnabledTime", CurTime());
		end
	else
		self.nocollide = {};
		self.nocollideID = {};
		self:DrawBubbleEffect(Vector(1,1,1), Vector(1,1,1), 1, true, false);
		self:SetNWBool("Enabled",false);
		self:SetNotSolid(true);
	end
end

-----------------------------------DETECTION----------------------------------
-- Works like the regular shield (entities/shield): every tick, everything inside the shield that
-- isn't allowed to be there is pushed back out. Players (also noclipping ones, with Anti Noclip), NPCs,
-- props, contraptions and ships are all handled the same way.

function ENT:Think()
	if (self.Enabled and not self.Depleted and self.ShapeRadii and IsValid(self.Parent)) then
		self:ScanShield();
	end
	self:NextThink(CurTime());
	return true;
end

function ENT:CanBeReflected(e)
	if (e == self.Entity or e == self.Parent or self.nocollide[e] or e.IgnoreShield) then return false end
	if (e:IsWorld() or IsValid(e:GetParent())) then return false end -- Parented things move with their parent
	if (e.IsShieldCore or e:GetClass() == "shield") then return false end
	if (e:IsPlayer()) then
		if (not e:Alive()) then return false end
	elseif (e:GetSolid() == SOLID_NONE) then
		return false;
	end
	local owner = self.Parent.Owner;
	if (self.Parent.Immunity and IsValid(owner) and (e == owner or e:GetOwner() == owner)) then return false end
	return true;
end

function ENT:HasStrength()
	return self.Parent.Atlantis or self.Parent.Strength > 0;
end

function ENT:ScanShield()
	local reach = math.max(self.ShapeRadii.x, self.ShapeRadii.y, self.ShapeRadii.z) + MAX_MARGIN;
	for _,e in pairs(ents.FindInSphere(self.Entity:GetPos(), reach)) do
		if (self:CanBeReflected(e)) then
			local margin = math.Clamp(e:BoundingRadius()*0.5, 0, MAX_MARGIN);
			local depth = self:ShapeDepth(self:WorldToLocal(e:LocalToWorld(e:OBBCenter())), margin);
			if (depth < 1) then
				self:OnEntityInside(e, depth);
			else
				self.Passed[e] = nil; -- Outside again: next time it is a new arrival
			end
		end
	end
end

function ENT:OnEntityInside(e, depth)
	-- First time we see it inside: if it is already deep inside, it was spawned there or fired
	-- from inside by someone who may pass (same rule as the regular shield)
	if (not self.Passed[e]) then
		self.Passed[e] = true;
		local owner = e:GetOwner();
		if ((IsValid(owner) and self.nocollide[owner]) or depth <= 0.5) then
			self.nocollide[e] = true;
			return;
		end
	end
	if (not self:HasStrength()) then return end
	StarGate.ShieldOnTouch(self.Entity, e, function(v, do_not_draw_hit) self:Reflect(v, do_not_draw_hit) end, self.Parent.AntiNoclip);
end

-----------------------------------REFLECT----------------------------------

function ENT:Reflect(e, do_not_draw_hit)
	local pos = e:LocalToWorld(e:OBBCenter());
	local lp = self:WorldToLocal(pos);
	local depth, n = self:ShapeDepth(lp);
	local normal = self:LocalToWorld(n) - self.Entity:GetPos(); -- Outward, following the shield's shape
	local velo = e:GetVelocity(); -- Before reflecting, for the hit strength
	local phys = e:GetPhysicsObject();

	-- The actual pushing is shared with the regular shield (StarGate.ShieldReflectEntity in stargate/server/cap.lua)
	if (not StarGate.ShieldReflectEntity(self.Entity, e, normal)) then return end
	if (do_not_draw_hit) then return end

	local now = CurTime();
	if ((self.NextHit[e] or 0) > now) then return end
	self.NextHit[e] = now + 0.2;

	local strength = 5;
	if (IsValid(phys)) then
		strength = math.ceil(phys:GetMass()*velo:Length()/10000);
	end
	local hitpos = pos;
	if (depth > 0) then hitpos = self:LocalToWorld(lp/depth) end -- On the shield's surface
	self:DrawBubbleEffect(hitpos, normal, strength, false, true);
	-- Players, NPCs and missiles don't drain the shield (same as the regular shield)
	if (not (e:IsPlayer() or e:IsNPC() or e:GetClass() == "rpg_missile")) then
		self.Parent:Hit(strength, normal, hitpos);
	end
end

-----------------------------------EFFECT----------------------------------

function ENT:DrawBubbleEffect(pos, normal, strength, turn_off, hit)
	if IsValid(self.Parent) then
		if self.Parent.Draw then -- if Atlantis type
			if (not hit) then
				local fx = EffectData();
				fx:SetOrigin(self.Entity:GetPos()); -- Effects are only sent to players near their origin (was 0,0,0)
				fx:SetEntity(self.Parent);
				if(turn_off) then
					fx:SetMagnitude(0);
				else
					fx:SetMagnitude(1);
				end
				util.Effect("shield_core_flash_atl",fx,true,true);
			else
				local fx = EffectData();
				fx:SetOrigin(pos);
				fx:SetEntity(self);
				fx:SetNormal(normal)
				fx:SetScale(strength);
				util.Effect("shield_core_hit_atl",fx,true,true);
			end

		else
			if (hit) then
				local fx = EffectData();
				fx:SetOrigin(pos);
				fx:SetEntity(self);
				fx:SetNormal(normal)
				fx:SetScale(strength);
				util.Effect("shield_core_hit",fx,true,true);
			end

			local fx = EffectData();
			fx:SetOrigin(self.Entity:GetPos()); -- Effects are only sent to players near their origin (was 0,0,0)
			fx:SetEntity(self.Parent);
			if(turn_off) then
				fx:SetMagnitude(1);
			elseif(hit) then
				fx:SetMagnitude(2);
			else
				fx:SetMagnitude(0);
			end
			util.Effect("shield_core_flash",fx,true,true);
		end
	end
end

-----------------------------------HIT----------------------------------

function ENT:Hit(e,pos,dmg,normal)
	if(not self.Parent.Depleted) then
		if(self.Parent.Strength > 2) then
			normal = normal or Vector(0,0,0);
			self.Parent:Hit(dmg,normal,pos);
			self:DrawBubbleEffect(pos, normal, dmg, false, true);
		else
			self:Status(false);
			self.Parent:EmitSound(self.Parent.Sounds.Disengage,90,math.random(90,110));
			self.Parent.Depleted = true;
			self.Depleted = true;
			self.Entity:SetNWBool("depleted",true); -- For the traceline class - Clientside
		end
	end
end

local function CalcDmgProtect(ent, inflictor, attacker, ammount, dmginfo)
	if (IsValid(ent) and ent:IsPlayer()) then
		if (IsValid(inflictor) and attacker) then
			local class = inflictor:GetClass();
			if (class == "tokra_shield" or class == "shield_core_buble") then
				dmginfo:SetDamage(0);
			end

			local start = inflictor:LocalToWorld(inflictor:OBBCenter()) - inflictor:GetVelocity():GetNormal()*20; //move it a bit into attacker side (better protect for shield and staff)
			local endpos = ent:LocalToWorld(ent:OBBCenter());

			debugoverlay.Line(start, endpos, 20, Color(255,255,255));
			local dir2 = endpos - start;

			local trace = StarGate.Trace:New(start,dir2,inflictor);

			if IsValid(trace.Entity) then
				local class2 = trace.Entity:GetClass();
				if (class2 == "shield_core_buble" or class2 == "tokra_shield") then
					if(trace.Entity:Hit(attacker, trace.HitPos, dmginfo:GetDamage()*10, -1*trace.Normal)) then return end;
				end
				if (trace.Entity != ent) then
					local dmg = 2-math.Clamp(start:Distance(endpos)/100, 0, 2);
					dmginfo:SetDamage(dmg); //small damage relative to distance
				end
			end
		end
	end
end
hook.Add("EntityTakeDamage", "CAP.GlobalDamageProtect",CalcDmgProtect)