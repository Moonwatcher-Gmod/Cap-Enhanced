--[[
	Shield Core flash effect Atlantis
	Copyright (C) 2011 Madman07
]]--

EFFECT.Atlantis = Material("effects/atlantisa");
EFFECT.Refract = Material("effects/atlantisb");

function EFFECT:Init(data)
	local ent = data:GetEntity();
    if (not IsValid(ent)) then return end
	self.Status = data:GetMagnitude();

	self.Siz = ent:GetNetworkedVector("Size", Vector(100,100,100)) - Vector(10,10,10);
	self.Siz = self.Siz/512;
	self.Mod = ent:GetNWString("Mod");
	self.Ang = ent:GetNWAngle("Ang", Angle(0,0,0));
	self.Pos = ent:GetNWVector("Pos", Vector(0,0,0));

	self.Entity:SetModel(Model(self.Mod));
	self.Entity:SetPos(ent:LocalToWorld(self.Pos));
	self.Entity:SetAngles(ent:GetAngles()+self.Ang);
	self.Entity:SetRenderMode( RENDERMODE_TRANSALPHA );
	-- The model is scaled up with a matrix, which doesn't grow its render bounds: without this the
	-- bubble disappeared whenever its (unscaled) centre left the screen
	local mn, mx = self.Entity:GetModelBounds();
	self.Mins, self.Maxs = mn*self.Siz, mx*self.Siz;
	self.Entity:SetRenderBounds(self.Mins, self.Maxs);

	self.Time = 5;
	self.LifeTime = CurTime() + self.Time;
	self.Normal = Vector(0,0,-1);

	local shield = ent.ShieldBubble;
	if(IsValid(shield)) then
		if (self.Status == 0) then
			shield:Remove();
		end
	end
	ent.ShieldBubble = self.Entity;
	self.Parent = ent;
	self.Draw = true;
end

function EFFECT:Think()
	-- Only the switch on/off animation: once it is done, the shield (shield_core_buble/cl_init.lua) draws
	-- the "always show" bubble itself. This used to stay alive forever after switching on.
	if (self.LifeTime==nil or self.LifeTime < CurTime()) then return false
	else return true end
end

function EFFECT:Render()
	if self.Draw then
		if not IsValid(self.Parent) then return end

		self.Entity:SetPos(self.Parent:LocalToWorld(self.Pos));
		self.Entity:SetAngles(self.Parent:GetAngles()+self.Ang);

		local mat = Matrix()
		mat:Scale(self.Siz)
		self.Entity:EnableMatrix( "RenderMultiply", mat )

		local mn, mx = self.Mins, self.Maxs;

		local Up = (mx-mn):GetNormal();
		local Bottom =  self:GetPos() + mn;
		local Top = self:GetPos() + mx;

		local Fraction = (self.LifeTime - CurTime()) / self.Time;
		Fraction = math.Clamp( Fraction, 0, 1 );
		local Lerped = Vector(1,1,1);

		if (self.Status > 0.5) then
			Lerped = LerpVector( Fraction, Top, Bottom);
		else
			Lerped = LerpVector( Fraction, Bottom, Top);
		end

		local distance = self.Normal:Dot(Vector(0,0,Lerped.z));

		local uvmove = 1-Fraction;

		self:SetRenderClipPlaneEnabled(true);
		self:SetRenderClipPlane(self.Normal, distance);

		--render.UpdateRefractTexture();
		--self.Atlantis:SetMaterialFloat("$ypos", uvmove);

		if StarGate.VisualsMisc("cl_shieldcore_refract") then
			render.MaterialOverride(self.Refract);
			self.Entity:DrawModel();
		end

		render.MaterialOverride(self.Atlantis)
		self.Entity:SetColor(Color(255,255,255,128));
		self.Entity:DrawModel();

		render.MaterialOverride(nil);
	end
end