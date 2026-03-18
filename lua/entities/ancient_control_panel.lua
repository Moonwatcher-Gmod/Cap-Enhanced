--[[
	Ancient Console
	Copyright (C) 2011 Madman07
]]
--
if (StarGate ~= nil and StarGate.LifeSupportAndWire ~= nil) then
    StarGate.LifeSupportAndWire(ENT)
end

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Ancient Control Panel"
ENT.Author = "Madman07"
ENT.Category = "Stargate Carter Addon Pack"
ENT.WireDebugName = "Ancient Control Panel"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.AutomaticFrameAdvance = true
ENT.Untouchable = true

if SERVER then
    if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("entweapon")) then return end
    AddCSLuaFile()

    ENT.Sounds = {
        PressOne = Sound("dakara/dakara_control_panel.wav"),
        PressFew = Sound("dakara/dakara_control_panel2.wav")
    }

    ENT.Anims = {"push1", "push2", "push3", "push4", "push5", "random", "reset", "crystalo", "crystalc"}

    -----------------------------------INIT----------------------------------
    function ENT:Initialize()
        util.PrecacheModel("models/Iziraider/dakara/console.mdl")
        self.Entity:SetModel("models/Iziraider/dakara/console.mdl")
        self.Entity:SetName("Ancient Control Console")
        self.Entity:PhysicsInit(SOLID_VPHYSICS)
        self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
        self.Entity:SetSolid(SOLID_VPHYSICS)
        self.Entity:SetUseType(SIMPLE_USE)
        self.CurrentOption = 0
        self.OpenCrystal = false
        self.Busy = false
        self.AlreadyOpened = false
        self.AnimRunning = false
        self.SlotOpen = false
        --self.SelectiveTargeting = false
        
        -- Register the console command once during initialization
        concommand.Add("AP" .. self:EntIndex(), function(ply, cmd, args)
            local power = tonumber(args[1])
            self.AnimRunning = true
            self:Anim(self.Anims[1], 0, false, self.Sounds.PressOne)
            self:Anim(self.Anims[2], 1.5, false, self.Sounds.PressOne)
            self:Anim(self.Anims[3], 3, false, self.Sounds.PressOne)
            self:Anim(self.Anims[4], 4.5, false, self.Sounds.PressOne)
            self:Anim(self.Anims[5], 6, false, self.Sounds.PressOne)
            self:Anim(self.Anims[6], 7.5 + power / 2, false, self.Sounds.PressFew)
            self:Anim(self.Anims[6], 11.5 + power / 2, false, self.Sounds.PressFew)
            self:Anim(self.Anims[7], 17.5 + power / 2, false, self.Sounds.PressOne)

            timer.Create("StopAnim" .. self:EntIndex(), 20 + power / 2, 1, function()
                self.AnimRunning = false
            end)

            local dakara = self:FindDakara()

            if (IsValid(dakara)) then
                target_players = tonumber(args[2])
                target_props = tonumber(args[3])
                target_vehicles = tonumber(args[4])
                target_replicators = tonumber(args[5])
                target_npcs = tonumber(args[6])
                target_range = tonumber(args[7])
                dial_gates = tonumber(args[8])

                timer.Create("PrepareDakara" .. self:EntIndex(), 5 / 2, 1, function()
                if (IsValid(dakara)) then
                    dakara:PrepareWeapon(power, target_players, target_props, target_vehicles, target_replicators, target_npcs, target_range, dial_gates)
                end
                end)
                timer.Create("DialAllGates" .. self:EntIndex(), 1 / 2, 1, function()
                    if (dial_gates == 1) then
                        self:DiallAllGates(dakara, dial_gates)
                    end
                end)
            end
        end)
    end

    -----------------------------------USE----------------------------------
    function ENT:Use(ply)
        if (not self.Busy) then
            umsg.Start("AncientPanel", ply)
            umsg.Entity(self.Entity)
            --umsg.Bool(StarGate.CFG:Get("cap_enhanced_cfg", "dakara_selective_targeting", false))
            umsg.End()
            self.Player = ply
        end
    end

    -- function ENT:StartTouch(ent)
    -- if IsValid(ent) then
    -- if (ent:GetModel() == "models/iziraider/artifacts/ancient_pallet.mdl") then
    -- if not self.AlreadyOpened then
    -- self.AlreadyOpened = true;
    -- local dakara = self:FindDakara();
    -- dakara.Inputs = WireLib.CreateInputs( dakara, {"Main", "Secret"});
    -- end
    -- end
    -- end
    -- end
    -- function ENT:ToggleCrystal()
    -- if self.OpenCrystal then
    -- self.OpenCrystal = false;
    -- self.ModelAnim:Fire("setanimation","crystalc","0")
    -- else
    -- self.OpenCrystal = true;
    -- self.ModelAnim:Fire("setanimation","crystalo","0")
    -- end
    -- end
    -----------------------------------OTHER CRAP----------------------------------
    function ENT:UpdateTransmitState()
        return TRANSMIT_ALWAYS
    end

    --########## Run the anim that's set in the arguements @RononDex
    function ENT:Anim(anim, delay, nosound, sound)
        timer.Create(anim .. self:EntIndex(), delay, 1, function()
            if IsValid(self) then
                self:NextThink(CurTime())

                --Set false to allow sound
                if (not (nosound)) then
                    self:EmitSound(sound, 100, math.random(90, 110)) --create sound as a string in the arguements
                end

                self:SetPlaybackRate(1)
                self:ResetSequence(self:LookupSequence(anim)) -- play the sequence
            end
        end)
    end

    function ENT:Think()
        --run often only if doors are busy
        if self.AnimRunning then
            self:NextThink(CurTime())

            return true
        end
    end

    function ENT:DiallAllGates(dakara , dial_gates)
        self.DialGate = dakara:FindGate()

        if IsValid(self.DialGate) then
            self.IncomingGates = dakara:FindAllGate()
            self.DialGate.Target = self.DialGate
            self.DialGate:AbortDialling()

            for _, v in pairs(self.IncomingGates or {}) do
                v:AbortDialling()
            end

            timer.Create("DialFrom" .. self:EntIndex(), 2, 1, function()
                local action = self.DialGate.Sequence:New()
                action = self.DialGate.Sequence:Dial(false, true, false)
                action = action + self.DialGate.Sequence:OpenGate(true)
                self.DialGate:RunActions(action)
            end)

            timer.Create("DialTo" .. self:EntIndex(), 2.3, 1, function()
                for _, v in pairs(self.IncomingGates or {}) do
                    if v == self.DialGate then continue end
                    v.Outbound = true -- fix lighting up dhds
                    local action = v.Sequence:New()
                    action = v.Sequence:Dial(true, true, false)
                    action = action + v.Sequence:OpenGate()
                    v:RunActions(action)
                end
            end)

            timer.Create("Autoclose" .. self:EntIndex(), 15, 1, function()
                if (IsValid(self.DialGate)) then
                    self.DialGate:EmergencyShutdown() -- different methods or gates wont close, hope it will work
                    self.DialGate:AbortDialling()
                    self.DialGate:DeactivateStargate(true)

                    for _, v in pairs(self.IncomingGates or {}) do
                        if IsValid(v) then
                            v:EmergencyShutdown()
                            v:AbortDialling()
                            v:DeactivateStargate(true)
                        end
                    end
                end
            end)
        end
    end

    function ENT:FindDakara()
        local gate
        local dist = 10000000
        local pos = self.Entity:GetPos()

        for _, v in pairs(ents.FindByClass("dakara_building")) do
            local sg_dist = (pos - v:GetPos()):Length()

            if (dist >= sg_dist) then
                dist = sg_dist
                gate = v
            end
        end

        return gate
    end
