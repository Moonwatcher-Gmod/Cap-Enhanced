/*
	ZPM MK III Spawn Tool for GarrysMod10
	Copyright (C) 2010 Llapp
*/

if (StarGate==nil or StarGate.CheckModule==nil or not StarGate.CheckModule("energy") or SGLanguage==nil or SGLanguage.GetMessage==nil) then return end
include("weapons/gmod_tool/stargate_base_tool.lua");

TOOL.Category="Energy"
TOOL.Name="ZPM MK IV";

TOOL.ClientConVar["autolink"] = 1;
TOOL.ClientConVar["autoweld"] = 1;
TOOL.ClientConVar["capacity"] = 100;
TOOL.ClientConVar["model"] = "models/pg_props/pg_zpm/pg_zpm4.mdl";
TOOL.Entity.Class = "zpm_mk4";
TOOL.Entity.Keys = {"model"};
TOOL.Entity.Limit = 6;
TOOL.Topic["name"] = "ZPM MK IV Spawner";
TOOL.Topic["desc"] = SGLanguage.GetMessage("stool_zpm_mk3_create");
TOOL.Topic[0] = "LeftClick, to spawn a ZPM MK IV";
TOOL.Language["Undone"] = SGLanguage.GetMessage("stool_zpm_mk3_undone");
TOOL.Language["Cleanup"] = SGLanguage.GetMessage("stool_zpm_mk3_cleanup");
TOOL.Language["Cleaned"] = SGLanguage.GetMessage("stool_zpm_mk3_cleaned");
TOOL.Language["SBoxLimit"] = SGLanguage.GetMessage("stool_zpm_mk3_limit");

function TOOL:LeftClick(t)
	if(t.Entity and t.Entity:IsPlayer()) then return false end;
	if(t.Entity and t.Entity:GetClass() == self.Entity.Class) then return false end;
	if(CLIENT) then return true end;
	if(not self:CheckLimit()) then return false end;
	local p = self:GetOwner();
	local model = self:GetClientInfo("model");
	local e = self:SpawnSENT(p,t,model);
	if (not IsValid(e)) then return false end
	local weld = util.tobool(self:GetClientNumber("autoweld"));
	if(SERVER and t.Entity and t.Entity.ZPMHub) then
		t.Entity:Touch(e);
		weld = false;
	elseif(util.tobool(self:GetClientNumber("autolink"))) then
		self:AutoLink(e,t.Entity);
	end
	local c = self:Weld(e,t.Entity,weld);
	local capacity = tonumber(self:GetClientInfo("capacity"));
	e.Energy = (e.Energy / 100) * math.Clamp(capacity,0,100)
	self:AddUndo(p,e,c);
	self:AddCleanup(p,c,e);
	return true;
end

function TOOL:PreEntitySpawn(p,e,model)
	e:SetModel(model);
	e:SetSkin(4);
end

function TOOL:ControlsPanel(Panel)
	Panel:NumSlider(SGLanguage.GetMessage("stool_zpm_mk4_capacity"),"zpm_mk4_capacity",0,100,4);
	Panel:CheckBox("Autoweld","zpm_mk3_autoweld");
	if(StarGate.HasResourceDistribution) then
		Panel:CheckBox("Autolink","zpm_mk3_autolink"):SetToolTip("Autolink this to resouce node using Entities?");
	end
	Panel:AddControl("Label", {Text = "This is a ZPM MK IV. Which has increased capacity and max output compared to MK III"})
end

TOOL:Register();