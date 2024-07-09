--[[
	Cap Console
	Copyright (C) 2011 Madman07
]]--

if (StarGate!=nil and StarGate.LifeSupportAndWire!=nil) then StarGate.LifeSupportAndWire(ENT); end


ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Cap Console"
ENT.Author = "Madman07"
ENT.Category = "Stargate Carter Addon Pack"
ENT.WireDebugName = "Cap Console"

ENT.Spawnable = false
ENT.AdminSpawnable = false

if SERVER then

if (StarGate==nil or StarGate.CheckModule==nil or not StarGate.CheckModule("extra")) then return end

if (StarGate!=nil and StarGate.LifeSupportAndWire!=nil) then StarGate.LifeSupportAndWire(ENT); end


AddCSLuaFile();

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS);
	self:SetMoveType(MOVETYPE_VPHYSICS);
	self:SetSolid(SOLID_VPHYSICS);
	self:SetUseType(SIMPLE_USE);
	self:AddResource("energy",0);
	self.Pressed = false;
	self:CreateWireInputs("Disable Auto-mode","ATA Mode","Radius","Press","Disable Use","Mute");
	self:CreateWireOutputs("Active","ATA Active","Radius");
	self.Auto = true
	self.Light = false
	self.HasEnergy = false
	self.Time = 0
	self.Radius = 100
	self:SetWire("Radius",self.Radius)
	if(self:GetModel() == "models/micropro/ancientconsole/ancient_console.mdl") then
		self:SetSkin(1);
	end
end

function ENT:Think()
	if(CurTime() > self.Time) then
		self.ply = StarGate.FindPlayer(self:GetPos(), self.Radius)
		self.Time = CurTime()+1
	end

	if(StarGate.HasResourceDistribution) then
		if (self:GetResource("energy") >= 10) then
			self.HasEnergy = true
		elseif(self.HasEnergy == true) then
			self.HasEnergy = false
		end

		if (self.Light and self.HasEnergy == true) then
			self:ConsumeResource("energy",10)
		end
	elseif(self.HasEnergy == false) then
		self.HasEnergy = true
	end

	if (self.HasEnergy == true) then
		if(self.ply and not self.Light and self.Auto) then
			self.Light = true
			self:SetWire("Active",1)

			if (self:GetWire("Mute") == 0) then
				self:EmitSound("zpmhub/zpm_power_up.wav")
			end
			if (self:GetModel()=="models/micropro/ancientconsole/ancient_console.mdl") then
				self:SetSkin(0)
			else
				self:SetSkin(1)
			end
		elseif(not self.ply and self.Light and self.Auto) then
			self.Light = false
			self:SetWire("Active",0)

			if(self:GetWire("Mute") == 0) then	
				self:EmitSound("zpmhub/zpm_power_down.wav")
			end
			if(self:GetModel()=="models/micropro/ancientconsole/ancient_console.mdl") then
				self:SetSkin(1)
			else
				self:SetSkin(0)
			end
		end
	elseif(self.HasEnergy == false) then
		if(self.Light) then
			self.Light = false
			self:SetWire("Active",0)

			if(self:GetWire("Mute") == 0) then	
				self:EmitSound("zpmhub/zpm_power_down.wav")
			end
			if(self:GetModel()=="models/micropro/ancientconsole/ancient_console.mdl") then
				self:SetSkin(1)
			else
				self:SetSkin(0)
			end
		end
	end
end

function ENT:TriggerInput(variable, value)
	if (variable == "Press") then
		if(value <= 0) then
			self:PressConsole(false)
		else
			self:PressConsole(true)
		end
	elseif(variable == "Disable Auto-mode") then
		if (value > 0) then 
			self.Auto = false
		else 
			self.Auto = true
		end
	elseif(variable == "ATA Mode") then
		if(value > 0) then
			self:SetWire("ATA Active",1)
		else 
			self:SetWire("ATA Active",0)
		end
	elseif(variable == "Radius") then
		if(value < 0) then
			self.Radius = 0
			self:SetWire("Radius",0)
		elseif(value > 2048) then
			self.Radius = 2048
			self:SetWire("Radius",2048)
		else
			self.Radius = value
			self:SetWire("Radius",value)
		end
	end
end

function ENT:Use(ply)
	if(self:GetWire("Disable Use") > 0) then return end

	if(self:GetWire("ATA Mode") > 0) then
		if(ply:GetNWInt("ATAGene",0) == 1) then
			self:PressConsole(not self.Light);
		else return end
	else
		self:PressConsole(not self.Light);
	end
end

function ENT:PressConsole(pressed)
	if (self.Auto) then return end
	if (StarGate.HasResourceDistribution) then
		if (self:GetResource("energy") >= 10) then
			self.HasEnergy = true
		else
			self.HasEnergy = false
		end
	else
		self.HasEnergy = true
	end

	if(pressed)then
		if(self.HasEnergy and self.Light == false) then
			self:EmitSound("button/ancient_button1.wav")
			self.Light = true
			self:SetWire("Active",1)

			if(self:GetModel()=="models/micropro/ancientconsole/ancient_console.mdl") then
				self:SetSkin(9)
			else
				self:SetSkin(1)
			end
		end
	elseif(self.Light == true) then
		self:EmitSound("button/ancient_button2.wav")
		self.Light = false
		self:SetWire("Active",0)

		if(self:GetModel()=="models/micropro/ancientconsole/ancient_console.mdl") then
			self:SetSkin(1)
		else
			self:SetSkin(0)
		end
	end
end

end