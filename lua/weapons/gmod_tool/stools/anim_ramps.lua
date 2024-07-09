--[[   Copyright (C) 2010 by Llapp   ]]
if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("extra") or SGLanguage == nil or SGLanguage.GetMessage == nil) then return end
include("weapons/gmod_tool/stargate_base_tool.lua")
TOOL.Category = "Ramps"
TOOL.Name=SGLanguage.GetMessage("stool_anim_ramps");
TOOL.ClientConVar["autoweld"] = 1
TOOL.ClientConVar['model'] = StarGate.Ramps.AnimDefault[1]
local entityName = "anim_ramps"
TOOL.Entity.Class = "anim_ramps"
TOOL.Entity.Limit = 10
TOOL.CustomSpawnCode = true
TOOL.Topic["name"] = SGLanguage.GetMessage("stool_ramp_spawner")
TOOL.Topic["desc"] = SGLanguage.GetMessage("stool_ramp_create")
TOOL.Topic[0] = SGLanguage.GetMessage("stool_ramp_desc")
TOOL.Language["Undone"] = SGLanguage.GetMessage("stool_ramp_remove")
TOOL.Language["Cleanup"] = SGLanguage.GetMessage("stool_ramp_cleanup")
TOOL.Language["Cleaned"] = SGLanguage.GetMessage("stool_ramp_cleaned")
TOOL.Language["SBoxLimit"] = SGLanguage.GetMessage("stool_ramp_limit")

function TOOL:LeftClick(t)
	if(t.Entity and t.Entity:IsPlayer()) then return false end;
	if(t.Entity and t.Entity:GetClass() == self.Entity.Class) then return false end;
	if(CLIENT) then return true end;
	local p = self:GetOwner();
	if(p:GetCount("CAP_anim_ramps")>=GetConVar("sbox_maxanim_ramps"):GetInt()) then
		p:SendLua("GAMEMODE:AddNotify(SGLanguage.GetMessage(\"stool_ramp_anim_limit\"), NOTIFY_ERROR, 5); surface.PlaySound( \"buttons/button2.wav\" )");
		return false;
	end
	local ang = p:GetAimVector():Angle(); ang.p = 0; ang.r = 0; ang.y = (ang.y+180) % 360
	local model = self:GetClientInfo("model");
	local e = self:MakeEntity(p, t.HitPos, ang, model)
	if (not IsValid(e)) then return end
	local c = self:Weld(e,t.Entity,util.tobool(self:GetClientNumber("autoweld")));
	self:AddUndo(p,e,c);
	self:AddCleanup(p,c,e);
	p:AddCount("CAP_anim_ramps", e)
	return true;
end

if (SERVER) then
    function TOOL:MakeEntity(ply, position, angle, model)
        if (IsValid(ply)) then
            if (StarGate_Group and StarGate_Group.Error == true) then
                StarGate_Group.ShowError(ply)

                return
            elseif (StarGate_Group == nil or StarGate_Group.Error == nil) then
                Msg("Carter Addon Pack - Unknown Error\n")
                ply:SendLua("Msg(\"Carter Addon Pack - Unknown Error\\n\")")
                ply:SendLua("GAMEMODE:AddNotify(\"Carter Addon Pack: Unknown Error\", NOTIFY_ERROR, 5); surface.PlaySound( \"buttons/button2.wav\" )")

                return
            end

            if (StarGate.NotSpawnable("anim_ramps", ply, "tool")) then return end
        end

        local class = ""
        local pos = Vector(0, 0, 0)

        if (StarGate.Ramps.Anim[model]) then
            class = StarGate.Ramps.Anim[model][1]

            if (StarGate.Ramps.Anim[model][2]) then
                pos = StarGate.Ramps.Anim[model][2]
            end

            if (StarGate.Ramps.Anim[model][3]) then
                angle = angle + StarGate.Ramps.Anim[model][3]
            end
        else
            class = StarGate.Ramps.AnimDefault[2]

            if (StarGate.Ramps.AnimDefault[3]) then
                pos = StarGate.Ramps.AnimDefault[3]
            end

            if (StarGate.Ramps.AnimDefault[4]) then
                angle = angle + StarGate.Ramps.AnimDefault[4]
            end
        end

        local entity
        entity = ents.Create(class)
        entity:SetAngles(angle)
        entity:SetPos(position + pos)
        entity:SetVar("Owner", ply)
        entity:SetModel(model)
        entity:Spawn()

        if (IsValid(ply)) then
            ply:AddCount("CAP_anim_ramps", entity)
        end

        return entity
    end
end

function TOOL.BuildCPanel(panel)
    if (StarGate.CFG:Get("cap_disabled_tool","anim_ramps",false)) then
		Panel:Help(SGLanguage.GetMessage("stool_disabled_tool"));
		return
	end

    if (StarGate.HasInternet) then
        local VGUI = vgui.Create("SHelpButton", Panel)
        VGUI:SetHelp("stools/#anim_ramps")
        VGUI:SetTopic("Help: Tools - "..SGLanguage.GetMessage("stool_anim_ramps"));
        panel:AddPanel(VGUI)
    end

    panel:AddControl("Header", {
        Text = "#Tool_" .. entityName .. "_name",
        Description = "#Tool." .. entityName .. ".desc"
    })

    for model, _ in pairs(StarGate.Ramps.Anim) do
        if (file.Exists(model, "GAME")) then
            list.Set(entityName .. "Models", model, {})
        end
    end

   panel:AddControl("PropSelect",
   {
		Label = SGLanguage.GetMessage("stool_model"),
		ConVar = entityName.."_model",
		Category = "Stargate",
		Models = list.Get(entityName.."Models")
   })
end

TOOL:Register()