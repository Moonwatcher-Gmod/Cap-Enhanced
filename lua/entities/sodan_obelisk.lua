--[[
	Sodan Obelisk
	Copyright (C) 2010 Madman07
]]
--
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Sodan Obelisk"
ENT.Author = "RononDex, Madman07, Rafael De Jongh"
ENT.Category = "Stargate Carter Addon Pack"
if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
ENT.Category = SGLanguage.GetMessage("entity_main_cat");
end
list.Set("CAP.Entity", ENT.PrintName, ENT)

ENT.ButtonPos = {
    [1] = Vector(22.53, -3.98, 94.35),
    [2] = Vector(22.53, 4.63, 94.35),
    [3] = Vector(22.53, -3.98, 81.5),
    [4] = Vector(22.53, 4.63, 81.5),
    [5] = Vector(22.53, -3.98, 69.45),
    [6] = Vector(22.53, 4.63, 69.45),
    PASS = Vector(22.53, 4.63, 43.4)
}

function ENT:GetAimingButton(p)
    local e = self.Entity
    local c = self.ButtonPos
    local t = p:GetEyeTrace()
    local cv = self.Entity:WorldToLocal(t.HitPos)
    local btn = nil
    local lastd = 5

    for k, v in pairs(c) do
        da = (cv - c[k]):Length()

        if (da < 1.5) then
            if (da < lastd) then
                lastd = da
                btn = k
            end
        end
    end

    return btn
end

