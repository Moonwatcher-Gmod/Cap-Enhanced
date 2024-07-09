--[[
	ZPM MK III Spawn Tool for GarrysMod10
	Copyright (C) 2010 Llapp
]]
if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("energy") or SGLanguage == nil or SGLanguage.GetMessage == nil) then return end
include("weapons/gmod_tool/stargate_base_tool.lua")
TOOL.Category = "Energy"
TOOL.Name = "Powercell"
TOOL.ClientConVar["autolink"] = 1
TOOL.ClientConVar["autoweld"] = 1
TOOL.ClientConVar["capacity"] = 100
TOOL.ClientConVar["model"] = "models/props_phx/life_support/battery_small.mdl"
TOOL.Entity.Class = "powercell_small"
TOOL.Entity.Keys = {"model"}
TOOL.Entity.Limit = 6
TOOL.Topic["name"] = "Powercell"
TOOL.Topic["desc"] = "This is a Powercell"
TOOL.Topic[0] = "Click to spawn a Powercell"
TOOL.Language["Undone"] = "Powercell removed"
TOOL.Language["Cleanup"] = "Powercell removed"
TOOL.Language["Cleaned"] = "Powercell removed"
TOOL.Language["SBoxLimit"] = "Powercell: Limit reached"

function TOOL:LeftClick(t)
    local p = self:GetOwner()
    if (t.Entity and t.Entity:IsPlayer()) then return false end
    if (t.Entity and t.Entity:GetClass() == self.Entity.Class) then return false end
    if (CLIENT) then return true end

    if (not util.IsValidModel("models/props_phx/life_support/battery_small.mdl")) then       
            p:EmitSound( "buttons/button8.wav" )
            p:SendLua( "GAMEMODE:AddNotify('Error: Client/Server missing model, Spacebuild is required', NOTIFY_ERROR, 7);" )
            return
    end

    if (not self:CheckLimit()) then return false end
    
    local model = self:GetClientInfo("model")
    local e = self:SpawnSENT(p, t, model)
    if (not IsValid(e)) then return false end
    local weld = util.tobool(self:GetClientNumber("autoweld"))

    if (SERVER and t.Entity and t.Entity.ZPMHub) then
        t.Entity:Touch(e)
        weld = false
    elseif (util.tobool(self:GetClientNumber("autolink"))) then
        self:AutoLink(e, t.Entity)
    end

    local c = self:Weld(e, t.Entity, weld)
    local capacity = tonumber(self:GetClientInfo("capacity"))
    e.Energy = (e.Energy / 100) * math.Clamp(capacity, 0, 100)
    self:AddUndo(p, e, c)
    self:AddCleanup(p, c, e)

    return true
end

function TOOL:PreEntitySpawn(p, e, model)
    e:SetModel(model)
end

function TOOL:ControlsPanel(Panel)
    Panel:NumSlider("Powercell Capacity", "powercell_small_capacity", 0, 100, 4)

    if (StarGate.HasResourceDistribution) then
        Panel:CheckBox("Autolink", "zpm_mk3_autolink"):SetToolTip("Autolink this to resouce node using Entities?")
    end
end

TOOL:Register()