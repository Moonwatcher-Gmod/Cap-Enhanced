--[[
	Ancient Obelisk
	Copyright (C) 2010 Madman07
]]
--
ENT.Type = "anim"
ENT.Base = "base_anim"

if (StarGate ~= nil and StarGate.LifeSupportAndWire ~= nil) then
    StarGate.LifeSupportAndWire(ENT)
end

ENT.PrintName = "Ancient Obelisk"
ENT.Author = "Madman07, Rafael De Jongh"
ENT.Category = "Stargate Carter Addon Pack"
list.Set("CAP.Entity", ENT.PrintName, ENT)

if CLIENT then

if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
	ENT.Category = SGLanguage.GetMessage("entity_main_cat");
	ENT.PrintName = SGLanguage.GetMessage("entity_obelisk");
end

end

if SERVER then
    if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("devices")) then return end
    AddCSLuaFile()

    ENT.Sounds = {
        Transport = Sound("tech/gate_transport_oblisk.wav")
    }

    -----------------------------------INIT----------------------------------
    function ENT:Initialize()
        self.Entity:SetModel("models/ZsDaniel/ancient-obelisk/obelisk.mdl")
        self.Entity:SetName("Ancient Obelisk")
        self.Entity:PhysicsInit(SOLID_VPHYSICS)
        self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
        self.Entity:SetSolid(SOLID_VPHYSICS)
        self.ObeliskTable = {}
        self.Range = 1000

        --[[
	local CurrentToSend = true;
	for _,v in pairs(ents.FindByClass("ancient_obelisk")) do
		if (v != self) then
			CurrentToSend = false;
		end
	end

	if CurrentToSend then self.Entity:CreateTimer() end     ]]
        -- now global timer, not anymore bugs with few times...
        if (not timer.Exists("CAP_Obelisk_TeleportFunc")) then
            timer.Create("CAP_Obelisk_TeleportFunc", 60, 0, function()
                local obelisks = ents.FindByClass("ancient_obelisk")

                if (obelisks and #obelisks > 1) then
                    table.Random(obelisks):PrepareTeleport()
                end
            end)
        end
    end

    -----------------------------------SPAWN----------------------------------
    function ENT:SpawnFunction(ply, tr)
        if (not tr.Hit) then return end
        local PropLimit = GetConVar("CAP_anc_obelisk_max"):GetInt()

        if (ply:GetCount("CAP_anc_obelisk") + 1 > PropLimit) then
            ply:SendLua("GAMEMODE:AddNotify(\"Ancient Obelisk limit reached!\", NOTIFY_ERROR, 5); surface.PlaySound( \"buttons/button2.wav\" )")

            return
        end

        local ang = ply:GetAimVector():Angle()
        ang.p = 0
        ang.r = 0
        ang.y = (ang.y + 180) % 360
        local ent = ents.Create("ancient_obelisk")
        ent:SetAngles(ang)
        ent:SetPos(tr.HitPos)
        ent:Spawn()
        ent:Activate()
        ent.Owner = ply
        local phys = ent:GetPhysicsObject()

        if IsValid(phys) then
            phys:EnableMotion(false)
        end

        ply:AddCount("CAP_anc_obelisk", ent)

        return ent
    end

    -----------------------------------THINK----------------------------------
    --[[
function ENT:CreateTimer()
	timer.Create(self.Entity:EntIndex().."TeleportFunc", 5, 1, function() if IsValid(self.Entity) then self:PrepareTeleport() end end)
end
]]
    function ENT:PrepareTeleport()
        self.TargetObelisk = nil

        -- well, be sure that target have stargates and its valid and adress is valid - no more manualy adres seting
        while (true) do
            self.Entity:FindObelisk()
            self.TargetObelisk = table.Random(self.ObeliskTable)
            if (not IsValid(self.TargetObelisk)) then return end
            self.TargetGate = self.TargetObelisk:FindGate()
            if (not IsValid(self.TargetGate)) then return end
            if (self.TargetGate:GetGateAddress() ~= "") then break end
        end

        --self.TargetObelisk:CreateTimer()
        self.PairGate = self.Entity:FindGate()
        if not IsValid(self.PairGate) then return end -- if there is no gates near current obelisk, then say other obelisk to transport sg-1

        -- if gates are open close them 2 times and give them time, then call prepare2
        if (self.PairGate.IsOpen or self.PairGate.Dialling or self.TargetGate.IsOpen or self.TargetGate.Dialling) then
            self.PairGate:AbortDialling()
            self.TargetGate:AbortDialling()

            timer.Create(self.Entity:EntIndex() .. "EmergencyAbortGates", 4, 1, function()
                if IsValid(self.PairGate) then
                    self.PairGate:AbortDialling()
                end

                if IsValid(self.TargetGate) then
                    self.TargetGate:AbortDialling()
                end
            end)

            timer.Create(self.Entity:EntIndex() .. "EmergencyAbortGates2", 8, 1, function()
                if IsValid(self.PairGate) then
                    self.PairGate:AbortDialling()
                end

                if IsValid(self.TargetGate) then
                    self.TargetGate:AbortDialling()
                end
            end)

            timer.Create(self.Entity:EntIndex() .. "EmergencyAbortGates3", 12, 1, function()
                if IsValid(self.PairGate) then
                    self.PairGate:AbortDialling()
                end

                if IsValid(self.TargetGate) then
                    self.TargetGate:AbortDialling()
                end
            end)

            timer.Create(self.Entity:EntIndex() .. "DelayedDialGates", 16, 1, function()
                self:PrepareTeleport2()
            end)
        else
            self:PrepareTeleport2()
        end
    end

    function ENT:PrepareTeleport2()
        --if obelisk isnt valid then go back to prepare, otherwise dial it!
        if IsValid(self.TargetObelisk) then
            if (IsValid(self.PairGate)) then
                self.PairGate:DialGate(self.TargetGate.GateAddress, true)

                timer.Create(self.Entity:EntIndex() .. "TeleportEffect", 10, 1, function()
                    if IsValid(self) then
                        self:Teleport()
                    end
                end)
            end
            --self.TargetObelisk:CreateTimer()
        else
            self:PrepareTeleport()
        end
    end

    function ENT:Teleport()
        if IsValid(self.Entity) and IsValid(self.TargetObelisk) and IsValid(self.TargetGate) then
            local pos = self.Entity:GetPos()
            local oldpos = Vector(0, 0, 5)
            local newpos = Vector(0, 0, 5)
            self.Entity:EmitSound(self.Sounds.Transport, 100, math.random(90, 110))
            self.TargetObelisk:EmitSound(self.Sounds.Transport, 100, math.random(90, 110))
            local deltayaw = self.PairGate:GetAngles().Yaw - self.TargetGate:GetAngles().Yaw

            local function IsPlayerNPC(self, v)
                if IsValid(v) and (v:IsPlayer() or v:IsNPC()) then
                    local dist = (pos - v:GetPos()):Length()

                    if (dist < self.Range) then
                        timer.Create("Transport" .. v:EntIndex(), 0.5, 1, function()
                            if not IsValid(self.Entity) then return end
                            if not IsValid(v) then return end
                            oldpos = self.PairGate:WorldToLocal(v:GetPos()) + Vector(0, 0, 5)
                            newpos = self.TargetGate:LocalToWorld(oldpos)
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

        timer.Create(self.Entity:EntIndex() .. "CloseGates", 1, 1, function()
            if not IsValid(self.Entity) then return end
            if not IsValid(self.PairGate) then return end
            if not IsValid(self.TargetGate) then return end
            self.TargetGate:AbortDialling()
        end)
    end

    function ENT:OnRemove()
        if not IsValid(self.PairGate) then
            self.PairGate = self.Entity:FindGate()
        end

        if timer.Exists(self.Entity:EntIndex() .. "CloseGates") then
            timer.Destroy(self.Entity:EntIndex() .. "CloseGates")
        end

        if timer.Exists("Transport*") then
            timer.Destroy("Transport*")
        end

        if timer.Exists(self.Entity:EntIndex() .. "TeleportEffect") then
            timer.Destroy(self.Entity:EntIndex() .. "TeleportEffect")
        end

        if timer.Exists(self.Entity:EntIndex() .. "TeleportFunc") then
            timer.Destroy(self.Entity:EntIndex() .. "TeleportFunc")
        end

        if timer.Exists(self.Entity:EntIndex() .. "EmergencyAbortGates") then
            timer.Destroy(self.Entity:EntIndex() .. "EmergencyAbortGates")
        end

        if timer.Exists(self.Entity:EntIndex() .. "EmergencyAbortGates2") then
            timer.Destroy(self.Entity:EntIndex() .. "EmergencyAbortGates2")
        end

        if timer.Exists(self.Entity:EntIndex() .. "EmergencyAbortGates3") then
            timer.Destroy(self.Entity:EntIndex() .. "EmergencyAbortGates3")
        end

        if timer.Exists(self.Entity:EntIndex() .. "DelayedDialGates") then
            timer.Destroy(self.Entity:EntIndex() .. "DelayedDialGates")
        end

        if IsValid(self.PairGate) then
            self.PairGate:AbortDialling()
        end

        if IsValid(self.TargetGate) then
            self.TargetGate:AbortDialling()
        end

        if IsValid(self.Entity) then
            self.Entity:Remove()
        end
    end

    -----------------------------------FIND RINGS----------------------------------
    function ENT:FindGate()
        local gate
        local dist = 500
        local pos = self.Entity:GetPos()

        for _, v in pairs(ents.FindByClass("stargate_*")) do
            if (v.IsGroupStargate and v:GetClass() ~= "stargate_orlin" and v:GetGateAddress() ~= "") then
                local sg_dist = (pos - v:GetPos()):Length()

                if (dist >= sg_dist) then
                    dist = sg_dist
                    gate = v
                end
            end
        end

        return gate
    end

    function ENT:FindObelisk()
        self.ObeliskTable = {}

        for _, v in pairs(ents.FindByClass("ancient_obelisk")) do
            if (not table.HasValue(self.ObeliskTable, v) and v ~= self.Entity) then
                table.insert(self.ObeliskTable, v)
            end
        end
    end

    function ENT:PreEntityCopy()
        local dupeInfo = {}

        if IsValid(self.Entity) then
            dupeInfo.EntID = self.Entity:EntIndex()
        end

        duplicator.StoreEntityModifier(self, "AncientObeliskDupeInfo", dupeInfo)
    end

    duplicator.RegisterEntityModifier("AncientObeliskDupeInfo", function() end)

    function ENT:PostEntityPaste(ply, Ent, CreatedEntities)
        if (StarGate.NotSpawnable(Ent:GetClass(), ply)) then
            self.Entity:Remove()

            return
        end

        local PropLimit = GetConVar("CAP_anc_obelisk_max"):GetInt()

        if (IsValid(ply)) then
            if (ply:GetCount("CAP_anc_obelisk") + 1 > PropLimit) then
                ply:SendLua("GAMEMODE:AddNotify(\"Ancient Obelisk limit reached!\", NOTIFY_ERROR, 5); surface.PlaySound( \"buttons/button2.wav\" )")
                self.Entity:Remove()

                return
            end

            ply:AddCount("CAP_sod_obelisk", self.Entity)
            self.Owner = ply
        end

        local dupeInfo = Ent.EntityMods.AncientObeliskDupeInfo

        if dupeInfo.EntID then
            self.Entity = CreatedEntities[dupeInfo.EntID]
        end
    end

    if (StarGate and StarGate.CAP_GmodDuplicator) then
        duplicator.RegisterEntityClass("ancient_obelisk", StarGate.CAP_GmodDuplicator, "Data")
    end
end