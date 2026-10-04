--[[
	Shield Core Buble
	Copyright (C) 2011 Madman07
]]--

include('shared.lua');
if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
language.Add("shield_core_buble",SGLanguage.GetMessage("ship_core_buble"));
end

include("modules/bullets.lua");

if (StarGate==nil or StarGate.Trace==nil) then return end

-- Clientside trace rule (beam/bullet effects). Only networked values exist here - a second copy of this
-- rule that used the serverside e.Enabled/e.Depleted used to override it, so effects went straight through.
StarGate.Trace:Add("shield_core_buble",
	function(e,values,trace,in_box)
		if(not e:GetNetworkedBool("depleted",false) and e:IsShieldUp()) then
			-- local own = e;
			-- if (type(values[3]) == "table") then
				-- own = values[3][1]:GetNWEntity("SC_Owner", e); // readed from serverside
			-- else
				-- own = values[3]:GetNWEntity("SC_Owner", e);
			-- end
			-- if not (IsValid(own) and own:IsPlayer()) then return true end

			-- local nocollide = string.Explode(" ", e:GetNWString("NoCollideID", ""));
			-- if (table.HasValue(nocollide, own:EntIndex()) or (e:GetNWBool("Immunity",false) and e:SetNetworkedEntity("Own",e) == own)) then
				-- return false
			-- else
				-- return true
			-- end

			-- Same as the server rule: from outside always blocked, from inside anyone still in the shield may
			-- shoot out (everyone else gets pushed out of it), and the owner passes with Immunity
			local own = values[3];
			if (type(own) == "table") then own = own[1] end
			own = IsValid(own) and own:GetNWEntity("SC_Owner", NULL) or NULL;
			-- Trusted shooters (Immunity owner and friends, Allowed Players), sent by the server as entity indexes
			if (IsValid(own) and string.find(e:GetNWString("TrustedIDs", ""), " " .. own:EntIndex() .. " ", 1, true)) then return false end
			local inside = in_box; -- Exact: e:ContainsPoint(trace start), see tracelines.lua
			if (e:IsContainment()) then return inside end -- Containment field: nothing gets out, everything in
			return not inside;
		else
			return false
		end
		return true
	end
);


--################# "Always show Bubble": drawn every frame for as long as the shield is up.
-- This used to rely on the switch-on effect staying alive, which players who weren't nearby at that
-- moment (or joined later) never received, and which got culled when its centre left the screen.
local MatAtlantis = Material("effects/atlantisa");
local MatRefract = Material("effects/atlantisb");
local SWITCH_ON_TIME = 5 -- shield_core_flash_atl draws the bubble while it switches on

-- The shield model, scaled like the switch on/off effect does it. Only drawn by us.
function ENT:GetBubbleModel()
	local model = self:GetNWString("BubbleModel","");
	if (model == "") then return end

	local bubble = self.BubbleModel;
	-- Compare with the name we created it with: GetModel() can return the path in another case
	-- (models/madman07/...), which recreated the model every frame without scaling it
	if (not IsValid(bubble) or self.BubbleModelName ~= model) then
		if (IsValid(bubble)) then bubble:Remove() end
		bubble = ClientsideModel(model, RENDERGROUP_TRANSLUCENT);
		if (not IsValid(bubble)) then return end
		bubble:SetNoDraw(true);
		self.BubbleModel = bubble;
		self.BubbleModelName = model;
		self.BubbleScale = nil; -- A new model needs its scale applied
	end
	local scale = self:GetNWVector("BubbleScale",Vector(1,1,1));
	if (self.BubbleScale ~= scale) then
		self.BubbleScale = scale;
		local mat = Matrix();
		mat:Scale(scale);
		bubble:EnableMatrix("RenderMultiply", mat);
	end
	bubble:SetPos(self:GetPos());
	bubble:SetAngles(self:GetAngles());
	return bubble;
end

function ENT:DrawAlwaysOnBubble()
	if (not self:GetNWBool("AlwaysShow",false) or not self:GetNWBool("Enabled",false) or self:GetNWBool("depleted",false)) then return end
	if (CurTime() < self:GetNWFloat("EnabledTime",0) + SWITCH_ON_TIME) then return end
	local bubble = self:GetBubbleModel();
	if (not bubble) then return end

	if (StarGate.VisualsMisc("cl_shieldcore_refract")) then
		render.MaterialOverride(MatRefract);
		bubble:DrawModel();
	end
	render.MaterialOverride(MatAtlantis);
	render.SetBlend(128/255);
	bubble:DrawModel();
	render.SetBlend(1);
	render.MaterialOverride(nil);
end

