TOOL.AddToMenu = false
--[[/*
	Tampered ZPM
	Copyright (C) 2010  Llapp
*/
if (StarGate==nil or StarGate.CheckModule==nil or not StarGate.CheckModule("energy") or SGLanguage==nil or SGLanguage.GetMessage==nil) then return end
include("weapons/gmod_tool/stargate_base_tool.lua");

TOOL.Category="Energy";
TOOL.Name="Ion Generator"
TOOL.ClientConVar["autoweld"] = 1;
TOOL.ClientConVar["autolink"] = 1;
TOOL.ClientConVar["model"] = "models/starwars/syphadias/props/sw_tor/bioware_ea/props/nar_shadda/nar_holo_bench.mdl"
TOOL.Entity.Class = "ion_generator";
TOOL.Entity.Keys = {"model"};
TOOL.Entity.Limit = 3;
TOOL.Topic["name"] = "Ion Generator"
TOOL.Topic["desc"] = "This is an Ion generator"
TOOL.Topic[0] = SGLanguage.GetMessage("This is an Ion generator");
TOOL.Language["Undone"] = SGLanguage.GetMessage("stool_tampered_zpm_undone");
TOOL.Language["Cleanup"] = SGLanguage.GetMessage("stool_tampered_zpm_cleanup");
TOOL.Language["Cleaned"] = SGLanguage.GetMessage("stool_tampered_zpm_cleaned");
TOOL.Language["SBoxLimit"] = SGLanguage.GetMessage("stool_tampered_zpm_limit");

function TOOL:LeftClick(t)
	if(t.Entity and t.Entity:IsPlayer()) then return false end;
	if(t.Entity and t.Entity:GetClass() == self.Entity.Class) then return false end;
	if(CLIENT) then return true end;
	if(not self:CheckLimit()) then return false end;
	local p = self:GetOwner();
	local model = self:GetClientInfo("model");
	local e = self:SpawnSENT(p,t,model);
	if(SERVER and t.Entity and t.Entity.ZPMHub) then
		t.Entity:Touch(e);
		weld = false;
	elseif(util.tobool(self:GetClientNumber("autolink"))) then
		self:AutoLink(e,t.Entity);
	end
	local c = self:Weld(e,t.Entity,weld);
	self:AddUndo(p,e,c);
	self:AddCleanup(p,c,e);
	return true;
end

function TOOL:RightClick(t)
	if(t.Entity and t.Entity:IsPlayer()) then return false end;
	if(t.Entity and (t.Entity:GetClass()!="ion_generator")) then return false end;
	if(CLIENT) then return true end;
	t.Entity.LastRefill = t.Entity.LastRefill or 0;
	if (t.Entity:GetClass()=="ion_generator") then
		if (t.Entity.Energy<t.Entity.MaxEnergy and t.Entity.LastRefill<CurTime()) then
			t.Entity.Energy = math.Clamp((t.Entity.Energy + t.Entity.MaxEnergy*0.25),0,t.Entity.MaxEnergy);
			t.Entity.LastRefill = CurTime()+30;
			t.Entity.depleted = false;
			t.Entity:AddResource("energy",2000);
		end
	else
		if (t.Entity.Naquadah<t.Entity.MaxEnergy and t.Entity.LastRefill<CurTime()) then
			t.Entity.Naquadah = math.Clamp((t.Entity.Naquadah + t.Entity.MaxEnergy*0.25),0,t.Entity.MaxEnergy);
			t.Entity.LastRefill = CurTime()+30;
			t.Entity.depleted = false;
			t.Entity:AddResource("energy",2000);
		end
	end
	return true;
end








function TOOL:PreEntitySpawn(p,e,model)
	e:SetModel(model);
end

function TOOL:ControlsPanel(Panel)
	Panel:CheckBox("Autoweld","tampered_zpm_autoweld");
	if(StarGate.HasResourceDistribution) then
		Panel:CheckBox("Autolink","tampered_zpm_autolink"):SetToolTip("Autolink this to resouce node using Entities?");
	end
	Panel:AddControl("Label", {Text = "This is an Ion generator",})
	Panel:AddControl("Label", {Text = "\n".."Description:".."\n\n".."This is an Ion generator",})
end

TOOL:Register();
]]
