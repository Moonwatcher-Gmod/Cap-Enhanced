if (StarGate ~= nil and StarGate.LifeSupportAndWire ~= nil) then
    StarGate.LifeSupportAndWire(ENT)
end

ENT.Type = "anim"
ENT.Base = "base_anim" --gmodentity
ENT.PrintName = "Pulser"
ENT.Author = "Soren"
ENT.WireDebugName = "Pulser"
ENT.Spawnable = false
ENT.AdminSpawnable = false

--ENT.Category = "Stargate Carter Addon Pack: MoonWatcher"
--list.Set("CAP.Entity", ENT.PrintName, ENT)
ENT.Category = "MoonWatcher"

if SERVER then
    AddCSLuaFile()
    function ENT:Initialize()
        self.Entity:SetModel("models/hunter/blocks/cube05x05x05.mdl")
        self.Entity:PhysicsInit(SOLID_VPHYSICS)
        self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
        self.Entity:SetSolid(SOLID_VPHYSICS)
        self.Busy = false
        self:CreateWireInputs("Pulse!")
    end

    function ENT:TriggerInput(k, v)
        
        if (k == "Pulse!") then
            if ((v or 0) >= 1) then
                    self:Pulse()
                
            end
        end
    end

    function ENT:Pulse()
        if (self.Busy ==true) then return end
        --self:SetColor( Color( 255, 0, 0, 255 ) )
        --self:EmitSound("ambient/energy/spark4.wav",100,math.random(90,100))
        -- local fx = EffectData() 
        --         fx:SetOrigin( self:GetPos() ) 
        --         fx:SetEntity(self) 
        --         fx:SetScale( 0.4 * 4 ) 
        --         fx:SetRadius( 20 + 10 * 4 ) 
        --         fx:SetNormal( Vector( 2, 0.1, 0.15 ) * 1 )
                
        --         util.Effect( "scifi_aftershock", fx )

        -- local effectdata = EffectData()
        --     effectdata:SetOrigin( self.Entity:LocalToWorld(self.Entity:OBBCenter()-Vector(0,0,20)))
        --     effectdata:SetMagnitude(0)
        -- util.Effect( "transportcore", effectdata )

        -- local ed = EffectData()
        --     ed:SetEntity(self)
        -- util.Effect( "old_propspawn", ed, true, true )


        --self:SetColor( Color( 0, 0, 255, 255 ) ) 
        self.Busy = true
        timer.Simple(0.10, function ()

            self:Contact_pulsers()
        end)

        timer.Simple(1.3, function ()
            self.Busy = false
            --self:SetColor( Color( 255, 255, 255, 255 ) ) 
        end)
    end

    function ENT:Contact_pulsers()
        pulsers = ents.FindInSphere(self:GetPos(), 150)

        for i,v in ipairs(pulsers) do
            if (v:GetClass()=="pulser") then

                if (v.Busy == false) then
                    local fx3 = EffectData()
                        fx3:SetStart(self:GetPos());
                        fx3:SetOrigin(v:GetPos());
                        fx3:SetScale(50);
                        fx3:SetMagnitude(50);
                        fx3:SetEntity(self);
                        fx3:SetRadius(200)

                        util.Effect("icarus_zap", fx3)
                    local SparkFX = EffectData()
                        SparkFX:SetOrigin(self:GetPos())
                        SparkFX:SetMagnitude(1)
                        SparkFX:SetScale(1)
                        SparkFX:SetRadius(10)


                    
                    util.Effect("Sparks",SparkFX)
                    --util.Effect("TeslaHitBoxes",fx3);
                    v:Pulse()
                end
            elseif (v:IsNPC()) then
                local fx3 = EffectData()
                        fx3:SetStart(self:GetPos());
                        fx3:SetOrigin(v:GetPos());
                        fx3:SetScale(50);
                        fx3:SetMagnitude(50);
                        fx3:SetEntity(self);
                        fx3:SetRadius(200)

                        util.Effect("icarus_zap", fx3)
                    v:TakeDamage(10)
            end
        end
    end

    function ENT:SpawnFunction(pl, tr)
        local e = ents.Create("pulser")
        e:SetPos(tr.HitPos)
        e:SetUseType(SIMPLE_USE)
        e:Spawn()

        return e
    end
end