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
include("modules/bullets.lua");

StarGate.Trace:Add("shield_core_buble",
	function(e,values,trace,in_box)
		if(not e.Depleted and e:IsShieldUp()) then
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
			-- Immunity: the owner may always go or shoot through (see the shield core menu)
			-- Trusted shooters (Immunity owner and friends, Allowed Players) always go through
			if (e:IsTrusted(own)) then return false end

			-- Containment field: shots from inside are stopped, shots from outside go in
			local inside = in_box; -- Exact: e:ContainsPoint(trace start), see tracelines.lua
			if (e:IsContainment()) then return inside end

			-- Anything coming from outside is stopped. Only shots fired from inside the shield, by someone
			-- allowed to be in it, go out. (This used to only check the owner, so e.g. an Asuran gate weapon
			-- beam owned by a player standing inside went straight through and killed him.)
			if (not inside) then return true end

			if not IsValid(own) then return true end
			return not e.nocollide[own];
		else
			return false
		end
	end
);

-- Shape ids (also sent to clients as "PhysicModel")
local SHAPE_SPHERE, SHAPE_BOX, SHAPE_ATLANTIS = 1, 2, 3
-- Radius of the shield meshes at scale 1. The Atlantis dome is 279 wide, 208 high and sits on its base (z >= 0).
local SHAPE_RADII = {
	[SHAPE_SPHERE] = Vector(200,200,200),
	[SHAPE_BOX] = Vector(200,200,200),
	[SHAPE_ATLANTIS] = Vector(279,279,208),
}
local MAX_MARGIN = 64 -- Things are pushed back when their centre is this close to the shield (half their size, at most this)

local function WeakTable() return setmetatable({}, {__mode = "k"}) end

-- "stargate_shield_debug 1": log what the shield core decides for non-player entities (server console)
local ShieldDebug = CreateConVar("stargate_shield_debug","0",FCVAR_NONE,"Log shield core decisions for non-player entities");
local function DebugPrint(e, ...)
	if (ShieldDebug:GetBool() and IsValid(e) and not e:IsPlayer()) then print("[ShieldCore]", e, ...) end
end

-----------------------------------INIT----------------------------------

function ENT:Initialize()
	-- The shape is pure maths (ShapeDepth here, ContainsPoint/TraceIntersect in shared.lua), and things are
	-- stopped by ENT:Think - the shield doesn't physically collide with anything.
	-- It still gets a small physics object with collisions off, like the regular shield: many weapons and
	-- SENTs only react to (explode on) things that have one, e.g. in StartTouch/PhysicsCollide.
	self.Entity:PhysicsInitSphere(8, "default_silent");
	self.Entity:SetMoveType(MOVETYPE_NONE);
	self.Entity:SetNotSolid(true);
	local phys = self.Entity:GetPhysicsObject();
	if (IsValid(phys)) then
		phys:EnableCollisions(false);
		phys:EnableMotion(false);
	end
	self.Entity:SetColor(Color(0,0,0,0));
	self.Entity:SetRenderMode(RENDERMODE_TRANSALPHA);

	self.Enabled = false;
	self.nocollide = {}; -- [entity] = true: allowed to pass (inside when the shield came up)
	self.nocollideID = {};
	self.Passed = WeakTable(); -- Entities we have already seen inside
	self.NextHit = WeakTable(); -- Per entity cooldown for hit effects and energy drain
	self.Contained = WeakTable(); -- Containment mode: what is held inside
	self.Depleted = false;

	self.Radius = 0.01;

	self.IsShieldCore = true;
end

-----------------------------------COLLISION SCALE----------------------------------

function ENT:SetCollisionScale(model, size)
	local mod = SHAPE_SPHERE;
	if (model == "models/Madman07/shields/box.mdl") then mod = SHAPE_BOX;
	elseif (model == "models/Madman07/shields/atlantis.mdl") then mod = SHAPE_ATLANTIS; end
	self.ShShap = mod;
	self:SetNWInt("PhysicModel", mod);
	self:SetShapeSize(size);
