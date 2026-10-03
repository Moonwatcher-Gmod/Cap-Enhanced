--[[
	Shield Core Buble
	Copyright (C) 2011 Madman07
]]--

include('shared.lua');
if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
language.Add("shield_core_buble",SGLanguage.GetMessage("ship_core_buble"));
end

include("modules/sphere.lua")
include("modules/box.lua")
include("modules/atlantis.lua")
include("modules/bullets.lua");

if (StarGate==nil or StarGate.Trace==nil) then return end

-- Clientside trace rule (beam/bullet effects). Only networked values exist here - a second copy of this
-- rule that used the serverside e.Enabled/e.Depleted used to override it, so effects went straight through.
StarGate.Trace:Add("shield_core_buble",
	function(e,values,trace,in_box)
		if(not e:GetNetworkedBool("depleted",false) and e:GetNWBool("Enabled",false)) then
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

			return true // Fix it!
		else
			return false
		end
		return true
	end
);


function ENT:Initialize()
	self.Created = false;
	self.RayModel = {};
end

function ENT:Think()
	if (self:GetNWBool("DoPhysicClientside", false) and not self.Created) then
		self.Created = true
		self:SetCollisionScale()
	end
end

function ENT:SetCollisionScale()
	local model = self:GetNWInt("PhysicModel", 1);
	local size = self:GetNWVector("PhysicScale", Vector(1,1,1));

	local vect, vec;
	local convex = {}
	local i = 0;
	local ShieldModel;

	if (model == 1) then ShieldModel = SphereModel;
	elseif (model == 2) then ShieldModel = BoxModel;
	elseif (model == 3) then ShieldModel = AtlantisModel; end

	for _, vertex in pairs(ShieldModel) do
		vec = Vector(vertex.x*size.x,vertex.y*size.y,vertex.z*size.z);
		vect = Vertex(vec, 1, 1, Vector( 0, 0, 1 ) )
		table.insert(convex, vect);
		table.insert(self.RayModel, vec);
	end

	if (table.getn(convex) == 0) then return end //safefail

	self.Entity:PhysicsFromMesh(convex);
	local phys = self.Entity:GetPhysicsObject();
	if (IsValid(phys)) then
		phys:EnableCollisions(false);
		phys:EnableMotion(false);
	end

	self.ShShap = model;
	self.Size = size;
end

--################# "Always show Bubble": drawn every frame for as long as the shield is up.
-- This used to rely on the switch-on effect staying alive, which players who weren't nearby at that
-- moment (or joined later) never received, and which got culled when its centre left the screen.
local MatAtlantis = Material("effects/atlantisa");
local MatRefract = Material("effects/atlantisb");
local SWITCH_ON_TIME = 5 -- shield_core_flash_atl draws the bubble while it switches on

function ENT:DrawAlwaysOnBubble()
	if (not self:GetNWBool("AlwaysShow",false) or not self:GetNWBool("Enabled",false) or self:GetNWBool("depleted",false)) then return end
	if (CurTime() < self:GetNWFloat("EnabledTime",0) + SWITCH_ON_TIME) then return end
	local model = self:GetNWString("BubbleModel","");
	if (model == "") then return end

	local bubble = self.BubbleModel;
	if (not IsValid(bubble) or bubble:GetModel() ~= model) then
		if (IsValid(bubble)) then bubble:Remove() end
		bubble = ClientsideModel(model, RENDERGROUP_TRANSLUCENT);
		if (not IsValid(bubble)) then return end
		bubble:SetNoDraw(true); -- Only drawn by us
		self.BubbleModel = bubble;
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

function ENT:OnRemove()
	if (IsValid(self.BubbleModel)) then self.BubbleModel:Remove() end
end

hook.Add("PostDrawTranslucentRenderables","StarGate.ShieldCore.AlwaysShow",function(depth, skybox)
	if (depth or skybox) then return end
	for _,e in ipairs(ents.FindByClass("shield_core_buble")) do
		e:DrawAlwaysOnBubble();
	end
end)
