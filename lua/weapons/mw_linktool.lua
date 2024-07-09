if(StarGate==nil) then include("autorun/stargate.lua") end;
if(SGLanguage==nil or SGLanguage.GetMessage==nil) then include("autorun/language_lib.lua") end;
if (TOOL==nil) then return end -- wtf?
include("weapons/gmod_tool/stargate_base_tool.lua")
TOOL.Category = "Energy"
TOOL.Name = "Link TOOL"
TOOL.ClientConVar["autolink"] = 1
TOOL.ClientConVar["autoweld"] = 1
TOOL.ClientConVar["capacity"] = 100
TOOL.ClientConVar["model"] = "models/props_phx/life_support/battery_small.mdl"
TOOL.Entity.Class = "powercell_small"
TOOL.Entity.Keys = {"model"}
TOOL.Entity.Limit = 6
TOOL.Topic["name"] = "Powercell"
TOOL.Topic["desc"] = "This is a Powercell"
TOOL.Topic[0] = SGLanguage.GetMessage("stool_zpm_mk3_desc")
TOOL.Language["Undone"] = SGLanguage.GetMessage("stool_zpm_mk3_undone")
TOOL.Language["Cleanup"] = SGLanguage.GetMessage("stool_zpm_mk3_cleanup")
TOOL.Language["Cleaned"] = SGLanguage.GetMessage("stool_zpm_mk3_cleaned")
TOOL.Language["SBoxLimit"] = SGLanguage.GetMessage("stool_zpm_mk3_limit")

function TOOL:Initialize()
	self.note1 = nil
	self.note2 = nil
end

function TOOL:LeftClick( trace )
	if (!trace.Entity:IsValid()) or (trace.Entity:IsPlayer()) then return end
	if (CLIENT) then return true end
	self.note1 = trace.Entity

	return true
end


function TOOL:RightClick( trace )
	if (!trace.Entity:IsValid()) or (trace.Entity:IsPlayer()) then return end

	trace.Entity.Node = self.note1

	return true
end