end

-- Everything that depends on the shield's size (scale = menu size/512). Cheap, so it is also called
-- every few ticks while the shield resizes.
function ENT:SetShapeSize(size)
	self.ShapeScale = size;
	self.Radius = math.max(size.x, size.y, size.z);
	local radii = SHAPE_RADII[self.ShShap or SHAPE_SPHERE];
	self.ShapeRadii = Vector(radii.x*size.x, radii.y*size.y, radii.z*size.z);
	local low = (self.ShShap == SHAPE_ATLANTIS) and 0 or -self.ShapeRadii.z; -- The dome sits on its base
	self:SetCollisionBounds(Vector(-self.ShapeRadii.x, -self.ShapeRadii.y, low), self.ShapeRadii);

	self:SetNWVector("PhysicScale", size);
	self:SetNWVector("BubbleScale", size - Vector(10,10,10)/512); -- "Always show Bubble" (like the effects: menu size - 10)
end

local RESIZE_TIME = 3 -- Seconds a resize from the menu takes

-- Smoothly change size (instantly if the shield is off)
function ENT:ResizeTo(size, time)
	time = time or RESIZE_TIME;
	if (not self.ShapeScale or not self.Enabled or time <= 0) then
		self.ResizeEnd = nil;
		self:SetShapeSize(size);
		return;
	end
	self.ResizeFrom = self.ShapeScale;
	self.ResizeTarget = size;
	self.ResizeStart = CurTime();
	self.ResizeEnd = CurTime() + time;
end

function ENT:ResizeThink()
	if (not self.ResizeEnd) then return end
	local f = math.Clamp((CurTime() - self.ResizeStart)/(self.ResizeEnd - self.ResizeStart), 0, 1);
	if (f < 1 and CurTime() < (self.NextResizeStep or 0)) then return end
	self.NextResizeStep = CurTime() + 0.05;
	f = f*f*(3 - 2*f); -- Ease in and out
	self:SetShapeSize(LerpVector(f, self.ResizeFrom, self.ResizeTarget));
	if (f >= 1) then self.ResizeEnd = nil end
end

-- Switching containment on or off while the shield is up: whatever is inside right now is held in
-- (containment), or may pass (normal shield)
function ENT:SetContainment(on)
	if (on == self:IsContainment()) then return end
	self:SetNWBool("Containment", on);
	self:IsEntityInShield();
	self:SetNWString("NoCollideID", string.Implode(" ", self.nocollideID));
	self.Contained = WeakTable();
	if (on) then
		for v,_ in pairs(self.nocollide) do self.Contained[v] = true end
	end
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
	local reach = self.ShapeRadii:Length(); -- Far enough for a box's corners
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
		-- Containment: everything inside when it comes up is held in
		self:SetNWBool("Containment", IsValid(self.Parent) and self.Parent.Containment == true);
		self.Contained = WeakTable();
		if (self:IsContainment()) then
			for v,_ in pairs(self.nocollide) do self.Contained[v] = true end
		end

		-- "Always show Bubble": drawn by the client (cl_init.lua) once the switch-on effect is done
		if (IsValid(self.Parent)) then
			self:SetNWBool("AlwaysShow", self.Parent.Draw == true);
			self:SetNWBool("RisingEdge", self.Parent.RisingEdge == true); -- Rise and lower without the bubble too
			self:SetNWString("BubbleModel", self.Parent.Mod or "");
			self:SetNWFloat("EnabledTime", CurTime());
		end
	else
		-- nocollide is kept: with "Always show Bubble" the shield keeps protecting while it lowers
		-- (ENT:IsShieldUp), and it is rebuilt when the shield comes up again
		self:SetNWFloat("DisabledTime", CurTime());
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
	self:ResizeThink();
	if (self:IsShieldUp() and not self.Depleted and self.ShapeRadii and IsValid(self.Parent)) then
		self:ScanShield();
	end
	self:NextThink(CurTime());
	return true;