--################# Glowing band along the edge while the shield rises or lowers (about a metre deep)
-- Drawn as rings of beams on the shield's surface. (Drawing the shield model again inside a clipped band
-- didn't show: the switch on/off effect draws the same model at the same place first.)
local MatEdge = Material("trails/laser");
local EDGE_DEPTH = 160 -- ~1 metre
local EDGE_RINGS = 28 -- Rings from the edge downwards, getting fainter
local EDGE_POINTS = 64 -- Points per ring
local EDGE_COLOR = Color(110, 210, 255)

-- Points around the shield's surface at a height above its centre (world z, like the rise effect),
-- following the shield's yaw. nil if that height is outside the shape.
function ENT:GetRing(height)
	local r = self:GetShapeRadii();
	local shape = self:GetNWInt("PhysicModel",1);
	if (math.abs(height) >= r.z or (shape == 3 and height < 0)) then return end
	local points = {};
	for i = 0, EDGE_POINTS do
		local a = i/EDGE_POINTS*math.pi*2;
		local x, y;
		if (shape == 2) then -- Box: walk around the rectangle
			local c, sn = math.cos(a), math.sin(a);
			local k = 1/math.max(math.abs(c), math.abs(sn));
			x, y = r.x*c*k, r.y*sn*k;
		else -- Sphere/dome: ellipse at this height
			local k = math.sqrt(1 - (height/r.z)^2);
			x, y = r.x*k*math.cos(a), r.y*k*math.sin(a);
		end
		points[#points + 1] = self:LocalToWorld(Vector(x, y, 0)) + Vector(0, 0, height); -- Horizontal: shield's yaw, height: world z
	end
	return points;
end

function ENT:DrawRisingEdge()
	if (self:GetNWBool("depleted",false) or not self:IsShieldUp()) then return end
	local level = self:GetCoverLevel();
	if (not level) then return end
	local center_z = self:GetPos().z;
	local pulse = 0.8 + 0.2*math.sin(CurTime()*14);
	local width = EDGE_DEPTH/EDGE_RINGS*1.8;

	render.SetMaterial(MatEdge);
	for i = 0, EDGE_RINGS - 1 do
		local ring = self:GetRing(level - center_z - EDGE_DEPTH*i/EDGE_RINGS);
		if (ring) then
			local k = (1 - i/EDGE_RINGS)^2;
			local col = Color(EDGE_COLOR.r, EDGE_COLOR.g, EDGE_COLOR.b, 255*k*pulse);
			local w = (i == 0) and width*1.6 or width;
			for j = 1, #ring - 1 do
				render.DrawBeam(ring[j], ring[j + 1], w, 0, 1, col);
			end
		end
	end
end

--################# Beam impact: crackling red arcs spreading through the shield from where a beam hits it,
-- like a tesla coil (the Asuran beam hitting the Atlantis shield). The server sets BeamHitPos/BeamHitTime
-- (energy_laser.lua). A new random pattern is made many times a second; the previous one fades behind it.
local MatVein = Material("cable/redlaser"); -- Red beams (Asuran)
local MatVeinTint = Material("trails/laser"); -- Other colours (tinted)
local MatGlow = Material("sprites/light_glow02_add");
local VEIN_GROW_SPEED = 260 -- Units per second the arcs reach further while the beam keeps hitting
local VEIN_FADE_TIME = 0.8 -- Seconds to fade after the beam stops
local VEIN_REFRESH = 0.05 -- Seconds between new patterns (roughly)
local VEIN_MAX_SEGMENTS = 400

-- Projects a local point onto the shield's surface, and returns the outward normal there
local function ProjectToSurface(lp, r, box)
	if (box) then
		local ax, ay, az = math.abs(lp.x)/r.x, math.abs(lp.y)/r.y, math.abs(lp.z)/r.z;
		local m = math.max(ax, ay, az, 0.001);
		local n;
		if (m == ax) then n = Vector(lp.x >= 0 and 1 or -1,0,0)
		elseif (m == ay) then n = Vector(0,lp.y >= 0 and 1 or -1,0)
		else n = Vector(0,0,lp.z >= 0 and 1 or -1) end
		return lp/m, n;
	end
	local depth = math.max(Vector(lp.x/r.x, lp.y/r.y, lp.z/r.z):Length(), 0.001);
	local p = lp/depth;
	local n = Vector(p.x/(r.x*r.x), p.y/(r.y*r.y), p.z/(r.z*r.z));
	n:Normalize();
	return p, n;
end

-- One random arc pattern around the impact point, reaching up to `reach` units
function ENT:BuildVeins(lhit, reach)
	local r = self:GetShapeRadii();
	local box = (self:GetNWInt("PhysicModel",1) == 2);
	local dome = (self:GetNWInt("PhysicModel",1) == 3); -- The Atlantis dome has nothing below its base
	local size = math.max(r.x, r.y, r.z);
	local step = math.Clamp(size*0.03, 5, 24);

	local segments = {};
	local function grow(pos, dir, dist, width, budget, level)
		while (budget > 0 and #segments < VEIN_MAX_SEGMENTS) do
			local _, n = ProjectToSurface(pos, r, box);
			dir = (dir - n*dir:Dot(n)):GetNormalized(); -- Keep it on the surface
			local side = n:Cross(dir);
			local turn = (math.random() - 0.5)*1.8; -- Sharp zig-zags
			local d = dir*math.cos(turn) + side*math.sin(turn);
			local len = step*(0.5 + math.random());
			local nextpos = ProjectToSurface(pos + d*len, r, box);
			if (dome and nextpos.z < 0) then break end
			dist = dist + len;
			segments[#segments + 1] = {A = pos, B = nextpos, D = dist, W = width};
			pos = nextpos;
			budget = budget - len;
			width = width*0.97;
			if (level < 3 and math.random() < 0.16) then -- Fork
				local f = (math.random() < 0.5 and 1 or -1)*(0.5 + math.random()*0.6);
				grow(pos, dir*math.cos(f) + side*math.sin(f), dist, width*0.65, budget*(0.3 + math.random()*0.4), level + 1);
			end
		end
	end

	local p, n = ProjectToSurface(lhit, r, box);
	local tangent = n:Cross(math.abs(n.z) < 0.9 and Vector(0,0,1) or Vector(1,0,0)):GetNormalized();
	local branches = math.random(6, 10);
	for i = 1, branches do
		local a = math.random()*math.pi*2;
		local dir = tangent*math.cos(a) + n:Cross(tangent)*math.sin(a);
		grow(p, dir, 0, 1, reach*(0.35 + 0.65*math.random()), 0);
	end
	return {Hit = lhit, Segments = segments, Reach = math.max(reach, 1)};
end

local function DrawVeinPattern(self, veins, alpha_mul, width, col)
	for _, seg in ipairs(veins.Segments) do
		local k = 1 - seg.D/veins.Reach;
		if (k > 0) then
			local a, b = self:LocalToWorld(seg.A), self:LocalToWorld(seg.B);
			local w = width*seg.W*(0.35 + 0.65*k);
			render.DrawBeam(a, b, w*2.2, 0, 1, Color(col.x, col.y*(0.8 + 0.6*k), col.z, 150*alpha_mul*k)); -- Glow
			-- Hot core: the beam's colour, mostly white
			render.DrawBeam(a, b, w*0.6, 0, 1, Color(200 + col.x*0.2, 200 + col.y*0.2, 200 + col.z*0.2, 255*alpha_mul*k));
		end
	end
end

function ENT:DrawBeamVeins()
	local now = CurTime();
	local since_hit = now - self:GetNWFloat("BeamHitTime", 0);
	if (since_hit > 0.25 + VEIN_FADE_TIME) then
		self.VeinStart = nil;
		self.Veins = nil;
		self.OldVeins = nil;
		return;
	end
	if (not self.VeinStart) then self.VeinStart = now end

	local fade = 1;
	if (since_hit > 0.25) then fade = 1 - (since_hit - 0.25)/VEIN_FADE_TIME end
	-- The beam decides the colour and size (Asuran: big and red, Asgard/Ori: small, in their colour)
	local col = self:GetNWVector("BeamVeinColor", Vector(255, 60, 20));
	local vein_scale = self:GetNWFloat("BeamVeinScale", 1);
	local r = self:GetShapeRadii();
	local max_reach = math.Clamp(math.max(r.x, r.y, r.z)*0.7*vein_scale, 50, 1000);
	local reach = math.min(30 + (now - self.VeinStart)*VEIN_GROW_SPEED, max_reach);

	local lhit = self:WorldToLocal(self:GetNWVector("BeamHitPos", self:GetPos()));
	if (not self.Veins or now >= (self.VeinNext or 0) or self.Veins.Hit:Distance(lhit) > 40) then
		self.OldVeins = self.Veins;
		self.OldVeinTime = now;
		self.Veins = self:BuildVeins(lhit, reach);
		self.VeinNext = now + VEIN_REFRESH*(0.6 + math.random()*0.8);
	end

	local width = math.Clamp(max_reach*0.015, 2, 10);
	local red = (col.x > 200 and col.y < 100 and col.z < 100);
	render.SetMaterial(red and MatVein or MatVeinTint);
	if (self.OldVeins) then -- Previous pattern fading out quickly: crackling instead of jumping
		local old = 1 - (now - self.OldVeinTime)/VEIN_REFRESH;
		if (old > 0) then DrawVeinPattern(self, self.OldVeins, fade*old*0.5, width, col) end
	end
	DrawVeinPattern(self, self.Veins, fade*(0.75 + 0.25*math.random()), width, col);

	-- Hot spot where the beam hits
	local glow = math.Clamp(reach*0.5, 40, 450)*(0.85 + 0.3*math.random());
	render.SetMaterial(MatGlow);
	render.DrawSprite(self:LocalToWorld(lhit), glow, glow, Color(col.x, math.min(255, col.y + 60), math.min(255, col.z + 40), 255*fade));
end

--################# Impact ripples: a ring expanding along the shield's surface from where it was hit
local MatRipple = Material("trails/laser");
local RIPPLE_TIME = 0.7 -- Seconds a ripple lives
local RIPPLE_POINTS = 36 -- Points around a ring
local RIPPLE_MAX = 10 -- Ripples at once per shield
local RIPPLE_REPEAT = 0.15 -- Seconds before the same spot (e.g. a beam) starts a new one

function ENT:AddRipple(pos, strength)
	self.Ripples = self.Ripples or {};
	local lp = self:WorldToLocal(pos);
	local now = CurTime();
	for _, rip in ipairs(self.Ripples) do
		if (now - rip.Start < RIPPLE_REPEAT and rip.Pos:Distance(lp) < 50) then return end
	end
	if (#self.Ripples >= RIPPLE_MAX) then table.remove(self.Ripples, 1) end
	table.insert(self.Ripples, {Pos = lp, Start = now, Size = math.Clamp(60 + (strength or 1)*12, 60, 450)});
end

function ENT:DrawRipples()
	local ripples = self.Ripples;
	if (not ripples or #ripples == 0) then return end
	local r = self:GetShapeRadii();
	local shape = self:GetNWInt("PhysicModel",1);
	local box, dome = (shape == 2), (shape == 3);
	local col = self:GetNWVector("Col", Vector(170,189,255));
	local now = CurTime();
	render.SetMaterial(MatRipple);
	for i = #ripples, 1, -1 do
		local rip = ripples[i];
		local age = (now - rip.Start)/RIPPLE_TIME;
		if (age >= 1) then
			table.remove(ripples, i);
		else
			local dist = rip.Size*(1 - (1 - age)^2); -- Fast at first, slowing down
			local alpha = 255*(1 - age);
			local width = 4 + 10*(1 - age);
			local p, n = ProjectToSurface(rip.Pos, r, box);
			local t1 = n:Cross(math.abs(n.z) < 0.9 and Vector(0,0,1) or Vector(1,0,0)):GetNormalized();
			local t2 = n:Cross(t1);
			local prev;
			for k = 0, RIPPLE_POINTS do
				local a = k/RIPPLE_POINTS*math.pi*2;
				local q = ProjectToSurface(p + (t1*math.cos(a) + t2*math.sin(a))*dist, r, box);
				local w = (not dome or q.z >= 0) and self:LocalToWorld(q) or nil; -- Nothing below the dome's base
				if (prev and w) then
					render.DrawBeam(prev, w, width, 0, 1, Color(math.min(255, col.x + 60), math.min(255, col.y + 60), 255, alpha));
				end
				prev = w;
			end
		end
	end
end

function ENT:OnRemove()
	if (IsValid(self.BubbleModel)) then self.BubbleModel:Remove() end
end

-- Drawn before other translucent things (beams, effects): its refraction would otherwise paint over
-- everything already drawn in front of it, so e.g. a beam in front of the shield disappeared
hook.Add("PreDrawTranslucentRenderables","StarGate.ShieldCore.AlwaysShow",function(depth, skybox)
	if (depth or skybox) then return end
	-- Don't write depth: from inside the shield its surface would hide everything behind it (e.g. a beam outside)
	render.OverrideDepthEnable(true, false);
	for _,e in ipairs(ents.FindByClass("shield_core_buble")) do
		e:DrawAlwaysOnBubble();
	end
	render.OverrideDepthEnable(false);
end)

-- Drawn after everything else (also after the switch on/off effect, whose refraction would hide them)
hook.Add("PostDrawTranslucentRenderables","StarGate.ShieldCore.Effects",function(depth, skybox)
	if (depth or skybox) then return end
	render.OverrideDepthEnable(true, false);
	for _,e in ipairs(ents.FindByClass("shield_core_buble")) do
		e:DrawRisingEdge();
		e:DrawBeamVeins();
		e:DrawRipples();
	end
	render.OverrideDepthEnable(false);
end)
