if (StarGate ~= nil and StarGate.LifeSupportAndWire ~= nil) then
    StarGate.LifeSupportAndWire(ENT)
end

ENT.Type = "anim"
ENT.Base = "base_anim" --gmodentity
ENT.PrintName = "Extractor"
ENT.Author = "Soren"
ENT.WireDebugName = "Extractor"
ENT.Spawnable = false
ENT.AdminSpawnable = false

--ENT.Category = "Stargate Carter Addon Pack: MoonWatcher"
--list.Set("CAP.Entity", ENT.PrintName, ENT)
--ENT.Category = "MoonWatcher"


if SERVER then
    if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("energy")) then return end
    AddCSLuaFile()

    function ENT:Initialize()
        self.Entity:SetModel("models/props_combine/combinethumper002.mdl")
        self.Entity:PhysicsInit(SOLID_VPHYSICS)
        self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
        self.Entity:SetSolid(SOLID_VPHYSICS)
        self.tier = 1
        self.multiplier = 1
        self.EntHealth = 100
        self.MaxHealth = self.EntHealth
        self.On = false
        self.wait = false
        self.firstime = true
        self.delay = 0.5
        self.lastOccurance = -self.delay
        self:Off()
        --self:AddResource("Promethium", 1000, 0)
        --self:AddResource("Trinium", 1000, 0)
        --self:AddResource("Naquadah", 1000, 0)
        --self:AddResource("Naquadria", 1000, 0)

        self:AddResource("energy",1);
        --self:SupplyResource("Promethium", 50 * self.multiplier)
        self:CreateWireInputs("ON/OFF", "Disable Use")
        self:CreateWireOutputs("Active","Current Resource", "Health")
        local phys = self.Entity:GetPhysicsObject()
        self:SetWire("Health", self.EntHealth)

        if (phys:IsValid()) then
            phys:EnableMotion(false)
            phys:SetMass(10)
        end
    end

    function ENT:SpawnFunction(pl, tr)
        if (not tr.HitWorld) then return end
        local e = ents.Create("extractor")
        e:SetPos(tr.HitPos)
        e:SetUseType(SIMPLE_USE)
        e:Spawn()

        return e
    end

    function ENT:Think()
        if (not self.HasResourceDistribution) then return end
        if self.On then

            ore_deposits = ents.FindInSphere(self:GetPos(), 500)

            for k,v in pairs(ore_deposits) do
                if (v:GetClass()=="oredeposit_pr" or v:GetClass()=="oredeposit_naq" or v:GetClass()=="oredeposit_naq+" or v:GetClass()=="oredeposit_trin" ) then
                    
                    if (v:GetClass()=="oredeposit_pr") then
                        --self:SupplyResource("Promethium", 50 * self.multiplier)
                    end
                    if (v:GetClass()=="oredeposit_naq") then
                        --self:SupplyResource("Naquadah", 50 * self.multiplier)
                    end
                    if (v:GetClass()=="oredeposit_naq+") then
                        --self:SupplyResource("Naquadria", 50 * self.multiplier)
                    end
                    if (v:GetClass()=="oredeposit_trin") then
                        --self:SupplyResource("Trinium", 50 * self.multiplier)
                    end
                end
            end

            self.wait = false
            self:SetWire("Active", 1)
        else
            --if (self.HasRD) then StarGate.WireRD.OnRemove(self,true) end;
            --self:AddResource("Promethium", 0)
            self:SetWire("Active", 0)

            --self.Energy = 0;
            if (not self.wait == true) then
                self:Off()
                self.wait = true
            end
        end

        --local my_capacity = self:GetUnitCapacity("energy");
        --local nw_capacity = self:GetNetworkCapacity("energy");
        --if(my_capacity ~= nw_capacity)then
        if (StarGate.WireRD.Connected(self.Entity)) then
            self.Connected = true
        else
            self.Connected = false
        end

        self:Output(self.enabled)
        self.Entity:NextThink(CurTime() + 1.5)

        return true
    end

    function ENT:Output(enabled)
        local add = "Offline"

        if (enabled) then
            add = "Online"
        else
            add = "Offline"
        end

        self:SetWire("Active", enabled)
        self.Entity:SetNWString("add", add)
        --self.Entity:SetNWInt("Tier", self.tier)
        --self.Entity:SetNWString("perc",perc);
        --self.Entity:SetNWString("eng",math.floor(eng));
    end

    function ENT:Off()
        --self.CloseAnim = self:LookupSequence("open") -- For some reason the anims are the wrong way round
        self.On = false
        self.enabled = false
        self.wait = true
        self:StopSound("apc_engine_start")

        if (not self.firstime) then
            self:EmitSound("apc_engine_stop")
        end
        --self:SetSequence(self.CloseAnim)
    end

    function ENT:SetOn()
        --self.OpenSeq = self:LookupSequence("close");
        self.On = true
        self.enabled = true
        self:EmitSound("apc_engine_start")
        --self:ResetSequence(self.OpenSeq);
    end

    function ENT:OnTakeDamage(dmg, attacker)
        self.EntHealth = self.EntHealth - dmg:GetDamage()
        self:SetWire("Health", self.EntHealth)

        if (self.EntHealth < 1) then
            self:Boom()
        end
    end

    function ENT:HealthRepair(health)
        self.EntHealth = health
        self:SetWire("Health", health)
    end

    function ENT:Boom()
        local fx = EffectData()
        fx:SetOrigin(self:GetPos())
        util.Effect("Explosion", fx)
        self:Remove()
        StarGate.WireRD.OnRemove(self)
    end

    function ENT:TriggerInput(k, v)
        if (self.depleted) then return end

        if (k == "ON/OFF") then
            if ((v or 0) >= 1) then
                if (self.enabled) then
                    self:Off()
                else
                    self:SetOn()
                end
            end
        end
    end

    function ENT:Use(p)
        if (self:GetWire("Disable Use") > 0) then return end
        if (self.depleted) then return end

        if (self.enabled) then
            self:Off()
        else
            self:SetOn()
        end
    end

    function ENT:PostEntityPaste(ply, Ent, CreatedEntities)
        if (StarGate.NotSpawnable("naq_gen_mks", ply, "tool")) then
            self.Entity:Remove()

            return
        end

        if (IsValid(ply)) then
            if (ply:GetCount("naq_gen_mks") + 1 > GetConVar("sbox_maxnaq_gen_mks"):GetInt()) then
                ply:SendLua("GAMEMODE:AddNotify(\"Naquadah generator limit reached!\", NOTIFY_ERROR, 5); surface.PlaySound( \"buttons/button2.wav\" )")
                self.Entity:Remove()

                return
            end

            ply:AddCount("naq_gen_mks", self.Entity)
        end

        StarGate.WireRD.PostEntityPaste(self, ply, Ent, CreatedEntities)
    end

    if (StarGate and StarGate.CAP_GmodDuplicator) then
        duplicator.RegisterEntityClass("extractor", StarGate.CAP_GmodDuplicator, "Data")
    end

    