end

function ENT:CanBeReflected(e, containment)
	if (e == self.Entity or e == self.Parent or e.IgnoreShield) then return false end
	if (self.nocollide[e] and not containment) then return false end -- In a containment field everyone stays in
	if (e:IsWorld() or IsValid(e:GetParent())) then return false end -- Parented things move with their parent
	if (e.IsShieldCore or e:GetClass() == "shield") then return false end
	if (e:IsPlayer()) then
		if (not e:Alive()) then return false end
	elseif (e:GetSolid() == SOLID_NONE) then
		return false;
	end
	-- Trusted players and their shots, and anything carrying a shield identifier on our frequency, pass both ways
	if (self:IsTrusted(e) or self:IsTrusted(e:GetOwner()) or self:HasMatchingIdentifier(e)) then return false end
	return true;
end

-- May this player always go and shoot through? With Immunity: the owner and his prop protection friends.
-- Always: the players in the core's "Allowed Players" Wire input.
function ENT:IsTrusted(ply)
	local core = self.Parent;
	if (not IsValid(ply) or not ply:IsPlayer() or not IsValid(core)) then return false end
	if (core.AllowedPlayers and table.HasValue(core.AllowedPlayers, ply)) then return true end
	local owner = core.Owner;
	if (core.Immunity and IsValid(owner)) then
		if (ply == owner) then return true end
		if (owner.CPPIGetFriends) then
			local friends = owner:CPPIGetFriends();
			if (type(friends) == "table" and table.HasValue(friends, ply)) then return true end
		end
	end
	return false;
end

-- Is something constrained to an active shield identifier on the core's frequency? (Cached for a second,
-- looking through a contraption every tick would be slow.)
function ENT:HasMatchingIdentifier(e)
	local frequency = tonumber(self.Parent.Frequency) or 0;
	if (frequency == 0 or e:IsPlayer()) then return false end
	local cache = e.__ShieldIdentifierCache;
	if (cache and cache.Time > CurTime() and cache.Frequency == frequency) then return cache.Result end
	local result = false;
	for _,v in pairs(constraint.GetAllConstrainedEntities(e) or {}) do
		if (IsValid(v) and v:GetClass() == "shield_identifier" and v:Enabled() and v:GetFrequency() == frequency) then
			result = true;
			break;
		end
	end
	e.__ShieldIdentifierCache = {Time = CurTime() + 1, Frequency = frequency, Result = result};
	return result;
end

function ENT:HasStrength()
	return self.Parent.Atlantis or self.Parent.Strength > 0;
end

function ENT:ScanShield()
	-- Far enough for a box's corners (the biggest radius alone missed them, so you could shoot in there)
	local reach = self.ShapeRadii:Length() + MAX_MARGIN;
	local level = self:GetCoverLevel(); -- While rising/lowering, only the part up to here blocks
	local containment = self:IsContainment();
	local min_radius = math.min(self.ShapeRadii.x, self.ShapeRadii.y, self.ShapeRadii.z);
	for _,e in pairs(ents.FindInSphere(self.Entity:GetPos(), reach)) do
		if (ShieldDebug:GetBool() and IsValid(e) and not e:IsPlayer() and e ~= self.Entity and not self:CanBeReflected(e, containment)) then
			self.DebugIgnored = self.DebugIgnored or WeakTable();
			if (not self.DebugIgnored[e] and self:ShapeDepth(self:WorldToLocal(e:LocalToWorld(e:OBBCenter()))) < 1) then
				self.DebugIgnored[e] = true;
				DebugPrint(e, "ignored inside the shield: on allowed list", self.nocollide[e] == true, "parented", IsValid(e:GetParent()),
					"not solid", e:GetSolid() == SOLID_NONE, "trusted owner", self:IsTrusted(e:GetOwner()), "identifier", self:HasMatchingIdentifier(e), "IgnoreShield", e.IgnoreShield == true);
			end
		end
		if (self:CanBeReflected(e, containment)) then
			local margin = math.Clamp(e:BoundingRadius()*0.5, 0, MAX_MARGIN);
			local center = e:LocalToWorld(e:OBBCenter());
			local lp = self:WorldToLocal(center);
			local covered = not (level and center.z - margin > level);
			if (containment) then
				self:ScanContained(e, lp, math.min(margin, min_radius*0.5), covered);
				continue;
			end
			local depth = self:ShapeDepth(lp, margin);
			if (not covered) then depth = math.huge end -- Not covered yet
			if (depth < 1) then
				self:OnEntityInside(e, depth);
			else
				self.Passed[e] = nil; -- Outside again: next time it is a new arrival
			end
		end
	end