if SERVER then
    if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("devices")) then return end
    AddCSLuaFile()

    ENT.Sounds = {
        [1] = Sound("button/ancient_button1.wav"),
        [2] = Sound("button/ancient_button2.wav"),
        Transport = Sound("tech/sodan_oblisk.wav")
    }

    -----------------------------------INIT----------------------------------
    function ENT:Initialize()
        self.Entity:SetModel("models/ZsDaniel/ancient-obelisk/obelisk.mdl")
        self.Entity:SetName("Sodan Obelisk")
        self.Entity:PhysicsInit(SOLID_VPHYSICS)
        self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
        self.Entity:SetSolid(SOLID_VPHYSICS)
        self.Entity:SetUseType(SIMPLE_USE)
        self.Range = 600
        self.CantDial = false
        self.DialAdress = {}
        self.Password = ""
        self.Entity:SetNWString("pass", "")
        self.Entity:SetNWString("ADDRESS", string.Implode(",", self.DialAdress))
    end

    -----------------------------------SPAWN----------------------------------
    function ENT:SpawnFunction(ply, tr)
        if (not tr.Hit) then return end
        local PropLimit = GetConVar("CAP_sod_obelisk_max"):GetInt()

        if (ply:GetCount("CAP_sod_obelisk") + 1 > PropLimit) then
            ply:SendLua("GAMEMODE:AddNotify(SGLanguage.GetMessage(\"entity_limit_sod_obelisk\"), NOTIFY_ERROR, 5); surface.PlaySound( \"buttons/button2.wav\" )")

            return
        end

        local ang = ply:GetAimVector():Angle()
        ang.p = 0
        ang.r = 0
        ang.y = (ang.y + 180) % 360
        local ent = ents.Create("sodan_obelisk")
        ent:SetAngles(ang)
        ent:SetPos(tr.HitPos)
        ent:Spawn()
        ent:Activate()
        ent.Owner = ply
        local phys = ent:GetPhysicsObject()

        if IsValid(phys) then
            phys:EnableMotion(false)
        end

        ply:AddCount("CAP_sod_obelisk", ent)

        return ent
    end

    -----------------------------------USE----------------------------------
    function ENT:Use(ply)
        if (IsValid(ply) and ply:IsPlayer()) then
            if self.Paired and IsValid(self.Target) then
                local button = self:GetAimingButton(ply)

                if (button) then
                    if button == "PASS" then
                        if ply == self.Owner then
                            self.Entity:EmitSound(self.Sounds[2])
                            umsg.Start("ObeliskShowPassWindow", ply)
                            umsg.Entity(self.Entity)
                            umsg.End()
                            ply.ObeliskNameEnt = self
                        end
                    else
                        self:PressButton(button, ply)
                    end
                end
            end
        end
    end

    -----------------------------------BUTTON----------------------------------
    function ENT:PressButton(button, ply)
        self.CantDial = true
        if table.HasValue(self.DialAdress, button) then return end
        table.insert(self.DialAdress, button)
        self.Entity:SetNWString("ADDRESS", string.Implode(",", self.DialAdress))
        local adr = string.Implode("", self.DialAdress)

        if (adr == self.Password) then
            self.Entity:EmitSound(self.Sounds[2])

            timer.Create(self.Entity:EntIndex() .. "Dial", 2, 1, function()
                if (IsValid(self)) then
                    self.DialAdress = nil
                    self.DialAdress = {}
                    self.CantDial = false
                    self.Entity:SetNWString("ADDRESS", string.Implode(",", self.DialAdress))
                end
            end)

            timer.Destroy(self.Entity:EntIndex() .. "Counting")
            self.Entity:Teleport()
        else
            if (table.getn(self.DialAdress) == 0) then
                timer.Create(self.Entity:EntIndex() .. "Counting", 3, 1, function()
                    if (IsValid(self)) then
                        self.DialAdress = nil
                        self.DialAdress = {}
                        self.CantDial = false
                        self.Entity:SetNWString("ADDRESS", string.Implode(",", self.DialAdress))
                    end
                end)
            else
                if timer.Exists(self.Entity:EntIndex() .. "Counting") then
                    timer.Destroy(self.Entity:EntIndex() .. "Counting")
                end

                timer.Create(self.Entity:EntIndex() .. "Counting", 3, 1, function()
                    if (IsValid(self)) then
                        self.DialAdress = nil
                        self.DialAdress = {}
                        self.CantDial = false
                        self.Entity:SetNWString("ADDRESS", string.Implode(",", self.DialAdress))
                    end
                end)
            end

            timer.Create(self.Entity:EntIndex() .. "Skin", 0.5, 1, function()
                self.CantDial = false
            end)

            self.Entity:EmitSound(self.Sounds[1])
        end
    end

    -----------------------------------PAIR----------------------------------
    function ENT:Touch(ent)
        if (ent:GetClass() == "sodan_obelisk") then
            if not self.Paired then
                local fx = EffectData()
                fx:SetEntity(self.Entity)
                util.Effect("propspawn", fx)
                self.Target = ent
                self.Paired = true
            end
        end
    end

    -----------------------------------PASS----------------------------------
    function SetObeliskPassword(ply, cmd, args)
        if ply.ObeliskNameEnt and ply.ObeliskNameEnt ~= NULL then
            if args[1] then
                ply.ObeliskNameEnt.Password = args[1]
                ply.ObeliskNameEnt:SetNWString("pass", args[1])

                if ply.ObeliskNameEnt.Paired and IsValid(ply.ObeliskNameEnt.Target) then
                    ply.ObeliskNameEnt.Target.Password = args[1]
                    ply.ObeliskNameEnt.Target:SetNWString("pass", args[1])
                end
            end

            ply.ObeliskNameEnt = nil
        end
    end

    concommand.Add("setobeliskpass", SetObeliskPassword)

    -----------------------------------TELEPORT----------------------------------
    function ENT:Teleport()
        if IsValid(self.Entity) and IsValid(self.Target) then
            local pos = self.Entity:GetPos()
            local oldpos = Vector(0, 0, 5)
            local newpos = Vector(0, 0, 5)
            self.Entity:EmitSound(self.Sounds.Transport, 100, math.random(90, 110))
            self.Target:EmitSound(self.Sounds.Transport, 100, math.random(90, 110))
            local deltayaw = self.Entity:GetAngles().Yaw - self.Target:GetAngles().Yaw

            local function IsPlayerNPC(self, v)
                if IsValid(v) and (v:IsPlayer() or v:IsNPC()) then
                    local dist = (pos - v:GetPos()):Length()

                    if (dist < self.Range) then
                        timer.Create("Transport" .. v:EntIndex(), 0.5, 1, function()
                            if not IsValid(self.Entity) then return end
                            if not IsValid(v) then return end
                            oldpos = self.Entity:WorldToLocal(v:GetPos()) + Vector(0, 0, 5)
                            newpos = self.Target:LocalToWorld(oldpos)
                            v:SetPos(newpos)

                            if (not v:IsNPC()) then
                                v:SetEyeAngles(v:GetAimVector():Angle() - Angle(0, deltayaw, 0))
                            else
                                v:SetAngles(v:GetAimVector():Angle() - Angle(0, deltayaw, 0))
                            end

                            local fx3 = EffectData()
                            fx3:SetOrigin(v:GetShootPos() + v:GetAimVector() * 10)
                            fx3:SetEntity(v)
                            util.Effect("arthur_cloak", fx3, true)
                        end)

                        local fx = EffectData()
                        fx:SetOrigin(v:GetShootPos() + v:GetAimVector() * 10)
                        fx:SetEntity(v)
                        util.Effect("arthur_cloak", fx, true)
                        local fx2 = EffectData()
                        fx2:SetEntity(v)
                        util.Effect("arthur_cloak_light", fx2, true)
                    end
                end
            end

            for _, v in pairs(ents.FindByClass("player*")) do
                IsPlayerNPC(self, v)
            end

            for _, v in pairs(ents.FindByClass("npc*")) do
                IsPlayerNPC(self, v)
            end
        end
    end

    function ENT:OnRemove()
        if timer.Exists(self.Entity:EntIndex() .. "Dial") then
            timer.Destroy(self.Entity:EntIndex() .. "CloseGates")
        end

        if timer.Exists("Transport*") then
            timer.Destroy("Transport*")
        end

        if timer.Exists(self.Entity:EntIndex() .. "Counting") then
            timer.Destroy(self.Entity:EntIndex() .. "TeleportEffect")
        end

        if timer.Exists(self.Entity:EntIndex() .. "Skin") then
            timer.Destroy(self.Entity:EntIndex() .. "DialGates")
        end

        if IsValid(self.Entity) then
            self.Entity:Remove()
        end
    end

    -----------------------------------DUPLICATOR----------------------------------
    function ENT:PreEntityCopy()
        local dupeInfo = {}

        if IsValid(self.Entity) then
            dupeInfo.EntID = self.Entity:EntIndex()
        end

        dupeInfo.Password = self.Password
        dupeInfo.Target = self.Target
        dupeInfo.Paired = self.Paired
        duplicator.StoreEntityModifier(self, "SodanTrDupeInfo", dupeInfo)
    end

    duplicator.RegisterEntityModifier("SodanTrDupeInfo", function() end)

    function ENT:PostEntityPaste(ply, Ent, CreatedEntities)
        if (StarGate.NotSpawnable(Ent:GetClass(), ply)) then
            self.Entity:Remove()

            return
        end

        if (IsValid(ply)) then
            local PropLimit = GetConVar("CAP_sod_obelisk_max"):GetInt()

            if (ply:GetCount("CAP_sod_obelisk") + 1 > PropLimit) then
                ply:SendLua("GAMEMODE:AddNotify(SGLanguage.GetMessage(\"entity_limit_sod_obelisk\"), NOTIFY_ERROR, 5); surface.PlaySound( \"buttons/button2.wav\" )")
                self.Entity:Remove()

                return
            end
        end

        local dupeInfo = Ent.EntityMods.SodanTrDupeInfo

        if dupeInfo.EntID then
            self.Entity = CreatedEntities[dupeInfo.EntID]
        end

        self.Password = dupeInfo.Password
        self.Target = dupeInfo.Target
        self.Paired = dupeInfo.Paired

        if (self.Paired and IsValid(self.Target)) then
            self.Target.Target = self
            self.Target.Paired = true
        end

        self.Entity:SetNWString("pass", self.Password)

        if (IsValid(ply)) then
            self.Owner = ply
            ply:AddCount("CAP_sod_obelisk", self.Entity)
        end
    end

    if (StarGate and StarGate.CAP_GmodDuplicator) then
        duplicator.RegisterEntityClass("sodan_obelisk", StarGate.CAP_GmodDuplicator, "Data")
    end