end

if CLIENT then

	function ENT:Initialize()
	    self.Entity:SetNWString("add", "Offline")
	    self.Entity:SetNWInt("tier", 1)
	    self.Entity:SetNWString("perc", 0)
	    self.Entity:SetNWString("eng", 0)
	end

	--ENT.Zpm_hud = surface.GetTextureID("VGUI/resources_hud/ion_gen");
	function ENT:UpdateUI(hud_tier)
	    if (hud_tier == 2) then
	        c_hud = surface.GetTextureID("VGUI/resources_hud/tier_1")
	    end

	    if (hud_tier == 1) then
	        c_hud = surface.GetTextureID("VGUI/resources_hud/tier_2")
	    end

	    if (hud_tier == 3) then
	        c_hud = surface.GetTextureID("VGUI/resources_hud/ion_gen")
	    end

	    return c_hud
	end

	function ENT:OnRemove()
    	hook.Remove("HUDPaint", tostring(self.Entity) .. "ION")
    	self:StopSound("apc_engine_start")
	end

	--self:UpdateUI(self.Entity.GetNetworkedInt("tier"))
	function ENT:Draw()
	    self.Entity:DrawModel()
	    hook.Remove("HUDPaint", tostring(self.Entity) .. "ION")
	    if (not StarGate.VisualsMisc("cl_draw_huds", true)) then return end

	    if (LocalPlayer():GetEyeTrace().Entity == self.Entity and EyePos():Distance(self.Entity:GetPos()) < 1024) then
	        hook.Add("HUDPaint", tostring(self.Entity) .. "ION", function()
	            local w = 0
	            local h = 260
	            surface.SetTexture(self:UpdateUI(self:GetNetworkedInt("tier")))
	            surface.SetDrawColor(Color(255, 255, 255, 255))
	            surface.DrawTexturedRect(ScrW() / 2 + 6 + w, ScrH() / 2 - 50 - h, 180, 360)
	            surface.SetFont("center2")
	            surface.SetFont("header")
	            --draw.DrawText("Promethium", "header", ScrW() / 2 + 54 + w, ScrH() / 2 +41 - h, Color(255,255,255,255), 0)
	            draw.DrawText("Name", "center2", ScrW() / 2 + 40 + w, ScrH() / 2 + 65 - h, Color(209, 238, 238, 255), 0)
	            draw.DrawText("Status", "center2", ScrW() / 2 + 40 + w, ScrH() / 2 + 115 - h, Color(209, 238, 238, 255), 0)
	            draw.DrawText("Capacity", "center2", ScrW() / 2 + 40 + w, ScrH() / 2 + 165 - h, Color(209, 238, 238, 255), 0)

	            if (IsValid(self.Entity)) then
	                add = self.Entity:GetNetworkedString("add")
	                perc = self.Entity:GetNWString("perc")
	                eng = self.Entity:GetNWString("eng")
	            else
	                add = ""
	                perc = 0
	                eng = ""
	            end

	            surface.SetFont("center")

	            -- local color = Color(255,255,255,255);
	            -- if(add == "Offline" or add == "Depleted")then
	            --     color = Color(255,255,255,255);
	            -- end
	            if (tonumber(perc) > 0) then
	                perc = string.format("%4.2f", perc)
	            end

	            draw.SimpleText(add, "HudHintTextLarge", ScrW() / 2 + 54 + w, ScrH() / 2 + 35 - h, color, 0)
	            draw.SimpleText("Extractor", "center", ScrW() / 2 + 40 + w, ScrH() / 2 + 85 - h, Color(255, 255, 255, 255), 0)
	            draw.SimpleText(tostring(perc) .. "%", "center", ScrW() / 2 + 40 + w, ScrH() / 2 + 185 - h, Color(255, 255, 255, 255), 0)
	        end)
	    end
	end
end