end

function ENT:OnEntityInside(e, depth)
	-- First time we see it inside: it may stay if it was spawned there (deep inside) or fired from inside
	-- by someone who may pass - but only if it isn't moving inwards. (Before, a player who was inside when
	-- the shield came up could fly out and shoot back in, because his shots were allowed by owner alone.)
	if (not self.Passed[e]) then
		self.Passed[e] = true;
		local _, n = self:ShapeDepth(self:WorldToLocal(e:LocalToWorld(e:OBBCenter())));
		local outward = self:LocalToWorld(n) - self.Entity:GetPos();
		local owner = e:GetOwner();
		local moving_out = e:GetVelocity():Dot(outward) >= 0;
		local owner_allowed = IsValid(owner) and self.nocollide[owner] == true;
		DebugPrint(e, "first seen inside: depth", math.Round(depth, 2), "speed", math.floor(e:GetVelocity():Length()), "moving out", moving_out, "owner", owner, "owner allowed", owner_allowed);
		if (moving_out and (depth <= 0.5 or owner_allowed)) then
			DebugPrint(e, "-> allowed through (spawned/fired inside)");
			self.nocollide[e] = true;
			return;
		end
	end
	if (not self:HasStrength()) then
		DebugPrint(e, "-> no strength left, not pushed");
		return;
	end
	self:MoveShotToSurface(e, true);
	StarGate.ShieldOnTouch(self.Entity, e, function(v, do_not_draw_hit) self:Reflect(v, do_not_draw_hit) end, self.Parent.AntiNoclip);
end

-- Fast shots are often well past the surface before we see them (staff blasts move up to ~120 units per
-- tick). Put them back where they crossed it - just outside (or just inside for a containment field) - so
-- they bounce or explode there, and not among the people they should be kept away from.
function ENT:MoveShotToSurface(e, outside)
	if (e:IsPlayer() or e:IsNPC()) then return end
	local vel = e:GetVelocity();
	if (not e.CAPOnShieldTouch and vel:Length() < 1500) then return end
	local pos = e:GetPos();
	-- Where its path of the last few ticks crossed the surface. The normal faces where it came from.
	local hitpos, normal = self:TraceIntersect(pos - vel*engine.TickInterval()*4, pos);
	if (not hitpos) then -- Straight out from the centre (or straight in)
		local lp = self:WorldToLocal(pos);
		local depth, n = self:ShapeDepth(lp);
		if (depth <= 0) then return end
		hitpos = self:LocalToWorld(lp/depth);
		normal = self:LocalToWorld(n) - self.Entity:GetPos();
		if (not outside) then normal = -1*normal end
	end
	e:SetPos(hitpos + normal*2);
	-- SetPos teleports a physics object and its speed then reads 0 this tick, which made the push-back
	-- think the shot wasn't moving: no hit effect and no strength loss. Give it its speed back.
	local phys = e:GetPhysicsObject();
	if (IsValid(phys)) then phys:SetVelocity(vel) end
	e:SetLocalVelocity(vel);
	DebugPrint(e, "moved back to the surface, speed now", math.floor(e:GetVelocity():Length()));
end