end

if CLIENT then
    local SelectiveTargeting = false
    function ENT:Draw()
        self.Entity:DrawModel()
    end

    local VGUI = {}

    function VGUI:Init()
        local DermaPanel = vgui.Create("DFrame")
        DermaPanel:SetPos(ScrW() / 2 - 163.5, ScrH() / 2 - 227.5)
        DermaPanel:SetSize(400, 270)
        DermaPanel:SetTitle("Dakara Device Control Panel")
        DermaPanel:SetVisible(true)
        DermaPanel:SetDraggable(false)
        DermaPanel:ShowCloseButton(true)
        DermaPanel:MakePopup()

        DermaPanel.Paint = function()
            surface.SetDrawColor(80, 80, 80, 185)
            surface.DrawRect(0, 0, DermaPanel:GetWide(), DermaPanel:GetTall())
        end

        local NumSliderThingy2 = vgui.Create("DNumSlider", DermaPanel)
        NumSliderThingy2:SetPos(25, 180)
        NumSliderThingy2:SetSize(360, 50)
        NumSliderThingy2:SetText("Faster - Stronger")
        NumSliderThingy2:SetMin(-5)
        NumSliderThingy2:SetMax(5)
        NumSliderThingy2:SetValue(0)
        NumSliderThingy2:SetDecimals(2)
        NumSliderThingy2:SetToolTip("Set the Power of Device, which affect on radius and time of charging.")
        local CheckBoxThing1 = vgui.Create("DCheckBoxLabel", DermaPanel)
        CheckBoxThing1:SetPos(25, 30)
        CheckBoxThing1:SetText("Desintegrate Players")
        CheckBoxThing1:SetValue(1)
        CheckBoxThing1:SizeToContents()
        CheckBoxThing1:SetToolTip("Set for desintegrate players.")
        local immunity = 0
        local CheckBoxThing2 = vgui.Create("DCheckBoxLabel", DermaPanel)
        CheckBoxThing2:SetPos(25, 50)
        CheckBoxThing2:SetText("Desintegrate Props")
        CheckBoxThing2:SetValue(0)
        CheckBoxThing2:SizeToContents()
        CheckBoxThing2:SetToolTip("Set for desintegrate props.")
        local phaseshifting = 0
        local CheckBoxThing3 = vgui.Create("DCheckBoxLabel", DermaPanel)
        CheckBoxThing3:SetPos(25, 70)
        CheckBoxThing3:SetText("Desintegrate Vehicles")
        CheckBoxThing3:SetValue(0)
        CheckBoxThing3:SizeToContents()
        CheckBoxThing3:SetToolTip("Set for desintegrate vehicles.")
        local drawbubble = 0
        local CheckBoxThing4 = vgui.Create("DCheckBoxLabel", DermaPanel)
        CheckBoxThing4:SetPos(200, 30)
        CheckBoxThing4:SetText("Desintegrate Replicators")
        CheckBoxThing4:SetValue(0)
        CheckBoxThing4:SizeToContents()
        CheckBoxThing4:SetToolTip("Set for desintegrate replicators.")
        local passing = 0
        local CheckBoxThing5 = vgui.Create("DCheckBoxLabel", DermaPanel)
        CheckBoxThing5:SetPos(200, 50)
        CheckBoxThing5:SetText("Desintegrate NPCs")
        CheckBoxThing5:SetValue(0)
        CheckBoxThing5:SizeToContents()
        CheckBoxThing5:SetToolTip("Set for desintegrate NPCs.")

        -- if SelectiveTargeting then
        --     local CheckBoxThing6 = vgui.Create("DCheckBoxLabel", DermaPanel)
        --     CheckBoxThing6:SetPos(200, 70)
        --     CheckBoxThing6:SetText("Desintegrate Entiity of type:")
        --     CheckBoxThing6:SetValue(0)
        --     CheckBoxThing6:SizeToContents()
        --     CheckBoxThing6:SetToolTip("Set for desintegrate entities.")
        
        --     local CheckBoxThing7 = vgui.Create("DTextEntry", DermaPanel)
        --     CheckBoxThing7:SetPos(200, 90)
        --     CheckBoxThing7:SetText("Desintegrate Entity of type:")
        --     CheckBoxThing7:SetValue("")
        --     CheckBoxThing7:SizeToContents()
        --     CheckBoxThing7:SetToolTip("Set for desintegrate entities.")
        -- end

        local CheckBoxThing8 = vgui.Create("DCheckBoxLabel", DermaPanel)
        CheckBoxThing8:SetPos(25, 90)
        CheckBoxThing8:SetText("Dial Stargates")
        CheckBoxThing8:SetValue(0)
        CheckBoxThing8:SizeToContents()
        CheckBoxThing8:SetToolTip("Should the weapon dial stargates?")

        local NumSliderThingy3 = vgui.Create("DNumSlider", DermaPanel)
        NumSliderThingy3:SetPos(25, 130)
        NumSliderThingy3:SetSize(360, 50)
        NumSliderThingy3:SetText("Set size of wave")
        NumSliderThingy3:SetMin(5000)
        NumSliderThingy3:SetMax(18000)
        NumSliderThingy3:SetValue(0)
        NumSliderThingy3:SetDecimals(0)
        NumSliderThingy3:SetToolTip("Set the Power of Device, which affect on radius and time of charging.")


        local containment = 0
        local MenuButtonClose = vgui.Create("DButton")
        MenuButtonClose:SetParent(DermaPanel)
        MenuButtonClose:SetText("Close")
        MenuButtonClose:SetPos(25, 230)
        MenuButtonClose:SetSize(75, 25)

        MenuButtonClose.DoClick = function(btn)

            DermaPanel:Remove()
        end

        local MenuButtonCreate = vgui.Create("DButton")
        MenuButtonCreate:SetParent(DermaPanel)
        MenuButtonCreate:SetText("Launch")
        MenuButtonCreate:SetPos(125, 230)
        MenuButtonCreate:SetSize(75, 25)

        MenuButtonCreate.DoClick = function(btn)
            local d_ply = 0
            local d_prp = 0
            local d_veh = 0
            local d_rep = 0
            local d_npc = 0
            local d_gate = 0
            local power = NumSliderThingy2:GetValue() + 5
            local range = NumSliderThingy3:GetValue()

            if (CheckBoxThing1:GetChecked()) then
                d_ply = 1
            end

            if (CheckBoxThing2:GetChecked()) then
                d_prp = 1
            end

            if (CheckBoxThing3:GetChecked()) then
                d_veh = 1
            end

            if (CheckBoxThing4:GetChecked()) then
                d_rep = 1
            end

            if (CheckBoxThing5:GetChecked()) then
                d_npc = 1
            end
            
            if (CheckBoxThing8:GetChecked()) then
                d_gate = 1
            end

            LocalPlayer():ConCommand("AP" .. e:EntIndex() .. " " .. power .. " " .. d_ply .. " " .. d_prp .. " " .. d_veh .. " " .. d_rep .. " " .. d_npc.." "..range.." "..d_gate)
            DermaPanel:Remove()
        end
    end

    vgui.Register("AncientEntry", VGUI)

    function AncientPanel(um)
        local Window = vgui.Create("AncientEntry")
        Window:SetMouseInputEnabled(true)
        Window:SetVisible(true)
        e = um:ReadEntity()
        if (not IsValid(e)) then return end
        --SelectiveTargeting = um:ReadBool()
    end

    usermessage.Hook("AncientPanel", AncientPanel)
end