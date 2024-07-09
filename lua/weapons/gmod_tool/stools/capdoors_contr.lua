/*
	Door Controller
	Copyright (C) 2011  Madman07
*/
if (StarGate==nil or StarGate.CheckModule==nil or not StarGate.CheckModule("devices") or SGLanguage==nil or SGLanguage.GetMessage==nil) then return end
include("weapons/gmod_tool/stargate_base_tool.lua");

TOOL.Category="Tech";
TOOL.Name=SGLanguage.GetMessage("stool_door_c");
TOOL.ClientConVar["autoweld"] = 1;

TOOL.ClientConVar["model"] = "models/iziraider/destinybutton/destinybutton.mdl";
TOOL.List = "ControllerModels";
list.Set(TOOL.List,"models/iziraider/destinybutton/destinybutton.mdl",{});
list.Set(TOOL.List,"models/boba_fett/props/buttons/atlantis_button.mdl",{});
list.Set(TOOL.List,"models/soren/atlantis_button_v2/atlantis_button_v2.mdl",{});
list.Set(TOOL.List,"models/madman07/ring_panel/goauld_panel.mdl",{Angle=Angle(270,0,0),Position=Vector(0,0,-12)});
list.Set(TOOL.List,"models/zsdaniel/ori-ringpanel/panel.mdl",{Angle=Angle(270,0,0),Position=Vector(0,0,-5)});
list.Set(TOOL.List,"models/madman07/ring_panel/ancient/panel.mdl",{Angle=Angle(270,0,0),Position=Vector(0,0,-10)});

TOOL.Entity.Class = "cap_doors_contr";
TOOL.Entity.Keys = {"model"}; -- These keys will get saved from the duplicator
TOOL.Entity.Limit = 10;
TOOL.Topic["name"] = SGLanguage.GetMessage("stool_cap_door_contr_spawner");
TOOL.Topic["desc"] = SGLanguage.GetMessage("stool_cap_door_contr_create");
TOOL.Topic[0] = SGLanguage.GetMessage("stool_cap_door_contr_desc");
TOOL.Language["Undone"] = SGLanguage.GetMessage("stool_cap_door_contr_undone");
TOOL.Language["Cleanup"] = SGLanguage.GetMessage("stool_cap_door_contr_cleanup");
TOOL.Language["Cleaned"] = SGLanguage.GetMessage("stool_cap_door_contr_cleaned");
TOOL.Language["SBoxLimit"] = SGLanguage.GetMessage("stool_cap_door_contr_limit");

function TOOL:LeftClick(t)
	if(t.Entity and t.Entity:IsPlayer()) then return false end;
	if(CLIENT) then return true end;
	local p = self:GetOwner();
	local model = self:GetClientInfo("model");

	if(not self:CheckLimit()) then return false end;
	local e = self:SpawnSENT(p,t,model);
	local c = self:Weld(e,t.Entity,util.tobool(self:GetClientNumber("autoweld")));
	self:AddUndo(p,e,c);
	self:AddCleanup(p,c,e);
	return true;
end

function TOOL:PreEntitySpawn(p,e,model)
	e:SetModel(model);
end

function TOOL:ControlsPanel(Panel)
	Panel:AddControl("PropSelect",{Label=SGLanguage.GetMessage("stool_model"),ConVar="capdoors_contr_model",Category="",Models=self.Models});
	Panel:CheckBox(SGLanguage.GetMessage("stool_autoweld"),"capdoors_contr_autoweld");
end

TOOL:Register();