end

if CLIENT then

    ENT.ButtonPos = {
        [1] = Vector(22.53, -3.98, 94.35),
        [2] = Vector(22.53, 4.63, 94.35),
        [3] = Vector(22.53, -3.98, 81.5),
        [4] = Vector(22.53, 4.63, 81.5),
        [5] = Vector(22.53, -3.98, 69.45),
        [6] = Vector(22.53, 4.63, 69.45),
        [7] = Vector(22.53, 4.63, 43.4)
    }

    function ENT:Draw()
        self.Entity:DrawModel()
        local address = self.Entity:GetNetworkedString("ADDRESS"):TrimExplode(",")
        local eye = self.Entity:WorldToLocal(LocalPlayer():GetEyeTrace().HitPos)
        local len = (eye - Vector(22.53, -3.98, 69.45)):Length()

        if (len <= 50 or table.GetFirstValue(address) ~= "") then
            local restalpha = 0

            if (len <= 50) then
                restalpha = 100
            end

            local ang = self.Entity:GetAngles()
            ang:RotateAroundAxis(ang:Up(), -90)
            ang:RotateAroundAxis(ang:Up(), 180)
            ang:RotateAroundAxis(ang:Forward(), 90)
            local button = 0
            button = self:GetAimingButton(LocalPlayer())

            for i = 1, 7 do
                local pos = self.Entity:LocalToWorld(self.ButtonPos[i])
                local alpha = restalpha

                if (table.HasValue(address, tostring(i)) or button == i) then
                    alpha = 200
                end

                local a = Color(255, 255, 255, alpha)
                local txt = i

                if (i == 7) then
                    txt = "PASS"
                end

                cam.Start3D2D(pos, ang, 0.1)
                draw.SimpleText(txt, "DHD_font", 0, 0, a, 1, 1)
                cam.End3D2D()
            end
        end
    end

    local PANEL = {}

    function PANEL:DoClick()
        local panel2 = self:GetParent()
        LocalPlayer():ConCommand("setobeliskpass " .. panel2.TextEntry:GetValue())
        panel2:Remove()
    end

    vgui.Register("ObeliskPassButton", PANEL, "Button")
    local PANEL = {}

    function PANEL:Init()
        self:SetSize(500, 80)
        self:SetName("Password")
        self:MakePopup()
        self:SetSizable(false)
        self:SetDraggable(false)
        self:SetTitle("")
        self.Logo = vgui.Create("DImage", self)
        self.Logo:SetPos(8, 10)
        self.Logo:SetImage("gui/cap_logo")
        self.Logo:SetSize(16, 16)
        self.TextEntry = vgui.Create("DTextEntry", self)
        self.TextEntry:SetText("")

        self.TextEntry.OnTextChanged = function(TextEntry)
            local pos = TextEntry:GetCaretPos()
            local len = TextEntry:GetValue():len()
            local letters = TextEntry:GetValue():gsub("[^1-6]", ""):TrimExplode("")
            local text = "" -- Wipe

            for _, v in pairs(letters) do
                if (not text:find(v)) then
                    text = text .. v
                end
            end

            TextEntry:SetText(text)
            TextEntry:SetCaretPos(math.Clamp(pos - (len - #letters), 0, text:len())) -- Reset the caretpos!
        end

        self.L1 = vgui.Create("DLabel", self)
        self.L1:SetText("Set obelisk password (only numbers from 1 to 6!):")
        self.L1:SetFont("OldDefaultSmall")
        self.Button = vgui.Create("ObeliskPassButton", self)
        self.Button:SetText("OK")
        self.Button:SetPos(425, 39)
        self.TextEntry:SetSize(405, self.TextEntry:GetTall())
        self.TextEntry:SetPos(10, 40)
        self.L1:SetPos(30, 3)
        self.L1:SetSize(500, 30)
    end

    function PANEL:Paint(w, h)
        draw.RoundedBox(10, 0, 0, w, h, Color(16, 16, 16, 160))

        return true
    end

    vgui.Register("ObeliskPassEntry", PANEL, "DFrame")

    function ObeliskShowPassWindow(um)
        local Window = vgui.Create("ObeliskPassEntry")
        Window:SetKeyBoardInputEnabled(true)
        Window:SetMouseInputEnabled(true)
        Window:SetPos((ScrW() / 2 - 350) / 2, ScrH() / 2 - 75)
        Window:SetVisible(true)
        local e = um:ReadEntity()
        if (not IsValid(e)) then return end
        Window.TextEntry:SetText(e:GetNWString("pass"))
    end

    usermessage.Hook("ObeliskShowPassWindow", ObeliskShowPassWindow)
end