-- Containment field: entering is free, but whatever got well inside is pushed back in at the wall
function ENT:ScanContained(e, lp, inner_margin, covered)
	local depth = self:ShapeDepth(lp);
	if (self:ShapeDepth(lp, -inner_margin) < 1) then -- Well inside (its whole body)
		if (covered) then self.Contained[e] = true end
		return;
	end
	if (not self.Contained[e]) then return end
	if (depth > 1.5 or not covered) then -- It got out anyway (teleported, or the field isn't up there yet)
		self.Contained[e] = nil;
		return;
	end
	if (not self:HasStrength()) then return end
	self:MoveShotToSurface(e, false);
	StarGate.ShieldOnTouch(self.Entity, e, function(v, do_not_draw_hit) self:Reflect(v, do_not_draw_hit) end, self.Parent.AntiNoclip);
end

-----------------------------------REFLECT----------------------------------

function ENT:Reflect(e, do_not_draw_hit)
	local pos = e:LocalToWorld(e:OBBCenter());
	local lp = self:WorldToLocal(pos);
	local depth, n = self:ShapeDepth(lp);
	local normal = self:LocalToWorld(n) - self.Entity:GetPos(); -- Outward, following the shield's shape
	if (self:IsContainment()) then normal = -1*normal end -- Containment field: push back in
	local velo = e:GetVelocity(); -- Before reflecting, for the hit strength
	local phys = e:GetPhysicsObject();

	-- The actual pushing is shared with the regular shield (StarGate.ShieldReflectEntity in stargate/server/cap.lua)
	if (not StarGate.ShieldReflectEntity(self.Entity, e, normal)) then
		DebugPrint(e, "-> push-back did nothing (not moving, or held with the physgun)");
		return;
	end
	if (do_not_draw_hit) then return end

	local now = CurTime();
	if ((self.NextHit[e] or 0) > now) then DebugPrint(e, "-> pushed, hit cooldown") return end
	self.NextHit[e] = now + 0.2;

	local strength = 5;
	if (IsValid(phys)) then
		strength = math.ceil(phys:GetMass()*velo:Length()/10000);
	end
	local hitpos = pos;
	if (depth > 0) then hitpos = self:LocalToWorld(lp/depth) end -- On the shield's surface
	DebugPrint(e, "-> HIT: strength", strength, "mass", IsValid(phys) and phys:GetMass() or "-", "speed", math.floor(velo:Length()));
	self:DrawBubbleEffect(hitpos, normal, strength, false, true);
	-- Players, NPCs and missiles don't drain the shield (same as the regular shield)
	if (not (e:IsPlayer() or e:IsNPC() or e:GetClass() == "rpg_missile")) then
		self.Parent:Hit(strength, normal, hitpos, e.FireFrequency);
	end
end

-----------------------------------EFFECT----------------------------------

function ENT:DrawBubbleEffect(pos, normal, strength, turn_off, hit)
	if (hit) then -- Expanding ring along the surface (shield_core_ripple, drawn in cl_init.lua)
		local fx = EffectData();
		fx:SetOrigin(pos);
		fx:SetEntity(self.Entity);
		fx:SetScale(strength or 1);
		util.Effect("shield_core_ripple",fx,true,true);
	end
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

function ENT:Hit(e,pos,dmg,normal,fireFrequency)
	if(not self.Parent.Depleted) then
		if(self.Parent.Strength > 2) then
			normal = normal or Vector(0,0,0);
			self.Parent:Hit(dmg,normal,pos,fireFrequency);
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

-- Is this point protected by the shield right now: inside the shape, and below the part that has risen?
-- Used by the splash damage protection (StarGate.ShieldSplashProtect in stargate/server/cap.lua), which
-- replaces the old CAP.GlobalDamageProtect hook here (it used the GMod 12 hook signature and never ran)
function ENT:ProtectsPoint(pos)
	if (self.Depleted or not self.ShapeRadii or not self:IsShieldUp()) then return false end
	return self:ShapeDepth(self:WorldToLocal(pos)) < 1 and self:IsCoveredAt(pos);
end
